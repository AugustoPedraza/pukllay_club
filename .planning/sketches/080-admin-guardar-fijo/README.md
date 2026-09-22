---
sketch: 080
name: admin-guardar-fijo
question: "r1 · ¿alcanza con fijar al pie el `Guardar` que ya está ahí? · r2 · ¿ese botón no es demasiado grande? ¿qué dice la barra fija que la web YA tiene?"
winner: null
tags: [admin, editor, guardar, dirty-state, cta, pie-fijo, franja, d47, 064, D-19f, D-19h, phase-01.8.2]
rounds: 2
status: PENDING REVIEW — 24/24, no confirmado en dispositivo
---

# Sketch 080: el `Guardar` del pie, fijo

Sale del hueco que la 079 dejó abierto y que el handoff del admin marcó como prerequisito de la 075.

El desarrollador eligió **`la hoja prepara, el pie escribe`**, y sobre dónde vive ese `Guardar`:

> *"make the bottom «Guardar» that already exist there be «fixed» at bottom."*

**Una sola cosa cambia de lugar.** La barra de la 079 (`‹ · título · ⋮`) no se toca, la franja de
estado tampoco, y no aparece ningún control nuevo arriba.

## Cómo verla

```
python3 -m http.server 8765          # desde la raíz del repo
open http://127.0.0.1:8765/.planning/sketches/080-admin-guardar-fijo/index.html
node .planning/sketches/080-admin-guardar-fijo/verify.js     # 24/24
```

Arriba: **HOY · en el flujo (079)** es el antes, no una variante. Las dos que sí se comparan son
**A · 52 (078)** y **B · 44 (como la web)**.
Para llegar al estado del que habla la ronda: tocá **Es una expansión** y cambiala.

---

## El número que motiva la ronda

Medido sobre la 079 antes de tocar nada, a 375×667:

| | |
|---|---|
| `.tbar` | 0 – 56 |
| la franja | 56 – 94,5 |
| el cuerpo | 94,5 – 1529 (**1434px = 2,15 pantallas**) |
| **el `Guardar`** | **y = 1453** |

**A 880px de scroll del reposo.** Es la misma forma que el hallazgo de la 075 — *no está demotado,
está inalcanzable* — y la 079 ya lo había anotado sin resolverlo (su README, 5g y 23b).

Y el `Guardar` de la 079 **tampoco escribía**: `setField` commitea al cerrar cada hoja (079:1508) y
el CTA del pie sólo hacía `snack('Cambios guardados')` (079:1621). No hay `START` ni rastreo de sucio
en ninguna parte de la 079, así que el artefacto ya había elegido *"la hoja escribe"* y ese botón era
vestigial: un rótulo reclamando un trabajo que no hacía.

## Lo que hace la ronda

- **`la hoja prepara, el pie escribe`.** `G` es el borrador (lo que la página muestra y lo que las
  hojas escriben); `SAVED` es lo último commiteado, que es lo que la web sirve. `Guardar` copia uno
  sobre el otro. `status` queda afuera: lo cambia el ⋮ y commitea solo — despublicar no es un
  borrador, es una acción de página.
- **El `Guardar` que ya estaba al pie, fijo al pie.** Visible en reposo (y=**603** de 667) y con el
  cuerpo scrolleado hasta el fondo (checks 2, 3).
- **Habilitado sólo si hay algo que guardar** (checks 5, 6).
- **El cuerpo le reserva el hueco**, así que el último bloque no queda tapado: 65px libres a 375,
  64,7 a 360 (checks 4, 17, 18). El hueco se **mide** del alto real de la barra, no se estima — si se
  estima, el último bloque queda tapado por unos pocos píxeles y ningún check lo nota.

### No es un patrón nuevo: la ficha pública ya lo resuelve así

`.pk-mobile-cta-bar` (`app.css:5375`), desde la fase 01.2: `position: fixed`, `padding: .75rem 0`,
`border-top`, y `body.pk-has-cta-bar` reservando el alto abajo. **E3 dice que el editor se ve como la
ficha**, así que acá se reusa esa forma en vez de inventar una. Los 148px que la web reserva son de
*su* barra, que tiene dos filas; ésta tiene una.

---

## Ronda 2 — ¿el botón no es demasiado grande?

> *"wondering if that «save» at bottom isn't too big. Check the balance with another pages that use
> that to make it consistent and well balanced."*

**Medido en vivo contra la app corriendo** (`localhost:4000/juegos/10`, 375 de ancho) — no deducido
del CSS, y sobre la **misma ficha de juego** que E3 dice que este editor espeja:

| | `.pk-mobile-cta-bar` (la web, real) | A · el `.cta` de la 078 (lo que traía) |
|---|---|---|
| barra | **69px**, fondo `--color-surface`, borde 1px | 77px, fondo de la página |
| botón | **44px · radio 4 · 14/600** | 52px · radio 12 · 16/600 |
| quilla | 14 / 14 | 14 / 14 |
| reserva del body | 148px (`9.25rem`) | 88px (medido del alto real) |

**Sí era más grande: 8px de botón, 8px de barra, 2px de radio y 2px de tipo.**

### El dato que decide el eje

El `.cta` de 52px viene de la 078 — pero **ahí no es una barra de página: vive adentro de una hoja**.
Así que no son dos precedentes compitiendo por el mismo contenedor. Para una **barra fija al pie de
una página**, el único precedente que existe en este producto es el de la web, y E3 ya dice que este
editor se ve como esa ficha.

B lo reproduce al píxel (check 21) y recupera 8px de alto (check 22).

### El defecto que trae adoptar el fondo tonal

