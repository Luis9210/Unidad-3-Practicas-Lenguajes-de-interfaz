INCLUDE Irvine32.inc

;Materia: Lenguajes de interfaz
;Alumno: Luis Fernando Velázquez Araujo
;Horario: 9:00/10:00 am
;Docente: Dr. José Luis Medina jiménez
;Practica: Proyecto Unidad 3 - Sistema de ventas e inventario con Macros y Procedimientos (USES)
;Descripción: Actualizacion del sistema de consola para tienda de electronica y microcontroladores
;             incorporando definicion y expansion de MACROS (Practica 05 Unidad 3) y preservacion
;             automatica de registros en la pila mediante la directiva PROC USES en cada procedimiento.

; =============================================================================
; DEFINICION DE MACROS (Vistas en Unidad 3 - Practica 05 MACROS)
; Se colocan antes de .data y se expanden en linea durante el ensamblado.
; =============================================================================

; 1. Macro MostrarMensaje (Reusado de Practica 05 - MACROS):
;    Recibe la referencia de una cadena, la imprime por consola y agrega salto de linea.
MostrarMensaje MACRO texto
	mov edx, OFFSET texto
	call WriteString
	call Crlf
ENDM

; 2. Macro MostrarTextoSinSalto:
;    Imprime una cadena en consola sin salto de linea (ideal para pedir datos o etiquetas en la misma linea).
MostrarTextoSinSalto MACRO texto
	mov edx, OFFSET texto
	call WriteString
ENDM

; 3. Macro CapturarCadena:
;    Limpia el primer byte del buffer, carga su direccion en EDX y su capacidad en ECX, y llama a ReadString.
CapturarCadena MACRO buffer
	mov buffer, 0
	mov edx, OFFSET buffer
	mov ecx, SIZEOF buffer
	call ReadString
ENDM

; 4. Macro ImprimirNumeroDecimal:
;    Carga un numero entero en EAX, lo convierte a cadena con convertirDecimal y lo muestra con WriteString.
ImprimirNumeroDecimal MACRO valor
	mov eax, valor
	call convertirDecimal
	mov edx, OFFSET bufferDecimal
	call WriteString
ENDM

; 5. Macro ImprimirImporte:
;    Carga una cantidad en centavos enteros en EAX y la muestra con formato "$XXXX.XX MXN".
ImprimirImporte MACRO valorCentavos
	mov eax, valorCentavos
	call mostrarImporteMXN
ENDM

; 6. Macro multiplicarAB (Adaptado de Practica 05 - MACROS):
;    Recibe dos valores sin signo, los multiplica con MUL y deja el producto en EAX.
multiplicarAB MACRO num1, num2
	mov eax, num1
	mov ebx, num2
	mul ebx
ENDM

; 7. Macro CalcularDesplazamientoESI:
;    Calcula el desplazamiento en bytes ESI = indice * tamanoElemento para localizar un producto en memoria.
CalcularDesplazamientoESI MACRO indice, tamanoElemento
	mov eax, indice
	mov ebx, tamanoElemento
	mul ebx
	mov esi, eax
ENDM

; 8. Macro AgregarCaracterArchivo:
;    Coloca un caracter ASCII (como '|', '.', '0', CR o LF) en bufferArchivo[posArchivo] e incrementa posArchivo.
AgregarCaracterArchivo MACRO caracterAscii
	mov ebx, posArchivo
	mov bufferArchivo[ebx], caracterAscii
	inc posArchivo
ENDM

