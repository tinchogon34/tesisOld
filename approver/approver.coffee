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

# map/reduce functions
# imap, ireduce, idata deben tener un str con la info correspondiente.
if imap == undefined or ireduce == undefined or idata == undefined
        throw 'Varias del investigador sin setear'
else
        imap = fs.readFileSync(imap, 'UTF-8')
        ireduce = fs.readFileSync(imap, 'UTF-8')

emit = (x, y) ->
    if x == undefined or x == null or y == undefined or y == null
        throw 'Uso incorrecto de la funcion emit'

# Como se llama a emit?
check_emit = () ->
        emit_regex = /emit\(.*?\)/g
        res = imap.march(emit_regex)
        if res == null
                throw 'Debe usar emit en map'
        for call in res
                args = call.match(/,/g)
                if args and args.length != 1
                        throw 'Mal llamado a emit' + call

search_urls = () ->
    url_reg = ///
        [-a-zA-Z0-9@:%_\+.~\#?&//=]{2,256}
        \.[a-z]{2,4}\b |
        (\d{1,3}\.){3}\d
        (\/[-a-zA-Z0-9@:%_\+.~\#?&//=]*)?
        ///gi

    if ireduce.search(url_reg) or imap.search(url_reg)
        throw 'No se admiten URLs en las funciones map/reduce'

vm = require('vm')
Benchmark = require('benchmark')
suite = new Benchmark.Suite

try
    # has urls?
        check_emit()
    search_urls()
    test.url = true

    if imap.search(/require\(.*\)/g) or ireduce.search(/require\(.*\)/g)
        throw 'Contiene sentencias de NodeJS'
    test.nodejs = true

    # check for syntax errors and use of emit
    context =
        emit: emit
        data: idata
        start: start
        documment: null
        Date: _Date

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

catch error
    result = false
    message = error