`.cta[disabled]` también es `--color-surface`, así que dentro de la barra tonal el `Guardar` apagado
daba **1:1 de contraste** — invisible salvo por su anillo de 1px. **La barra real de la web nunca lo
pisó porque su botón no se deshabilita nunca** (*"Reservar para el sábado"* siempre está vivo); el
nuestro sí, porque pediste habilitado/apagado. El apagado toma ahora el fondo de la página: **1,16:1**,
el mismo "un tono, no un borde" que la 069 usó para el carril del control segmentado (checks 23, 24).

---

## Hallazgos de la ronda 1

### 1. La franja le debe una oración al estado sucio

`Así se ve en la web.` describe **lo guardado**. Con el estado sucio de vuelta, esa frase es
literalmente falsa justo cuando importa: la web sirve `SAVED` y la pantalla muestra `G`.

Es la forma de la 075 al revés — allá una frase se quedaba quieta **acusando** mientras el remedio
desaparecía; acá se queda quieta **afirmando** mientras abajo cambió todo. La franja de la 079 se
escribió para una página **sin** estado sucio.

| | limpio | con cambios |
|---|---|---|
| publicado | Así se ve en la web. | **Tus cambios todavía no están en la web.** |
| retirado | No se ve en la web ni está en el estante. | **Tus cambios todavía no están guardados.** |

Más un tinte pendiente (`--warn` al 9%), verificado que pinta en claro y en oscuro (checks 10, 19).

**Esto lo agregué yo, no salió de una decisión tuya** — está acá para que lo apruebes o lo saques, no
como un hecho consumado.

### 2. El snackbar y la barra pelean por el mismo borde, y se salvan por 2px

La 079 r1 ya había encontrado que *"el snack entierra la zona de M2"*. Medido con la barra fija: el
snack va de 540 a 588 y la barra arranca en 590 — **2px de aire** (check 16). Funciona, pero el `79`
del `bottom` del snack se eligió para otra cosa (el alto de la barra de pestañas), así que los 2px
son una coincidencia, no un margen. Si la barra crece un renglón, el snack queda abajo.

### 3. Dos defectos del marco del sketch, encontrados por la captura

`#vnav` es `fixed` y pisaba los primeros píxeles de `.tbar`. Y al reservarle el alto con padding,
`.stage` más un `.device` de `100vh` pasaban de la ventana, dejando la **página** desplazable bajo un
`#vnav` fijo. El device se achica ahora lo que mide el `#vnav`, así que la página no se desplaza
nunca y los dos controles de la barra se hit-testean (check 12). **El número se re-mide cada vez que
cambia la cantidad de variantes** — ver el hallazgo 4.

Y el propio arnés tenía dos trampas: `elementFromPoint` sobre un `<svg>` devuelve un
`SVGAnimatedString` por `className`, que serializa a `{}` y se lee como *"no hay nada ahí"*; y el
snack usa la clase `show`, no `on` — leer la equivocada devolvía `null`, que se lee como *"no hay
snack"* en vez de *"no lo estoy midiendo"*.

---

## El precio, escrito

No es un efecto secundario: es lo que se compra al elegir *la hoja prepara*.

1. **Vuelve el confirmar-al-salir.** d47 lo había eliminado junto con el estado sucio. Ahora salir
   puede perder trabajo, así que `‹` con cambios abre el diálogo de **D-19f** (checks 13, 14).
2. **Vuelve un botón deshabilitado** — el conflicto con `064` que este linaje viene arrastrando, pero
   ahora por elección explícita y no por omisión.
3. **La 075 conserva su eje.** El estado sucio existe otra vez, así que su pregunta original
   (*¿dónde vive el remedio mientras el editor está sucio?*) sigue en pie tal como se planteó.
4. **La barra se lleva 77px del alto, siempre.** Contra los 880px de scroll que reemplaza.

### 4. El `#vnav` volvió a romperlo solo, al agregar el tercer botón

La ronda 1 encontró (con la captura) que `#vnav` es `fixed` y pisaba `.tbar`, dejando además la
**página** desplazable. Al sumar el tercer botón el `#vnav` volvió a envolver a dos renglones —
**76,8 medido a 360 y a 375** — y el defecto volvió entero: el check 12 pasó a dar `no-boton:DIV` en
los dos controles de la barra. El alto se mide ahora cada vez que cambia la cantidad de variantes,
en vez de quedar fijo en un número que valía para dos botones.

## Qué mirar

- Cambiá **Es una expansión** y mirá el momento en que `Guardar` se enciende.
- Scrolleá hasta el fondo. ¿El último bloque se lee entero?
- Guardá y mirá dónde cae el snackbar: pasa 2px por encima de la barra.
- Leé la franja limpia y con cambios. ¿La segunda oración es tuya o te sobra?
- Pasá a **HOY** y buscá el `Guardar`. Está a 880px.
- Alterná **A · 52** y **B · 44** con el pulgar donde lo tendrías de verdad. ¿B se siente chico o se
  siente en su lugar?
- Con `Guardar` apagado en B: ¿lo ves contra la barra tonal?

## Abierto

- **El punto sigue verde con cambios sin guardar.** El estado *es* `Publicado` y D-19h manda punto +
  texto, así que no está mal — pero lo pendiente no tiene punto propio. Nombrado, no resuelto.
- **La barra no se esconde nunca.** No se midió una que se oculte mientras está limpio; sería otro eje.
- **`Publicar` no está en esta ronda.** El editor de un publicado no lo tiene: vive en la hoja del
  borrador (078).
- No confirmado en dispositivo real.
