---
sketch: 079
name: admin-lifecycle
question: "r1 · ¿dónde vive la transición de ciclo? · r2 · en la ficha editable, ¿qué dice que un bloque se puede editar?"
winner: "r1 · M1 el ⋮ (premisa del desarrollador) · r2 abierta"
tags: [admin, juegos, lifecycle, retire, menu, kebab, ficha, rhythm, d37, d42, d44, d47, D-19i, D-19j, 064, slice-4]
rounds: 2
status: PENDING REVIEW — r2 A1/A2/A3, 26/29 (25d, 1c y 26c en rojo: los tres son hallazgos, no aserciones rotas)
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
node .planning/sketches/079-admin-lifecycle/verify.js     # 26/29
```

**La página que abre es la RONDA 2** (A1 / A2 / A3, la ficha editable). Los toggles de la ronda 1 están
eliminados — el desarrollador eligió el ⋮ — y sus mediciones quedan abajo, en la sección de la ronda 1.

**El estado y la tapa** se cambian desde el panel. Son **switches de fixture**, no controles de la página:
existen para poder contar qué ofrece el ⋮ en cada estado **sin usar el control que se está midiendo**, y
para ver los 49 juegos sin tapa. Es la lección de la 075: una página que sólo puede llegar a un estado a
través del control bajo prueba no puede medir ese control.

---

## Ronda 1 — dónde vive la transición (DECIDIDA: el ⋮)

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


---

# Ronda 2 — E3, la ficha editable

> *"son lo mismo — un solo verbo, y que despublicar sea retirar. The 3 dots opens a bottom sheet with the
> options. for this, the form is closer to how this looks like on the web. the CTA must to have same
> patterh that the 'publish' stacked at bottom."*
>
> *"Yes, second round with ⋮ as the only CTA at top. For 'edit', yes, the full form with the same
> rythm(UI/UX) that how the details looks on the web"*

**Los toggles de la ronda 1 están eliminados** (convención de 072): M1 es la decisión, M2 y M3 salieron de
la página y sus mediciones quedan arriba.

## Premisas del desarrollador — no se varían

```
el ⋮ es el ÚNICO control de arriba, y abre una hoja inferior
un solo verbo: Retirar / Restaurar
el CTA es el apilado de 52px de la 078 (`.cta`, 078:860)
el cuerpo es la FICHA, editable en el lugar          ← E3, elegida sobre E1 y E2
```

## El colapso del verbo: lo que resuelve y lo que cuesta

La ronda 1 midió un desacuerdo — el diálogo de `form.ex:352-356` describe `Retirar` como *despublicar*
(*"No va a aparecer más en la ludoteca pública"*) mientras `shelves.ex` lo usa en **5** consultas como
*"el club no lo tiene"*. **Colapsados, el desacuerdo desaparece en vez de resolverse a favor de uno:**
las 5 consultas quedan correctas, y lo que estaba incompleto era la copia, que decía una sola mitad.
Ahora dice las dos (check 31b).

Y evita el destino que la ronda 1 midió y era peor que no existir: `:draft` no es un estado al que volver
(check 9b).

**Lo que cuesta, escrito y no derivado (d47):** se pierde el caso *"lo publiqué por error y todavía lo
tengo"* — ese juego sale también del mapa de estantes. Hoy vale cero (0 retirados, 1 de 435 con estante),
pero es la decisión, no un efecto secundario.

---

## La medición que reencuadró la ronda, antes de dibujar nada

**"El ritmo de la web" sólo está definido para la mitad de los campos.** El editor castea seis:

| campo | ¿está en la ficha pública? | cómo |
|---|---|---|
| **name** | sí | `<h1 class="font-display text-3xl">` — Bebas 30/36, **sin etiqueta** |
| **description** | sí | prosa 16px justificada, clamp de 3 líneas, **sin etiqueta ni título** |
| **weight_band** | sí | un pill de 11px/600 arriba de la tapa, con 3 puntos, **sin etiqueta** |
| **is_expansion** | **no** | cero ocurrencias en `show.ex` |
| **units** | **no** | el campo existe, ninguna plantilla lo lee |
| **shelf** | **no** | sólo en comentarios sobre el carousel |

Y **el único vocabulario etiqueta→valor que tiene la web es de 12px mayúsculas con 0.08em** — `AÑO ·
DISEÑADORES · ILUSTRADORES · MECÁNICAS · TEMÁTICAS · COMUNIDAD BGG` — **y los seis son datos de BGG que el
editor no deja tocar.** El rango de etiqueta de la web existe exactamente para lo que no se edita.

### Por eso el eje de la ronda es el affordance, y no una preferencia

E3 obliga a usar ese mismo rango para `COPIAS`, `ESTANTE` y `ES UNA EXPANSIÓN`, que sí se editan:

```
24   las 3 etiquetas editables son BYTE-IDÉNTICAS en rango a las 5 no editables
     12px | 400 | uppercase | 0.96px | rgb(103,92,125)
