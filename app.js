(function() {
  var MongoClient, ObjectID, allowCrossDomain, app, assert, bodyParser, compression, db, db_url, express, fs, get_slices, get_work_or_data, morgan, serveStatic, shuffle, trusted_hosts, worker_js,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  express = require('express.io');

  bodyParser = require('body-parser');

  compression = require('compression');

  morgan = require('morgan');

  serveStatic = require('serve-static');

  assert = require('assert');

  fs = require('fs');

  MongoClient = require('mongodb').MongoClient;

  ObjectID = require('mongodb').ObjectID;

  app = express();

  trusted_hosts = ['http://localhost:3000'];

  db_url = 'mongodb://127.0.0.1:27017/tesis';

  worker_js = fs.readFileSync('worker.js', 'utf8');

  db = null;

  MongoClient.connect(db_url, function(err, connection) {
    assert.ifError(err);
    assert.ok(connection);
    return db = connection;
  });

  allowCrossDomain = function(req, res, next) {
    res.header('Access-Control-Allow-Origin', trusted_hosts);
    res.header('Access-Control-Allow-Methods', 'GET, POST');
    res.header('Access-Control-Allow-Headers', 'Content-Type');
    return next();
  };

  /* SET MIDDLEWARE
  */

  app.use(serveStatic(__dirname + '/public'));

  app.use(morgan('default'));

  app.use(bodyParser.urlencoded({
    extended: true
  }));

  app.use(compression());

  app.use(allowCrossDomain);

  shuffle = function(h) {
    var i, j, keys, randomKeyI, randomKeyJ, size, _ref, _ref2;
    keys = Object.keys(h);
    size = keys.length;
    for (i = 0, _ref = size - 1; 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
      randomKeyI = keys[i];
      j = Math.floor(Math.random() * size);
      randomKeyJ = keys[j];
      _ref2 = [h[randomKeyJ], h[randomKeyI]], h[randomKeyI] = _ref2[0], h[randomKeyJ] = _ref2[1];
    }
    return h;
  };

  get_slices = function(data, size) {
    var contador, hash, i, key, keysLength, value, _ref;
    hash = {};
    keysLength = Object.keys(data).length;
    for (i = 0, _ref = Math.floor(keysLength % size); 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
      hash[i] = {
        "status": "created",
        "data": {}
      };
    }
    i = 0;
    contador = 0;
    for (key in data) {
      value = data[key];
      hash[i].data[key] = value;
      contador++;
      if (contador % size === 0) i++;
    }
    return shuffle(hash);
  };

  get_work_or_data = function(callback) {
    return db.collection('workers', function(err, collection) {
      if (err) {
        return callback({
          task_id: 0
        });
      }
      assert.ok(collection);
      return collection.find({
        "status": {
          $ne: "reduce_pending"
        }
      }).toArray(function(err, items) {
        var size, work;
        if (err) {
          return callback({
            task_id: 0
          });
        }
        assert.ok(items);
        if (!items.length) {
          console.log("Workers empty");
          return callback({
            task_id: 0
          });
        }
        work = items[Math.floor(Math.random() * items.length)];
        size = Object.keys(work.slices).length;
        if (work.status !== 'reduce_pending' && work.received_count === size) {
          console.log("Entre al received");
          collection.update({
            _id: work._id
          }, {
            $set: {
              status: 'reduce_pending'
            }
          }, function(err, count) {
            if (err) {
              return callback({
                task_id: 0
              });
            }
            return assert.equal(1, count);
          });
          return get_work_or_data(callback);
        } else if (work.current_slice === size - 1) {
          return get_work_or_data(callback);
        }
        return collection.findAndModify({
          _id: work._id
        }, [], {
          $inc: {
            current_slice: 1
          }
        }, {
          "new": true
        }, function(err, work) {
          var arr, doc, key, value, _ref;
          if (err) {
            return callback({
              task_id: 0
            });
          }
          assert.ok(work);
          /* {"0": 1, "1": 1, "2": 2} => [["0",1],["1",1],["2",2]]
          */
          /* PROC.JS COMPATIBILITY, REMOVE THIS!
          */
          arr = [];
          _ref = work.slices[work.current_slice].data;
          for (key in _ref) {
            value = _ref[key];
            arr.push([key, value]);
          }
          doc = {
            task_id: work._id,
            slice_id: work.current_slice,
            data: arr,
            worker: work.worker_code + ";" + worker_js
          };
          return callback(doc);
        });
      });
    });
  };

  app.get('/work', function(req, res) {
    var _ref;
    if ((req.accepts('json') !== 'undefined') && (_ref = req.headers.origin, __indexOf.call(trusted_hosts, _ref) >= 0)) {
      return get_work_or_data(function(work) {
        return res.json(work);
      });
    }
    return res.send("");
  });

  app.post('/data', function(req, res) {
    var doc_id, result, slice_id, update;
    doc_id = req.body.task_id;
    slice_id = req.body.slice_id;
    result = req.body.result;
    update = {};
    update["map_results." + slice_id] = result;
    update["slices." + slice_id + ".status"] = "received";
    /*
        DO CHECKS # args are required
    */
    /*
        # TODO: esto tiene que ser un push, en vez de un set
        # Para almacenar varios resultados de un mismo slice, para luego elijir el
        # correcto. De esta manera prevenimos datos falsos.
    */
    return db.collection('workers', function(err, collection) {
      if (err) {
        return res.json({
          task_id: 0
        });
      }
      assert.ok(collection);
      /*
              Need to wait update status???
      */
      collection.update({
        _id: new ObjectID(doc_id)
      }, {
        $inc: {
          received_count: 1
        },
        $set: update
      }, function(err, count) {
        if (err) {
          return res.json({
            task_id: 0
          });
        }
        return assert.equal(1, count);
      });
      return get_work_or_data(function(work) {
        return res.json(work);
      });
    });
  });

  app.post('/form', function(req, res) {
    var data, doc, map, reduce;
    console.log(req.body);
    data = JSON.parse(req.body.data.replace(/'/g, "\""));
    map = req.body.map;
    reduce = req.body.reduce;
    /*
        DO CHECKS
    */
    doc = {
      data: data,
      worker_code: "investigador_map = " + map,
      reduce: reduce,
      map_results: {},
      reduce_results: {},
      slices: get_slices(data, 3),
      current_slice: -1,
      status: 'created',
      received_count: 0,
      send_count: 0
    };
    return db.collection('workers', function(err, collection) {
      assert.ifError(err);
      collection.insert(doc, {
        w: 1
      }, function(err, result) {
        assert.ifError(err);
        return assert.ok(result);
      });
      return res.send("Thx for submitting a job");
    });
  });

  app.post('/log', function(req, res) {
    console.log(req.body.message);
    return res.send(200);
  });

  app.listen('3000');

}).call(this);
