#!/usr/bin/env ruby

require 'mongo'
require 'v8'

include Mongo

@con = MongoClient.new("localhost").db("tesis")

def process
  while(true)
    pendientes = @con["workers"].find({"status" => "reduce_pending"}).to_a
    if(pendientes.empty?)
      sleep(30)
      next
    end

    pendientes.each do |worker|
      process_pending(worker) 
    end
  end
end

def pre_reduce_map(map_results)
 #{1 => {"llave" : ["1","1","4"]}, 2 =>{"llave" : ["9"]}} => {"llave" => ["1","1","4","9"]}

 h = {}
 map_results.each do |k, v|
   v.each do |key, value|
     if(!h[key])
       h[key] = value
     else
       h[key] = h[key].concat(value)
     end
   end    
 end

 return h
end

def process_pending(worker)
  cxt = V8::Context.new
  #[{"llave"=>["1", "1", "4"]}]
  map_results = pre_reduce_map(worker["map_results"])
  map_results.each do |key, value|
    cxt["k"] = key
    cxt["v"] = value
    worker["reduce_results"][key] = cxt.eval("investigador_reduce = " + worker["reduce"] + ";investigador_reduce(k, v)");
  end
  @con["workers"].update({"_id" => worker["_id"]}, worker)
  worker["map_results"] = []
  worker["status"] = "finished"
  worker["data"] = []
  @con["workers"].update({"_id" => worker["_id"]}, worker)
end

process

