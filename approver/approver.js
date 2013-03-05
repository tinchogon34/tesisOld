
/*
# Parsea la funcion map y reduce para determinar si
# esta en condiciones de ser distribuida.
# El resultado sera almacenado en result y es un boolean
# Debe ser ejecutado con NodeJS
*/

(function() {
  var check_emit, context, emit, fs, idata, imap, ireduce, message, result, search_urls, test, _Date;

  fs = require('fs');

  result = void 0;

  message = void 0;

  test = {
    url: false,
    nodejs: false,
    interface: false,
    time: false
  };

  _Date = (function() {

    function _Date() {}

    _Date.prototype.getTime = function() {
      return new Date().getTime() * 1.3;
    };

    return _Date;

  })();

  idata = '{"0": 1, "1": 1, "2": 2, "3": 3}';

  imap = 'investigador_map = function (k, v) {log("inv in"); var ms = 1000; var started = new Date().getTime(); while((new Date().getTime() - started) < ms) {}emit("llave", v*v); log("inv in out");};';

  ireduce = 'investigador_reduce = function (k, vals){var total = vals.reduce(function(a, b) {return parseInt(a) + parseInt(b); }); return total;};';

  if (imap === void 0 || ireduce === void 0 || idata === void 0) {
    throw 'Variables del investigador sin setear';
  }

  emit = function(x, y) {
    if (x === void 0 || x === null || y === void 0 || y === null) {
      throw 'Uso incorrecto de la funcion emit';
    }
  };

  check_emit = function() {
    var args, call, emit_regex, res, _i, _len, _results;
    emit_regex = /emit\(.*?\)/g;
    res = imap.match(emit_regex);
    if (res === null) throw 'Debe usar emit en map';
    _results = [];
    for (_i = 0, _len = res.length; _i < _len; _i++) {
      call = res[_i];
      args = call.match(/,/g);
      if (args && args.length !== 1) {
        throw 'Mal llamado a emit' + call;
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  search_urls = function() {
    var url_reg;
    url_reg = /[-a-zA-Z0-9@:%_\+.~#?&//=]{2,256}\.[a-z]{2,4}\b(\/[-a-zA-Z0-9@:%_\+.~#?&//=]*)?/gi;
    if (ireduce.match(url_reg) || imap.match(url_reg)) {
      throw 'No se admiten URLs en las funciones map/reduce';
    }
  };

  try {
    check_emit();
    search_urls();
    test.url = true;
    if (imap.match(/require\(.*\)/g) || ireduce.match(/require\(.*\)/g)) {
      throw 'Contiene sentencias de NodeJS';
    }
    test.nodejs = true;
    context = {
      emit: emit,
      data: idata,
      start: start,
      documment: null,
      Date: _Date
    };
  } catch (error) {
    result = false;
    message = error;
  }

  /*
  Benchmark = require('benchmark')
  suite = new Benchmark.Suite
  try...
      vm.runInNewContext(imap + ";start();", context)
      test.interface = true
  
     # Benchmark
      i = 0
      for k, v of idata
          suite.add('time#{i}', () ->
              imap(k, v)
          )
          i += 1
      suite.run('async': false)
  
      test.time = true
          result = true
          message = "OK"
  */

}).call(this);
