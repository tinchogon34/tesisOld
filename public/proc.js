$(function() {
    /*
     * Contiene la logica para pedir el codigo que debe ejecutar el
     * worker y hacerlo funcinar tratando que de no usar tanto
     * procesador como para que el usuario se de cuenta.
     */
    post_url = 'http://127.0.0.1:3000/data';
    log_url = 'http://127.0.0.1:3000/log';
    work_url = 'http://127.0.0.1:3000/work';

    tiempo_de_ejecucion = 5000;
    sleep_time = 2500;
    worker = null;

    /* Globals vars here! It is a dynamic content {{{ */
    task_id = null;
    slice_id = null;
    worker_code = null;
    data = null;
    get_work_interval = null;
    get_work_running = false;

    /* worker vars */
    blob = null;
    intervalId = null;
    pause = true;

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
            log_to_server(errorThrown);
        });
    };

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

    pre_reduce_result = function (result) {
        res = {}; /* list (k2, list (v2)) */
        /* result => [ list(k2,v2) ] */
        result.forEach(function (element) {
            element.forEach(function (element) {
                if(element.length != 2) {
                    return; /* omitir */
                }
                var val = element.pop();
                var key = element.pop();

                if(res[key] === undefined) {
                    res[key] = [];
                }
                res[key].push(val);
            });
        });
        return res;
    };

    send_result = function (result) {
        /*
         * Envia <result> al server quien devolvera mas datos
         * para seguir procesando. Utiliza la funcion "process_response"
         * para dicha tarea.
         */

        result = pre_reduce_result(result); //[["0",1],["0",2],["2",3]] => // {"llave"=>["1", "1", "4"]}

        $.ajax(post_url, {
            async: false,
            dataType: "json",
            type: "POST",
            data: {
                task_id: task_id,
            slice_id: slice_id,
            result: result
            }
        }).done(function (json, textStatus, jqXHR) {
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

            /* manejar cuando no hay mas trabajo */
            if(json.task_id == 0) {
                if(worker != null){
                    worker.terminate();
                }
                task_id = null;
                if(!get_work_running){
                    wait_for_new_tasks();
                }
                return;
            }

            clearInterval(get_work_interval);
            get_work_running = false;

            data = json.data;
            slice_id = json.slice_id;
            if(task_id != json.task_id) {
                task_id = json.task_id;
                worker_code = json.worker;
                create_worker();
            }
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

        clearInterval(intervalId);

        worker.postMessage({
            type: "pause",
            sleep_time: sleep_time
        });
        log("pause" + " send");

        intervalId = setInterval(toggle_pause, tiempo_de_ejecucion);

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
                /* send results and receive new data to process */
                send_result(msg.args);
                //clearInterval(intervalId);

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
        worker.postMessage({
            type: "start",
            args: data
        });


        //intervalId = setInterval(toggle_pause, tiempo_de_ejecucion);
    };

    wait_for_new_tasks = function () {
        get_work_running = true;
        log("<a style='color:red'>Esperando nuevos trabajos...</a>");
        get_work_interval = setInterval("get_work()", 5000);
    };

    /* document ready */
    get_work();
    log("comienza proc.js");

});