---
sketch: 079
name: admin-lifecycle
question: "r1 · ¿dónde vive la transición de ciclo, ahora que la barra de 074 ya tiene su único CTA?"
winner: null
tags: [admin, juegos, lifecycle, publish, unpublish, retire, menu, kebab, d42, d44, d29, D-19i, D-19h, 064, slice-4]
rounds: 1
status: PENDING REVIEW — M1 / M2 / M3, 39/40 (el 11c en rojo a propósito)
---

# Sketch 079: dónde vive la transición de ciclo

**Slice 4 de cuatro.** Levanta el paseo donde lo dejó la 078: el juego está creado, los datos llegaron, el
borrador se completó y se publicó desde su hoja. Ahora es un publicado, y la pregunta es qué se puede
hacer con él después.

El alcance que trajo el desarrollador al intake:

> *"un menú ⋮ con editar / publicar / despublicar"*

## Cómo verlo

```
python3 -m http.server 8765          # desde la raíz del repo
open http://127.0.0.1:8765/.planning/sketches/079-admin-lifecycle/index.html
node .planning/sketches/079-admin-lifecycle/verify.js     # 39/40
```

**El estado del juego** se cambia desde el panel (Publicado / Retirado / Borrador). Es un **switch de
fixture**, no un control de la página — existe para poder contar qué ofrece el menú en cada estado **sin
usar el control que se está midiendo**. Es la lección de la 075: una página que sólo puede llegar a un
estado a través del control bajo prueba no puede medir ese control.

---

## Cuatro de las siete mediciones del intake cambiaron de forma al re-chequearlas

### (1) El contenedor NO estaba precedentado — ni siquiera en la superficie que esta ronda toca

`.tb-act` existe, con su comentario que dice *"dos controles"* y su gap de 6px:

```
074:157   .tb-act { display: flex; align-items: center; gap: 6px; flex-shrink: 0; }
075:181   idéntico
```

Pero **nunca renderizó dos**. En los dos sketches `slot` es un solo botón (`074:683`, `075:851`), así que
el gap jamás se ejerció. Y la **078 lo eliminó entero**: la barra decidida arma el botón como hijo directo
de `.tbar`.

```
078:1436-1438   `‹` · <span class="tb-t"> · <button class="btn">Guardar</button>
```

Así que el ⋮ no es *"un patrón nuevo en un contenedor viejo"*: es **un patrón nuevo y un contenedor nuevo**.

Lo que sí existe, y no estaba en la lista, es un **registro de haber rechazado el dropdown del framework**:

> `layouts.ex:792-794` — *"Checked daisyUI's `dropdown` component first … its CSS-only focus/`popover` show
> mechanism has no first-class way to pair a dimmed backdrop, a document-level Escape handler, and the
> `.CatalogNav` scroll-spy's `is-active` class"* → hecho a mano.

O sea que el precedente del proyecto no es *"usar el dropdown de daisyUI"*: es *"si hace falta un panel, se
escribe a mano"*. M1 está escrito a mano.

### (7) La lectura (b) ya se rechazó — por este mismo argumento, y para otra acción

El intake planteaba dos lecturas: (a) el ⋮ en el header del editor, (b) el ⋮ en la fila de la lista. **La (b)
ya está decidida en contra**, y no por el verbo sino por la estructura:

> `juegos-ui-redesign.md:750` — *"Un botón `Reintentar` dentro de la fila es una segunda acción por fila,
> cuando D-19i reserva el slot trailing para 'abre una página'"* → **"la fila se queda SÓLO con su chevron,
> y Reintentar se muda al editor."**

Es exactamente la forma de (b), ya contestada. Por eso esta ronda dibuja las tres variantes **en el editor**.

Corrección menor de paso: la fila que corre **hoy** no tiene chevron ni cluster trailing — el `:action` slot
de `table/1` no se pasa nunca, y la fila entera es un solo `row_click` a `~p"/admin/juegos/#{id}/editar"`.
El chevron está en el **sketch** (078), no en la app.

### (2) Es más fuerte: no falta un botón, falta el DESTINO

`:draft` es un estado de **una sola vía**. Barrido completo sobre `lib/`:

```
game.ex:159        put_change(:status, :draft)      la ÚNICA escritura de :draft en todo lib/
catalog.ex:325     |> Multi.insert(:game, Game.draft_changeset(...))    su ÚNICO sitio de llamada
game.ex:183-212    enrichment_changeset — su propio docstring: "Never casts :status —
                   a draft stays a draft until staff publish it."
game.ex:243+       admin_changeset — tampoco castea :status
                   sin update_all, sin SQL crudo
migración 20260914012900   default 'published', null: false, + CHECK games_status_must_be_known
```