.data
	; =========================================================================
	; 1. CONSTANTES SIMBOLICAS
	; =========================================================================
	maxProductos = 10					; Capacidad maxima del catalogo: 10 productos
	bytesPorCodigo = 8					; Cada codigo ocupa 8 bytes: 7 caracteres (ABC-123) + 1 byte nulo (00h)
	bytesPorNombre = 26					; Cada nombre ocupa 26 bytes: hasta 25 caracteres + 1 byte nulo (00h)
	maxExistencia = 100					; Existencia maxima permitida por producto: 100 unidades
	minPrecioCentavos = 1				; Precio minimo permitido: $0.01 MXN = 1 centavo entero
	maxPrecioCentavos = 999999			; Precio maximo permitido: $9999.99 MXN = 999999 centavos enteros
	minCantidadMayoreo = 5				; Regla del negocio: a partir de 5 unidades aplica descuento de mayoreo
	porcentajeDescuento = 10			; Regla del negocio: 10% de descuento sobre el importe base
	capacidadBufferArchivo = 1024		; Capacidad maxima de lectura de ReadFromFile (sin contar el byte 00h extra)

	; =========================================================================
	; 2. ORGANIZACION DEL CATALOGO EN MEMORIA (Arreglos paralelos indexados con ESI)
	; =========================================================================
	codigosProductos BYTE 80 DUP(0)		; 10 productos * 8 bytes = 80 bytes inicializados en 0
	nombresProductos BYTE 260 DUP(0)	; 10 productos * 26 bytes = 260 bytes inicializados en 0
	preciosProductos DWORD 10 DUP(0)	; 10 precios en centavos enteros (4 bytes cada DWORD)
	existenciasProductos DWORD 10 DUP(0); 10 existencias en unidades (4 bytes cada DWORD)
	totalProductos DWORD 0				; Contador de productos registrados actualmente (0 a 10)

	; =========================================================================
	; 3. ARREGLOS TEMPORALES PARA VALIDAR EL ARCHIVO ANTES DE REEMPLAZAR EL CATALOGO
	; =========================================================================
	tempCodigos BYTE 80 DUP(0)			; Codigos temporales mientras se valida Inventario.txt
	tempNombres BYTE 260 DUP(0)			; Nombres temporales mientras se valida Inventario.txt
	tempPrecios DWORD 10 DUP(0)			; Precios temporales en centavos mientras se valida Inventario.txt
	tempExistencias DWORD 10 DUP(0)		; Existencias temporales mientras se valida Inventario.txt
	tempTotal DWORD 0					; Cantidad de productos leidos y validados desde el archivo

	; =========================================================================
	; 4. VARIABLES DE CONTROL DE SESION Y ESTADO
	; =========================================================================
	ingresosSesion DWORD 0				; Suma acumulada de importes finales de las ventas aceptadas (en centavos)
	cambiosSinGuardar DWORD 0			; Bandera: 0 = todo guardado, 1 = hay cambios pendientes de guardar
	indiceEncontrado DWORD 0			; Guarda el indice (0 a 9) cuando buscarProductoPorCodigo localiza un producto
	resultadoValidacion DWORD 0			; Bandera de salida de validaciones: 1 = correcto/exito, 0 = error

	; =========================================================================
	; 5. BUFFERS DE CAPTURA Y CONVERSION PROPIA
	; =========================================================================
	bufferDecimal BYTE 16 DUP(0)		; Buffer donde convertirDecimal deja el numero convertido a texto ASCII
	bufferCaptura BYTE 40 DUP(0)		; Buffer general donde ReadString deposita lo que el usuario teclea
	bufferCodigo BYTE 16 DUP(0)			; Buffer para capturar y validar el codigo en formato ABC-123
	bufferNombre BYTE 32 DUP(0)			; Buffer para capturar y validar el nombre (1 a 25 caracteres)

	; Variables de trabajo para las conversiones numericas
	acumuladoNum DWORD 0				; Acumulador donde se construye el numero entero a partir de caracteres ASCII
	pesosAcumulados DWORD 0				; Acumulador de la parte entera (pesos) al leer un precio
	centavosAcumulados DWORD 0			; Acumulador de la parte decimal (centavos) al leer un precio
	tienePunto DWORD 0					; Bandera: 0 = aun no aparece '.', 1 = ya aparecio el punto decimal '.'
	digitosEnteros DWORD 0				; Cuenta cuantos digitos de pesos se leyeron antes del punto
	digitosDecimales DWORD 0			; Cuenta cuantos digitos de centavos se leyeron despues del punto (max 2)
	centavosTemp DWORD 0				; Guarda el residuo (EDX) de dividir entre 100 al mostrar u obtener centavos

	; Variables de trabajo para operaciones de inventario, ventas y resumen
	indiceActual DWORD 0				; Indice del producto que se esta procesando o mostrando (0 a 9)
	cantidadCapturada DWORD 0			; Unidades enteras capturadas para entrada de mercancia o venta
	precioUnitarioActual DWORD 0		; Precio en centavos del producto actual
	existenciaActualNum DWORD 0			; Existencia en unidades del producto actual
	importeBaseVenta DWORD 0			; Resultado de multiplicar (precio * cantidad) en centavos
	descuentoVenta DWORD 0				; Descuento de mayoreo en centavos (con fracciones de centavo descartadas)
	importeFinalVenta DWORD 0			; Importe final a cobrar (importeBaseVenta - descuentoVenta)
	unidadesTotalesResumen DWORD 0		; Acumulador de unidades disponibles totales para el resumen
	valorTotalInventario DWORD 0		; Acumulador de (precio * existencia) de todos los productos para el resumen

	; =========================================================================
	; 6. VARIABLES DE ARCHIVO DE DISCO
	; =========================================================================
	nombreArchivo BYTE "Inventario.txt", 0
	archivoHandle DWORD ?				; Guarda el handle (identificador del sistema operativo) del archivo
	bufferArchivo BYTE 1025 DUP(0)		; 1024 bytes de capacidadBufferArchivo + 1 byte extra para el 00h final
	bytesArchivo DWORD 0				; Cantidad de bytes a escribir o cantidad de bytes leidos del archivo
	posArchivo DWORD 0					; Indice para recorrer bufferArchivo al construir o leer el archivo

	; =========================================================================
	; 7. CADENAS DE TEXTO PARA MENUS, ETIQUETAS Y MENSAJES DE CONSOLA
	; =========================================================================
	msgSeparador BYTE "================================================================", 0
	msgLinea     BYTE "----------------------------------------------------------------", 0
	msgTitulo    BYTE "   SISTEMA DE VENTAS E INVENTARIO - ELECTRONICA ESP32/ARDUINO   ", 0
	msgMenu1     BYTE "1. Registrar nuevo producto (Alta)", 0
	msgMenu2     BYTE "2. Mostrar inventario completo", 0
	msgMenu3     BYTE "3. Buscar producto por codigo", 0
	msgMenu4     BYTE "4. Recibir mercancia (Entrada a almacen)", 0
	msgMenu5     BYTE "5. Realizar venta", 0
	msgMenu6     BYTE "6. Mostrar resumen del inventario y sesion", 0
	msgMenu7     BYTE "7. Guardar catalogo en archivo (Inventario.txt)", 0
	msgMenu8     BYTE "8. Cargar catalogo desde archivo (Inventario.txt)", 0
	msgMenu9     BYTE "9. Demostrar/consultar regla del negocio (Mayoreo)", 0
	msgMenu0     BYTE "0. Salir del sistema", 0
	msgPedirOp   BYTE "Seleccione una opcion (0-9): ", 0
	msgOpInvalida BYTE "ERROR: Opcion no valida. Ingrese un digito entre 0 y 9.", 0

	; Mensajes de alta y validacion de campos
	msgTituloAlta      BYTE "--- ALTA DE NUEVO PRODUCTO ---", 0
	msgInventarioLleno BYTE "ERROR: Capacidad maxima alcanzada (10 productos). No se pueden registrar mas.", 0
	msgPedirCodigo     BYTE "Ingrese el codigo del producto (Formato ABC-123, 3 mayusculas, guion, 3 digitos): ", 0
	msgErrCodigo       BYTE "ERROR: Codigo incorrecto. Debe tener exactamente 3 letras MAYUSCULAS, un guion '-' y 3 digitos (ej. ESP-001).", 0
	msgErrDuplicado    BYTE "ERROR: El codigo ingresado ya existe en el catalogo. Rechazando duplicado.", 0
	msgPedirNombre     BYTE "Ingrese el nombre del producto (1 a 25 caracteres, sin usar '|'): ", 0
	msgErrNombre       BYTE "ERROR: Nombre invalido. Debe tener entre 1 y 25 caracteres y no estar vacio.", 0
	msgPedirPrecio     BYTE "Ingrese el precio en pesos mexicanos ($0.01 a $9999.99, ej. 185.50): ", 0
	msgErrPrecio       BYTE "ERROR: Precio invalido. Use solo digitos y opcionalmente un punto con 1 o 2 decimales (rango 0.01 a 9999.99).", 0
	msgPedirExistIni   BYTE "Ingrese la existencia inicial (0 a 100 unidades enteras): ", 0
	msgErrExistIni     BYTE "ERROR: Existencia invalida. Ingrese un numero entero entre 0 y 100.", 0
	msgAltaExito       BYTE "EXITO: Producto registrado correctamente en el catalogo.", 0

	; Mensajes de consulta e impresion de productos
	msgTituloInv       BYTE "--- CATALOGO DE INVENTARIO ACTUAL ---", 0
	msgInvVacio        BYTE "AVISO: El inventario esta vacio actualmente (0 productos registrados).", 0
	msgTituloBuscar    BYTE "--- BUSQUEDA DE PRODUCTO POR CODIGO ---", 0
	msgNoEncontrado    BYTE "ERROR: No se encontro ningun producto con ese codigo.", 0
	msgProductoHallado BYTE "Producto localizado:", 0
	lblNumProd         BYTE "# Producto: ", 0
	lblCodigo          BYTE " | Codigo: ", 0
	lblNombre          BYTE " | Nombre: ", 0
	lblPrecio          BYTE " | Precio: ", 0
	lblExistencia      BYTE " | Existencia: ", 0
	lblUnidades        BYTE " unidades", 0
	SimboloPesos       BYTE "$", 0
	SimboloPunto       BYTE ".", 0
	textoCero          BYTE "0", 0
	EtiquetaMXN        BYTE " MXN", 0

	; Mensajes de recepcion de mercancia
	msgTituloRecibir   BYTE "--- RECIBIR MERCANCIA EN ALMACEN ---", 0
	msgExistActual     BYTE "Existencia actual del producto: ", 0
	msgPedirEntrada    BYTE "Ingrese la cantidad de unidades a recibir (entero mayor que 0): ", 0
	msgErrCantidad     BYTE "ERROR: Cantidad invalida. Debe ser un numero entero mayor que cero.", 0
	msgErrExcede100    BYTE "ERROR: Operacion rechazada. La suma supera el limite maximo de 100 unidades por producto.", 0
	msgEntradaExito    BYTE "EXITO: Mercancia recibida. Nueva existencia actualizada: ", 0

	; Mensajes de ventas
	msgTituloVenta     BYTE "--- REALIZAR VENTA DE PRODUCTO ---", 0
	msgSinStock        BYTE "ERROR: Este producto tiene 0 unidades disponibles. No se puede vender.", 0
	msgPrecioActual    BYTE "Precio unitario: ", 0
	msgPedirVenta      BYTE "Ingrese la cantidad de unidades a vender (entero mayor que 0): ", 0
	msgErrInsuficiente BYTE "ERROR: Venta rechazada. No hay existencias suficientes para cubrir esa cantidad.", 0
	msgErrOverflow     BYTE "ERROR: Desbordamiento aritmetico detectado. Operacion rechazada.", 0
	msgResumenTicket   BYTE "--- DESGLOSE DE LA VENTA ACEPTADA ---", 0
	msgImporteBase     BYTE "Importe base (Precio x Cantidad): ", 0
	msgDescuentoApl    BYTE "Regla de negocio aplicada (10% descuento mayoreo >= 5 uds): -", 0
	msgSinDescuento    BYTE "Descuento de mayoreo (aplica en 5 o mas unidades): $0.00 MXN", 0
	msgImporteFinal    BYTE "Importe final a pagar: ", 0
	msgStockRestante   BYTE "Venta registrada con exito. Existencia restante del producto: ", 0

	; Mensajes de resumen
	msgTituloResumen   BYTE "--- RESUMEN DEL INVENTARIO Y DE LA SESION ---", 0
	msgTotalProdReg    BYTE "Productos registrados en catalogo: ", 0
	msgTotalUnidades   BYTE "Total de unidades disponibles en almacen: ", 0
	msgValorTotalInv   BYTE "Valor total del inventario: ", 0
	msgIngresosAcum    BYTE "Ingresos acumulados de la sesion (ventas): ", 0

	; Mensajes de regla del negocio
	msgTituloRegla     BYTE "--- REGLA DEL NEGOCIO: DESCUENTO POR MAYOREO (10%) ---", 0
	msgDescRegla1      BYTE "Definicion: En la compra de 5 o mas unidades de un mismo producto,", 0
	msgDescRegla2      BYTE "se aplica automaticamente un 10% de descuento sobre el importe base.", 0
	msgDescRegla3      BYTE "Las fracciones de centavo se descartan mediante division entera (DIV).", 0
	msgDemoCasoNo      BYTE "Demostracion Caso 1 (NO aplica, < 5 unidades): 3 unidades de ", 0
	msgDemoCasoSi      BYTE "Demostracion Caso 2 (SI aplica, >= 5 unidades): 5 unidades de ", 0
	msgDemoBase        BYTE "  -> Importe base: ", 0
	msgDemoDesc        BYTE "  -> Descuento (10%, truncando fraccion de centavo): ", 0
	msgDemoFinal       BYTE "  -> Importe final: ", 0

	; Mensajes de archivo y salida
	msgTituloGuardar   BYTE "--- GUARDAR CATALOGO EN ARCHIVO ---", 0
	msgGuardarExito    BYTE "EXITO: Catalogo guardado correctamente en Inventario.txt.", 0
	msgGuardarError    BYTE "ERROR: No se pudo guardar el archivo Inventario.txt.", 0
	msgTituloCargar    BYTE "--- CARGAR CATALOGO DESDE ARCHIVO ---", 0
	msgContenidoLeido  BYTE "Contenido leido del archivo Inventario.txt:", 0
	msgCargarExito     BYTE "EXITO: Archivo validado y catalogo reconstruido en memoria correctamente.", 0
	msgCargarError     BYTE "ERROR: El archivo Inventario.txt no existe o no se pudo abrir. Se conserva el catalogo actual.", 0
	msgArchivoDanado   BYTE "ERROR: El archivo esta vacio o contiene datos invalidos/danados. Se conserva el catalogo actual.", 0
	msgAvisoSinGuardar BYTE "ADVERTENCIA: Hay cambios en el inventario sin guardar en el archivo.", 0
	msgPreguntaSalir   BYTE "Desea salir sin guardar los cambios? (1 = Si, salir / 2 = No, volver al menu): ", 0
	msgDespedida       BYTE "Saliendo del sistema. Gracias por usar el programa!", 0

