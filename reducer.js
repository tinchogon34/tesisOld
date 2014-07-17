(function() {
  var MongoClient, assert, db_url, sleep;

  db_url = 'mongodb://127.0.0.1:27017/tesis';

  MongoClient = require('mongodb').MongoClient;

  sleep = require('sleep');

  assert = require('assert');

  MongoClient.connect(db_url, function(err, connection) {
    var pre_reduce_map, process, process_pending;
    (process = function() {
      return connection.collection("workers", function(err, collection) {
        return collection.find({
          "status": "reduce_pending"
        }).toArray(function(err, pendientes) {
          var worker, _i, _len;
          if (pendientes.length === 0) {
            sleep.sleep(30);
          } else {
            for (_i = 0, _len = pendientes.length; _i < _len; _i++) {
              worker = pendientes[_i];
              process_pending(worker);
            }
          }
          return process();
        });
      });
    })();
    process_pending = function(worker) {
      var k, key, map_results, v, value;
      map_results = pre_reduce_map(worker.map_results);
      for (key in map_results) {
        value = map_results[key];
        k = key;
        v = value;
        worker["reduce_results"][key] = eval("investigador_reduce = " + worker["reduce"] + ";investigador_reduce(k, v)");
      }
      return connection.collection("workers", function(err, collection) {
        return collection.update({
          _id: worker._id
        }, {
          $set: {
            reduce_results: worker.reduce_results,
            map_results: [],
            status: "finished",
            data: []
          }
        }, function(err, count) {
          return assert.equal(1, count);
        });
      });
    };
    return pre_reduce_map = function(map_results) {
      var h, k, key, v, value;
      h = {};
      for (k in map_results) {
        v = map_results[k];
        for (key in v) {
          value = v[key];
          if (!h[key]) {
            h[key] = value;
          } else {
            h[key] = h[key].concat(value);
          }
        }
      }
      return h;
    };
  });

}).call(this);