Se entra a borrador **al crear y nunca más** (check 9c). Y las tres transiciones que existen viven en un
solo archivo — `form.ex:112, 127, 166`. El índice no llama ninguna.

### (3) Estaba al revés: `Retirar` ya significa despublicar, y lo dice su propio diálogo

La medición decía que *"Retirar dice lo que no es"* porque `retired` = el club ya no tiene el juego. Pero la
copia que corre hoy dice otra cosa (`form.ex:352-356`, citada carácter por carácter en el check 10a):

> *"¿Retirar Scythe? Vas a poder restaurarlo después. **No va a aparecer más en la ludoteca pública.**"*

Eso **describe despublicar**: reversible, y sobre la visibilidad en la web. En ningún lado dice que el club
no tenga el juego.

Y sin embargo el otro sentido también está en el código, en otro archivo:

```
shelves.ex   status != :retired   en 5 consultas — ubicación, sin ubicar, en estante, búsqueda, pick list
```

Ahí `retired` sí significa *"no está en la colección física"*. **Un estado, dos significados, dos archivos,
en desacuerdo** (check 10d). Eso no es un problema de etiqueta: es el modelo sin decidir.

---

## El número que se midió antes de dibujar ningún contenedor

La instrucción de la ronda era *"una pregunta por ronda, medida antes de dibujarla"*. Esto es lo medido:

```
2a   publicado   2 transiciones     Despublicar + Retirar
2b   retirado    1 transición       Restaurar
2c   borrador    0                  no llega a esta página (078:1212 lo manda a la HOJA)
```

**El menú nunca tiene más de dos ítems, y en el único estado que alguna vez va a existir de verdad tiene
uno.** Un menú de un ítem es un botón con un toque de más y la etiqueta escondida.

Las tres variantes leen el **mismo** array (check 1), y el check 1b lo hace falsificable pisando `actions`
desde el arnés — sin eso, el 1 pasaría igual si las tres leyeran una constante muerta.

---

## Las tres respuestas

| | dónde vive | al reposo |
|---|---|---|
| **M1 · el menú ⋮** | en la barra de 074, a la derecha del CTA | **0 verbos** y un glifo que dice que hay algo, no qué |
| **M2 · al pie** | una zona `CICLO` al final del formulario — **el incumbente** | **2 verbos en palabras**, con su explicación |
| **M3 · el read-out es el control** | `● Publicado` se vuelve el que abre la hoja de ciclo | **0 verbos**; sólo la línea de estado |

**M2 no es una propuesta: es lo que corre hoy.** `form.ex:324-330` pone `Retirar` / `Restaurar` en un `<div
class="flex">` pelado **después de `</.form>`**, o sea al pie del cuerpo, fuera del submit. Es la misma forma
que la ronda 3 de la 074 encontró con W2 — la variante que parecía la propuesta era el sistema de registro,
y la pregunta real era si seguir apartándose de él.

Y hay algo más: **en todo el linaje rediseñado (074, 075, 078) la palabra `Retirar` no aparece una sola vez.**
Se dibujó **una** vez, en la G2 de la 073 (`073:797`), dentro de la barra de acción de abajo — y **d42 rechazó
G2 justamente por poner un control destructivo al lado del slot seguro**. Después la 074 borró esa barra.
Desde entonces la transición de ciclo no tiene contenedor en ninguna parte. Se difirió tres veces como
*"slice 5's job"*.

---

## Lo que midió

### El costo de M1 es la regla que el linaje sostuvo tres sketches

```
6a   M2 y M3   Guardar termina en R359      la quilla de 16px de d42, intacta
6b   M1        Guardar termina en R307      52px adentro — y en la quilla queda el ⋮
6c   NEGATIVO  sacando el ⋮, vuelve solo a R359
```

d42: *"el primario siempre termina en el mismo borde."* La 074 ronda 3 volvió a poner ahí la tinta de W3 a
propósito, con `padding-right: 0` y un `::before` que saca el área de toque a R373 sin mover la tinta. **M1
empuja el primario 52px adentro y le da la quilla a un glifo.** El 6c descarta que lo esté moviendo cualquier
otra cosa.

### El costo de M2, y la predicción que la medición desmintió

```
11a   el piso es 740        la 078 sacó la barra de tabs: nada superpone al scroller
11b   la zona arranca en y=591, SOBRE el piso
      Despublicar  y640-715   entera y tocable
      Retirar      y715-773   CORTADA
11d   al fondo aparece entera, y el scroll total del editor es de 157px
```

