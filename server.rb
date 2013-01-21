require 'sinatra'
require 'json'
require 'uglifier'

def get_slices(arr, cant)
 slices = []
 while !arr.empty? do
   slices.push arr.slice!(0, cant)
 end
 slices
end

def init_worker
    Vars[:current_worker][:slices] = get_slices(Vars[:current_worker][:data], 3).shuffle

end

Vars = {
    workers: [
{nombre: 'worker1',
data: [1,2,3,4,5,6,7,8,9,10],
task_id: 1,
slices: nil,
current_slice: 0},
{ nombre: 'worker2',
data: (1..10000).to_a,
task_id: 2,
slices: nil,
current_slice: 0}],
    reduce_data: [],
    current_worker: nil
}

get '/' do
    send_file 'views/index.html'
end

get '/proc.js' do
    logger.info "Peticion de #{request.url} desde #{request.ip}"
    content_type 'application/javascript'

    if Vars[:current_worker] == nil
            Vars[:workers].reverse!
            Vars[:current_worker] = Vars[:workers].pop
            init_worker
    end

    if Vars[:current_worker][:current_slice] >= Vars[:current_worker][:slices].size
        if Vars[:workers].empty?
            @worker = []
            @data = []
            return Uglifier.compile(erb :'./proc.js')
        else
            Vars[:current_worker] = Vars[:workers].pop
            init_worker
        end
    end
    @worker = "'#{Uglifier.compile(File.read("#{Vars[:current_worker][:nombre]}.js"))}'"
    @slice_id = Vars[:current_worker][:current_slice]
    Vars[:current_worker][:current_slice]++
    @data = Vars[:current_worker][:slices][@slice_id]
    @task_id = Vars[:current_worker][:task_id]
    logger.info @data
    Uglifier.compile(erb :'./proc.js')
end

post '/data' do
    response['Content-Type'] = 'application/json'
    response['Access-Control-Allow-Origin'] = '*'
    response['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    response['Access-Control-Max-Age'] = '1000'
    response['Access-Control-Allow-Headers'] = 'Content-Type'

    #Vars[:reduce_data].concat(params[:numeros])
    if Vars[:current_worker][:data].empty?
        #Vars[:reduce_data].collect!{|x| x.to_i}
        #logger.info "resultado #{Vars[:reduce_data].inject(0,:+)}"

        if Vars[:workers].empty?
            return { task_id: 0 }.to_json
        else
            #Vars[:reduce_data] = []
            Vars[:current_worker] = Vars[:workers].pop
            init_worker
            @slice_id = Vars[:current_worker][:slice_id]
            Vars[:current_worker][:slice_id]++
            @data = { task_id: Vars[:current_worker][:task_id],
                slice_id: @slice_id,
                data: Vars[:current_worker][:slices][@slice_id],
                worker: Uglifier.compile(File.read("#{Vars[:current_worker][:nombre]}.js"))
                }.to_json

                puts @data
                @data
        end
    else

            @slice_id = Vars[:current_worker][:slice_id]
            Vars[:current_worker][:slice_id]++
            @data = { task_id: Vars[:current_worker][:task_id],
                slice_id: @slice_id,
                data: Vars[:current_worker][:slices][@slice_id]
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