```

**En E3 el rango no puede decir qué se puede tocar. Todo el peso queda en el affordance.**

Y d37 no cubre el caso: contestó esta pregunta para el spine del admin — *"etiqueta prominente, valor
subordinado, y el valor lleva `--val`"* — pero la cabecera de E3 **no tiene esa anatomía**: el título es un
`<h1>` pelado, la descripción prosa pelada, el nivel un pill. No hay etiqueta de la cual el valor sea
subordinado. Y 072 ya cerró dos salidas: sacó el chevron (D-19i) y después sacó el `⌄` que lo reemplazó,
aterrizando en **ningún glifo**.

## Las tres respuestas

| | qué marca el bloque editable |
|---|---|
| **A1 · el tinte de d37** | el valor lleva `--val` |
| **A2 · el lápiz** | un glifo de 14px al final de cada bloque |
| **A3 · nada** | la línea base — la forma pura que 075-V4 midió en `diffPx 0` |

## Lo que midió

### El check central queda en rojo, y es el hallazgo

```
26a  A1   el valor editable SÍ se distingue del de BGG      rgb(60,18,105) vs rgb(35,19,57)
26b  A2   se distingue por un NODO, no por tratamiento — el estilo es idéntico al de BGG
26c  A3   editable y no editable son "rgb(35,19,57)|400|none|transparent|none" — LOS DOS
```

Se compara `Copias` (editable) contra `Año` (de BGG), que están en el mismo rango. **En A3 nada distingue
lo que podés cambiar de lo que no.** Es el `diffPx 0` de 075-V4 dicho sobre el par que importa — y se mide
por estilo computado, no por píxeles, porque los dos valores tienen textos distintos ("1" contra "2016") y
un diff de píxeles mediría los glifos, no el tratamiento.

### A1 pinta 6,1× lo que A2 — y choca con algo que no se edita

```
25a  A1 (el tinte)   20.364 px de 1.110.000 contra A3    maxDelta 194
25b  A2 (el lápiz)    3.333 px                            maxDelta 163
25c  el tinte cubre 6,1× — en el spine de d37 el valor es una línea corta;
     acá es un H1 de 30px y un párrafo justificado de tres líneas
25d  EN ROJO — el tinte (rgb 60,18,105) es EL MISMO COLOR que el chip de sección,
     que NO es editable (es `section_names`, virtual)
```

**25d lo encontró la captura.** La causa está medida desde la 074 ronda 3: en tema claro
`--color-primary` y `--color-accent-text` **son el mismo hex**, y `--val` se define sobre el segundo
mientras `.pill.tag` usa el primero. Así que en A1 el tinte **no puede significar "esto se edita": ya
significa otra cosa en la misma pantalla.**

### A2 marca 5 de 7 bloques, no 7 — y contar nodos no lo veía

```
1b   6 lápices de 7 bloques      la TAPA se queda sin marca:
                                 un glifo inline necesita un final de texto del cual colgarse
1c   de esos 6, uno está RECORTADO   el de la descripción vive dentro del clamp de 3 líneas
                                     (el lápiz en y=861, la caja termina en 736)
```

**El check 1b contaba nodos y daba verde sobre una marca que en pantalla no existe.** Es la forma del punto
invisible de la 078 y de la banda de la ronda 1 que pintaba detrás de `.device`. El 1c mide contra el rect
del ancestro que recorta.

### Los dos "apilado abajo" no son el mismo, y acá se ve cuánto

```
23a  el CTA mide 52px, el patrón de Publicar de la 078
23b  y al reposo está en y=1415 contra un piso de 740 — invisible y no tocable.
     Hay que scrollear 751px (1,9 pantallas) para llegar a Guardar
```

La 078 podía permitírselo porque su formulario entraba en una hoja corta. **La ficha de la web mide casi
dos pantallas, y la web resuelve el pie con una barra FIJA** (`.pk-mobile-cta-bar`, `position: fixed`, más
148px de `padding-bottom` reservados en el body). Las dos cosas que se pidieron —el ritmo de la web y el
CTA de la 078— **se contradicen exactamente en el pie**, y esto es cuánto.

### Adoptar la quilla de la web rompe R359

```
21a  la quilla es 14px (--pk-gutter 0.875rem a ≤480), no los 16 del admin
21b  así que el CTA termina en R361, no en R359 — el borde que d42 fijó y 074/075/078 sostuvieron
21c  y la barra NO se mudó: el ⋮ sigue en R359 → la página tiene DOS bordes derechos
22   y dos izquierdos: texto a 14, tapa a 31 (= 14 quilla + 1 borde + 16 padding del panel)
```

### El ⋮ como único control: borra su costo y hereda otro

```
27a  la barra tiene 2 controles y NINGÚN primario — Guardar bajó al pie, así que el ⋮ no empuja nada.
     Esto BORRA el único costo que la ronda 1 le midió a M1 (empujaba Guardar de R359 a R307)