**El check 11b estaba escrito para asertar lo contrario.** La predicción era que M2 moriría en el pliegue como
murió la V3 de la 075. No muere: la 078 sacó la barra de tabs y este editor mide poco. El check se reescribió
para medir en vez de para confirmar, y queda anotado, porque una aserción escrita antes de medir que después
se ajusta al resultado es la forma exacta en que un arnés deja de poder fallar.

Lo que sí paga M2 está en **11c, que queda en rojo**: al reposo entra **una fila y media**. Y **cuál se corta
lo decide el orden del array**, no el diseño.

### M3 · la banda de d29 no es portable, y lo dijo la captura

075-V4 dibujó *"el diagnóstico ES el remedio"* sin pintura y el pixel-diff dio `diffPx 0 of 270000` — no un
affordance débil: **ninguno**. La salida fue la banda de d29. Acá se reusó verbatim, y en la captura se ve
dónde cae:

```
18   la banda arranca a 0px del borde de la TAPA
     y 14px a la IZQUIERDA de la columna de texto
     → cae en la canaleta de 14px de `.ghead`, no sobre la línea de estado
     queda a 14px del punto que supuestamente marca, y mide 30px contra los 8 del punto
```

En 075-V4 la banda funcionaba porque el bloque era de ancho completo y no tenía nada a su izquierda. **Acá
tiene una tapa de 64px, así que la banda se lee como un separador entre columnas.**

### Y el pixel-diff de 075-V4 NO es portable tampoco — la trampa nueva de esta ronda

```
8a   M3 con banda   vs M2            diffPx 2883 de 31920 · maxDelta 237
8b   M3 SIN banda   vs M2            diffPx 2535 de 31920 · maxDelta 91     ← y no es pintura
8d   M3 con banda   vs M3 sin banda  diffPx  348 de 31920 · maxDelta 237
```

El 8b estaba escrito para dar cero, copiando el resultado de 075-V4. Dio 2535. **La causa no es pintura**: la
geometría entera coincide al píxel (check 7) y ningún color computado difiere. Es que un `<button>` con ancho
de ajuste al contenido mide **231,141px** contra los **265** del `<div>`, y ese ancho fraccionario corre las
posiciones subpíxel de las letras, así que el mismo texto se rasteriza distinto.

**Allá las dos variantes eran el mismo `<div>` y lo único que cambiaba era pintura. Acá cambia el tipo de
caja.** El diff contra M2 no puede aislar la banda; el 8d sí, porque compara las dos imágenes con la misma
caja. El check 8c existe para que ninguno de los tres pueda pasar por un recorte que deje la banda afuera.

### Dos defectos míos que encontraron los checks en rojo

**`esconder` no es `vaciar` (check 5b).** `closeMenu` sólo ponía `hidden`. Los `.mi[data-cyc]` quedaban en el
DOM, así que en estado `borrador` — donde `actions()` devuelve **cero** y no debería existir ningún control de
ciclo en ninguna parte — la página seguía teniendo dos verbos de un estado anterior. Misma forma que registró
la 076: un reset que borra la cosa de la que habla la pantalla tiene que cambiar la pantalla también.

**M3 movía texto (checks 7 y 8b).** La primera versión puso `margin-left: -10px` con `padding-left: 14px` —
un neto de +4px — y padding vertical sin margen que lo compensara. El punto se corría 4px y `.glabel` bajaba
10. **Un pixel-diff ahí habría reportado mi CSS como affordance**, que es exactamente lo que 075-V4 perdió una
ronda en descubrir con `font: inherit`. Y el `margin` en atajo además pisaba el `margin-top: 4px` de `.gh-st`.

### El destino de Despublicar, evaluado contra el código de la 078 y no afirmado

El check 9b **lee los predicados reales de `078/index.html`** (`GROUPS`, `opensSheet`, `enrOf`) y los corre
contra la fila que queda después de despublicar:

```
status 'draft' · gap false · enr 'enriched'
  → sección "Borradores"        cerrada al reposo: true
  → opensSheet: true
```

O sea: **la fila sale de "Juegos del club", entra en una sección de excepción cerrada, pierde el chevron, y al
tocarla abre la hoja que te pide completar y PUBLICAR.** Te pide deshacer lo que acabás de hacer.

### Y el retirado no tiene dónde ir

