require 'sinatra'
require 'json'
require 'uglifier'

Vars = {
	workers: [
		{
			nombre: 'worker',
			data: [1,2,3,4,5,6,7,8,9,10],
			task_id: 1,
			slices: nil,
			current_slice: 0,
			worker_code: nil
		}],
	reduce_data: [],
	current_worker: nil
}

def get_slices(arr, cant)
	# DE [1,2,3,4,5,6,7,8,9,10] OBTENGO [[1,2,3],[4,5,6],[7,8,9],[10]]
	slices = []
	while !arr.empty? do
		slices.push arr.slice!(0, cant)
	end
	slices
end

def init_worker
	Vars[:current_worker][:worker_code] = Uglifier.compile(File.read("#{Vars[:current_worker][:nombre]}.js"))
	Vars[:current_worker][:slices] = get_slices(Vars[:current_worker][:data], 3).shuffle
end

def get_work_or_data
# SI EL WORKER NO TIENE MAS INFO QUE PROCESAR
	if Vars[:current_worker][:current_slice] >= Vars[:current_worker][:slices].size
		# SI NO QUEDAN MAS WORKERS, DAR SIGNAL DE FINALIZAR
		if Vars[:workers].empty?
			return { task_id: 0 }.to_json
		# SINO OBTENER Y MANDAR UN NUEVO WORKER
		else
			Vars[:current_worker] = Vars[:workers].pop
			init_worker
		end
	end
	# SI HAY MAS INFO QUE PROCESAR, ENVIARLA
	@slice_id = Vars[:current_worker][:current_slice]
	Vars[:current_worker][:current_slice] += 1
	return { task_id: Vars[:current_worker][:task_id],
			slice_id: @slice_id,
			data: Vars[:current_worker][:slices][@slice_id],
			worker: Vars[:current_worker][:worker_code]
	}.to_json		
	
end

def enable_cross_domain
	response['Content-Type'] = 'application/json'
	response['Access-Control-Allow-Origin'] = '*'
	response['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
	response['Access-Control-Max-Age'] = '1000'
	response['Access-Control-Allow-Headers'] = 'Content-Type'
end

get '/' do
	send_file 'views/index.html'
end

get '/proc.js' do
	logger.info "Peticion de #{request.url} desde #{request.ip}"
	content_type 'application/javascript'

# LA PRIMERA VEZ QUE CUALQUIERA PIDE /PROC
	if Vars[:current_worker] == nil
		Vars[:workers].reverse!
		Vars[:current_worker] = Vars[:workers].pop
		init_worker
	end
	
	Uglifier.compile(File.read('./proc.js'))
end

post '/data' do
	enable_cross_domain

	# ACA DEBERIA PROCESAR LOS DATOS
	################################
	
	get_work_or_data # MANDAR MAS INFORMACION SI LA HAY
end

get '/work' do
	enable_cross_domain	
	get_work_or_data
end

post '/log' do
	enable_cross_domain
	puts params[:data][:message]
end
