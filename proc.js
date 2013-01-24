$(function() {
/*
* Contiene la logica para pedir el codigo que debe ejecutar el
* worker y hacerlo funcinar tratando que de no usar tanto
* procesador como para que el usuario se de cuenta.
*/
post_url = 'http://localhost:4567/data';
log_url = 'http://localhost:4567/log';
work_url = 'http://localhost:4567/work';

/* Globals vars here! It is a dynamic content {{{ */
task_id = null;
slice_id = null;
worker_code = null;
data = null;
tiempo_de_ejecucion = 2000;
get_work_interval = null;
/* }}} */

/* worker vars */
blob = null;
worker = null;
intervalId = null;
pause = true;
result = []; /* data send */

get_work = function(){
	$.ajax(work_url, {
				dataType: "json",
				type: "GET"
			}).done(function (json, textStatus, jqXHR) {
				/* <data> is a raw string conatainig more data. */
				try {
					process_response(json);
				} catch (err) {
					log_to_server(err.message);
				}

			}).fail(function (jqXHR, textStatus, errorThrown) {
				alert("FAIL: Cannot parse data as json");
				log_to_server(errorThrown);
			});
}

log_to_server = function (msg) {
	/* Loggeo en el server. */
	$.ajax(log_url, {
		dataType: "json",
		type: "POST",
		data: {
			message: msg,
			task_id: task_id
		}
	});
};

send_result = function () {
/*
 * Envia <result> al server quien devolvera mas datos
 * para seguir procesando. Utiliza la funcion "process_response"
 * para dicha tarea.
 */
 $.ajax(post_url, {
 	dataType: "json",
 	type: "POST",
 	data: {
 		task_id: task_id,
 		slice_id: slice_id,
 		result: result
 	}
 }).done(function (json, textStatus, jqXHR) {
 	/* <data> is a raw string conatainig more data. */
 	try {
 		process_response(json);

 	} catch (err) {
 		log_to_server(err.message);
 	}

 }).fail(function (jqXHR, textStatus, errorThrown) {
 	alert("FAIL: Cannot parse data as json");
 	log_to_server(errorThrown);
 });
};

process_response = function(json) {
/*
 * Setea las variables necesarias para re-iniciar el worker
 * y lo pone a funcionar llamand a create_worker() y
 * start_worker()
 */
 try {
	console.log(json);
 	/* manejar cuando no hay mas trabajo */
 	result = [];
 	if(json.task_id == 0) {		
		if(!get_work_interval)
			log("Esperando nuevos trabajos...");
			get_work_interval = setInterval("get_work()",5000);
 		return;
 	}
 	/* Es el mismo worker? */
 	else if(task_id == json.task_id) {
		clearInterval(get_work_interval);
 		data = json.data;		
 	} else {
		clearInterval(get_work_interval);
 		task_id = json.task_id;
 		data = json.data;
 		worker_code = json.worker;
 		create_worker();
 	}
 	slice_id = json.slice_id;
 	start_worker();
 } catch (err) {
 	throw new Error("FATAL: " + err.message);
 }
};

log = function(line) {
	$(document.body).append(
		new Date().getTime() + " " + line + "<br/>");
};


toggle_pause = function () {
	pause = !pause;
	worker.postMessage({
		type: pause ? "pause": "resume"
	});
	log((pause ? "pause": "resume") + " send");

};

create_worker = function () {
/* Setea variables usadas por el worker y configura
 * el manejo de mensajes.
 */
 intervalId = null;
 blob = new Blob([worker_code], { type: "text/javascript" });
 worker = new Worker(window.URL.createObjectURL(blob));
 
 worker.onmessage = function (evnt) {
 	msg = evnt.data;
 	if(msg.type == "send_result") {
 		log("send_result recv");
 		log("enviando data " + result);
 		send_result(); /* send results and receive new data to process */
 		clearInterval(intervalId);

 	} else if (msg.type == "add_result") { /* nose si esto esta bien */

 		log("add_result recv");
 		result[result.length] =  msg.args; /* Es una lista! */

 		/*  */
 	} else if (msg.type == "log") {
 		log(msg.args);
 	} else {
 		log(msg);
 	}
 };

};

start_worker = function () {
/*
 * Crea el temporalizado que pausara al worker y
 * lo inicia.
 */
 intervalId = setInterval(function () {
 	toggle_pause();
 }, tiempo_de_ejecucion);

 worker.postMessage({
 	type: "start",
 	args: data
 });
};

/* document ready */
get_work();
log("comienza proc.js");

});