.code
; =============================================================================
; PROCEDIMIENTO PRINCIPAL: main
; Descripcion: Despliega el menu principal utilizando la macro MostrarMensaje,
;              captura la opcion mediante la macro CapturarCadena y llama al
;              procedimiento elegido.
; Entradas:    Captura por teclado del usuario.
; Salidas:     Finaliza el programa con exit.
; Registros modificados: EAX, EBX, ECX, EDX, ESI.
; =============================================================================
main PROC
cicloMenu:
	call Crlf
	; Desplegamos el menu completo usando la macro MostrarMensaje (Practica 05)
	MostrarMensaje msgSeparador
	MostrarMensaje msgTitulo
	MostrarMensaje msgSeparador
	MostrarMensaje msgMenu1
	MostrarMensaje msgMenu2
	MostrarMensaje msgMenu3
	MostrarMensaje msgMenu4
	MostrarMensaje msgMenu5
	MostrarMensaje msgMenu6
	MostrarMensaje msgMenu7
	MostrarMensaje msgMenu8
	MostrarMensaje msgMenu9
	MostrarMensaje msgMenu0
	MostrarMensaje msgLinea

	; Pedimos y leemos la opcion usando las macros MostrarTextoSinSalto y CapturarCadena
	MostrarTextoSinSalto msgPedirOp
	CapturarCadena bufferCaptura
	call Crlf

	; Validamos que el usuario haya escrito exactamente 1 caracter (EAX == 1)
	cmp eax, 1
	jne opcionMenuInvalida

	mov esi, 0							; ESI = 0 para apuntar al primer caracter de bufferCaptura
	mov eax, 0							; Limpiamos los 32 bits de EAX antes de usar AL
	mov al, bufferCaptura[esi]			; Movemos a AL el caracter capturado en la posicion 0

	cmp al, '1'
	je ejecutarOp1
	cmp al, '2'
	je ejecutarOp2
	cmp al, '3'
	je ejecutarOp3
	cmp al, '4'
	je ejecutarOp4
	cmp al, '5'
	je ejecutarOp5
	cmp al, '6'
	je ejecutarOp6
	cmp al, '7'
	je ejecutarOp7
	cmp al, '8'
	je ejecutarOp8
	cmp al, '9'
	je ejecutarOp9
	cmp al, '0'
	je intentarSalir

opcionMenuInvalida:
	MostrarMensaje msgOpInvalida
	jmp cicloMenu

ejecutarOp1:
	call registrarProducto
	jmp cicloMenu

ejecutarOp2:
	call mostrarInventario
	jmp cicloMenu

ejecutarOp3:
	call consultarPorCodigo
	jmp cicloMenu

ejecutarOp4:
	call recibirMercancia
	jmp cicloMenu

ejecutarOp5:
	call realizarVenta
	jmp cicloMenu

ejecutarOp6:
	call mostrarResumen
	jmp cicloMenu

ejecutarOp7:
	call guardarEnArchivo
	jmp cicloMenu

ejecutarOp8:
	call cargarDesdeArchivo
	jmp cicloMenu

ejecutarOp9:
	call demostrarReglaNegocio
	jmp cicloMenu

intentarSalir:
	cmp cambiosSinGuardar, 0
	je confirmarSalida

pedirConfirmacionSalida:
	MostrarMensaje msgAvisoSinGuardar
	MostrarTextoSinSalto msgPreguntaSalir
	CapturarCadena bufferCaptura
	call Crlf

	cmp eax, 1
	jne pedirConfirmacionSalida
	mov esi, 0
	mov eax, 0
	mov al, bufferCaptura[esi]
	cmp al, '1'
	je confirmarSalida
	cmp al, '2'
	je cicloMenu
	jmp pedirConfirmacionSalida

confirmarSalida:
	MostrarMensaje msgDespedida
	exit
main ENDP

; =============================================================================
; NOTA SOBRE LA DIRECTIVA "PROC USES":
; En MASM, al declarar por ejemplo:
;   cargarDesdeArchivo PROC USES eax ebx ecx edx esi
; (los registros se separan con espacios porque en MASM la coma ',' despues de
; USES indica parametros en la pila), el ensamblador genera automaticamente las
; instrucciones PUSH al inicio del procedimiento y las instrucciones POP en
; orden inverso (LIFO) justo antes de RET, manteniendo equilibrada la pila.
; =============================================================================

; =============================================================================
; PROCEDIMIENTO: validarVacio (Reusado de Unidad 3 - Practica 03)
; Descripcion: Revisa si la longitud devuelta por ReadString en EAX es 0.
; Entradas:    EAX = numero de caracteres leidos por ReadString.
; Salidas:     EBX = 1 si la cadena tiene al menos 1 caracter (es valida);
;              EBX = 0 si la cadena esta vacia.
; Registros conservados automaticamente: EAX (mediante USES eax).
; =============================================================================
validarVacio PROC USES eax
	cmp eax, 0
	je vacioDetectado
	mov ebx, 1
	jmp finValidarVacio
vacioDetectado:
	mov ebx, 0
finValidarVacio:
	ret
validarVacio ENDP

; =============================================================================
; PROCEDIMIENTO: convertirDecimal
; Descripcion: Convierte un numero entero sin signo en EAX a una cadena decimal
;              ASCII terminada en 00h dentro de bufferDecimal.
; Entradas:    EAX = numero entero sin signo a convertir.
; Salidas:     bufferDecimal contiene el numero como texto ASCII terminado en 0.
; Registros conservados automaticamente: EAX, EBX, ECX, EDX, ESI (con USES).
; =============================================================================
convertirDecimal PROC USES eax ebx ecx edx esi
	mov esi, 0							; ESI lleva la cuenta de cuantos digitos se meten a la pila
	mov ecx, eax						; Copiamos el numero original en ECX
	mov ebx, 10							; EBX = 10 (divisor para extraer digitos en base 10)

calcular:
	mov edx, 0							; Limpiamos EDX en 0 porque DIV divide el par EDX:EAX entre EBX
	div ebx								; EAX = cociente, EDX = residuo (ultimo digito 0..9)
	add dl, 30h							; Sumamos 30h ('0' ASCII) al residuo en DL
	push edx							; Metemos el caracter ASCII a la pila para invertir el orden

	inc esi								; Contamos un digito mas
	cmp eax, 0							; Revisamos si el cociente en EAX ya llego a 0
	je iniciarGuardado
	jmp calcular

iniciarGuardado:
	mov ebx, 0							; EBX recorre bufferDecimal[ebx] desde 0
	dec esi								; ESI pasa a representar el ultimo indice (0 a N-1)

guardarDigito:
	pop edx								; Sacamos de la pila el digito de mayor peso (LIFO)
	mov bufferDecimal[ebx], dl			; Escribimos el caracter ASCII en bufferDecimal
	cmp ebx, esi
	je finConvertirDecimal
	inc ebx
	jmp guardarDigito

finConvertirDecimal:
	inc ebx
	mov bufferDecimal[ebx], 0			; Colocamos el byte nulo 00h requerido por WriteString
	ret
convertirDecimal ENDP

; =============================================================================
; PROCEDIMIENTO: mostrarImporteMXN
; Descripcion: Recibe en EAX un importe en centavos enteros y lo muestra en
;              pantalla con formato "$XXXX.XX MXN" apoyandose en las macros.
; Entradas:    EAX = importe en centavos enteros.
; Salidas:     Imprime por consola "$pesos.centavos MXN".
; Registros conservados automaticamente: EAX, EBX, EDX (con USES).
; =============================================================================
mostrarImporteMXN PROC USES eax ebx edx
	; 1. Separar pesos y centavos dividiendo entre 100
	mov edx, 0
	mov ebx, 100
	div ebx								; EAX = pesos (cociente), EDX = centavos (residuo 0..99)
	mov centavosTemp, edx

	; 2. Mostrar el signo "$" seguido de los pesos y el punto "."
	MostrarTextoSinSalto SimboloPesos
	ImprimirNumeroDecimal eax
	MostrarTextoSinSalto SimboloPunto

	; 3. Revisar si los centavos necesitan un cero a la izquierda (0 a 9 -> "05")
	mov eax, centavosTemp
	cmp eax, 9
	jg mostrarCentavosDosCifras
	MostrarTextoSinSalto textoCero

