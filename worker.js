/*
 * Define las funciones necesarias para que funcione
 * el worker. Ademas contiene el la funcion del map
 * del investigador.
 */
work = this;
sleep = false;
intervalId = null;


log = function (msg) {
  work.postMessage({
    type: "log",
    args: msg
  });
};
/*
investigador_map = function (x) {
  log("inv in");
  var ms = 1000;
  var started = new Date().getTime();
  while((new Date().getTime() - started) < ms) {
  }
  log("inv in out");
  return x*x;
};
*/
/*
reduce
function (res) {
var total = res.reduce(function(a, b) {
    return parseInt(a) + parseInt(b);
});
return total;
};    
*/
add_result = function (res) {
/*
 * Envia un mensaje <add_result>
 */
 log("add_result send");
 if(res != null || res == undefined) {
    postMessage({
      type: "add_result",
      args: res
    });
  }
};

send_result = function () {
  /*
   * Envia un mensaje <send_result>
   */
   clearInterval(intervalId);
   log("send_result worker");
   postMessage({
      type: "send_result"
    });
   cola.i = 0;
   cola.args = [];
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
     this.executing = false;
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
    /*
     * Manejador de mensajes
     */
     msg = evnt.data;

     if(msg.type == "start") {
      log("start recv");
      log("argumentos " + msg.args);
      msg.args.forEach(function(arg) {
        cola.add_arg(arg);
      });
      intervalId = setInterval(function(){
        try {
          cola.process();
        }
        catch (err) {
          log(err.message);
          send_result();
      }},50);
      

    } else if(msg.type == "pause") {
      sleep = true;
      clearInterval(intervalId);
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
        }},50);
        
      },msg.sleep_time);
      
    } 
  };

work.postMessage("termino worker");
