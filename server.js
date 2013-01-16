var http = require('http');
var fs = require('fs')
var url = require('url');
var qs = require("querystring");

function is_valid_origin (origin) {
    /* ask in mongoDB */ 
    return true;
}

resultados = [];
/* Process /data */
function data (request, response) {
    if (request.method != "POST") {
        throw new Error("Unsupported method: " + request.method);
    }
    if (!is_valid_origin(request.headers.origin)) {
        throw new Error("Invalid origin: " + request.headers.origin);
    }

    response.writeHead(200, {
        'Content-Type': 'text/plain',
        'Access-Control-Allow-Origin': '*'
    });
    
    var post = "";
    request.on("data", function (data) {
        post += data;
    });
    request.on("end", function () {
        post = qs.parse(post);
        console.log(post);
        res = post["args[]"];
        res = res.map(function (x) { return parseInt(x)});
        resultados.push(res.pop());
        resultados.push(res.pop());
        console.log(resultados);

    });
            
    response.end('{"task_id": 1}');
}

function worker (req, res) {
    res.writeHead(200, {'Content-Type': 'text/javascript'});
    archivo = fs.readFileSync("worker_code.js").replace(/\s+/g, ' ');
    res.end(archivo);
    console.log(archivo);
}

contador = 0;
argumentos = [1,2,3,4,5,6,7,8,9,10];

http.createServer(function (request, response) {
    urlinfo = url.parse(request.url, true);
    console.log("peticion: " + urlinfo.pathname);
    //console.log(urlinfo.query);
    
    if(request.url == '/proc.js' && request.method == 'GET') {
        if(contador >= 10){
            response.end("termino");
           console.log(resultados.reduce(function(previousValue, currentValue, index, array){
                return previousValue + currentValue;
            }));
        }
    	response.writeHead(200, {'Content-Type': 'text/javascript'});
        foo = fs.readFileSync('proc.js', 'utf-8', function (error, data) {
    		if(error) {
    	    	console.log(error);
    		}

        });

        foo = foo.replace("<data>", "{numeros : ["+(argumentos[contador])+","+(argumentos[contador+1])+"]}");
        archivo = fs.readFileSync("worker_code.js","utf-8").replace(/\s+/g, ' ');
        foo = foo.replace("<worker>", archivo);
        response.end(foo);
        contador += 2;

    } else if (request.url == "/data") {
        try {
            data(request, response);
        } catch (err) {
            console.log(err);
            /* reventa todo */
        }

    } else if (request.url == "/worker") {
        try {
            worker(request, response);
        } catch (err) {
            console.log(err);
            /* reventa todo */
        }

    } else {
    	response.writeHead(200, {'Content-Type': 'text/plain'});
    	foo = "U MAD?";

    }
    
}).listen(1337, '192.168.1.150');
console.log('Server running at http://127.0.0.1:1337/');
