INCLUDE Irvine32.inc

;Materia: Lenguajes de interfaz
;Alumno: Luis Fernando Velázquez Araujo
;Horario: 9:00/10:00 am
;Docente: Dr. José Luis Medina jiménez
;Practica: 5 Macros
;Descripción: Uso simple de macros para desplegar texto y multiplicar

MostrarMensaje MACRO texto			;Este macro recibe la referencia de una cadena y la imprime por consola
	mov edx, OFFSET texto
	call WriteString
	call Crlf
ENDM

multiplicarAB MACRO num1, num2		;Este macro recibe 2 numeros, los multiplica y deja el resultado en eax
	mov eax, num1
	imul eax, num2
ENDM

.data
	mensajeBienvenida BYTE "BIENVENIDO AL SISTEMA DE INVENTARIO",0
	mensajeFin BYTE "HASTA LUEGO, VUELVA PRONTO",0

.code 
main PROC
	MostrarMensaje mensajeBienvenida	;Dos llamadas al macro para imprimir mensajes
	MostrarMensaje mensajeFin

	multiplicarAB 7, 8					;Llamada al macro multiplicarAB
	call WriteDec

	exit
main ENDP
END main