mostrarCentavosDosCifras:
	ImprimirNumeroDecimal centavosTemp
	MostrarTextoSinSalto EtiquetaMXN
	ret
mostrarImporteMXN ENDP

; =============================================================================
; PROCEDIMIENTO: validarFormatoCodigo
; Descripcion: Valida que la cadena en bufferCodigo tenga longitud 7 y cumpla
;              con el formato ABC-123.
; Entradas:    bufferCodigo = cadena leida; EAX = longitud devuelta por ReadString.
; Salidas:     resultadoValidacion = 1 si el codigo es valido, 0 si es invalido.
; Registros conservados automaticamente: EAX, ESI (con USES).
; =============================================================================
validarFormatoCodigo PROC USES eax esi
	cmp eax, 7
	jne errorCodigoFormato

	mov esi, 0
validacionPosicionCodigo:
	mov eax, 0
	mov al, bufferCodigo[esi]
	cmp esi, 3
	jl letrasCodigo
	je guionCodigo
	cmp esi, 6
	jg finCodigoValido
	jmp digitosCodigo

letrasCodigo:
	cmp al, 65							; 'A' mayuscula en ASCII
	jl errorCodigoFormato
	cmp al, 90							; 'Z' mayuscula en ASCII
	jg errorCodigoFormato
	inc esi
	jmp validacionPosicionCodigo

guionCodigo:
	cmp al, 45							; '-' en ASCII
	jne errorCodigoFormato
	inc esi
	jmp validacionPosicionCodigo

digitosCodigo:
	cmp al, 48							; '0' en ASCII
	jl errorCodigoFormato
	cmp al, 57							; '9' en ASCII
	jg errorCodigoFormato
	inc esi
	jmp validacionPosicionCodigo

finCodigoValido:
	mov resultadoValidacion, 1
	jmp salirValidarCodigo

errorCodigoFormato:
	mov resultadoValidacion, 0

salirValidarCodigo:
	ret
validarFormatoCodigo ENDP

; =============================================================================
; PROCEDIMIENTO: buscarProductoPorCodigo
; Descripcion: Recorre con ESI el arreglo codigosProductos buscando si el codigo
;              en bufferCodigo ya existe dentro de los productos registrados.
; Entradas:    bufferCodigo = codigo de 7 caracteres a buscar; totalProductos.
; Salidas:     resultadoValidacion = 1 si se encontro (y guarda su posicion 0..9
;              en indiceEncontrado); resultadoValidacion = 0 si no existe.
; Registros conservados automaticamente: EAX, EBX, ECX, EDX, ESI (con USES).
; =============================================================================
buscarProductoPorCodigo PROC USES eax ebx ecx edx esi
	mov resultadoValidacion, 0
	cmp totalProductos, 0
	je finBusquedaCodigo

	mov ecx, 0							; ECX = indice del producto actual (0, 1, 2...)
cicloBuscarProducto:
	mov eax, ecx
	cmp eax, totalProductos
	je finBusquedaCodigo

	; Usamos la macro CalcularDesplazamientoESI para obtener ESI = ECX * 8
	CalcularDesplazamientoESI ecx, bytesPorCodigo

	mov ebx, 0							; EBX recorre de 0 a 6 los 7 caracteres de bufferCodigo
compararSieteCaracteres:
	mov eax, 0
	mov al, codigosProductos[esi]
	mov edx, 0
	mov dl, bufferCodigo[ebx]
	cmp al, dl
	jne pasarSiguienteProducto

	inc esi
	inc ebx
	cmp ebx, 7
	je productoEncontradoExito
	jmp compararSieteCaracteres

pasarSiguienteProducto:
	inc ecx
	jmp cicloBuscarProducto

productoEncontradoExito:
	mov resultadoValidacion, 1
	mov indiceEncontrado, ecx

finBusquedaCodigo:
	ret
buscarProductoPorCodigo ENDP

; =============================================================================
; PROCEDIMIENTO: convertirCadenaEntero
; Descripcion: Recorre con ESI los caracteres de bufferCaptura verificando que
;              todos sean digitos decimales entre '0' y '9' y los convierte a
;              un entero en acumuladoNum.
; Entradas:    bufferCaptura = cadena capturada; EAX = longitud de la cadena.
; Salidas:     resultadoValidacion = 1 y acumuladoNum = entero convertido;
;              resultadoValidacion = 0 si es invalida o desborda.
; Registros conservados automaticamente: EAX, EBX, EDX, ESI (con USES).
; =============================================================================
convertirCadenaEntero PROC USES eax ebx edx esi
	call validarVacio
	cmp ebx, 0
	je errorConversionEntero

	cmp eax, 6
	jg errorConversionEntero

	mov esi, 0
	mov acumuladoNum, 0

ciclarDigitosEntero:
	cmp bufferCaptura[esi], '0'
	jl errorConversionEntero
	cmp bufferCaptura[esi], '9'
	jg errorConversionEntero

	; Multiplicamos acumuladoNum por 10 usando la macro multiplicarAB
	multiplicarAB acumuladoNum, 10
	jc errorConversionEntero
	mov acumuladoNum, eax

	mov ebx, 0
	mov bl, bufferCaptura[esi]
	sub ebx, 30h
	add acumuladoNum, ebx
	jc errorConversionEntero

	inc esi
	cmp bufferCaptura[esi], 0
	je conversionEnteroCorrecta
	jmp ciclarDigitosEntero

conversionEnteroCorrecta:
	mov resultadoValidacion, 1
	jmp finConvertirCadenaEntero

errorConversionEntero:
	mov resultadoValidacion, 0

finConvertirCadenaEntero:
	ret
convertirCadenaEntero ENDP

; =============================================================================
; PROCEDIMIENTO: convertirPrecioCentavos
; Descripcion: Convierte un precio capturado en pesos mexicanos dentro de
;              bufferCaptura a centavos enteros en acumuladoNum.
; Entradas:    bufferCaptura = cadena con el precio; EAX = longitud leida.
; Salidas:     resultadoValidacion = 1 y acumuladoNum = centavos enteros;
;              resultadoValidacion = 0 si el precio es invalido.
; Registros conservados automaticamente: EAX, EBX, EDX, ESI (con USES).
; =============================================================================
convertirPrecioCentavos PROC USES eax ebx edx esi
	call validarVacio
	cmp ebx, 0
	je errorPrecio

	mov pesosAcumulados, 0
	mov centavosAcumulados, 0
	mov tienePunto, 0
	mov digitosEnteros, 0
	mov digitosDecimales, 0
	mov esi, 0

cicloAnalizarPrecio:
	mov eax, 0
	mov al, bufferCaptura[esi]
	cmp al, 0
	je revisarCierrePrecio

	cmp al, 46							; '.' en ASCII
	je puntoDecimalEncontrado

	cmp al, '0'
	jl errorPrecio
	cmp al, '9'
	jg errorPrecio

	cmp tienePunto, 1
	je procesarDigitoCentavos

procesarDigitoPesos:
	inc digitosEnteros
	cmp digitosEnteros, 4
	jg errorPrecio

	multiplicarAB pesosAcumulados, 10
	mov pesosAcumulados, eax

	mov ebx, 0
	mov bl, bufferCaptura[esi]
	sub ebx, 30h
	add pesosAcumulados, ebx

	inc esi
	jmp cicloAnalizarPrecio

puntoDecimalEncontrado:
	cmp tienePunto, 1
	je errorPrecio
	cmp digitosEnteros, 0
	je errorPrecio
	mov tienePunto, 1
	inc esi
	jmp cicloAnalizarPrecio

procesarDigitoCentavos:
	inc digitosDecimales
	cmp digitosDecimales, 2				; Rechaza un tercer decimal
	jg errorPrecio

	multiplicarAB centavosAcumulados, 10
	mov centavosAcumulados, eax

	mov ebx, 0
	mov bl, bufferCaptura[esi]
	sub ebx, 30h
	add centavosAcumulados, ebx

	inc esi
	jmp cicloAnalizarPrecio

revisarCierrePrecio:
	cmp tienePunto, 0
	je unirPesosYCentavos

	cmp digitosDecimales, 0
	je errorPrecio

	cmp digitosDecimales, 1
	jne unirPesosYCentavos
	multiplicarAB centavosAcumulados, 10
	mov centavosAcumulados, eax

unirPesosYCentavos:
	multiplicarAB pesosAcumulados, 100
	jc errorPrecio
	add eax, centavosAcumulados
	jc errorPrecio

	cmp eax, minPrecioCentavos
	jl errorPrecio
	cmp eax, maxPrecioCentavos
	jg errorPrecio

	mov acumuladoNum, eax
	mov resultadoValidacion, 1
	jmp finConvertirPrecio

errorPrecio:
	mov resultadoValidacion, 0

finConvertirPrecio:
	ret
convertirPrecioCentavos ENDP

