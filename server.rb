require 'sinatra'
require 'json'
require 'mongo'
require 'v8'

include Mongo

set :db, nil
set :workers, nil
set :worker_code, File.read("worker.js")
set :trusted_hosts, ['http://127.0.0.1:4567']
set :protection, origin_whitelist: settings.trusted_hosts

def init
	settings.db = MongoClient.new("localhost").db("tesis")
	settings.workers = settings.db["workers"].find({"status" => "created"}).to_a
	process_pending
end

def get_slices(arr, cant)
  arr.each_slice(cant).to_a.shuffle
end

def get_work_or_data

	if settings.workers.empty?
		return { task_id: 0 }.to_json
	end

	worker = settings.workers.sample

	while(worker["current_slice"] >= worker["slices"].size)
		worker["status"] = 'reduce_pending'
		settings.db["workers"].update({"_id" => worker["_id"]}, worker)
		process_pending
		settings.workers.delete worker
		if settings.workers.empty?
			return { task_id: 0 }.to_json
		end	
		worker = settings.workers.sample
	end

	current_slice = worker["current_slice"]
	worker_id = worker["_id"].to_s
	worker["current_slice"] += 1
	settings.db["workers"].update({"_id" => worker["_id"]}, worker)
  
	return { task_id: worker_id,
			slice_id: current_slice,
			data: worker["slices"][current_slice],
			worker: worker["worker_code"] + ";" + settings.worker_code
	}.to_json	

end

def process_pending
	pending = settings.db["workers"].find({"status" => "reduce_pending"}).to_a
	cxt = V8::Context.new
	pending.each do |worker|
    #[{"llave"=>["1", "1", "4"]}]
    worker["map_results"].each do |hash|
      hash.each do |key, value|
        cxt["k"] = key
        cxt["v"] = value
      end

      worker["reduce_results"][key] = cxt.eval("investigador_reduce = " + worker["reduce"] + ";investigador_reduce(k, v)");
		  settings.db["workers"].update({"_id" => worker["_id"]}, worker)
    end
		worker["status"] = "finished"
	end
end

def enable_cross_origin
	response['Content-Type'] = 'application/json'
	response['Access-Control-Allow-Origin'] = settings.trusted_hosts
	response['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
	response['Access-Control-Max-Age'] = '1000'
	response['Access-Control-Allow-Headers'] = 'Content-Type'
end

get '/' do
	send_file 'views/index.html'
end

get '/form' do
	send_file 'views/form.html'
end

get '/proc.js' do
	logger.info "Peticion de #{request.url} desde #{request.ip}"
	content_type 'application/javascript'

	send_file './proc.js'
end

get '/work' do
	enable_cross_origin

	if settings.trusted_hosts.include?(request.env['HTTP_ORIGIN']) || request.xhr?	
		return get_work_or_data
	end	
end

post '/data' do
	enable_cross_origin

	doc_id = params[:task_id]
	current_slice = params[:current_slice]
	results = params[:result] #[["0",[1,2]],["2",[3]]

	settings.db["workers"].update({"_id" => BSON::ObjectId(doc_id)}, '$push' => { :map_results => results})
	settings.workers = settings.db["workers"].find({"status" => "created"}).to_a
	get_work_or_data # MANDAR MAS INFORMACION SI LA HAY
end

post '/form' do

	data = JSON.parse params[:data].gsub("'","\"")
  print data
  print params[:data]
	map = params[:map]
	reduce = params[:reduce]

	coll = settings.db.collection("workers")
	doc = {
		data: data,
		worker_code: "investigador_map = " + map,
		reduce: reduce,
    map_results: [],
		reduce_results: {},
		slices: get_slices(data, 3),
		current_slice: 0,
		status: 'created'
		}

	doc_id = coll.insert(doc)
	settings.workers.push(settings.db["workers"].find({"_id" => doc_id}).first)
	"Thx for submitting a job"
end

post '/log' do
	enable_cross_origin
	puts params[:message]
end

init
