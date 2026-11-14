# Sistema de Ventas e Inventario en Ensamblador — Proyecto Unidad 3 (Macros y `PROC USES`)

- **Materia:** Lenguajes de Interfaz — Unidad 3
- **Autor:** Luis Fernando Velázquez Araujo
- **Horario:** 9:00 / 10:00 am
- **Docente:** Dr. José Luis Medina Jiménez

---

## 1. Contenido del Paquete (`.zip`)

Al descomprimir la carpeta del proyecto (`Proyecto Unidad 3`) se encuentran los siguientes archivos de entrega:

- `main.asm`: Código fuente completo del sistema en ensamblador MASM x86 de 32 bits con **8 macros** y **18 procedimientos modulares** que utilizan preservación automática de registros mediante la directiva `PROC USES`.
- `Inventario.txt`: Archivo de catálogo de prueba con tres productos precargados para verificar la lectura y reconstrucción del inventario desde disco.
- Archivos de solución y proyecto de Visual Studio (`Proyecto Unidad 3.slnx`, `Proyecto Unidad 3.vcxproj`, `Proyecto Unidad 3.vcxproj.filters`, `Proyecto Unidad 3.vcxproj.user`).
- `README.md`: Este documento con las instrucciones de compilación, el informe técnico de modularización (Macros y `PROC USES`), organización en memoria y tabla de pruebas.

---

## 2. Instrucciones de Compilación y Ejecución en Visual Studio

### Requisitos previos
- **Visual Studio** (2019, 2022 o 2026) con la carga de trabajo **Desarrollo para el escritorio con C++** (incluye MASM `ml.exe`).
- Biblioteca **Irvine32** (`Irvine32.inc`, `SmallWin.inc`, `VirtualKeys.inc` e `Irvine32.lib`).

### Pasos para compilar y ejecutar
1. Extraiga el contenido completo del archivo `.zip` en una carpeta local.
2. Abra el archivo de solución (`Proyecto Unidad 3.slnx`) o proyecto (`Proyecto Unidad 3.vcxproj`) en **Visual Studio**.
3. En la barra de herramientas superior, seleccione la configuración **`Debug`** y la plataforma **`x86`** (`Win32`).
4. Si la biblioteca `Irvine32` se encuentra en una ruta distinta en el equipo donde se evalúa el proyecto, actualice la ruta en **Proyecto -> Propiedades** (con `Configuración: Debug` y `Plataforma: Win32`):
   - **Microsoft Macro Assembler -> General -> Include Paths:** agregue la carpeta donde reside `Irvine32.inc`.
   - **Vinculador (Linker) -> General -> Directorios de bibliotecas adicionales:** agregue la carpeta donde reside `Irvine32.lib`.
   - **Vinculador (Linker) -> Entrada -> Dependencias adicionales:** verifique que incluya `Irvine32.lib;%(AdditionalDependencies)`.
   - **Vinculador (Linker) -> Sistema -> Subsistema:** `Consola (/SUBSYSTEM:CONSOLE)`.
5. Verifique que el archivo `Inventario.txt` se encuentre en el directorio de trabajo del proyecto (junto al archivo `.vcxproj`).
6. Presione **`Ctrl + F5`** para compilar y ejecutar sin depurador, o **`F5`** para iniciar con el depurador.

---

## 3. Actualización de Arquitectura para la Unidad 3 (Macros y `PROC USES`)

### 3.1. Definición y Expansión de Macros (`MACRO` / `ENDM`)
Siguiendo los temas de la Unidad 3, las operaciones repetitivas de entrada/salida, formateo numérico, direccionamiento con `ESI` y construcción del buffer de archivo se encapsularon en **8 macros** definidas antes de la sección `.data`. Durante el ensamblado, MASM expande estas macros en línea (*inline expansion*), reduciendo la duplicación de código sin el costo de salto de una llamada `CALL`/`RET`:

