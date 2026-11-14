INCLUDE Irvine32.inc


;Materia: Lenguajes de interfaz
;Alumno: Luis Fernando Velázquez Araujo
;Horario: 9:00/10:00 am
;Docente: Dr. José Luis Medina jiménez
;Practica: 1 Practica procedimiento
;Descripción: Multiples llamadas al mismo procedimiento que muestra un mensaje y el valor de eax

.data
	mensajeInicio BYTE "Inicio de programa", 0
	mensajeProcedimiento BYTE "Estoy dentro del procedimiento", 0
	mensajeEax BYTE "EAX: ", 0
	mensajeFin BYTE "Fin del programa", 0

.code 
main PROC
	mov edx, OFFSET mensajeInicio
	call WriteString
	call Crlf

	;Primera llamada 
	call procedimiento
	mov eax, 10
	;Segunda llamada
	call procedimiento
	mov eax, 20
	;Tercera llamada
	call procedimiento
	mov edx, OFFSET mensajeFin
	call WriteString
	call Crlf

	exit
main ENDP

procedimiento PROC						;Procedimiento en cuestión
	mov edx, OFFSET mensajeProcedimiento
	call WriteString
	call Crlf
	mov edx, OFFSET mensajeEAX			;Desplegamos el valor de eax por consola
	call WriteString
	call WriteDec
	call Crlf
	ret
procedimiento ENDP 


END main