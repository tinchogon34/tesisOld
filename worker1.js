self.onmessage = function(e) {
		e.data.numeros = e.data.numeros.map(function(x) {
			return x * 5;
		}); 
		postMessage({ type: 'add_result',
		args: e.data});
		postMessage({ type: 'send_result'});
};