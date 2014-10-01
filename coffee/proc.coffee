(->
  $ ->
    blob = undefined
    create_worker = undefined
    data = undefined
    get_work = undefined
    get_work_interval = undefined
    get_work_running = undefined
    intervalId = undefined
    log = undefined
    log_to_server = undefined
    log_url = undefined
    pause = undefined
    post_url = undefined
    pre_reduce_result = undefined
    process_response = undefined
    send_result = undefined
    sleep_time = undefined
    slice_id = undefined
    start_worker = undefined
    task_id = undefined
    tiempo_de_ejecucion = undefined
    toggle_pause = undefined
    wait_for_new_tasks = undefined
    work_url = undefined
    worker = undefined
    worker_code = undefined
    post_url = "http://127.0.0.1:3000/data"
    log_url = "http://127.0.0.1:3000/log"
    work_url = "http://127.0.0.1:3000/work"
    tiempo_de_ejecucion = 5000
    sleep_time = 2500
    worker = null
    task_id = null
    slice_id = null
    worker_code = null
    data = null
    get_work_interval = null
    get_work_running = false
    blob = null
    intervalId = null
    pause = true
    get_work = ->
      $.ajax(work_url,
        dataType: "json"
        type: "GET"
      ).done((json, textStatus, jqXHR) ->
        try
          process_response json
        catch err
          log_to_server err.message
        return
      ).fail (jqXHR, textStatus, errorThrown) ->
        log_to_server errorThrown
        return

      return

    log_to_server = (msg) ->
      $.ajax log_url,
        dataType: "json"
        type: "POST"
        data:
          message: msg
          task_id: task_id

      return

    pre_reduce_result = (result) ->
      res = undefined
      res = {}
      result.forEach (element) ->
        element.forEach (element) ->
          key = undefined
          val = undefined
          return  if element.length isnt 2
          val = element.pop()
          key = element.pop()
          res[key] = []  if res[key] is `undefined`
          res[key].push val
          return

        return

      res

    send_result = (result) ->
      result = pre_reduce_result(result)
      $.ajax(post_url,
        async: false
        dataType: "json"
        type: "POST"
        data:
          task_id: task_id
          slice_id: slice_id
          result: result
      ).done((json, textStatus, jqXHR) ->
        try
          process_response json
        catch err
          log_to_server err.message
        return
      ).fail (jqXHR, textStatus, errorThrown) ->
        alert "FAIL: Cannot parse data as json"
        log_to_server errorThrown
        return

      return

    process_response = (json) ->
      try
        if json.task_id is 0
          worker.terminate()  if worker?
          task_id = null
          wait_for_new_tasks()  unless get_work_running
          return
        clearInterval get_work_interval
        get_work_running = false
        data = json.data
        slice_id = json.slice_id
        if task_id isnt json.task_id
          worker.terminate()  if worker isnt null
          task_id = json.task_id
          worker_code = json.worker
          create_worker()
        start_worker()
      catch err
        throw new Error("FATAL: " + err.message)
      return

    log = (line) ->
      $(document.body).append new Date().getTime() + " " + line + "<br/>"
      return

    toggle_pause = ->
      clearInterval intervalId
      worker.postMessage
        type: "pause"
        sleep_time: sleep_time

      log "pause" + " send"
      intervalId = setInterval(toggle_pause, tiempo_de_ejecucion)
      return

    create_worker = ->
      intervalId = null
      blob = new Blob([worker_code],
        type: "text/javascript"
      )
      worker = new Worker(window.URL.createObjectURL(blob))
      worker.onmessage = (evnt) ->
        msg = undefined
        msg = evnt.data
        if msg.type is "send_result"
          log "send_result recv"
          send_result msg.args
        else if msg.type is "log"
          log msg.args
        else
          log msg
        return

      return

    start_worker = ->
      worker.postMessage
        type: "start"
        args: data

      return

    wait_for_new_tasks = ->
      get_work_running = true
      log "<a style='color:red'>Esperando nuevos trabajos...</a>"
      get_work_interval = setInterval("get_work()", 5000)
      return

    get_work()
    log "comienza proc.js"
    return

  return
).call this