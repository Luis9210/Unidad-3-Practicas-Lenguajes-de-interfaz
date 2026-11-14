INCLUDE Irvine32.inc


;Materia: Lenguajes de interfaz
;Alumno: Luis Fernando Velázquez Araujo
;Horario: 9:00/10:00 am
;Docente: Dr. José Luis Medina jiménez
;Practica: 2 Procedimientos anidados
;Descripción: Se llama a un procedimiento y ese procedimiento llama a otro


.data
	msgM BYTE "Estoy en el Main proc", 0
	msgP1 BYTE "Estoy en el procedimiento P1 este es mi ESP:",0
	msgP2 BYTE "Estoy en el procedimiento P2 este es mi ESP", 0



.code 
main PROC
	mov edx, OFFSET msgM
	call WriteString
	call Crlf
	;Llamada al primer procedimiento
	call p1
	mov eax, 4
	exit
main ENDP
		
p1 PROC						;Primer procedimiento
	mov edx, OFFSET msgP1	;Un mensaje para mostrar que estamos dentro del primer procedimiento
	call WriteString	
	call Crlf
	mov eax, [esp]
	call WriteHex
	call Crlf
	call p2					;llamada al segundo procedimiento
	ret
p1 ENDP

p2 PROC						;Segundo procedimiento
	mov edx, OFFSET msgP2	;Un mensaje para mostrar que estamos dentro del segundo procedimiento
	call WriteString
	call Crlf
	mov eax, [esp]
	call WriteHex
	call Crlf


ret
p2 ENDP

END main