| Macro | Parámetros | Instrucciones que Expande y Propósito |
| :--- | :--- | :--- |
| `MostrarMensaje` | `texto` | Carga `mov edx, OFFSET texto`, invoca `call WriteString` y ejecuta `call Crlf`. |
| `MostrarTextoSinSalto` | `texto` | Carga `mov edx, OFFSET texto` e invoca `call WriteString` sin salto de línea (para prompts y etiquetas en línea). |
| `CapturarCadena` | `buffer` | Limpia el primer byte (`mov buffer, 0`), asigna `OFFSET buffer` en `EDX` y `SIZEOF buffer` en `ECX`, y llama a `ReadString`. |
| `ImprimirNumeroDecimal`| `valor` | Carga `mov eax, valor`, llama a `convertirDecimal` e imprime `bufferDecimal` con `WriteString`. |
| `ImprimirImporte` | `valorCentavos` | Carga `mov eax, valorCentavos` y llama a `mostrarImporteMXN` para imprimir con formato `$XXXX.XX MXN`. |
| `multiplicarAB` | `num1, num2` | Carga `mov eax, num1`, `mov ebx, num2` y ejecuta `mul ebx`, dejando el producto de 32 bits en `EAX`. |
| `CalcularDesplazamientoESI` | `indice, tamanoElemento` | Multiplica `indice * tamanoElemento` y transfiere el resultado a `mov esi, eax` para indexar arreglos del catálogo. |
| `AgregarCaracterArchivo`| `caracterAscii` | Coloca el byte `caracterAscii` (`'|'`, `'.'`, `'0'`, `CR`, `LF`) en `bufferArchivo[posArchivo]` e incrementa `posArchivo`. |

### 3.2. Preservación Automática de Registros con `PROC USES`
En lugar de escribir manualmente las instrucciones `push` al principio y `pop` al final de cada procedimiento, todos los procedimientos auxiliares utilizan la directiva **`PROC USES`** de MASM:

```asm
cargarDesdeArchivo PROC USES eax ebx ecx edx esi
    ; Cuerpo del procedimiento
    ret
cargarDesdeArchivo ENDP
```

- **Funcionamiento interno:** Al ensamblar un procedimiento con `USES eax ebx ecx edx esi`, MASM genera de forma automática las instrucciones `push eax`, `push ebx`, `push ecx`, `push edx`, `push esi` al inicio del procedimiento, e inserta la secuencia inversa exacta (`pop esi`, `pop edx`, `pop ecx`, `pop ebx`, `pop eax`) inmediatamente antes de `ret`. Esto garantiza que la pila (`ESP`) quede siempre equilibrada sin riesgo de olvidar un `pop` o invertir el orden LIFO.
- **Detalle sintáctico en MASM:** Los nombres de los registros después de `USES` se separan con **espacios (sin comas)**, ya que en MASM el carácter coma `,` después de la lista de `USES` indica el inicio de la declaración de parámetros en la pila.

---

## 4. Informe del Proyecto

### 4.1. Giro del Negocio Elegido
Sistema de ventas y control de inventario para una **Tienda y Almacén de Electrónica y Microcontroladores** (tarjetas de desarrollo ESP32, placas Arduino Uno R3, sensores ultrasónicos y módulos electrónicos).

El sistema administra hasta **10 productos** con las siguientes reglas de validación:
- **Código único (`ABC-123`):** Exactamente 7 caracteres integrados por 3 letras mayúsculas (`A`–`Z`, ASCII 65–90), un guion (`-`, ASCII 45) y 3 dígitos decimales (`0`–`9`, ASCII 48–57). Se rechazan códigos con formato inválido o duplicados.
- **Nombre del producto:** De 1 a 25 caracteres (se rechazan cadenas vacías, mayores a 25 caracteres o que contengan el separador `|`).
- **Precio unitario:** De `$0.01` a `$9999.99 MXN`. Permite capturar pesos enteros o una cantidad con punto decimal seguido de 1 o 2 decimales, rechazando signos, símbolos monetarios (`$`), separadores de miles (`,`) o un tercer decimal. Internamente todos los precios e importes se almacenan y operan como **centavos enteros** (`1` a `999999`) y se despliegan con dos decimales y la etiqueta `MXN`.
- **Existencia:** De `0` a `100` unidades enteras en el registro inicial; en entradas de mercancía y ventas solo se aceptan cantidades enteras mayores que cero (`>= 1`), verificando que las existencias nunca superen `100` unidades ni bajen de `0`.

