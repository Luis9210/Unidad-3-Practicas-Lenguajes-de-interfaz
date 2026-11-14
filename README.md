# Prácticas de Lenguajes de Interfaz — Unidad 3

Repositorio con los proyectos prácticos de la **Unidad 3** enfocados en la arquitectura x86, modularización, llamadas a procedimientos, gestión de la pila (*stack*) y definición de macros con ensamblador MASM y la biblioteca **Irvine32**.

---

## 📌 Datos Generales

* **Materia:** Lenguajes de Interfaz  
* **Alumno:** Luis Fernando Velázquez Araujo  
* **Docente:** Dr. José Luis Medina Jiménez  
* **Horario:** 9:00 - 10:00 am  
* **Entorno:** Visual Studio (MASM x86 / 32 bits) + Biblioteca Irvine32  

---

## 📂 Contenido y Comprobación de las Prácticas

### 1. Práctica 01 — Procedimientos Básicos (`01 - Practica Procedimiento`)
* **¿Qué hace el programa?:**  
  Declara un procedimiento independiente (`procedimiento`) y realiza tres llamadas sucesivas (`call`) desde el bloque `main`. En cada invocación muestra un mensaje en pantalla y el valor actual del registro acumulador `EAX`, el cual se va alterando en el hilo principal (`10`, `20`, etc.).
* **¿Qué se comprobó al ejecutarlo?:**  
  * El salto y retorno limpio del flujo de ejecución (`call` y `ret`).
  * Que el procedimiento reutiliza la misma subrutina en distintos instantes sin perder el control del programa, reflejando correctamente en pantalla el contenido actualizado de `EAX` entre llamadas.

---

### 2. Práctica 02 — Procedimientos Anidados (`02 - Procedimientos anidados`)
* **¿Qué hace el programa?:**  
  Ejemplifica la anidación de subrutinas: el procedimiento `main` invoca a `p1`, y a su vez `p1` invoca a `p2`. Para evidenciar el comportamiento interno, el programa lee e imprime en hexadecimal el tope de la pila (`[esp]`) en cada etapa.
* **¿Qué se comprobó al ejecutarlo?:**  
  * La estructura LIFO (*Last In, First Out*) de la pila durante llamadas anidadas.
  * Al ingresar a cada nivel, `[esp]` almacena la dirección de retorno hacia la subrutina previa. Al ejecutar cada `ret`, se desapilan ordenadamente en reversa (`p2` -> `p1` -> `main`), garantizando la continuidad de la ejecución sin desbordamientos.

---

### 3. Práctica 03 — Validación de Cadena (`03 - Validación de cadena`)
* **¿Qué hace el programa?:**  
  Solicita al usuario una cadena de texto por teclado con `ReadString`. Posteriormente, invoca al procedimiento `validarVacio`, el cual analiza la longitud leída en `EAX` y devuelve un código de estado en `EBX` (`0` para cadena vacía y `1` para cadena con contenido). Si la entrada está vacía, advierte al usuario y solicita la entrada nuevamente en un bucle; si es válida, despliega un mensaje de éxito y finaliza.
* **¿Qué se comprobó al ejecutarlo?:**  
  * El retorno de banderas/estados a través de registros generales (`EBX`).
  * El control de flujo condicional (`cmp`, `je`, `jmp`) para validación de datos en tiempo de ejecución, respondiendo de forma interactiva tanto ante cadenas válidas como al pulsar *Enter* sin escribir texto.

---

### 4. Práctica 04 — Manejo de Pila Manual (`04 - Manejo de pila manual`)
* **¿Qué hace el programa?:**  
  Construye un marco de pila manual (*stack frame*). El procedimiento principal pasa dos operandos numéricos (`3` y `25`) a través de `push` antes de invocar a `SumarPila`. Dentro del procedimiento:
  1. Se preserva y establece la referencia de base con `EBP` (`push ebp`, `mov ebp, esp`).
  2. Se resguardan registros adicionales (`push ebx`).
  3. Se accede a los parámetros mediante direccionamiento indexado relativo a `EBP` (`[ebp+8]` y `[ebp+12]`).
  4. Realiza la multiplicación (`imul eax, ebx`) y restaura los registros.
  5. Retorna y desaloja los parámetros mediante `ret 8` (convención tipo *stdcall*).
* **¿Qué se comprobó al ejecutarlo?:**  
  * Mediante volcados con `DumpRegs`, se verificó la preservación íntegra de registros previos (`EBX = 999`).
  * Se confirmó la obtención exacta de los valores apilados y el cálculo correcto del producto ($3 \times 25 = 75$, representado como `4B` hexadecimal en `EAX`).
  * Se comprobó que `ret 8` equilibra la pila correctamente, dejando el puntero `ESP` exactamente en el estado en que se encontraba antes de apilar los argumentos.

---

### 5. Práctica 05 — Macros (`05 - MACROS`)
* **¿Qué hace el programa?:**  
  Demuestra la creación y expansión de macros en tiempo de ensamblado:
  * `MostrarMensaje`: recibe un identificador de texto y expande la carga del desplazamiento (`OFFSET`) y la llamada a `WriteString`.
  * `multiplicarAB`: recibe dos constantes o factores, genera las instrucciones de multiplicación y almacena el producto en `EAX`.
  En el cuerpo principal se despliegan mensajes del sistema y se calcula el producto $7 \times 8 = 56$ impreso con `WriteDec`.
* **¿Qué se comprobó al ejecutarlo?:**  
  * Que las macros se sustituyen en línea (*inline expansion*) sin costo de salto (`call`/`ret`), reduciendo la sobrecarga de tiempo de ejecución para operaciones directas.
  * Se validó en consola la impresión correcta de los mensajes y el resultado numérico exacto (`56`).

---

## 🛠️ Requisitos de Compilación

1. **IDE:** Visual Studio con la carga de trabajo de *Desarrollo para el escritorio con C++*.
2. **Dependencia:** Biblioteca `Irvine32` vinculada en las propiedades del proyecto (`Include` y `Library Directories`).
3. **Herramienta:** Ensamblador MASM habilitado en las dependencias de compilación (*Build Customizations -> masm*).
