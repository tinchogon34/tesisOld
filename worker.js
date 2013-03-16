/*
 * Define las funciones necesarias para que funcione
 * el worker. Ademas contiene el la funcion del map
 * del investigador.
 */
work = this;
sleep = false;
intervalId = null;
result = [ [] ]; //[["0",1],["1",2],["2",3]]

log = function (msg) {
  work.postMessage({
    type: "log",
    args: msg
  });
};

/*
investigador_map = function (k, v) {
  log("inv in");
  var ms = 1000;
  var started = new Date().getTime();
  while((new Date().getTime() - started) < ms) {
  }
  emit("llave", v*v);
  log("inv in out");
};
*/

/*
investigador_reduce = function (k, vals) {
  var total = vals.reduce(function(a, b) {
    return parseInt(a) + parseInt(b);
  });
  return total;
};
*/


emit = function (key, val) {
  /* funcion utilizada en investigador_map para agregar valores */
  var arr = result[result.length - 1];
  arr.push([key, val]);
};

send_result = function () {
  /* Envia un mensaje <send_result>
  */
  sleep = true;
  cola.i = 0;
  
  log("send_result worker");
  log(result);
  postMessage({
    type: "send_result",
    args: result
  });
  result = [ [] ];
};

function Cola () {
  /* <Humilde intento de clase en JS :'(>
   * Recibe todos los datos que necesita la funcion map.
   * Luego los ejecuta en orden realizando llamadas a la
   * función map del investigador. Luego de cada llamada
   * se duerme un pequeño lapso de tiempo para chequear
   * si recivio algun mje "sleep". De ser asi no empieza mas
   * tareas.
   */

  this.map = null;
  this.i = 0;
  this.args = [];
  this.executing = false;

  this._process = function() {
    this.executing = true;
    if(this.i < this.args.length) {
      log("ejecutando map con " + this.args[this.i][0] + " y " + this.args[this.i][1]);
      this.map(this.args[this.i][0],this.args[this.i][1]);
      if(result[result.length] != 0) {
        result.push([]);
      }
      this.i ++;

    } else{
      this.executing = false;
      throw new Error("<b>Nothing to process!</b>");
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
cola.map = investigador_map;

this.onmessage = function(evnt) {
  /* Manejador de mensajes
  */
  msg = evnt.data;

  if(msg.type == "start") {
    sleep = false;
    log("start recv");
    cola.args = msg.args; // array de arrays [["0", 1], ["1", 2], ["2", 3]]
    intervalId = setInterval(function(){
      try {
        cola.process();
      }
      catch (err) {
        clearInterval(intervalId);
        log(err.message);
        send_result();
      }},50);
  }
  else if(msg.type == "pause") {
      if(intervalId !== null){
          clearInterval(intervalId);
      }

    sleep = true;

    log("pause recv");
    setTimeout(function(){
      sleep = false;
      log("resume recv");
      intervalId = setInterval(function(){
        try {
          cola.process();
        }
        catch (err) {
          log(err.message);

          send_result();
        }},250);
    },msg.sleep_time);
  }
};

work.postMessage("termino worker");