### 4.2. Regla Adicional del Negocio: Descuento por Cantidad (Mayoreo)
- **Definición y condición de aplicación:** En cualquier venta donde la cantidad solicitada de un producto sea de **5 o más unidades** (`minCantidadMayoreo = 5`), se aplica automáticamente un **10% de descuento** (`porcentajeDescuento = 10`) sobre el importe base (`precio * cantidad`). En compras de 1 a 4 unidades no se aplica descuento (`$0.00 MXN`).
- **Cálculo y descarte de fracciones de centavo:**
  1. Se calcula el importe base en centavos enteros mediante la macro `multiplicarAB preciosProductos[esi], cantidadCapturada`.
  2. Para calcular el 10% se multiplica `importeBaseVenta * 10` y el resultado se divide entre `100` utilizando la instrucción de división entera sin signo `DIV`.
  3. `DIV` coloca el cociente entero en `EAX` y el residuo en `EDX`. Al tomar únicamente `EAX` como `descuentoVenta`, las fracciones de centavo (el residuo en `EDX`) quedan descartadas de manera exacta.
  - **Demostración incluida en el sistema (Opción 9 del menú y Opción 5 de ventas):**
    - *Caso sin descuento (< 5 unidades):* 3 unidades de `$45.55 MXN` (`4555` centavos) -> Importe base: `$136.65 MXN`, Descuento: `$0.00 MXN`, Importe final: `$136.65 MXN`.
    - *Caso con descuento (>= 5 unidades):* 5 unidades de `$45.55 MXN` (`4555` centavos) -> Importe base: `$227.75 MXN` (`22775` centavos). El 10% exacto equivale a `2277.5` centavos (`$22.775`); al dividir entre `100` con `DIV`, se obtiene un cociente `EAX = 2277` centavos (`$22.77 MXN`) y se descarta el medio centavo (`EDX = 50`), resultando en un importe final de `$204.98 MXN`.

### 4.3. Organización de Datos en Memoria
El catálogo se almacena en la sección `.data` mediante **cuatro arreglos paralelos contiguos** con capacidad para `10` productos (`indice` de `0` a `9`), direccionados mediante el registro **`ESI`** y la macro `CalcularDesplazamientoESI`:

| Arreglo | Definición en `.data` | Tamaño por Producto | Desplazamiento con `ESI` (`i = 0..9`) | Acceso en Código |
| :--- | :--- | :--- | :--- | :--- |
| `codigosProductos` | `BYTE 80 DUP(0)` | `8` bytes (`7` chars + `00h`) | `ESI = i * 8` | `codigosProductos[esi]` |
| `nombresProductos` | `BYTE 260 DUP(0)` | `26` bytes (`25` chars + `00h`) | `ESI = i * 26` | `nombresProductos[esi]` |
| `preciosProductos` | `DWORD 10 DUP(0)` | `4` bytes (centavos enteros) | `ESI = i * 4` | `preciosProductos[esi]` |
| `existenciasProductos` | `DWORD 10 DUP(0)` | `4` bytes (unidades `0..100`) | `ESI = i * 4` | `existenciasProductos[esi]` |

### 4.4. Formato del Archivo (`Inventario.txt`) y Validación de Carga
- **Estructura del archivo:** Archivo de texto plano donde cada línea representa un producto con sus cuatro atributos separados por el carácter `|` (ASCII `124`) y terminados con salto de línea `CRLF` (`13, 10`):
  ```text
  ESP-001|Tarjeta ESP32 WiFi|185.50|25
  ARD-002|Arduino Uno R3|245.05|15
  SEN-003|Sensor Ultrasonico HC04|45.55|50
  ```
- **Manejo de memoria y validación previa a la sustitución del catálogo:**
  - El buffer de recepción se define como `bufferArchivo BYTE 1025 DUP(0)` para una capacidad máxima de lectura de `1024` bytes (`capacidadBufferArchivo = 1024`), reservando `1` byte adicional para insertar el terminador nulo `00h` en `bufferArchivo[esi]` (donde `esi` recibe de `EAX` el número de bytes realmente leídos por `ReadFromFile`).
  - Durante la carga (`cargarDesdeArchivo`), los datos extraídos se validan y depositan primero en arreglos temporales (`tempCodigos`, `tempNombres`, `tempPrecios`, `tempExistencias`). Si el archivo no existe, está vacío o contiene cualquier registro dañado o fuera de rango, la carga se rechaza y **el catálogo activo en memoria permanece intacto**.

