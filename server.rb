# encoding: utf-8
require 'sinatra'
require 'json'
require 'mongo'
require 'v8'
require 'thread'

include Mongo

set :db, nil
set :workers, nil
set :worker_code, File.read("worker.js")
set :trusted_hosts, ['http://localhost:4567']
set :protection, origin_whitelist: settings.trusted_hosts
set :mutex, Mutex.new

# utilities functions
def init
  settings.db = MongoClient.new("localhost").db("tesis")
  settings.workers = settings.db["workers"].find({"status" => "created"}).to_a
end

def get_slices(arr, cant)
  a = []
  arr.each_slice(cant).to_a.shuffle.each_with_index do |el, index|
    a.push({status: 'initial', data: el})
  end
  return a
end

def enable_cross_origin
  response['Content-Type'] = 'application/json'
  response['Access-Control-Allow-Origin'] = settings.trusted_hosts
  response['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
  response['Access-Control-Max-Age'] = '1000'
  response['Access-Control-Allow-Headers'] = 'Content-Type'
end

def check_task(data, map, reduce)
  cxt = V8::Context.new
  cxt["data"] = data
  cxt["map"] = map
  cxt["reduce"] = reduce
  # TODO: continuar
  cxt.eval()
end

# Devuelve un tarea completa o solo datos para ejecutar en el clinte.
def get_work_or_data
  settings.workers = settings.db["workers"].find({"status" => "created"}).to_a

  if settings.workers.empty?
    puts 'workers empty'
    return {task_id: 0}.to_json
  end
  
  worker = settings.workers.sample
  worker["current_slice"] = worker["current_slice"].to_i
  current_slice = worker["current_slice"]
  worker_id = worker["_id"]
  
  # llegaron todos los resultados?
  # TODO: ver slices

  if(settings.db["workers"].find({"_id" => worker_id,"slices.status" => "initial"}).to_a.size == 0)
    puts "entre al initial"
    settings.db["workers"].update({"_id" => worker_id},
                                  {'$set' => {:status => 'reduce_pending'}})
    settings.workers.delete worker
    return {task_id: 0}.to_json
  end

  ### lock
  settings.mutex.lock()
 
  puts "segui de largo"
  settings.db["workers"].update({"_id" => worker_id},
                                {'$set' => {:current_slice => current_slice+1,
                                 "slices.#{current_slice}.status" => 'send'
                                }})
  worker["current_slice"] += 1
  resultado = {
    task_id: worker_id.to_s,
    slice_id: current_slice,
    data: worker["slices"][current_slice]["data"],
    worker: worker["worker_code"] + ";" + settings.worker_code
  }.to_json
  settings.mutex.unlock()
  return resultado
  ### free lock
end

# http function
get '/' do
  send_file 'views/index.html'
end

get '/proc.js' do
  logger.info "Peticion de #{request.url} desde #{request.ip}"
  content_type 'application/javascript'
  send_file './proc.js'
end

get '/work' do
  enable_cross_origin

  if settings.trusted_hosts.include?(request.env['HTTP_ORIGIN']) ||
    request.xhr?
    return get_work_or_data
  end
end

# Aca postea resultados.
post '/data' do
  enable_cross_origin
  doc_id = params[:task_id]
  slice_id = params[:slice_id]
  results = params[:result] # [["0",[1,2]],["2",[3]]]

  # args are required
  if not (doc_id and slice_id != nil and results != nil)
    return "Wrong arguments"
  end

  # TODO: esto tiene que ser un push, en vez de un set
  # Para almacenar varios resultados de un mismo slice, para luego elijir el
  # correcto. De esta manera prevenimos datos falsos.
  settings.db["workers"].update({ '_id' => BSON::ObjectId(doc_id)},
                                {'$set' => { "map_results.#{slice_id}" => results, "slices.#{slice_id}.status" => 'received'}})

  # TODO: es necesario otro acceso a la bd?
  #settings.workers = settings.db["workers"].find({"status" => "created"}).to_a
  get_work_or_data # MANDAR MAS INFORMACION SI LA HAY
end

get '/form' do
  send_file 'views/form.html'
end

post '/form' do
  data = JSON.parse params[:data].gsub("'","\"")
  map = params[:map]
  reduce = params[:reduce]
  # args are required
  if not (data and map != nil and reduce)
    return "Wrong arguments"
    # TODO: Add
    # else
    #     begin
    #         check_task(data, map, reduce)
    #     rescue
    #         return "ERROR!"
    #     end
  end

  doc = {
    data: data,
    worker_code: "investigador_map = " + map,
    reduce: reduce,
    map_results: {},    # {slide_id: [results]}
    reduce_results: {},
    slices: get_slices(data, 3),
    current_slice: 0.to_i,
    status: 'created'
  }

  doc_id = settings.db["workers"].insert(doc)
  # TODO: Cual es la diferencia entre doc en memoria y el obj en bd?
  # TODO: (posiblemente) elimianr el acceso la bd
  #settings.workers.push(settings.db["workers"].find({"_id" => doc_id}).first)
  "Thx for submitting a job"
end

post '/log' do
  # TODO: Logearlo en otro lado
  enable_cross_origin
  puts params[:message]
end

init