27b  pero el ⋮ hereda R359 — la esquina que cinco pantallas enseñaron como LA ACCIÓN PRINCIPAL
```

Es la forma inversa de lo que la 074 ronda 1 encontró con `Descartar` heredando el borde del primario.

### El nivel aparece dos veces, y no es el fixture

```
28   el pill de facts (y=89, EDITABLE) y el chip de sección bajo el título (y=567, NO editable)
```

El chip es `section_names`, que es virtual: publicar mete el juego en la sección de su banda. **Mismo
texto, dos rangos, uno se toca y el otro no.**

### Los 49 sin tapa abren sobre un hueco de media pantalla

```
29   el hueco mide 329px — el 44% de la pantalla — y empuja el título a y=523
```

Son exactamente `no_bgg_id` (41) + `bgg_missing` (8), verificado contra la base: de los 435, los 386
`enriched` tienen tapa y los 49 restantes no, 1:1. **Son los juegos que abrís el editor para arreglar.**

### Tres defectos míos que encontraron los checks y la captura

1. **`font: inherit` en el reset le ganó a la regla del título.** `.pg .ed` puesto *después* de `.pg .h1`,
   misma especificidad (0,2,0): el título salía en **Inter 16** en vez de Bebas 30, y la página se veía
   razonable. **Tercera vez en este linaje** — 075-V4 con el `line-height`, la ronda 1 de este mismo sketch
   con el `margin` en atajo, y yo escribí el comentario que lo advertía y lo hice igual. La regla, de una
   vez: **un reset va antes que las reglas de tipo**, y el check 20 lee lo computado.
2. **`.ed .h1` no es `.ed.h1`.** El bloque editable **es** el título, no lo contiene. Con el selector
   descendiente **A1 no pintaba nada y era byte-idéntica a A3** — la variante del tinte y la de "nada", la
   misma página. Un check de conteo de nodos habría pasado.
3. **La quilla de 14 se sumaba a los 16 que `main` trae de la 078** (línea 146), así que el texto quedaba a
   30px — y eso **se leía como el hallazgo esperado** ("es fiel a la web, la web tiene dos bordes"). Un
   borde heredado que se parece al hallazgo que uno busca es la peor clase de falso verde.

## Qué mirar

Abrí **A3** primero y buscá qué te dice que podés tocar algo. Después **A1**: mirá el párrafo entero en
morado, y fijate que el chip *Ingenio estratega* debajo del título está del mismo color **y no se edita**.
Después **A2**: buscá el lápiz de la descripción — no está, se lo comió el clamp — y el de la tapa, que no
existe.

En las tres, bajá hasta `Guardar`: son casi dos pantallas.

## Open (ronda 2)

- **A1 / A2 / A3 sin decidir.** Y ninguna de las tres pasa limpia: A1 choca de color con un elemento no
  editable (25d), A2 no alcanza 2 de 7 bloques (1b/1c), A3 no marca nada (26c).
- **La cuarta salida no está dibujada:** que el affordance no sea por bloque sino **de página** — un
  estado *"estás editando"* declarado una vez. Nombrada, no construida, porque cambia la premisa de E3
  (la ficha editable *en el lugar*).
- **El pie se contradice y hay que elegir**: el CTA de la 078 a y=1415, o la barra fija de la web con sus
  148px reservados. Medido (23b), no resuelto.
- **La quilla: 14 o 16.** Con 14 el cuerpo termina en R361 y la barra en R359. Con 16 se rompe el espejo.
- **D-19j queda pisada para esta página** (título Bebas 30 en vez de 22/600 Inter) y hay que escribirlo
  como decisión, no dejarlo como deriva — es lo que d47 existe para evitar.
- **El nivel duplicado (28) no se tocó.** El chip de sección es `section_names` y no es editable; que el
  mismo texto aparezca dos veces con dos rangos distintos es de la ficha pública, no del editor.
- **La tapa del sketch es el isologo, no la portada real** (`cover_url` vive en R2 y el arnés corre sin
  red). El `aspect-ratio: 1/1.05` y el `object-fit: contain` sí son los de la app, pero una portada real
  apaisa distinto y eso no está visto.
- **No confirmado en dispositivo.** Esta ronda agregó dos hallazgos más que encontró la captura y no el
  número (el lápiz recortado y el choque de color de A1).
- Todo lo abierto en la ronda 1 y en la 078 sigue abierto.
