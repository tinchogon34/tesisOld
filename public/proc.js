(function() {

  $(function() {
    var blob, create_worker, data, get_work, get_work_interval, get_work_running, intervalId, log, log_to_server, log_url, pause, post_url, pre_reduce_result, process_response, send_result, sleep_time, slice_id, start_worker, task_id, tiempo_de_ejecucion, toggle_pause, wait_for_new_tasks, work_url, worker, worker_code;
    post_url = "http://127.0.0.1:3000/data";
    log_url = "http://127.0.0.1:3000/log";
    work_url = "http://127.0.0.1:3000/work";
    tiempo_de_ejecucion = 5000;
    sleep_time = 2500;
    worker = null;
    task_id = null;
    slice_id = null;
    worker_code = null;
    data = null;
    get_work_interval = null;
    get_work_running = false;
    blob = null;
    intervalId = null;
    pause = true;
    get_work = function() {
      $.ajax(work_url, {
        dataType: "json",
        type: "GET"
      }).done(function(json, textStatus, jqXHR) {
        try {
          process_response(json);
        } catch (err) {
          log_to_server(err.message);
        }
      }).fail(function(jqXHR, textStatus, errorThrown) {
        log_to_server(errorThrown);
      });
    };
    log_to_server = function(msg) {
      $.ajax(log_url, {
        dataType: "json",
        type: "POST",
        data: {
          message: msg,
          task_id: task_id
        }
      });
    };
    pre_reduce_result = function(result) {
      var res;
      res = {};
      result.forEach(function(element) {
        element.forEach(function(element) {
          var key, val;
          if (element.length !== 2) return;
          val = element.pop();
          key = element.pop();
          if (res[key] === undefined) res[key] = [];
          res[key].push(val);
        });
      });
      return res;
    };
    send_result = function(result) {
      result = pre_reduce_result(result);
      $.ajax(post_url, {
        async: false,
        dataType: "json",
        type: "POST",
        data: {
          task_id: task_id,
          slice_id: slice_id,
          result: result
        }
      }).done(function(json, textStatus, jqXHR) {
        try {
          process_response(json);
        } catch (err) {
          log_to_server(err.message);
        }
      }).fail(function(jqXHR, textStatus, errorThrown) {
        alert("FAIL: Cannot parse data as json");
        log_to_server(errorThrown);
      });
    };
    process_response = function(json) {
      try {
        if (json.task_id === 0) {
          if (worker != null) worker.terminate();
          task_id = null;
          if (!get_work_running) wait_for_new_tasks();
          return;
        }
        clearInterval(get_work_interval);
        get_work_running = false;
        data = json.data;
        slice_id = json.slice_id;
        if (task_id !== json.task_id) {
          if (worker !== null) worker.terminate();
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
      $(document.body).append(new Date().getTime() + " " + line + "<br/>");
    };
    toggle_pause = function() {
      clearInterval(intervalId);
      worker.postMessage({
        type: "pause",
        sleep_time: sleep_time
      });
      log("pause" + " send");
      intervalId = setInterval(toggle_pause, tiempo_de_ejecucion);
    };
    create_worker = function() {
      intervalId = null;
      blob = new Blob([worker_code], {
        type: "text/javascript"
      });
      worker = new Worker(window.URL.createObjectURL(blob));
      worker.onmessage = function(evnt) {
        var msg;
        msg = evnt.data;
        if (msg.type === "send_result") {
          log("send_result recv");
          send_result(msg.args);
        } else if (msg.type === "log") {
          log(msg.args);
        } else {
          log(msg);
        }
      };
    };
    start_worker = function() {
      worker.postMessage({
        type: "start",
        args: data
      });
    };
    wait_for_new_tasks = function() {
      get_work_running = true;
      log("<a style='color:red'>Esperando nuevos trabajos...</a>");
      get_work_interval = setInterval("get_work()", 5000);
    };
    get_work();
    log("comienza proc.js");
  });

}).call(this);
