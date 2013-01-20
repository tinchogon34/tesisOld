require 'sinatra'
require 'json'
require 'uglifier'

Vars = {
	workers: [{nombre: 'worker1', data: [1,2,3,4,5,6,7,8,9,10] },
	{ nombre: 'worker2', data: (1..100).to_a }],
	reduce_data: [],
	current_worker: ''
}

get '/' do
	send_file 'views/index.html'
end

get '/proc.js' do
	logger.info "Peticion de #{request.url} desde #{request.ip}"
	content_type 'application/javascript'
	if Vars[:workers].empty?
		@worker = []
		@data = []
		Uglifier.compile(erb :'./proc.js')
	else
		if Vars[:current_worker] == ''
			Vars[:workers].reverse!
			Vars[:current_worker] = Vars[:workers].pop
		end
		@worker = "'#{Uglifier.compile(File.read("#{Vars[:current_worker][:nombre]}.js"))}'"
		@data = { numeros: Vars[:current_worker][:data].slice!(0,2) }.to_json
		logger.info @data
		Uglifier.compile(erb :'./proc.js')
	end
end

post '/data' do
	response['Content-Type'] = 'application/json'
	response['Access-Control-Allow-Origin'] = '*'
	response['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
	response['Access-Control-Max-Age'] = '1000'
	response['Access-Control-Allow-Headers'] = 'Content-Type'

	Vars[:reduce_data].concat(params[:numeros])
	if Vars[:current_worker][:data].empty?
		Vars[:reduce_data].collect!{|x| x.to_i}
		logger.info "resultado #{Vars[:reduce_data].inject(0,:+)}"
		if Vars[:workers].empty?
			return { type: 'finish' }.to_json
		else
			Vars[:reduce_data] = []
			Vars[:current_worker] = Vars[:workers].pop
			@data = { type: 'new_worker',
				numeros: Vars[:current_worker][:data].slice!(0,2),
				worker: Uglifier.compile(File.read("#{Vars[:current_worker][:nombre]}.js"))
				}.to_json

				puts @data
				@data
		end
	else
		@data = { type: 'new_data',
			numeros: Vars[:current_worker][:data].slice!(0,2) 
			}.to_json
		return @data
	end
end

post '/worker' do
end

post '/log' do
	response['Content-Type'] = 'text/plain'
	response['Access-Control-Allow-Origin'] = '*'
	response['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
	response['Access-Control-Max-Age'] = '1000'
	response['Access-Control-Allow-Headers'] = 'Content-Type'

	puts params[:data][:message]
end