; =============================================================================
; PROCEDIMIENTO: registrarProducto
; Descripcion: Captura y valida los 4 datos de un nuevo producto usando las
;              macros de captura y despliegue, y los almacena en el catalogo.
; Entradas:    Datos ingresados por el usuario mediante CapturarCadena.
; Salidas:     Almacena el producto, incrementa totalProductos y activa cambiosSinGuardar.
; Registros conservados automaticamente: EAX, EBX, ECX, EDX, ESI (con USES).
; =============================================================================
registrarProducto PROC USES eax ebx ecx edx esi
	MostrarMensaje msgTituloAlta

	mov eax, totalProductos
	cmp eax, maxProductos
	jl capturarCodigoNuevo

	MostrarMensaje msgInventarioLleno
	jmp finRegistrarProducto

capturarCodigoNuevo:
	MostrarTextoSinSalto msgPedirCodigo
	CapturarCadena bufferCodigo

	call validarFormatoCodigo
	cmp resultadoValidacion, 1
	jne errorFormatoEnAlta

	call buscarProductoPorCodigo
	cmp resultadoValidacion, 1
	je errorDuplicadoEnAlta
	jmp capturarNombreNuevo

errorFormatoEnAlta:
	MostrarMensaje msgErrCodigo
	jmp capturarCodigoNuevo

errorDuplicadoEnAlta:
	MostrarMensaje msgErrDuplicado
	jmp capturarCodigoNuevo

capturarNombreNuevo:
	MostrarTextoSinSalto msgPedirNombre
	CapturarCadena bufferNombre

	call validarVacio
	cmp ebx, 0
	je errorNombreEnAlta

	cmp eax, 25
	jg errorNombreEnAlta

	mov esi, 0
verificarSinBarraNombre:
	mov eax, 0
	mov al, bufferNombre[esi]
	cmp al, 0
	je capturarPrecioNuevo
	cmp al, 124							; ASCII 124 = '|'
	je errorNombreEnAlta
	inc esi
	jmp verificarSinBarraNombre

errorNombreEnAlta:
	MostrarMensaje msgErrNombre
	jmp capturarNombreNuevo

capturarPrecioNuevo:
	MostrarTextoSinSalto msgPedirPrecio
	CapturarCadena bufferCaptura

	call convertirPrecioCentavos
	cmp resultadoValidacion, 1
	jne errorPrecioEnAlta

	mov eax, acumuladoNum
	mov precioUnitarioActual, eax
	jmp capturarExistenciaNueva

errorPrecioEnAlta:
	MostrarMensaje msgErrPrecio
	jmp capturarPrecioNuevo

capturarExistenciaNueva:
	MostrarTextoSinSalto msgPedirExistIni
	CapturarCadena bufferCaptura

	call convertirCadenaEntero
	cmp resultadoValidacion, 1
	jne errorExistenciaEnAlta

	mov eax, acumuladoNum
	cmp eax, maxExistencia
	jg errorExistenciaEnAlta
	mov existenciaActualNum, eax
	jmp guardarProductoEnMemoria

errorExistenciaEnAlta:
	MostrarMensaje msgErrExistIni
	jmp capturarExistenciaNueva

guardarProductoEnMemoria:
	; A) Guardar el codigo en codigosProductos usando la macro CalcularDesplazamientoESI
	CalcularDesplazamientoESI totalProductos, bytesPorCodigo
	mov ebx, 0
cicloGuardarCodigo:
	mov eax, 0
	mov al, bufferCodigo[ebx]
	mov codigosProductos[esi], al
	cmp al, 0
	je guardarNombreEnMemoria
	inc esi
	inc ebx
	jmp cicloGuardarCodigo

guardarNombreEnMemoria:
	; B) Guardar el nombre en nombresProductos usando CalcularDesplazamientoESI
	CalcularDesplazamientoESI totalProductos, bytesPorNombre
	mov ebx, 0
cicloGuardarNombre:
	mov eax, 0
	mov al, bufferNombre[ebx]
	mov nombresProductos[esi], al
	cmp al, 0
	je guardarPrecioExistenciaMemoria
	inc esi
	inc ebx
	jmp cicloGuardarNombre

guardarPrecioExistenciaMemoria:
	; C) Guardar precio y existencia en sus arreglos DWORD usando CalcularDesplazamientoESI
	CalcularDesplazamientoESI totalProductos, 4
	mov eax, precioUnitarioActual
	mov preciosProductos[esi], eax
	mov eax, existenciaActualNum
	mov existenciasProductos[esi], eax

	inc totalProductos
	mov cambiosSinGuardar, 1

	MostrarMensaje msgAltaExito

finRegistrarProducto:
	ret
registrarProducto ENDP

; =============================================================================
; PROCEDIMIENTO: mostrarUnProducto
; Descripcion: Muestra en una sola linea todos los campos del producto en
;              indiceActual apoyandose en las macros de impresion y de calculo ESI.
; Entradas:    indiceActual = posicion del producto (0 a totalProductos - 1).
; Salidas:     Imprime los datos formateados en consola.
; Registros conservados automaticamente: EAX, EBX, EDX, ESI (con USES).
; =============================================================================
mostrarUnProducto PROC USES eax ebx edx esi
	; 1. Mostrar el numero de producto (indiceActual + 1)
	MostrarTextoSinSalto lblNumProd
	mov eax, indiceActual
	inc eax
	ImprimirNumeroDecimal eax

	; 2. Acceder al codigo con CalcularDesplazamientoESI (indiceActual * 8)
	MostrarTextoSinSalto lblCodigo
	CalcularDesplazamientoESI indiceActual, bytesPorCodigo
	mov edx, OFFSET codigosProductos
	add edx, esi
	call WriteString

	; 3. Acceder al nombre con CalcularDesplazamientoESI (indiceActual * 26)
	MostrarTextoSinSalto lblNombre
	CalcularDesplazamientoESI indiceActual, bytesPorNombre
	mov edx, OFFSET nombresProductos
	add edx, esi
	call WriteString

	; 4. Acceder al precio y a la existencia con CalcularDesplazamientoESI (indiceActual * 4)
	CalcularDesplazamientoESI indiceActual, 4

	MostrarTextoSinSalto lblPrecio
	ImprimirImporte preciosProductos[esi]

	MostrarTextoSinSalto lblExistencia
	ImprimirNumeroDecimal existenciasProductos[esi]
	MostrarMensaje lblUnidades
	ret
mostrarUnProducto ENDP

; =============================================================================
; PROCEDIMIENTO: mostrarInventario
; Descripcion: Recorre desde el producto 0 hasta totalProductos - 1 llamando a
;              mostrarUnProducto para desplegar el catalogo completo.
; Entradas:    totalProductos y arreglos del catalogo.
; Salidas:     Tabla de productos en consola.
; Registros conservados automaticamente: EAX, EDX (con USES).
; =============================================================================
mostrarInventario PROC USES eax edx
	MostrarMensaje msgTituloInv

	cmp totalProductos, 0
	jne recorrerCatalogoInventario

	MostrarMensaje msgInvVacio
	jmp finMostrarInventario

recorrerCatalogoInventario:
	mov indiceActual, 0
cicloImprimirProductos:
	mov eax, indiceActual
	cmp eax, totalProductos
	je finMostrarInventario

	call mostrarUnProducto
	inc indiceActual
	jmp cicloImprimirProductos

finMostrarInventario:
	ret
mostrarInventario ENDP

; =============================================================================
; PROCEDIMIENTO: consultarPorCodigo
; Descripcion: Pide al usuario un codigo ABC-123, valida su formato, lo busca
;              en codigosProductos usando ESI y muestra sus datos si existe.
; Entradas:    Codigo capturado con CapturarCadena.
; Salidas:     Muestra el producto localizado o un mensaje si no existe.
; Registros conservados automaticamente: EAX, ECX, EDX (con USES).
; =============================================================================
consultarPorCodigo PROC USES eax ecx edx
	MostrarMensaje msgTituloBuscar

	cmp totalProductos, 0
	jne pedirCodigoConsulta
	MostrarMensaje msgInvVacio
	jmp finConsultarPorCodigo

pedirCodigoConsulta:
	MostrarTextoSinSalto msgPedirCodigo
	CapturarCadena bufferCodigo

	call validarFormatoCodigo
	cmp resultadoValidacion, 1
	je ejecutarBusquedaCodigo

	MostrarMensaje msgErrCodigo
	jmp pedirCodigoConsulta

ejecutarBusquedaCodigo:
	call buscarProductoPorCodigo
	cmp resultadoValidacion, 1
	jne productoNoHallado

	MostrarMensaje msgProductoHallado
	mov eax, indiceEncontrado
	mov indiceActual, eax
	call mostrarUnProducto
	jmp finConsultarPorCodigo

productoNoHallado:
	MostrarMensaje msgNoEncontrado

finConsultarPorCodigo:
	ret
consultarPorCodigo ENDP

