/*
 * Worker code template.
 */
work = this;
log = function (s) {
	work.postMessage({
		type: "log",
		args: s
	});
};
sleep = true;

very_ugly_sleep = function (ms) {
	var started = new Date().getTime();
	while((new Date().getTime() - started) < ms) {
	}

};

investigador_map = function (x) {
 	log("inv in");
    /*
     * Funcion provista por el investigador.
     * Debemos tener una estimacion de cuanto tiempo necesita
     * Dinamico!
     */
	very_ugly_sleep(2000);
	log("inv in out");
};

add_result = function (res) {
	log("add_result send");
    if(res != null || res == undefined) {
        postMessage({
			type: "add_result",
            args: res
        });
    }
};

send_result = function () {
	log("send_result worker");
    postMessage({
        type: "send_result"
    });
};

function Cola () {
	this.func = null;
	this.i = 0;
	this.args = [];
	this.executing = false;

	this.add_arg = function (arg) {
		this.args[this.args.length] = arg;
		log("encolo " + arg);
	};

	this._process = function() {
		this.executing = true;
		if(this.i < this.args.length) {
			add_result(this.func(this.args[this.i]));
			this.i ++;

		} else{
			throw new Error("Nothing to process!");
		}
		this.executing = false;

	};
	this.process = function() {
		if(!this.executing && !sleep) {
			this._process();
		}
	};

}
cola = new Cola();
cola.func = investigador_map;

this.onmessage = function(evnt) {
    msg = evnt.data;

    if(msg.type == "start") {
		log("start recv");
        msg.args.map(function(arg) {
			cola.add_arg(arg);
		});

    } else if(msg.type == "pause") {
		log("pause recv");
        sleep = true;

    } else if(msg.type == "resume") {
		log("resume recv");
        sleep = false;
		try {
			setInterval(cola.process(), 250);
		} catch (err) {
			log(err.message);
			send_result();
		}
    }
};

work.postMessage("termino worker");
