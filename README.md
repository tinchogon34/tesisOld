Tesis
=====

Mi tesis para la carrera Ingeniera en Informatica en la Universidad de
Mendoza[1].

Breve descripción del tema.
Procesamiento Distribuido web usando Javascript.
Mi tesis propone una solución económica a las grandes cantidades de
procesamiento. La persona o entidad que desea resolver este procesamiento
se lo deneminará genericamente como "invesitigador".

Se utilizará el patrón "MapReduce" y el investigador deberá proporcionar
tanto la función map y reduce. No tendremos ningun tipo de interferencia
en su códogo.

Alojaremos sus funciones, las datos necesarios y sus resultados en un
servidor web, que llamaremos "Servidor de Tareas", o simplemente T.

Abran muchos otros servidores web W que se encargaran de distribuir
el siguiente tag
<script type="text/javascript" src="T/proc.js" /> [2]
Nos valdremos de la recomendacion de Recursos Compartidos de Origenes
Cruzados (CORS) [3] para poder brindar el script proc.js.

Nuestro script proc.js se encargara de pedir a nuestro servidor T
procesos que ejecutaran la funciona Map del Investigador en un Web Worker
en el cliente de W y nos traeran las resultados para luego realizar
la funcion Reduce.

[1] http://www.um.edu.ar/
[2] proc.js hasta que aparezca un mejor nombre
[3] http://en.wikipedia.org/wiki/Cross-origin_resource_sharing
