---
sketch: 069
name: estantes-ubicar
question: "Reinicio de la UI de estantes (01.8.2): Estantes como el lugar donde se levanta y se devuelve un juego — buscar hasta UN juego, verlo levantado entre sus vecinos, y ubicarlo eligiendo el hueco."
winner: "las 68 decisiones del desarrollador, sin variantes en la página"
tags: [admin, estantes, search, autocomplete, locate, rail, covers, status-dot, sheet, dialog, move, placement, animation, restart, phase-01.8.2]
rounds: 6 + la página de administración
status: DECIDIDO 2026-09-22 — sin variantes en la página, 68 decisiones en notes/estante-ui-restart.md. NO confirmado en dispositivo; tres ítems abiertos al pie
---

# Sketch 069: Estantes — ubicar un juego

## La pregunta

El desarrollador reinició la UI de estantes después de la 068 (*"Let's start over all of this UI. Ask the
question and I'll let you know. Be sure to focus only on that UI."*). **Cada elección de esta página la tomó
él, de a una pregunta por vez**, y están numeradas 1–68 en `.planning/notes/estante-ui-restart.md`. Este
sketch las dibuja: **no hay variantes en la página**, porque cada ronda terminó con las perdedoras borradas.

Reemplaza todo lo que 065 R8 y 066 dibujaron para estantes (UNA página Estantes, master/detail, barra de
zonas, modo Agregar juegos, Ordenar por estante). Lo que sí sobrevive de R8: la búsqueda contesta *dónde
está*, el orden de los juegos ES el orden del estante, los vecinos están a un toque, y Asignar queda
borrada.

## Cómo verla

```
python3 -m http.server 8765          # desde la raíz del repo
open http://127.0.0.1:8765/.planning/sketches/069-estantes-ubicar/index.html
```

Página suelta: sólo la UI de estantes. El header y la barra de pestañas son contexto y no hacen nada.
Datos: los 434 juegos reales con sus tapas (`games.js`), 428 repartidos en 9 estantes de 46–50 cajas y 6
sin lugar.

**Herramientas** (arriba a la derecha): Tema `Claro/Oscuro` · Teclado simulado `Sí/No` (292px) · Juegos sin
lugar `6/434` (el caso post-migración) · Afuera (Fase 4) `3/0` · Estante 10 vacío `Sí/No` (prueba el caso
directo de la decisión 35).

---

## Lo que quedó decidido

Los números entre paréntesis son las decisiones de `estante-ui-restart.md`.

### La página Estantes

- **Header:** título "Estantes", un **ícono de bandeja con contador** que lleva a Pendientes (59 · D-19g) y
  el **engranaje** que lleva a Administrar estantes (26).
- **En reposo, sólo la pregunta y el campo** (54, 58): *"¿Qué juego buscás?"*, con el campo debajo. Nada
  más. El ícono grande de arriba se sacó (54) y las tres listas se fueron de la página (58) — **la búsqueda
  es el componente más importante después del título, y nada debajo puede pesar más ni moverla** (54).
- **Enfocar el campo vacío abre Últimas búsquedas en el desplegable** (58): 3 filas con tapa, nombre y el
  estante — o **● Sin lugar** (22: el estado es un punto + texto, nunca una pastilla). Escribir las
  reemplaza por las sugerencias; borrar las trae de vuelta.
- **La búsqueda es un autocompletado que resuelve a UN juego** (1, 2): hasta 6 sugerencias que caen **sobre**
  la página (12). Teclado: ↑ ↓ Enter Esc. Etiqueta y placeholder **"Buscá un juego"** (65).
- **Sin resultados → "Crear «texto»"** (62): fila de 56px, "Agregarlo al catálogo".

### Cuando encuentra el juego

- **El campo conserva el nombre, con ✕ para volver al reposo** (60 — *revierte la decisión 11*). Tocar el
  campo selecciona el nombre, así escribir la siguiente caja lo reemplaza. Los nombres largos terminan en "…".
- **El estante es contexto, no título** (63): ícono de estante de 18px + "Estante 3" en 14/600 apagado,
  16px arriba de la tapa levantada. El mismo tratamiento que en la cabecera de la hoja (33).
- **El estante entero como una fila deslizable de tapas** (6), centrada en el juego, que está **levantado**
  (23) entre sus vecinos (3, 4). Ritmo: título→campo 16, campo→respuesta 32 (61).
- **"+" a cada lado de la tapa seleccionada** (64) → la hoja **"¿Qué juego va acá?"**, el reverso de "¿Dónde
  va?": busca el juego que va en ese hueco; uno que ya está en un estante se **mueve** ahí, en una sola
  transacción.
- **Tocar otra tapa** mueve la selección (y los "+" la siguen); **tocar la levantada** abre su hoja.

### La hoja del juego (29–33)

✕ en la cabecera (29 · D-19e, **app-wide**: reemplaza el "Cancelar último con ‹" de 065 R7). Cabecera: tapa
56×60, el estante arriba del nombre (33), título 18/600, divisor (31). Tres filas de 64px a dos líneas, con
un verbo y una línea gris que dice qué pasa (30): **Ver ficha** / *La página del juego en la web* ·
**Mover** / *Elegís el estante y el lugar* · **Quitar del estante** / *Queda sin lugar · te pedimos confirmar*.

### Ubicar, mover, quitar

- **"¿Dónde va?" es una hoja de alto completo** (37) que se abre **apenas se elige un juego sin lugar** (36),
  desde la búsqueda o desde Pendientes. No hay botón Ubicar.
- **Su búsqueda encuentra un estante o un juego que ya está en uno** (36): elegir un juego abre su estante
  con ese juego levantado y un "+" de cada lado, así la caja va "al lado de" algo que se ve. **El campo
  conserva el estante elegido** (38).
- **Elegís el hueco** (35 — *revierte D-00c*): antes del primero, entre dos cualesquiera, o después del
  último. **Un estante vacío se lleva el juego directo**, sin paso de hueco.
- **Al ubicar: "Juego ubicado"** con Deshacer, y **la tapa cae en su lugar** (39) desde 56px arriba al 92%,
  con un rebote chico, en 620ms. Sin movimiento bajo reduced-motion.
- **Mover es una transacción** (40): abre la misma hoja, el juego **se queda en su lugar** hasta que se
  elige el nuevo, y recién ahí sale de uno y entra en el otro. Mientras se mueve, el estante se dibuja **sin
  el juego que se mueve**, así mover dentro del mismo estante también funciona. Cancelar no cambia nada.
- **Quitar pregunta primero, en un diálogo centrado** (41, 42 · D-19f, **app-wide para toda acción
  destructiva del admin** — reemplaza el "Peligro siempre confirma en una hoja" de 064).

### Pendientes (58, 59)

Página propia, detrás del ícono de bandeja con contador. Una sección por cola: **Afuera** (datos de Fase 4,
el sketch finge 3) y **Sin ubicar**, cada una con su encabezado, una línea de ayuda y todas las filas. Una
fila de Afuera lleva a Estantes con el juego levantado en su lugar; una de Sin ubicar abre "¿Dónde va?".

### Administrar estantes (43–49, 67, 68)

- **Sólo filas de estantes, sin chevron** (45, 49): un estante **no tiene página propia** — los juegos se
  ven en el estante de verdad, y buscar, ubicar, mover y quitar ya pasan en la página Estantes. *Revisa
  D-08.*
- **En el header: ⇅ Ordenar y "+" Nuevo estante**, ambos sin texto (44, 68).
- **Tocar una fila abre su hoja** con **Editar** y **Eliminar** (46); Eliminar confirma en el diálogo.
- **Una sola hoja de nombre crea y edita** (67): pre-llena el próximo número ("Estante 10") **seleccionado**,
  así un toque alcanza; errores bajo la pista ("Escribí un nombre." / "Ya hay un estante con ese nombre.",
  sin distinguir mayúsculas ni acentos).
- **Ordenar es un modo** (68): el header pasa a "Ordenar estantes" + Listo, las filas terminan en un
  handle ≡ y se arrastran; tocar ≡ sin arrastrar muestra ↑/↓ en esa fila (WCAG 2.5.7). Listo → "Orden
  guardado" + Deshacer.

### Crear un juego desde acá (62, 66)

"Crear «texto»" abre el editor de juego nuevo con el nombre puesto. **Desde la búsqueda** (todavía sin
lugar) guardar sigue a "¿Dónde va?"; **desde un "+"** el lugar ya está elegido, así que guardar lo deja ahí
directamente, y el editor lo dice de antemano. El editor de este sketch es un **sustituto** — el real es el
de la 063.

---

## El dato de abajo: ya está decidido, y este diseño es lo que lo produce

La nota de alcance (`admin-redesign-scope.md:13-25`) marcó, con razón, que la premisa entera de esta página
—que el orden de los juegos en un estante ES su orden físico— **no tenía columna detrás**: `game.ex:84`
documenta *"at most one shelf per game, no in-shelf position"* y `shelves.ex:170-177` ordena **por nombre**.

**Eso ya está contestado en `01.8.2-CONTEXT.md`**, después de que se escribiera esa nota:

- **D-01** — cada **copia** tiene estante + posición de izquierda a derecha; entra una tabla de copias.
  *Revierte 01.8.1 D-11.*
- **D-05** — **se borra todo**: al llegar la posición, se eliminan los estantes y las asignaciones, y cada
  copia arranca en Sin ubicar. **Sin backfill desde el orden por nombre.** El personal rehace los estantes y
  camina cada uno de izquierda a derecha — **ubicar registra el orden real como efecto secundario.**

Por eso no existe un "decidir contra datos reales" previo a esta página: medido el 2026-09-22 contra
`pukllay_club_dev` hay **1 estante y 1 juego ubicado de 435**, y no hay fuente de la cual sacar orden
físico. **La 069 es el instrumento que crea ese dato**, no un consumidor de él. El slice de datos no es un
prerequisito para decidir esta página: es su primera tarea.

Corolario: los 9 estantes de 46–50 del sketch son un **sustituto de la realidad post-migración**, no una
afirmación sobre hoy. Si la forma real del salón resulta muy distinta, vuelven a medirse los números que
dependen de ella (49 huecos en un estante, el alto de la lista de "O elegí un estante").

---

## Reglas que salieron de acá y valen en todo el admin

Registradas en `01.8.2-CONTEXT.md` y `01.8.2-BENCHMARK.md`:

| regla | qué dice |
|---|---|
| **D-19e** | Toda hoja cierra con **✕ en su cabecera** (29); la cabecera es tapa · contexto · título 18/600 · divisor (31, 33). La línea chica de arriba es **contexto**, el título es **de qué se trata la hoja** (34). |
| **D-19f** | Toda acción destructiva confirma en un **diálogo centrado**, nunca en una hoja (41, 42). |
| **D-19g** | El trabajo pendiente vive detrás de un **ícono con contador en el header**, no en la página (59). |
| **D-19h** | El estado es un **punto + texto**, nunca una pastilla (22). |
| **D-19i** | Un **chevron significa "navega"** (25). |
| **D-19j** | Una sola tarea principal por página, y el rango de tipografía la respalda. |
| **D-00c** | Ubicar/mover: elegís el estante y después el hueco; vacío va directo (35, revisada). |

## Qué queda abierto

1. **El ranking de la familia Catan** en las sugerencias — `cat` propone una sola de las cinco ediciones en
   las primeras 6 (los prefijos rankean primero, en orden de catálogo).
2. **`shelfDrawing` quedó sin uso** en la página Estantes: la decisión 54 le sacó el ícono al reposo y sólo
   queda su definición. El ícono nuevo `estante` (dibujo (a), decisión 33) es el que se usa en las hojas.
3. **Si Quitar mantiene Deshacer después de confirmar** — hoy el diálogo confirma y el snackbar igual ofrece
   Deshacer.

No confirmado en dispositivo real: todo se midió a 360×640, 375×667, 375×740 y 375×800 en Chrome headless,
en ambos temas.
