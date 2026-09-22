---
sketch: 080
name: admin-guardar-arriba
question: "Si la hoja PREPARA y el pie escribe, ¿dónde vive ese `Guardar` — y cómo convive con la franja de estado que la 079 puso bajo la barra?"
winner: null
tags: [admin, editor, guardar, dirty-state, cta, franja, d47, d42, d44, 064, D-19f, D-19h, phase-01.8.2]
rounds: 1
status: PENDING REVIEW — 24/24, no confirmado en dispositivo
---

# Sketch 080: `Guardar` sube y se apila

Sale del hueco que la 079 dejó abierto y que el handoff del admin marcó como prerequisito de la 075:
**el `Guardar` del editor no escribía.**

El desarrollador eligió **`la hoja prepara, el pie escribe`** y lo movió: *"we need a stacked 'cta' bar at
top with the 'guardar' (enable or disable) based on if there is or aren't changes to save."*

## Cómo verla

```
python3 -m http.server 8765          # desde la raíz del repo
open http://127.0.0.1:8765/.planning/sketches/080-admin-guardar-arriba/index.html
node .planning/sketches/080-admin-guardar-arriba/verify.js     # 24/24
```

Variantes arriba (`#vnav`): **HOY (079)** · **A · dos bandas** · **B · una banda**.
Para llegar al estado del que habla la ronda: tocá **Es una expansión** y cambiala.
Herramientas: Estado `Publicado / Retirado` · Tapa · Tema.

---

## Lo medido ANTES de dibujar

La 079 dejó dos puntos de commit y **sólo uno escribía**: cada hoja de campo commitea al cerrarse
(`setField`, 079:1508) y el CTA del pie sólo hacía `snack('Cambios guardados')` (079:1621). No hay
`START` ni rastreo de sucio en ninguna parte de la 079 — o sea que **el artefacto ya había elegido
"la hoja escribe"** y el botón del pie era vestigial: un rótulo que reclama un trabajo que no hace.

Y dónde estaba, medido a 375×667:

| | |
|---|---|
| `.tbar` | 0 – 56 |
| `.stbar` (la franja) | 56 – 94,5 |
| el cuerpo | 94,5 – 1529 (**1434px = 2,15 pantallas**) |
| **el `Guardar` del pie** | **y = 1453** |

