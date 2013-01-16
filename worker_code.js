self.onmessage = function(e) {
		numeros = e.data.numeros.map(function(x) {
			return x * 5;
		}); 
		postMessage({ type: 'add_result',
		args: numeros});
		postMessage({ type: 'send_result'});
};