; =============================================================================
; PROCEDIMIENTO: recibirMercancia
; Descripcion: Busca un producto existente por su codigo, solicita la cantidad
;              de unidades a recibir (entero > 0) y verifica que al sumarla a
;              la existencia actual NO exceda el limite maximo de 100 unidades.
; Entradas:    Codigo del producto y cantidad a recibir con CapturarCadena.
; Salidas:     Actualiza existenciasProductos[esi] y cambiosSinGuardar = 1.
; Registros conservados automaticamente: EAX, EBX, ECX, EDX, ESI (con USES).
; =============================================================================
recibirMercancia PROC USES eax ebx ecx edx esi
	MostrarMensaje msgTituloRecibir

	cmp totalProductos, 0
	jne pedirCodigoEntrada
	MostrarMensaje msgInvVacio
	jmp finRecibirMercancia

pedirCodigoEntrada:
	MostrarTextoSinSalto msgPedirCodigo
	CapturarCadena bufferCodigo

	call validarFormatoCodigo
	cmp resultadoValidacion, 1
	je buscarProductoEntrada

	MostrarMensaje msgErrCodigo
	jmp pedirCodigoEntrada

buscarProductoEntrada:
	call buscarProductoPorCodigo
	cmp resultadoValidacion, 1
	je mostrarExistenciaAntesDeEntrada

	MostrarMensaje msgNoEncontrado
	jmp finRecibirMercancia

mostrarExistenciaAntesDeEntrada:
	CalcularDesplazamientoESI indiceEncontrado, 4

	MostrarTextoSinSalto msgExistActual
	ImprimirNumeroDecimal existenciasProductos[esi]
	MostrarMensaje lblUnidades

capturarUnidadesEntrada:
	MostrarTextoSinSalto msgPedirEntrada
	CapturarCadena bufferCaptura

	call convertirCadenaEntero
	cmp resultadoValidacion, 1
	jne errorCantidadEntrada

	cmp acumuladoNum, 0
	je errorCantidadEntrada

	mov eax, existenciasProductos[esi]
	add eax, acumuladoNum
	jc errorSuperaLimite100
	cmp eax, maxExistencia
	jg errorSuperaLimite100

	mov existenciasProductos[esi], eax
	mov cambiosSinGuardar, 1

	MostrarTextoSinSalto msgEntradaExito
	ImprimirNumeroDecimal eax
	MostrarMensaje lblUnidades
	jmp finRecibirMercancia

errorCantidadEntrada:
	MostrarMensaje msgErrCantidad
	jmp capturarUnidadesEntrada

errorSuperaLimite100:
	MostrarMensaje msgErrExcede100
	jmp capturarUnidadesEntrada

finRecibirMercancia:
	ret
recibirMercancia ENDP

; =============================================================================
; PROCEDIMIENTO: realizarVenta
; Descripcion: Realiza la venta de un producto verificando existencias,
;              calculando el importe base (precio * cantidad), aplicando la
;              regla del negocio (10% de descuento en 5 o mas unidades) y
;              comprobando desbordamientos antes de descontar existencias.
; Entradas:    Codigo del producto y unidades a vender mediante CapturarCadena.
; Salidas:     Actualiza existenciasProductos[esi], ingresosSesion y cambiosSinGuardar.
; Registros conservados automaticamente: EAX, EBX, ECX, EDX, ESI (con USES).
; =============================================================================
realizarVenta PROC USES eax ebx ecx edx esi
	MostrarMensaje msgTituloVenta

	cmp totalProductos, 0
	jne pedirCodigoEnVenta
	MostrarMensaje msgInvVacio
	jmp finRealizarVenta

pedirCodigoEnVenta:
	MostrarTextoSinSalto msgPedirCodigo
	CapturarCadena bufferCodigo

	call validarFormatoCodigo
	cmp resultadoValidacion, 1
	je buscarProductoEnVenta

	MostrarMensaje msgErrCodigo
	jmp pedirCodigoEnVenta

buscarProductoEnVenta:
	call buscarProductoPorCodigo
	cmp resultadoValidacion, 1
	je verificarProductoConStock

	MostrarMensaje msgNoEncontrado
	jmp finRealizarVenta

verificarProductoConStock:
	CalcularDesplazamientoESI indiceEncontrado, 4

	mov eax, existenciasProductos[esi]
	cmp eax, 0
	jne mostrarInfoProductoVenta

	MostrarMensaje msgSinStock
	jmp finRealizarVenta

mostrarInfoProductoVenta:
	MostrarTextoSinSalto msgPrecioActual
	ImprimirImporte preciosProductos[esi]
	call Crlf

	MostrarTextoSinSalto msgExistActual
	ImprimirNumeroDecimal existenciasProductos[esi]
	MostrarMensaje lblUnidades

capturarUnidadesVenta:
	MostrarTextoSinSalto msgPedirVenta
	CapturarCadena bufferCaptura

	call convertirCadenaEntero
	cmp resultadoValidacion, 1
	jne errorCantidadEnVenta

	mov eax, acumuladoNum
	cmp eax, 0
	je errorCantidadEnVenta

	cmp eax, existenciasProductos[esi]
	jg errorExistenciasInsuficientes

	mov cantidadCapturada, eax

	; 1. Calcular el importe base de venta usando la macro multiplicarAB
	multiplicarAB preciosProductos[esi], cantidadCapturada
	jc errorOverflowEnVenta
	mov importeBaseVenta, eax

	; 2. Regla del negocio: Descuento de mayoreo (10% al comprar 5 o mas unidades)
	mov descuentoVenta, 0
	mov eax, cantidadCapturada
	cmp eax, minCantidadMayoreo
	jl calcularTotalVenta

	multiplicarAB importeBaseVenta, porcentajeDescuento
	jc errorOverflowEnVenta
	mov edx, 0
	mov ebx, 100
	div ebx								; EAX = descuento en centavos enteros (fracciones descartadas)
	mov descuentoVenta, eax

calcularTotalVenta:
	mov eax, importeBaseVenta
	sub eax, descuentoVenta
	mov importeFinalVenta, eax

	; 3. Verificar que ingresosSesion + importeFinalVenta no desborde
	mov eax, ingresosSesion
	add eax, importeFinalVenta
	jc errorOverflowEnVenta

	; 4. Actualizacion atomica de ingresos y existencias
	mov ingresosSesion, eax
	mov eax, existenciasProductos[esi]
	sub eax, cantidadCapturada
	mov existenciasProductos[esi], eax
	mov cambiosSinGuardar, 1

	; 5. Mostrar el desglose completo de la venta usando las macros
	MostrarMensaje msgResumenTicket

	MostrarTextoSinSalto msgImporteBase
	ImprimirImporte importeBaseVenta
	call Crlf

	cmp descuentoVenta, 0
	je mostrarTicketSinDescuento
	MostrarTextoSinSalto msgDescuentoApl
	ImprimirImporte descuentoVenta
	call Crlf
	jmp mostrarTicketImporteFinal

mostrarTicketSinDescuento:
	MostrarMensaje msgSinDescuento

mostrarTicketImporteFinal:
	MostrarTextoSinSalto msgImporteFinal
	ImprimirImporte importeFinalVenta
	call Crlf

	MostrarTextoSinSalto msgStockRestante
	ImprimirNumeroDecimal existenciasProductos[esi]
	MostrarMensaje lblUnidades
	jmp finRealizarVenta

errorCantidadEnVenta:
	MostrarMensaje msgErrCantidad
	jmp capturarUnidadesVenta

errorExistenciasInsuficientes:
	MostrarMensaje msgErrInsuficiente
	jmp capturarUnidadesVenta

errorOverflowEnVenta:
	MostrarMensaje msgErrOverflow

finRealizarVenta:
	ret
realizarVenta ENDP

; =============================================================================
; PROCEDIMIENTO: mostrarResumen
; Descripcion: Recorre con ESI los arreglos preciosProductos y existenciasProductos
;              sumando las unidades disponibles y el valor del inventario, y
;              muestra ademas los ingresos acumulados de la sesion en MXN.
; Entradas:    Arreglos del catalogo, totalProductos e ingresosSesion.
; Salidas:     Imprime en consola unidades disponibles, valor del inventario e ingresos.
; Registros conservados automaticamente: EAX, EBX, ECX, EDX, ESI (con USES).
; =============================================================================
mostrarResumen PROC USES eax ebx ecx edx esi
	mov unidadesTotalesResumen, 0
	mov valorTotalInventario, 0

	mov ecx, 0
	mov esi, 0

cicloRecorrerResumen:
	cmp ecx, totalProductos
	je desplegarResumenEnPantalla

	mov eax, existenciasProductos[esi]
	add unidadesTotalesResumen, eax

	multiplicarAB preciosProductos[esi], existenciasProductos[esi]
	add valorTotalInventario, eax

	add esi, 4
	inc ecx
	jmp cicloRecorrerResumen