**A 880px de scroll del reposo.** Es la misma forma que el hallazgo de la 075 (*"no está demotado,
está INALCANZABLE"*), y es lo que respalda subirlo con un número en vez de con una preferencia.

## Las variantes

Un solo eje: **¿la franja y el CTA son dos bandas o una?** En las dos el CTA es el apilado de 52px de
la 078, a lo ancho, bajo la línea de estado — cambia si hay costura entre ellos.

- **HOY (079)** — la línea base, no una variante: la hoja escribe, no hay nada sucio, y el `Guardar`
  del pie sigue en y=1453.
- **A · dos bandas** — `tbar` 56 + franja 38,5 + banda propia 77 = **171,5** de chrome.
- **B · una banda** — `tbar` 56 + banda unida 102,5 = **158,5** de chrome.

---

## Hallazgos

### 1. Unir las bandas ahorra 13px, no los ~70 que predije

Antes de dibujar calculé que fundir la franja con el CTA ahorraría ~70px y que ése sería el argumento
de B. **Es 13px: el 2% de una pantalla de 667.** El CTA de 52px existe en las dos variantes y domina
el presupuesto; la costura es lo único que se ahorra.

Eso reencuadra la ronda: **el eje que dibujé casi no tiene costo de un lado ni del otro**, así que
elegir entre A y B no es presupuestario. Se decide por cómo se lee, no por cuánto mide. Queda escrito
así en vez de presentar los 13px como si fueran un argumento (check 4).

### 2. El costo de B lo encontró la medición, no el ojo

Limpio, el `Guardar` deshabilitado de B es **exactamente el mismo relleno que la banda que lo
contiene** — los dos resuelven a `rgb(241,236,253)`, porque `.cta[disabled]` y `.stbar` usan
`--color-surface`. Sobrevive sólo por su anillo de 1px. En A la banda es `--color-bg`, así que el
mismo botón sí contrasta (check 16).

### 3. La franja le debe una oración al estado sucio

`Así se ve en la web.` describe **lo guardado**. Con el estado sucio de vuelta esa frase es
literalmente falsa justo cuando importa: la web sirve `SAVED` y la pantalla muestra `G`.

Es la forma de la 075 al revés — allá una frase se quedaba quieta acusando mientras el remedio
desaparecía; acá una frase se queda quieta **afirmando** mientras abajo cambió todo. La franja de la
079 se escribió para una página **sin** estado sucio; devolvérselo le debe una oración:

| | limpio | sucio |
|---|---|---|
| publicado | Así se ve en la web. | **Tus cambios todavía no están en la web.** |
| retirado | No se ve en la web ni está en el estante. | **Tus cambios todavía no están guardados.** |

Más un tinte pendiente (`--warn` al 9%), verificado que **pinta** en claro y en oscuro (checks 13, 14, 24)
— `color-mix` sobre `--warn`, que sigue siendo el `TODO(palette)` local que la 075 dejó debido.

### 4. Dos defectos del marco que se leían como costos de la variante

Los 23 checks pasaban y la captura los encontró igual.

**(a)** `#vnav` es `fixed` y con tres botones mide 76,78 — más que los 46px que la 079 reservaba, así
que pisaba los primeros 2,8px de `.tbar`, **la barra que esta ronda está decidiendo**.

**(b)** Peor, y más instructivo: al reservarlos con padding, `.stage` + un `.device` de `100vh`
pasaban de la ventana, así que la página quedó desplazable — y al aparecer la banda de `Guardar` el
anclaje de scroll de Chrome la corría 80px sola. Medido: `scrollY` **0 en HOY y 80 en A y B**, con la
barra terminando debajo del `#vnav`. **El defecto aparecía sólo en las variantes nuevas**, que es la
forma más fácil de leerlo como un costo de A y de B en vez de un error del marco.

El check 21 ahora exige `scrollY === 0` y hit-testea `.tb-back` y `#kebab` en los tres modos. Y el
propio probe tenía su trampa: `elementFromPoint` sobre un `<svg>` devuelve un `SVGAnimatedString` por
`className`, que serializa a `{}` y se lee como *"no hay nada ahí"* — se sube al `<button>` antes de
nombrarlo.

---

## El precio, escrito

No es un efecto secundario: es lo que se compra al elegir *la hoja prepara*.

1. **Vuelve el confirmar-al-salir.** d47 lo había eliminado junto con el estado sucio. Ahora salir
   puede perder trabajo, así que `‹` con cambios abre el diálogo de **D-19f** (checks 18, 19).
2. **Vuelve un botón deshabilitado**, que es el conflicto con `064` que este linaje viene arrastrando
   — pero ahora por elección explícita del desarrollador, no por omisión.
3. **La 075 conserva su eje.** El estado sucio existe otra vez, así que su pregunta original
   (*¿dónde vive el remedio mientras el editor está sucio?*) sigue en pie tal como se planteó.

---

## Qué mirar

- Cambiá **Es una expansión** y mirá el momento en que `Guardar` se enciende. ¿Se nota?
- Con `Guardar` apagado, ¿lo ves en B? Es el mismo relleno que su banda.
- Leé la franja limpia y sucia. ¿La segunda oración dice lo que tiene que decir?
- Tocá `‹` con cambios sin guardar.
- Pasá a **HOY** y buscá el `Guardar` del pie. Está a 880px.

## Abierto

- **El punto sigue verde mientras hay cambios sin guardar.** El estado *es* `Publicado` y D-19h manda
  punto + texto, así que no está mal — pero lo pendiente no tiene punto propio. Queda nombrado, no
  resuelto por mi cuenta.
- **171,5px de chrome permanente** en A (158,5 en B) sobre 667: entre el 24% y el 26% de la pantalla
  antes de la primera fila de contenido, siempre, incluso limpio. No se midió contra una banda que se
  esconda al estar limpia — sería otro eje.
- **`Publicar` no está en esta ronda.** El editor de un publicado no lo tiene; vive en la hoja del
  borrador (078). Si el par `Guardar` + `Publicar` tiene que existir en algún lado, es otra pregunta.
- No confirmado en dispositivo real.
