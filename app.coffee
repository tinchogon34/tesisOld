express = require 'express'
assert = require 'assert'
fs = require 'fs'
MongoClient = require('mongodb').MongoClient
ObjectID = require('mongodb').ObjectID

app = express()
trusted_hosts = ['http://127.0.0.1:3000']
db_url = 'mongodb://127.0.0.1:27017/tesis'
worker_js = fs.readFileSync 'worker.js', 'utf8'
db = null

MongoClient.connect db_url, (err, connection) ->
    assert.equal null, err
    db = connection

allowCrossDomain = (req, res, next) ->
    res.header 'Access-Control-Allow-Origin', trusted_hosts
    res.header 'Access-Control-Allow-Methods', 'GET, POST'
    res.header 'Access-Control-Allow-Headers', 'Content-Type'
    next()

### SET MIDDLEWARE ###
app.use express.compress()
app.use express.static(__dirname + '/public')
app.use express.logger()
app.use express.bodyParser()
app.use allowCrossDomain
#######################

shuffle = (h) ->
    keys = Object.keys(h)
    size = keys.length
    for i in [0..size-1] # For each key
        randomKeyI = keys[i]
        j = Math.floor(Math.random() * size) # Pick random key
        randomKeyJ = keys[j]
        [h[randomKeyI], h[randomKeyJ]] = [h[randomKeyJ], h[randomKeyI]] # Do swap
    return h

get_slices = (data, size) ->
    # { "0" : 1, "1" : 1, "2" : 2, "3" : 3 }
    # { "0": {"status": "created", "data": {"0" : 1, "1" : 1, "2" : 2 }}, 1: {"status":"created","data":{"3" : 3}} }

    hash = {}
    keysLength = Object.keys(data).length
    hash[i] = {"status":"created", "data": {}} for i in [0..Math.floor(keysLength%size)]
    i = 0
    contador = 0
    
    for key, value of data
        hash[i].data[key] = value
        contador++
        i++ if (contador) % size == 0        
    
    return shuffle(hash)

get_work_or_data = (callback) ->
    
    db.collection 'workers', (err, collection) ->
        assert.equal null, err
       
        collection.find({"status": {$ne: "reduce_pending"}}).toArray((err, items) ->
            assert.equal null, err

            if !items.length
                console.log "Workers empty"
                
                return callback {task_id: 0} # No more works

            work = items[Math.floor(Math.random()*items.length)] # Random pick one work
            # NEED TO LOCK IT, no more than one request with same slice
            size = Object.keys(work.slices).length

            if work.status != 'reduce_pending' and work.received_count == size
                console.log "Entre al received"
                collection.update {_id: work._id}, {$set: {status: 'reduce_pending'}}, (err, count) ->
                    assert.equal null, err
                    assert.equal 1, count
                    
                return get_work_or_data callback

            else if work.current_slice == size
                return get_work_or_data callback                    

            collection.update {_id: work._id}, {$inc: {current_slice: 1}}, (err, count) ->
                assert.equal null, err
                assert.equal 1, count                
                ###
                if work.slices[work.current_slice].status == 'send'
                    return get_work_or_data callback
                
                update = {}
                update["slices.#{work.current_slice}.status"] = "send"
                collection.update {_id: work._id}, {$set: update}, (err, count) ->
                    assert.equal null, err
                    assert.equal 1, count
                ###    
                ### {"0": 1, "1": 1, "2": 2} => [["0",1],["1",1],["2",2]] ###
                ### PROC.JS COMPATIBILITY, REMOVE THIS! ###
                arr = []
                for key, value of work.slices[work.current_slice].data
                    arr.push [key, value]
                #############################################################

                doc =
                    task_id: work._id
                    slice_id: work.current_slice
                    data: arr
                    worker: work.worker_code + ";" + worker_js

                            
                return callback doc

        )

app.get '/work', (req, res) ->
    # Response only if json ajax request from known hosts
    if req.xhr and (req.accepts('json') != 'undefined') and "#{req.protocol}://#{req.headers.host}" in trusted_hosts
        return get_work_or_data (work) ->
            res.json work    
    res.send ""

app.post '/data', (req, res) ->
    doc_id = req.body.task_id
    slice_id = req.body.slice_id
    result = req.body.result
    update = {}
    update["map_results.#{slice_id}"] = result
    update["slices.#{slice_id}.status"] = "received"
    ###
    DO CHECKS # args are required
    ###

    ###
    # TODO: esto tiene que ser un push, en vez de un set
    # Para almacenar varios resultados de un mismo slice, para luego elijir el
    # correcto. De esta manera prevenimos datos falsos.
    ###

    db.collection 'workers', (err, collection) ->
        assert.equal null, err
        
        ###
        Need to wait update status???
        ###
        
        collection.update {_id: new ObjectID(doc_id)}, {$inc: {received_count: 1}, $set: update}, (err, count) ->
            assert.equal null, err
            assert.equal 1, count
        
        return get_work_or_data (work) ->
            res.json work

app.post '/form', (req, res) ->
    data = JSON.parse req.body.data.replace(/'/g,"\"")
    map = req.body.map
    reduce = req.body.reduce
    
    ###
    DO CHECKS
    ###
    
    doc =
        data: data
        worker_code: "investigador_map = " + map
        reduce: reduce
        map_results: {}
        reduce_results: {}
        slices: get_slices(data, 3)
        current_slice: 0
        status: 'created'
        received_count: 0
        send_count: 0

    db.collection 'workers', (err, collection) ->
        assert.equal null, err
        collection.insert doc, {w: 1}, (err, result) ->
            assert.equal null, err
        
        res.send "Thx for submitting a job"
        
app.post '/log', (req, res) ->
    console.log req.body.message
    res.send 200

app.listen '3000'