desplegarResumenEnPantalla:
	MostrarMensaje msgTituloResumen

	MostrarTextoSinSalto msgTotalProdReg
	ImprimirNumeroDecimal totalProductos
	call Crlf

	MostrarTextoSinSalto msgTotalUnidades
	ImprimirNumeroDecimal unidadesTotalesResumen
	MostrarMensaje lblUnidades

	MostrarTextoSinSalto msgValorTotalInv
	ImprimirImporte valorTotalInventario
	call Crlf

	MostrarTextoSinSalto msgIngresosAcum
	ImprimirImporte ingresosSesion
	call Crlf
	ret
mostrarResumen ENDP

; =============================================================================
; PROCEDIMIENTO: demostrarReglaNegocio
; Descripcion: Presenta la definicion de la regla del negocio (10% de descuento
;              por mayoreo al comprar 5 o mas unidades) y muestra dos casos
;              comparativos apoyandose en las macros de impresion y multiplicacion.
; Entradas:    Ninguna.
; Salidas:     Explicacion y demostracion comparativa en consola.
; Registros conservados automaticamente: EAX, EBX, EDX, ESI (con USES).
; =============================================================================
demostrarReglaNegocio PROC USES eax ebx edx esi
	MostrarMensaje msgTituloRegla
	MostrarMensaje msgDescRegla1
	MostrarMensaje msgDescRegla2
	MostrarMensaje msgDescRegla3
	call Crlf

	mov eax, 4555						; Precio de demostracion: $45.55 MXN (4555 centavos)
	mov precioUnitarioActual, eax

	; --- CASO 1: Venta de 3 unidades (Menor a 5 unidades -> NO aplica descuento) ---
	MostrarTextoSinSalto msgDemoCasoNo
	ImprimirImporte precioUnitarioActual
	call Crlf

	multiplicarAB precioUnitarioActual, 3
	mov importeBaseVenta, eax

	MostrarTextoSinSalto msgDemoBase
	ImprimirImporte importeBaseVenta
	call Crlf

	MostrarTextoSinSalto msgDemoDesc
	ImprimirImporte 0
	call Crlf

	MostrarTextoSinSalto msgDemoFinal
	ImprimirImporte importeBaseVenta
	call Crlf
	call Crlf

	; --- CASO 2: Venta de 5 unidades (5 >= 5 unidades -> SI aplica 10% de descuento) ---
	MostrarTextoSinSalto msgDemoCasoSi
	ImprimirImporte precioUnitarioActual
	call Crlf

	multiplicarAB precioUnitarioActual, 5
	mov importeBaseVenta, eax

	multiplicarAB importeBaseVenta, porcentajeDescuento
	mov edx, 0
	mov ebx, 100
	div ebx
	mov descuentoVenta, eax

	mov eax, importeBaseVenta
	sub eax, descuentoVenta
	mov importeFinalVenta, eax

	MostrarTextoSinSalto msgDemoBase
	ImprimirImporte importeBaseVenta
	call Crlf

	MostrarTextoSinSalto msgDemoDesc
	ImprimirImporte descuentoVenta
	call Crlf

	MostrarTextoSinSalto msgDemoFinal
	ImprimirImporte importeFinalVenta
	call Crlf
	ret
demostrarReglaNegocio ENDP

; =============================================================================
; PROCEDIMIENTO: agregarCadenaABufferArchivo
; Descripcion: Copia los caracteres de una cadena terminada en 00h (apuntada
;              por EDX) hacia bufferArchivo a partir del indice posArchivo.
; Entradas:    EDX = direccion de la cadena a copiar; posArchivo = posicion actual.
; Salidas:     bufferArchivo actualizado y posArchivo incrementado.
; Registros conservados automaticamente: EAX, EBX, ESI (con USES).
; =============================================================================
agregarCadenaABufferArchivo PROC USES eax ebx esi
	mov ebx, posArchivo
	mov esi, edx
cicloCopiarCadenaArchivo:
	mov eax, 0
	mov al, [esi]
	cmp al, 0
	je finCopiarCadenaArchivo
	mov bufferArchivo[ebx], al
	inc esi
	inc ebx
	jmp cicloCopiarCadenaArchivo

finCopiarCadenaArchivo:
	mov posArchivo, ebx
	ret
agregarCadenaABufferArchivo ENDP

; =============================================================================
; PROCEDIMIENTO: guardarEnArchivo
; Descripcion: Genera en bufferArchivo una linea de texto por cada producto con
;              el formato: CODIGO|NOMBRE|PRECIO.DECIMALES|EXISTENCIA y lo guarda
;              en "Inventario.txt".
; Entradas:    Catalogo actual en memoria y nombreArchivo ("Inventario.txt").
; Salidas:     Archivo "Inventario.txt" escrito en disco y cambiosSinGuardar = 0.
; Registros conservados automaticamente: EAX, EBX, ECX, EDX, ESI (con USES).
; =============================================================================
guardarEnArchivo PROC USES eax ebx ecx edx esi
	MostrarMensaje msgTituloGuardar

	mov posArchivo, 0
	mov indiceActual, 0

cicloArmarLineasArchivo:
	mov eax, indiceActual
	cmp eax, totalProductos
	je iniciarEscrituraDisco

	; A) Copiar el CODIGO del producto (indiceActual * 8)
	multiplicarAB indiceActual, bytesPorCodigo
	mov edx, OFFSET codigosProductos
	add edx, eax
	call agregarCadenaABufferArchivo

	; Escribir el separador '|' (ASCII 124) con la macro AgregarCaracterArchivo
	AgregarCaracterArchivo 124

	; B) Copiar el NOMBRE del producto (indiceActual * 26)
	multiplicarAB indiceActual, bytesPorNombre
	mov edx, OFFSET nombresProductos
	add edx, eax
	call agregarCadenaABufferArchivo

	; Escribir el separador '|' (ASCII 124)
	AgregarCaracterArchivo 124

	; C) Convertir y copiar el PRECIO con punto y 2 decimales
	CalcularDesplazamientoESI indiceActual, 4
	mov eax, preciosProductos[esi]
	mov edx, 0
	mov ebx, 100
	div ebx								; EAX = pesos, EDX = centavos (0..99)
	mov centavosTemp, edx

	call convertirDecimal
	mov edx, OFFSET bufferDecimal
	call agregarCadenaABufferArchivo

	; Escribir el punto decimal '.' (ASCII 46)
	AgregarCaracterArchivo 46

	; Si los centavos son menores o iguales a 9, escribir primero un '0' (ASCII 48)
	mov eax, centavosTemp
	cmp eax, 9
	jg escribirCentavosEnBuffer
	AgregarCaracterArchivo 48

escribirCentavosEnBuffer:
	mov eax, centavosTemp
	call convertirDecimal
	mov edx, OFFSET bufferDecimal
	call agregarCadenaABufferArchivo

	; Escribir el separador '|' (ASCII 124)
	AgregarCaracterArchivo 124

	; D) Convertir y copiar la EXISTENCIA en unidades enteras
	mov eax, existenciasProductos[esi]
	call convertirDecimal
	mov edx, OFFSET bufferDecimal
	call agregarCadenaABufferArchivo

	; Escribir salto de linea de Windows CR+LF (bytes 13 y 10)
	AgregarCaracterArchivo 13
	AgregarCaracterArchivo 10

	inc indiceActual
	jmp cicloArmarLineasArchivo

iniciarEscrituraDisco:
	mov ebx, posArchivo
	mov bufferArchivo[ebx], 0
	mov bytesArchivo, ebx

	mov edx, OFFSET nombreArchivo
	call CreateOutputFile
	cmp eax, INVALID_HANDLE_VALUE
	je mostrarErrorGuardado

	mov archivoHandle, eax

	mov eax, archivoHandle
	mov edx, OFFSET bufferArchivo
	mov ecx, bytesArchivo
	call WriteToFile

	jc errorAlEscribirArchivo

	cmp eax, bytesArchivo
	jne errorAlEscribirArchivo

	mov eax, archivoHandle
	call CloseFile

	test eax, eax
	jz mostrarErrorGuardado

	mov cambiosSinGuardar, 0
	MostrarMensaje msgGuardarExito
	jmp finGuardarEnArchivo

errorAlEscribirArchivo:
	mov eax, archivoHandle
	call CloseFile

mostrarErrorGuardado:
	MostrarMensaje msgGuardarError

finGuardarEnArchivo:
	ret
guardarEnArchivo ENDP

