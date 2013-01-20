self.onmessage = function(e) {
	var primos = [];
	var divisores = 0;

	e.data.numeros.forEach(function(numero){
		if(numero == 1 || numero == 2){
			primos.push(numero);
		}
		else {
			for ( j = 2; j<numero; j++){
				if(numero % j == 0){
					divisores++;
				}	
			}

			if(divisores == 0)			
				primos.push(numero);
			else
				primos.push(0);
			divisores = 0;
		}
	});
	e.data.numeros = primos;
	postMessage({ type: 'add_result',
		args: e.data});
	postMessage({ type: 'send_result'});
};