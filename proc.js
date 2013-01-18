/*
 * Contiene la unidad de trabajo que se ejecuta en el cliente
 */
post_url = 'http://localhost:1337/data';
log_url = 'http://localhost:1337/log';

/* Globals vars here! It is a dynamic content {{{ */
task_id = 5;
worker_code = "<worker>";
tiempo_de_ejecucion = 2000;
/* data = [1,2,3,4,5,6,7,8,9,0]; */
data = [1,2,3,4];
/* }}} */

result = []; /* data send */

log_to_server = function (msg) {
	/* Loggeo en el server. */
	$.ajax(log_url, {
		contentType: "text/plain",
		type: "POST",
		data: {
			message: msg,
			task_id: task_id
		}
	});
};

send_result = function () {
	/*
	 * It sends the results to the server and
	 * retrieve data for further proccess.
	 */
	if(result.length == 0) {
		result = "";
	}
	$.ajax(post_url, {
		async: false,
		contentType: "text/plain",
		type: "POST",
		data: {
			result: result
		}
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
};

process_response = function(json) { // TODO: Re-ver
	/*
	 * It sets the global vars to be ready to proccess the new work unit
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
};

log = function(line) {
	$(document.body).append(
		new Date().getTime() + " " + line + "<br/>");
};

pause = true;
toogle_pause = function(worker) {
	pause = !pause;
	worker.postMessage({
		type: pause ? "pause": "resume"
	});
	log((pause ? "pause": "resume") + " send");

};

$(document).ready(function() {
	var blob = new Blob([worker_code], { type: "text/javascript" });
	var worker = new Worker(window.URL.createObjectURL(blob));
	intervalId = null;

	worker.onmessage = function (evnt) {
		msg = evnt.data;
		if(msg.type == "send_result") {
			log("send_result recv");
			send_result();
			clearInterval(intervalId);
			worker.terminate();


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

   	/* main  loop */
	intervalId = setInterval(function () {
		toogle_pause(worker);
	}, tiempo_de_ejecucion);

	worker.postMessage({
		type: "start",
		args: data
	});
	log("termino");
});
