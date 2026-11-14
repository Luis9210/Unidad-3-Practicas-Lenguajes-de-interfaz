INCLUDE Irvine32.inc


;Materia: Lenguajes de interfaz
;Alumno: Luis Fernando Velázquez Araujo
;Horario: 9:00/10:00 am
;Docente: Dr. José Luis Medina jiménez
;Practica: 3 Validación de cadena
;Descripción: Uso de procedimiento "Validar vacío" que devuelve un valor de 0 o 1 en ebx 0 es vacío, 1 es cadena existente

.data
msgInicio BYTE "Ingrese una cadena: ", 0
msgInvalido BYTE "Su cadena es vacia verifique su entrada y pruebe de nuevo", 0
msgCorrecto	BYTE "Su cadena es valida", 0
msgRecibido BYTE 20 DUP(0), 0


.code 
main PROC
inicio:
	mov edx, OFFSET msgInicio
	call WriteString
	mov edx, OFFSET msgRecibido		;Se recibe el mensaje por consola
	mov ecx, SIZEOF msgRecibido
	call ReadString
	call Crlf

	call validarVacio				;Se valida la cadena para saber si está vacía

	cmp ebx, 1						;El procedimiento devuelve en ebx 0 o 1
	je correcto						;1 para correcto
	jmp invalido					;0 para vacío

invalido:
	mov edx, OFFSET msgInvalido		;Etiqueta invalida
	call WriteString
	call Crlf
	jmp inicio


correcto: 
	mov edx, OFFSET msgCorrecto		;Etiqueta correcta
	call WriteString
	call Crlf

	exit
main ENDP


validarVacio PROC				;Procedimiento que valida si una cadena recibida por consola es vacía o no
	cmp eax, 0
	je vacio
	jmp valido
vacio:
	mov ebx, 0
	jmp fin
valido:
	mov ebx, 1
	jmp fin
fin:	
	ret
validarVacio ENDP

END main