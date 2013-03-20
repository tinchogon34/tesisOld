MongoClient = require('mongodb').MongoClient
ObjectID = require('mongodb').ObjectID
open = require 'open'
assert = require 'assert'
sleep = require('sleep')
require './app.js'

db_url = 'mongodb://127.0.0.1:27017/tesis?maxPoolSize=10'
docs = []
doc1 =
	data:
		0: 1
		1: 1
		2: 2
		3: 3

	worker_code: "investigador_map = function (k, v) {\r\n  log(\"inv in\");\r\n  var ms = 1000;\r\n  var started = new Date().getTime();\r\n  while((new Date().getTime() - started) < ms) {\r\n  }\r\n  emit(\"llave\", v*v);\r\n  log(\"inv in out\");\r\n};      "
	reduce: "function (k, vals) {\r\n  var total = vals.reduce(function(a, b) {\r\n    return parseInt(a) + parseInt(b);\r\n  });\r\n  return total;\r\n};      "
	map_results:{}
	reduce_results:{}
	slices:
		0: 
			status: "created"
			data:
				0: 1
				1: 1
				2: 2
		1:
			status: "created"
			data:
				3: 3

	current_slice: -1
	status: "created"
	received_count: 0
	send_count: 0

doc2 =
	data:
		0: 5
		1: 8
		2: 3
		3: 9

	worker_code: "investigador_map = function (k, v) {\r\n  log(\"inv in\");\r\n  var ms = 1000;\r\n  var started = new Date().getTime();\r\n  while((new Date().getTime() - started) < ms) {\r\n  }\r\n  emit(\"llave\", v*v);\r\n  log(\"inv in out\");\r\n};      "
	reduce: "function (k, vals) {\r\n  var total = vals.reduce(function(a, b) {\r\n    return parseInt(a) + parseInt(b);\r\n  });\r\n  return total;\r\n};      "
	map_results:{}
	reduce_results:{}
	slices:
		0: 
			status: "created"
			data:
				3: 9
		1:
			status: "created"
			data:
				0: 5
				1: 8
				2: 3

	current_slice: -1
	status: "created"
	received_count: 0
	send_count: 0

docs.push doc1
docs.push doc2

open('http://localhost:3000') for i in [1..10]
sleep.sleep(10)

MongoClient.connect db_url, (err, db) ->
    assert.equal null, err

    db.collection 'workers', (err, collection) ->
    	assert.equal null, err

    	collection.remove {}, (err, count) ->
    		assert.equal null, err

    		(doc = docs[Math.floor(Math.random()*docs.length)]
    		doc["_id"] = new ObjectID()
    		collection.insert doc, (err, result) ->
    			assert.equal null, err) for i in [1..1000]
