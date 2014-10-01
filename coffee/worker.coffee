#
# * Define las funciones necesarias para que funcione
# * el worker. Ademas contiene el la funcion del map
# * del investigador.
# 
#[["0",1],["1",2],["2",3]]

#
#investigador_map = function (k, v) {
#  log("inv in");
#  var ms = 1000;
#  var started = new Date().getTime();
#  while((new Date().getTime() - started) < ms) {
#  }
#  emit("llave", v*v);
#  log("inv in out");
#};
#

#
#investigador_reduce = function (k, vals) {
#  var total = vals.reduce(function(a, b) {
#    return parseInt(a) + parseInt(b);
#  });
#  return total;
#};
#

# funcion utilizada en investigador_map para agregar valores 

# Envia un mensaje <send_result>
#  
Cola = ->
  
  # <Humilde intento de clase en JS :'(>
  #   * Recibe todos los datos que necesita la funcion map.
  #   * Luego los ejecuta en orden realizando llamadas a la
  #   * función map del investigador. Luego de cada llamada
  #   * se duerme un pequeño lapso de tiempo para chequear
  #   * si recivio algun mje "sleep". De ser asi no empieza mas
  #   * tareas.
  #   
  @map = null
  @i = 0
  @args = []
  @executing = false
  @_process = ->
    @executing = true
    if @i < @args.length
      log "ejecutando map con " + @args[@i][0] + " y " + @args[@i][1]
      @map @args[@i][0], @args[@i][1]
      result.push []  unless result[result.length] is 0
      @i++
    else
      @executing = false
      throw new Error("<b>Nothing to process!</b>")
    @executing = false
    return

  @process = ->
    @_process()  if not @executing and not sleep
    return
  return

work = this
sleep = false
intervalId = null
result = [[]]
log = (msg) ->
  work.postMessage
    type: "log"
    args: msg
  return

emit = (key, val) ->
  arr = result[result.length - 1]
  arr.push [
    key
    val
  ]
  return

send_result = ->
  sleep = true
  cola.i = 0
  log "send_result worker"
  log result
  postMessage
    type: "send_result"
    args: result
  result = [[]]
  return

cola = new Cola()
cola.map = investigador_map
@onmessage = (evnt) ->
  
  # Manejador de mensajes
  #  
  msg = evnt.data
  if msg.type is "start"
    sleep = false
    log "start recv"
    cola.args = msg.args # array de arrays [["0", 1], ["1", 2], ["2", 3]]
    intervalId = setInterval(->
      try
        cola.process()
      catch err
        clearInterval intervalId
        log err.message
        send_result()
      return
    , 50)
  else if msg.type is "pause"
    clearInterval intervalId  if intervalId isnt null
    sleep = true
    log "pause recv"
    setTimeout (->
      sleep = false
      log "resume recv"
      intervalId = setInterval(->
        try
          cola.process()
        catch err
          log err.message
          send_result()
        return
      , 250)
      return
    ), msg.sleep_time
  return

work.postMessage "termino worker"