```
078:1170-1172    Sin datos · Borradores · Juegos del club     (decisión 8: PARTICIONAN el catálogo)
                 el predicado de la tercera es `status !== 'draft' && !gap`
078:1176         "el GRUPO nombra el estado, así que la fila nunca lo repite" → la fila sólo lleva el año
index.ex:327     la app que CORRE hoy sí tiene un filtro `Retirados`
```

Un retirado cae en **"Juegos del club"** — el nombre de la sección afirma justo lo que el estado niega — y
**sin ninguna marca**. El rediseño perdió el único lugar donde un retirado era visible, y nadie lo notó
**porque hay 0 filas**. Recontado hoy contra `pukllay_club_dev`: `published 434 · draft 1 · retired 0`.

### Tres cosas que encontró la pantalla y no el arnés

Novena, décima y undécima vez en este linaje. **Los quince checks anteriores estaban todos verdes.**

```
16   el menú abierto de M1 tapa el NOMBRE del juego y su ESTADO — 15.974px² de la cabecera
17   el snack cae encima de la zona CICLO de M2 (label tapado), y es el snack DE LA PROPIA TRANSICIÓN
18   la banda de M3 cae en la canaleta (arriba)
```

El **16** es la forma del check 16 de la 078 (el toast enterrando `Publicar`), pero peor en un sentido: lo
tapado no es un anuncio, es **la identidad del objeto**. Elegís entre despublicar y retirar sin ver de qué
juego ni desde qué estado.

El **17** entró por la puerta de atrás: apareció en una captura contaminada por un snack de un check anterior.
**El accidente vale como hallazgo; dejarlo dentro del arnés no**, así que `atRest` ahora lo limpia y el choque
se mide a propósito.

---

## Qué mirar

Abrí **M1** y tocá el ⋮ **sin scrollear**: mirá qué deja de estar en pantalla mientras elegís. Después
cambiá a `Retirado` en el panel y volvé a abrirlo — un menú de un solo ítem.

Después **M2**, y bajá: la zona `CICLO` aparece sin pedir un scroll de más, pero `Retirar` cruza el piso.
Fijate si dos verbos con su explicación al pie de un formulario se leen como parte del formulario.

Después **M3**, y buscá la banda: está pegada al borde de la tapa, a 14px del punto que dice marcar.

Y en las tres, tocá `Retirar` y **leé el diálogo**: esa copia es la que corre hoy, sin retocar.

---

## Open

- **La ronda 1 está abierta. M1 / M2 / M3 sin decidir.**
- **`retired` significa dos cosas y hay que elegir una.** El diálogo de `form.ex` lo describe como
  *despublicar* (reversible, sobre la web); `shelves.ex` lo usa en 5 consultas como *"el club no lo tiene"*.
  Mientras no se decida, `Despublicar` y `Retirar` son o bien dos nombres de lo mismo, o bien dos cosas de
  las que una no existe. **Esto está antes que la elección de contenedor y puede volverla moot**: si son lo
  mismo, el menú tiene UN ítem en todos los estados.
- **El destino de Despublicar no existe** (check 9c) y `:draft` no es el destino correcto aunque existiera
  (check 9b lo manda a la hoja que te pide publicarlo de nuevo). Si `Despublicar` se decide, hay que decidir
  a qué estado va — y la opción que nadie midió es una cuarta columna o un cuarto valor del enum.
- **El retirado no tiene sección en la lista decidida.** Cualquier variante que ofrezca `Retirar` manda el
  juego a "Juegos del club" sin marca. La 078 no tiene la culpa: hay 0 retirados.
- **11c queda en rojo**: M2 ofrece una fila y media al reposo, y cuál se corta lo decide el orden del array.
- **El menú de M1 tapa la cabecera** (check 16). No se arregló: reubicarlo es una decisión, no un parche.
- **No confirmado en dispositivo.** En este linaje el dispositivo encontró ocho veces lo que el arnés no, y
  esta ronda agregó tres más que encontró la captura y no el número.
- **El guard que falta en el código** sigue faltando: `and g.is_expansion == false` en
  `section_query(:weight_band)` (`catalog.ex:850`).
- **El bug de `bgg_client.ex` sigue sin archivar** — `./` en `name`, `publishers`, `artists`. La página
  pública de Codenames sigue mostrando 3.304 caracteres de *"editado por"*.
- **`publish_game` y `retire_game` siguen sin guard de origen** (`catalog.ex:491`, `:502`), así que un
  retirado puede publicarse directo salteando el guard de `restore_game`. Ninguna variante de esta ronda
  puede arreglar eso: vive en el contexto, no en la pantalla.
- Todo lo abierto en la 078 sigue abierto.