; =============================================================================
; PROCEDIMIENTO: cargarDesdeArchivo
; Descripcion: Abre "Inventario.txt" con OpenInputFile, lee su contenido hacia
;              bufferArchivo con ReadFromFile, coloca el byte nulo 00h al final
;              de los bytes leidos y reconstruye el catalogo en los arreglos
;              temporales validando cada producto ANTES de reemplazar el catalogo.
; Entradas:    Archivo "Inventario.txt" en disco.
; Salidas:     Reemplaza el catalogo si todo el archivo es valido; si no existe
;              o esta danado, conserva intacto el catalogo actual en memoria.
; Registros conservados automaticamente: EAX, EBX, ECX, EDX, ESI (con USES).
; =============================================================================
cargarDesdeArchivo PROC USES eax ebx ecx edx esi
	MostrarMensaje msgTituloCargar

	mov edx, OFFSET nombreArchivo
	call OpenInputFile
	cmp eax, INVALID_HANDLE_VALUE
	je errorArchivoNoExiste

	mov archivoHandle, eax

	mov eax, archivoHandle
	mov edx, OFFSET bufferArchivo
	mov ecx, capacidadBufferArchivo
	call ReadFromFile
	jc errorLecturaDisco

	mov bytesArchivo, eax
	mov esi, eax
	mov bufferArchivo[esi], 0			; Agregamos 00h al final de los bytes leidos

	mov eax, archivoHandle
	call CloseFile
	test eax, eax
	jz errorArchivoNoExiste

	cmp bytesArchivo, 0
	je errorArchivoInvalido

	MostrarMensaje msgContenidoLeido
	MostrarMensaje bufferArchivo

	mov tempTotal, 0
	mov posArchivo, 0

cicloProcesarArchivo:
	mov esi, posArchivo
	cmp esi, bytesArchivo
	je aplicarCatalogoTemporal

	mov eax, 0
	mov al, bufferArchivo[esi]
	cmp al, 0
	je aplicarCatalogoTemporal
	cmp al, 13
	je avanzarCaracterVacio
	cmp al, 10
	je avanzarCaracterVacio
	jmp leerProductoDeLinea

avanzarCaracterVacio:
	inc posArchivo
	jmp cicloProcesarArchivo

leerProductoDeLinea:
	mov eax, tempTotal
	cmp eax, maxProductos
	je errorArchivoInvalido

	; A) Leer el campo CODIGO hasta encontrar el separador '|' (ASCII 124)
	mov esi, posArchivo
	mov ebx, 0
cicloLeerCodigoArchivo:
	mov eax, 0
	mov al, bufferArchivo[esi]
	cmp al, 0
	je errorArchivoInvalido
	cmp al, 13
	je errorArchivoInvalido
	cmp al, 10
	je errorArchivoInvalido
	cmp al, 124
	je validarCodigoDeArchivo
	cmp ebx, 10
	jg errorArchivoInvalido
	mov bufferCodigo[ebx], al
	inc ebx
	inc esi
	jmp cicloLeerCodigoArchivo

validarCodigoDeArchivo:
	mov bufferCodigo[ebx], 0
	inc esi
	mov posArchivo, esi

	mov eax, ebx
	call validarFormatoCodigo
	cmp resultadoValidacion, 1
	jne errorArchivoInvalido

	; Comprobar que el codigo no este duplicado dentro de tempCodigos
	mov ecx, 0
cicloDuplicadoEnTemp:
	cmp ecx, tempTotal
	je leerNombreDeArchivo
	CalcularDesplazamientoESI ecx, bytesPorCodigo
	mov ebx, 0
compararCodigoEnTemp:
	mov eax, 0
	mov al, tempCodigos[esi]
	mov edx, 0
	mov dl, bufferCodigo[ebx]
	cmp al, dl
	jne siguienteEnTemp
	inc esi
	inc ebx
	cmp ebx, 7
	je errorArchivoInvalido
	jmp compararCodigoEnTemp
siguienteEnTemp:
	inc ecx
	jmp cicloDuplicadoEnTemp

leerNombreDeArchivo:
	; B) Leer el campo NOMBRE hasta encontrar el separador '|' (ASCII 124)
	mov esi, posArchivo
	mov ebx, 0
cicloLeerNombreArchivo:
	mov eax, 0
	mov al, bufferArchivo[esi]
	cmp al, 0
	je errorArchivoInvalido
	cmp al, 13
	je errorArchivoInvalido
	cmp al, 10
	je errorArchivoInvalido
	cmp al, 124
	je validarNombreDeArchivo
	cmp ebx, 25
	je errorArchivoInvalido
	mov bufferNombre[ebx], al
	inc ebx
	inc esi
	jmp cicloLeerNombreArchivo

validarNombreDeArchivo:
	mov bufferNombre[ebx], 0
	inc esi
	mov posArchivo, esi
	cmp ebx, 0
	je errorArchivoInvalido

	; C) Leer el campo PRECIO hasta encontrar el separador '|' (ASCII 124)
	mov esi, posArchivo
	mov ebx, 0
cicloLeerPrecioArchivo:
	mov eax, 0
	mov al, bufferArchivo[esi]
	cmp al, 0
	je errorArchivoInvalido
	cmp al, 13
	je errorArchivoInvalido
	cmp al, 10
	je errorArchivoInvalido
	cmp al, 124
	je validarPrecioDeArchivo
	cmp ebx, 15
	je errorArchivoInvalido
	mov bufferCaptura[ebx], al
	inc ebx
	inc esi
	jmp cicloLeerPrecioArchivo

validarPrecioDeArchivo:
	mov bufferCaptura[ebx], 0
	inc esi
	mov posArchivo, esi

	mov eax, ebx
	call convertirPrecioCentavos
	cmp resultadoValidacion, 1
	jne errorArchivoInvalido
	mov eax, acumuladoNum
	mov precioUnitarioActual, eax

	; D) Leer el campo EXISTENCIA hasta encontrar fin de linea (CR=13, LF=10) o fin de archivo (0)
	mov esi, posArchivo
	mov ebx, 0
cicloLeerExistenciaArchivo:
	mov eax, 0
	mov al, bufferArchivo[esi]
	cmp al, 0
	je validarExistenciaDeArchivo
	cmp al, 13
	je validarExistenciaDeArchivo
	cmp al, 10
	je validarExistenciaDeArchivo
	cmp ebx, 10
	je errorArchivoInvalido
	mov bufferCaptura[ebx], al
	inc ebx
	inc esi
	jmp cicloLeerExistenciaArchivo

validarExistenciaDeArchivo:
	mov bufferCaptura[ebx], 0
	mov posArchivo, esi

	mov eax, ebx
	call convertirCadenaEntero
	cmp resultadoValidacion, 1
	jne errorArchivoInvalido
	mov eax, acumuladoNum
	cmp eax, maxExistencia
	jg errorArchivoInvalido
	mov existenciaActualNum, eax

	; E) Guardar el producto validado en los arreglos temporales usando CalcularDesplazamientoESI
	CalcularDesplazamientoESI tempTotal, bytesPorCodigo
	mov ebx, 0
guardarCodigoTemp:
	mov eax, 0
	mov al, bufferCodigo[ebx]
	mov tempCodigos[esi], al
	cmp al, 0
	je prepararNombreTemp
	inc esi
	inc ebx
	jmp guardarCodigoTemp

prepararNombreTemp:
	CalcularDesplazamientoESI tempTotal, bytesPorNombre
	mov ebx, 0
guardarNombreTemp:
	mov eax, 0
	mov al, bufferNombre[ebx]
	mov tempNombres[esi], al
	cmp al, 0
	je guardarNumerosTemp
	inc esi
	inc ebx
	jmp guardarNombreTemp

guardarNumerosTemp:
	CalcularDesplazamientoESI tempTotal, 4
	mov eax, precioUnitarioActual
	mov tempPrecios[esi], eax
	mov eax, existenciaActualNum
	mov tempExistencias[esi], eax

	inc tempTotal
	jmp cicloProcesarArchivo

aplicarCatalogoTemporal:
	cmp tempTotal, 0
	je errorArchivoInvalido

	mov esi, 0
copiarCodigosDefinitivos:
	cmp esi, 80
	je iniciarCopiaNombresDef
	mov eax, 0
	mov al, tempCodigos[esi]
	mov codigosProductos[esi], al
	inc esi
	jmp copiarCodigosDefinitivos

iniciarCopiaNombresDef:
	mov esi, 0
copiarNombresDefinitivos:
	cmp esi, 260
	je iniciarCopiaDwordsDef
	mov eax, 0
	mov al, tempNombres[esi]
	mov nombresProductos[esi], al
	inc esi
	jmp copiarNombresDefinitivos

iniciarCopiaDwordsDef:
	mov ecx, 0
	mov esi, 0
copiarDwordsDefinitivos:
	cmp ecx, maxProductos
	je terminarCargaExitosa
	mov eax, tempPrecios[esi]
	mov preciosProductos[esi], eax
	mov eax, tempExistencias[esi]
	mov existenciasProductos[esi], eax
	add esi, 4
	inc ecx
	jmp copiarDwordsDefinitivos

terminarCargaExitosa:
	mov eax, tempTotal
	mov totalProductos, eax
	mov cambiosSinGuardar, 0

	MostrarMensaje msgCargarExito
	jmp finCargarDesdeArchivo

errorLecturaDisco:
	mov eax, archivoHandle
	call CloseFile

errorArchivoNoExiste:
	MostrarMensaje msgCargarError
	jmp finCargarDesdeArchivo

errorArchivoInvalido:
	MostrarMensaje msgArchivoDanado

finCargarDesdeArchivo:
	ret
cargarDesdeArchivo ENDP

END main
