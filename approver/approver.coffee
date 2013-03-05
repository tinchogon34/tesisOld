###
# Parsea la funcion map y reduce para determinar si
# esta en condiciones de ser distribuida.
# El resultado sera almacenado en result y es un boolean
# Debe ser ejecutado con NodeJS
###

fs = require('fs')

result = undefined
message = undefined
test =
    url: false
    nodejs: false
    interface: false
    time: false

# Fake class. El jefe del tiempo. AKA Cronos
class _Date
    getTime: () ->
        new Date().getTime() * 1.3

idata = '{"0": 1, "1": 1, "2": 2, "3": 3}'

imap = 'investigador_map = function (k, v) {log("inv in"); var ms = 1000; var started = new Date().getTime(); while((new Date().getTime() - started) < ms) {}emit("llave", v*v); log("inv in out");};'

ireduce = 'investigador_reduce = function (k, vals){var total = vals.reduce(function(a, b) {return parseInt(a) + parseInt(b); }); return total;};'
# map/reduce functions
# imap, ireduce, idata deben tener un str con la info correspondiente.
if imap == undefined or ireduce == undefined or idata == undefined
        throw 'Variables del investigador sin setear'
#else
#        imap = fs.readFileSync(imap, 'UTF-8')
#        ireduce = fs.readFileSync(imap, 'UTF-8')

emit = (x, y) ->
    if x == undefined or x == null or y == undefined or y == null
        throw 'Uso incorrecto de la funcion emit'

# Como se llama a emit?
check_emit = () ->
        emit_regex = /emit\(.*?\)/g
        res = imap.match(emit_regex)
        if res == null
                throw 'Debe usar emit en map'
        for call in res
                args = call.match(/,/g)
                if args and args.length != 1
                        throw 'Mal llamado a emit' + call

search_urls = () ->
    url_reg = /[-a-zA-Z0-9@:%_\+.~#?&//=]{2,256}\.[a-z]{2,4}\b(\/[-a-zA-Z0-9@:%_\+.~#?&//=]*)?/gi

    if ireduce.match(url_reg) or imap.match(url_reg)
        throw 'No se admiten URLs en las funciones map/reduce'

try
  check_emit()
  search_urls()
  test.url = true
  if imap.match(/require\(.*\)/g) or ireduce.match(/require\(.*\)/g)
    throw 'Contiene sentencias de NodeJS'
  test.nodejs = true
  # check for syntax errors and use of emit
  context =
    emit: emit
    data: idata
    start: start
    documment: null
    Date: _Date
  
catch error
  result = false
  message = error





###
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
###
