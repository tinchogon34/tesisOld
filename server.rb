require 'sinatra'
require 'json'
require 'uglifier'
require 'mongo'

include Mongo

set :db, nil
set :workers, nil
set :trusted_hosts, ['http://127.0.0.1:4567']
set :protection, origin_whitelist: settings.trusted_hosts

def init
	settings.db = MongoClient.new("localhost").db("tesis")
	settings.workers = settings.db["workers"].find({"status" => {"$ne" => "terminado"}}).to_a
end

def get_slices(arr, cant)
	# DE [1,2,3,4,5,6,7,8,9,10] OBTENGO [[1,2,3],[4,5,6],[7,8,9],[10]]
	slices = []
	while !arr.empty? do
		slices.push arr.slice!(0, cant)
	end
	slices.shuffle
end

def get_work_or_data

	if settings.workers.empty?
		return { task_id: 0 }.to_json
	end

	worker = settings.workers.sample

	while(worker["current_slice"] >= worker["slices"].size)
		worker["status"] = 'terminado'
		settings.db["workers"].update({"_id" => worker["_id"]}, worker)
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
			worker: worker["worker_code"]
	}.to_json	

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

	Uglifier.compile(File.read('./proc.js'))
end

get '/work' do
	enable_cross_origin

	if settings.trusted_hosts.include?(request.env['HTTP_ORIGIN']) || request.xhr?	
		return get_work_or_data
	end	
end

post '/data' do
	enable_cross_origin

	# ACA DEBERIA PROCESAR LOS DATOS
	################################
	
	get_work_or_data # MANDAR MAS INFORMACION SI LA HAY
end

post '/form' do
	data = JSON.parse "{ \"dummy\": [#{params[:data].gsub("'","\"")}] }"
	map = params[:map]
	reduce = params[:reduce]

	coll = settings.db.collection("workers")
	doc = {
		data: data["dummy"].flatten,
		worker_code: Uglifier.compile(map + ";" + File.read("worker.js")),
		reduce: reduce,
		result: [],
		slices: get_slices(data["dummy"], 3),
		current_slice: 0,
		status: 'created'
		}

	doc_id = coll.insert(doc)
	doc["_id"] = doc_id
	settings.workers.push settings.db["workers"].find({"_id" => doc_id}).to_s
	print settings.workers
	redirect '/'
end

post '/log' do
	enable_cross_origin
	puts params[:message]
end

init