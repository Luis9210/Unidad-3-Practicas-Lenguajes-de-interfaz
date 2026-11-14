INCLUDE Irvine32.inc


;Materia: Lenguajes de interfaz
;Alumno: Luis Fernando Velázquez Araujo
;Horario: 9:00/10:00 am
;Docente: Dr. José Luis Medina jiménez
;Practica: 4 Manejo de pila manual
;Descripción: Acceso a la pila tomando como referencia un EBP fijo


.code 
main PROC
	mov ebx, 999		;Valor inicial de EBX que queremos conservar


	push 3				;Valores que se multiplicarán
	push 25
	call DumpRegs
	call SumarPila

	nop
	exit

main ENDP

SumarPila PROC
	push ebp			;Push ebp para no perder su valor (por si acaso)
	mov ebp, esp		;Establecemos nuestro punto de referencia en la pila con un EBP fijo
	
	push ebx
	
	mov eax,  [ebp+8]	;Recuperamos el valor de 25
	mov ebx, [ebp+12]	;Recuperamos el valor de 3
	call DumpRegs

	imul eax, ebx		;Resultado 75 (4B)
	call DumpRegs
	pop ebx				;Recuperamos ambos valores a conservar 
	pop ebp
ret 8					;Retornamos y retiramos 8 bytes (anulan el push 3 y 25 antes de la llamada al proc)
SumarPila ENDP



END main