/*	
	Contiene la unidad de trabajo que se ejecuta en el cliente
*/
/* Globals vars here! It is a dynamic content {{{ */
post_url = 'http://190.113.173.79:1337/data';
log_url = 'http://190.113.173.79:1337/log';

task_id = 5;
// .numeros.map(function(x) { return x * 5; })
worker_code = "<worker>"; //FUNCION MAP DADA POR EL INVESTIGADOR

//numeros = [1,2,3,4,5,6,7,8,9,10];

//data = {numeros : [1,2]};		//data recived
data = <data>;

result = {uno: 1}; // data send
/* }}} */

$(document).ready(function() {
	function log_to_server (msg) {
		alert(msg);
		/* Loggeo en el server. */
		$.ajax(log_url, {
			contentType: "text/plain",
			type: "POST",
			data : {
				message: msg,
				task_id: task_id
			}
		});
	}

	function send_result () {
		/* 
			It sends the results to the server and
			retrieve data for further proccess.
		*/
		$.ajax(post_url, {
			async: false,
			contentType: "text/plain",
			type: "POST",
			data : result,

		}).done(function (data, textStatus, jqXHR) {
			/* <data> is a raw string conatainig more data. */

			try {
				json = JSON.parse(data);
				process_response(json);

			} catch (err) {
				log_to_server(err.message);
			}			

		}).fail(function (jqXHR, textStatus, errorThrown) {
			alert("fail");
			log_to_server(errorThrown);
		});
	}

	function process_response (json) {
		/*
			It sets the global vars to be ready to proccess the new work unit
		*/
		try {
			task_id = json.task_id;
			//data = json.data;
			//if(!(task_id && data)) {
			if(!(task_id )) {	
				throw new Error("Bad formed response");
			}
			

		} catch (err) {
			throw new Error("FATAL: " + err.message);	
		}

		//return null;
	}

	function add_result (key, value) {
		/*
			Funcion llamada para agregar datos a enviar al server
		*/
		if(result[key]) {
			if(result[key] instanceof Array) {
				result[key][result[key].length] = value
			} else {
				dummy = result[key];
				result[key] = [];
				result[key][result[key].lenght] = dummy;
				result[key][result[key].lenght] = value;
			}

		} else {
			result[key] = value;
		}

	}	

	var blob = new Blob([worker_code], { type: "text/javascript" });
	var worker = new Worker(window.URL.createObjectURL(blob));
	
	worker.onmessage = function (evnt) {
		msg = evnt.data;
/*
evnt.data = {
	type: "add_result",
	args: {primo: 7}
}
*/

		if(msg.type == "send_result") {
			send_result();
			worker.terminate();

		} else if (msg.type == "add_result") {
			for(key in msg.args){
   				add_result(key,msg.args[key]);
   			}
   		}
		
	}
	
	worker.postMessage(data);
	/*
		other evnts
		worker.postMessage("pause");
		worker.postMessage("resume");

	*/
});
