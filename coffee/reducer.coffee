db_url = 'mongodb://127.0.0.1:27017/tesis'
MongoClient = require('mongodb').MongoClient
sleep = require 'sleep'
assert = require 'assert'

MongoClient.connect db_url, (err, connection) ->
  do process = ->
    connection.collection "workers", (err, collection) ->
      collection.find({ "status": "reduce_pending" }).toArray (err, pendientes) ->
          if pendientes.length == 0
            sleep.sleep(30)
          else
            for worker in pendientes
              process_pending worker

          process()

  process_pending = (worker) ->
    map_results = pre_reduce_map worker.map_results
    for key, value of map_results
      k = key
      v = value
      worker["reduce_results"][key] = eval("investigador_reduce = " + worker["reduce"] + ";investigador_reduce(k, v)")
    connection.collection "workers", (err, collection) ->
      collection.update {_id: worker._id}, {$set: {reduce_results: worker.reduce_results,map_results: [], status: "finished", data: []}}, (err, count) ->
        assert.equal 1, count

  pre_reduce_map = (map_results) ->
    h = {}
    for k, v of map_results
      for key, value of v
        if !h[key]
          h[key] = value
        else
          h[key] = h[key].concat value
    return h