---

## 5. Documentación de Procedimientos (`main.asm`)

| Procedimiento | Declaración con `PROC USES` | Entradas | Salidas |
| :--- | :--- | :--- | :--- |
| `main` | `main PROC` | Selección del menú por consola | Control de flujo principal y aviso de salida |
| `validarVacio` | `PROC USES eax` | `EAX` = longitud devuelta por `ReadString` | `EBX = 1` (no vacía) o `EBX = 0` (vacía) |
| `convertirDecimal` | `PROC USES eax ebx ecx edx esi` | `EAX` = entero sin signo | `bufferDecimal` con cadena ASCII terminada en `00h` |
| `mostrarImporteMXN` | `PROC USES eax ebx edx` | `EAX` = importe en centavos enteros | Despliega `$XXXX.XX MXN` en pantalla |
| `validarFormatoCodigo` | `PROC USES eax esi` | `bufferCodigo`, `EAX` = longitud | `resultadoValidacion` (`1` = válido, `0` = error) |
| `buscarProductoPorCodigo` | `PROC USES eax ebx ecx edx esi` | `bufferCodigo`, `totalProductos` | `resultadoValidacion` (`1` o `0`), `indiceEncontrado` |
| `convertirCadenaEntero` | `PROC USES eax ebx edx esi` | `bufferCaptura`, `EAX` = longitud | `resultadoValidacion` (`1` o `0`), `acumuladoNum` |
| `convertirPrecioCentavos`| `PROC USES eax ebx edx esi` | `bufferCaptura`, `EAX` = longitud | `resultadoValidacion` (`1` o `0`), `acumuladoNum` (centavos) |
| `registrarProducto` | `PROC USES eax ebx ecx edx esi` | Datos capturados con `CapturarCadena` | Alta en arreglos del catálogo, `cambiosSinGuardar = 1` |
| `mostrarUnProducto` | `PROC USES eax ebx edx esi` | `indiceActual` (`0..9`) | Imprime en consola los datos del producto |
| `mostrarInventario` | `PROC USES eax edx` | Arreglos del catálogo, `totalProductos` | Lista todos los productos registrados |
| `consultarPorCodigo` | `PROC USES eax ecx edx` | Código capturado con `CapturarCadena` | Muestra el producto localizado o mensaje de error |
| `recibirMercancia` | `PROC USES eax ebx ecx edx esi` | Código y cantidad con `CapturarCadena` | Incrementa existencia (`<= 100`), `cambiosSinGuardar = 1` |
| `realizarVenta` | `PROC USES eax ebx ecx edx esi` | Código y cantidad con `CapturarCadena` | Descuenta existencias, suma a `ingresosSesion`, imprime desglose |
| `mostrarResumen` | `PROC USES eax ebx ecx edx esi` | Catálogo en memoria e `ingresosSesion` | Muestra unidades disponibles, valor del inventario e ingresos |
| `demostrarReglaNegocio` | `PROC USES eax ebx edx esi` | Precio base de demostración (`$45.55 MXN`) | Compara en pantalla caso sin descuento vs caso con descuento |
| `agregarCadenaABufferArchivo`| `PROC USES eax ebx esi` | `EDX` = dirección de cadena, `posArchivo` | Copia caracteres a `bufferArchivo` y actualiza `posArchivo` |
| `guardarEnArchivo` | `PROC USES eax ebx ecx edx esi` | Catálogo actual en memoria | Escribe `Inventario.txt` y asigna `cambiosSinGuardar = 0` |
| `cargarDesdeArchivo` | `PROC USES eax ebx ecx edx esi` | Archivo `Inventario.txt` | Valida datos en arreglos temporales y actualiza el catálogo |

---

## 6. Tabla de Pruebas

| # | Escenario de Prueba | Entrada | Resultado Esperado | Resultado Obtenido |
| :-: | :--- | :--- | :--- | :--- |
| 1 | **Carga con archivo ausente** | Opción `8` (sin `Inventario.txt` en la carpeta) | Indicar error al abrir el archivo y conservar el catálogo actual. | `ERROR: El archivo Inventario.txt no existe o no se pudo abrir. Se conserva el catalogo actual.` |
| 2 | **Alta con código inválido** | Opción `1` -> Código: `esp-001` | Rechazar por usar minúsculas y solicitar nuevamente el código. | `ERROR: Codigo incorrecto. Debe tener exactamente 3 letras MAYUSCULAS, un guion '-' y 3 digitos (ej. ESP-001).` |
| 3 | **Alta con nombre vacío** | Código: `ESP-001` -> Nombre: *(vacío)* | Rechazar cadena vacía conservando el código ya validado. | `ERROR: Nombre invalido. Debe tener entre 1 y 25 caracteres y no estar vacio.` |
| 4 | **Alta con 3er decimal en precio** | Nombre: `Tarjeta ESP32 WiFi` -> Precio: `185.505` | Rechazar precio con 3 decimales y solicitar precio de nuevo. | `ERROR: Precio invalido. Use solo digitos y opcionalmente un punto con 1 o 2 decimales (rango 0.01 a 9999.99).` |
| 5 | **Alta válida** | Precio: `185.50` -> Existencia: `25` | Guardar `18550` centavos y `25` unidades en posición `0`. | `EXITO: Producto registrado correctamente en el catalogo.` |
| 6 | **Alta con código duplicado** | Opción `1` -> Código: `ESP-001` | Detectar código existente y rechazar el registro duplicado. | `ERROR: El codigo ingresado ya existe en el catalogo. Rechazando duplicado.` |
| 7 | **Búsqueda por código** | Opción `3` -> Código: `ARD-002` | Localizar el producto con `ESI` y mostrar importe con `05` centavos. | `# Producto: 2 \| Codigo: ARD-002 \| Nombre: Arduino Uno R3 \| Precio: $245.05 MXN \| Existencia: 15 unidades` |
| 8 | **Entrada excesiva (> 100 uds)** | Opción `4` -> `ESP-001` (25 uds) -> Cantidad: `80` | Rechazar por exceder 100 unidades (`25 + 80 = 105`), conservando `25`. | `ERROR: Operacion rechazada. La suma supera el limite maximo de 100 unidades por producto.` |
| 9 | **Entrada de mercancía válida** | `ESP-001` (25 uds) -> Cantidad: `10` | Incrementar existencia a `35` unidades. | `EXITO: Mercancia recibida. Nueva existencia actualizada: 35 unidades` |
| 10 | **Venta sin stock suficiente** | Opción `5` -> `ESP-001` (35 uds) -> Cantidad: `40` | Rechazar la venta sin modificar existencias (`35`) ni ingresos. | `ERROR: Venta rechazada. No hay existencias suficientes para cubrir esa cantidad.` |
| 11 | **Venta aceptada con descuento** | `ESP-001` (`$185.50`) -> Cantidad: `5` | Base `$927.50 MXN`, Desc. 10% `-$92.75 MXN`, Final `$834.75 MXN`, Stock `30`. | `Importe base: $927.50 MXN` / `Descuento: -$92.75 MXN` / `Importe final a pagar: $834.75 MXN` / `Existencia restante: 30 unidades` |
| 12 | **Venta aceptada sin descuento** | `SEN-003` (`$45.55`) -> Cantidad: `2` | Base `$91.10 MXN`, Desc. `$0.00 MXN`, Final `$91.10 MXN`, Stock `48`. | `Importe base: $91.10 MXN` / `Descuento: $0.00 MXN` / `Importe final a pagar: $91.10 MXN` / `Existencia restante: 48 unidades` |
| 13 | **Resumen del sistema** | Opción `6` | Mostrar `93` unidades disponibles, valor `$11427.15 MXN` e ingresos `$925.85 MXN`. | `Total de unidades: 93 unidades` / `Valor total del inventario: $11427.15 MXN` / `Ingresos acumulados: $925.85 MXN` |
| 14 | **Aviso al salir sin guardar** | Opción `0` (con cambios pendientes) -> `2` (No) | Mostrar advertencia de cambios sin guardar y volver al menú. | `ADVERTENCIA: Hay cambios en el inventario sin guardar en el archivo.` |
| 15 | **Guardado y carga en nueva ejecución** | Opción `7` (Guardar), reiniciar programa y elegir Opción `8` (Cargar) | Conservar el catálogo en `Inventario.txt` y reconstruirlo al iniciar otra sesión. | `EXITO: Archivo validado y catalogo reconstruido en memoria correctamente.` |
