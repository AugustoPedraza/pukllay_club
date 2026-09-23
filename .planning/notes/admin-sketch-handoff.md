# Admin — handoff de sketches (2026-09-22)

Escrito para retomar después de un `/clear`. Cubre **dónde quedó el linaje de sketches del admin**,
qué falta decidir, y en qué orden. No repite lo que ya está en los README de cada sketch ni en
`admin-redesign-scope.md` — apunta a ellos.

## El plan acordado con el desarrollador

```
1   decidir la 069 (Estantes)          ← pendiente
2   decidir la 075 (el remedio)        ← pendiente
3   /gsd-sketch --wrap-up              ← recién DESPUÉS de las dos
```

El wrap-up va al final a propósito: es lo que empaqueta las decisiones en el skill
`sketch-findings-pukllay_club`, y ese skill tiene que salir conteniendo 069 y 075 ya resueltas.

---

## Dónde quedó el linaje

Sketches del admin, en dos generaciones:

```
059-065   el rediseño completo (fase 01.8.2)      todos decididos
066-068   Estantes, primera vuelta                068 superseded por 069
069       Estantes, REINICIO                      winner: null   ← PENDIENTE
070-071   Web / Juegos rediseñados                decididos
072-074   el editor: spine, estado BGG, header    decididos
075       el remedio mientras está sucio          PENDING REVIEW  ← PENDIENTE
076-079   el escenario crear → editar → publicar → ciclo   decididos
```

**079 se decidió el 2026-09-22** y dejó el editor así: el ⋮ como único control de la barra abriendo
una hoja de ciclo · el tinte de d37 + un lápiz sutil como affordance · la edición **en hojas** (d33) ·
el estado explícito en una franja bajo la barra · el verbo colapsado (`Retirar` = despublicar) · el
cuerpo con el ritmo de la ficha pública.

---

## 1 · La 069 (Estantes) — `winner: null`

`/home/apedraza/projects/pukllay_club/.planning/sketches/069-estantes-ubicar/`

> *"Estante UI restart (01.8.2): the Estantes screen as the place to pick up and put back a game —
> search that resolves to one game, the estante picture with it lifted between its neighbours, recent
> lookups, and a secondary management page."*

**Antes de elegir, hay que saber esto** (medido contra `pukllay_club_dev` el 2026-09-22):

```
estantes          1        (se llama L0)
juegos ubicados   1        de 435
sin ubicar        434
```

Y el bloqueo estructural, que **no es de diseño** (`admin-redesign-scope.md:13-25`):

> `game.ex:84` documenta *"at most one shelf per game, no in-shelf position"* y
> `shelves.ex:170-177` (`games_on_shelf/1`) ordena **por nombre**. La premisa entera de la 069 —que
> el orden de los juegos en un estante ES su orden físico de izquierda a derecha— **no tiene columna
> detrás**. Zona, vecinos, el orden del rail, la barra de zonas y los ↑/↓ se apoyan en datos que no
> existen.

La nota lo llama defecto de corrección bajo SC-3 y dice que **bloquea otros cuatro slices** (gaps
#5, #6, #7, #8). Es backend puro (`shelf_position` + migración + backfill + read/write path) y puede
ir primero, independiente de toda decisión visual.

**Lo que hay que decidir**, entonces, es si la 069 se elige **sabiendo que su premisa depende de una
columna que todavía no existe** — o si primero va el slice de datos y la decisión visual se toma
contra datos reales. Las dos son defendibles; lo que no se puede es elegir sin nombrarlo.

Queda también abierto en la nota, textual: *"Focus mode for an expanded estante (centre it, recede
the rest)… Better judged in live LiveView than in a sketch."*

---

## 2 · La 075 (el remedio) — PENDING REVIEW, y la 079 la hizo más difícil

`/home/apedraza/projects/pukllay_club/.planning/sketches/075-admin-remedy-dirty/`

> *"¿Dónde vive el remedio (`Vincular` / `Corregir ID` / `Reintentar`) mientras el editor está sucio
> y el único slot de CTA lo ocupa `Guardar`?"*

**La pregunta cambió de forma, y eso hay que releerlo antes de elegir entre V1/V2/V3/V4.** La 079
eliminó el slot de CTA que la 075 daba por sentado: la barra decidida es `‹ · título · ⋮`, sin
primario. Así que:

- el eje *"el slot está ocupado por `Guardar`"* ya no existe — **`Guardar` bajó al pie**
- y la 075 ronda 3 había agregado un eje ortogonal (*"¿para qué es el CTA de arriba?"*, `Cambia` vs
  `Solo acciones de página`) que **la 079 contestó por otra vía**: arriba no hay ninguna acción de
  página, hay un menú

**A quién le pasa esto, medido el 2026-09-22:**

```
enriched     published   385
no_bgg_id    published    41    ← sin bgg_id: el remedio es Vincular
bgg_missing  published     8    ← con un id que no resuelve: Corregir ID o borrarlo
enriched     draft         1
```

**Los 49 están publicados y vivos en la web ahora mismo, sin tapa ni descripción** — los 386
`enriched` tienen tapa y los 49 restantes no, 1:1. Y abren el editor que decidió la 079, donde la
ficha espejada queda casi vacía (check 5i: el hueco de la tapa mide 329px, el 44% de la pantalla) y
**no hay ni diagnóstico ni remedio en ninguna parte**, porque la 079 nunca dibujó el bloque de d38.

`juegos-refine-handoff.md` agrega la mitad de datos: *"`enrichment_status` is filtered by no query
anywhere. A `failed` game is public the moment `status` is `:published`; nothing gates publishing on
BGG answering."* Los 49 siguen siendo **una decisión de datos que nadie tomó**, además de una de UI.

---

## 3 · Un hueco abierto en la 079, que está marcada DECIDIDO

Registrado en su propio README (sección Open) para que no derive, pero conviene tenerlo a mano
porque **toca a las dos decisiones de arriba**:

**El `Guardar` del editor no escribe.** Cada hoja de campo commitea al cerrarse (`setField` escribe y
renderiza) y el CTA del pie sólo hace `snack('Cambios guardados')` (`079/index.html:1621`). Dos
puntos de commit, uno solo escribe.

La 078 ronda 2 midió ese eje —*la hoja guarda* (A) contra *la hoja prepara* (B)— y la ronda 4 lo
retiró, **pero lo retiró para la hoja del borrador, que tiene un solo CTA**. El editor se quedó con
los dos. Las dos salidas son excluyentes:

```
la hoja escribe     el CTA del pie sobra y hay que borrarlo — y con él se va el patrón
                    de `Publicar` que el desarrollador pidió explícitamente
la hoja prepara     vuelve el estado sucio, vuelve el confirmar-al-salir de 074, y el CTA
                    nace muerto: la octava excepción a la prohibición de la 064
```

**Y esto es exactamente el terreno de la 075**, cuya pregunta entera era sobre el estado sucio. Si se
elige *la hoja escribe*, el estado sucio no existe y **la 075 se vuelve moot como eje** (sobrevive
sólo la pregunta de dónde vive el remedio). Si se elige *la hoja prepara*, la 075 sigue viva tal cual
se planteó. **Conviene resolver este hueco ANTES o JUNTO con la 075, no después.**

---

## 4 · Lo que el wrap-up tiene que arreglar

`admin-redesign-scope.md:129-131`, textual:

> **`sketch-findings-pukllay_club` skill is stale.** Last updated 2026-09-13; **zero** mentions of
> sketches 059–065 across its 14 reference files. CLAUDE.md says it is *"Auto-loaded during UI
> implementation"* — left as-is it will feed the replaced design back into the redesign.

Y hoy está peor que cuando se escribió eso: **tampoco conoce 066-079**, que rediseñaron Estantes otra
vez (069), la pestaña Web (070), Juegos otra vez (071) y el editor entero (072-079).

### Otros artefactos stale, que el planning va a leer

| artefacto | problema |
|---|---|
| `01.8.1-UI-SPEC.md` | `status: approved`, fechado **un día antes** de que empezara la 059. `admin-redesign-scope.md:97+` dice *"do not plan against it as-is"* y lista 16 filas superseded |
| `ROADMAP.md:36` y `:186-189` | la fase 01.8.2 está redactada como *"Implement sketches 059–065"*. **No sabe que existen 066-079.** Y 01.8.2 **no tiene fila en la tabla de progreso** (`:265-274`) |
| `STATE.md` | `last_activity: 2026-09-16`, `stopped_at: Phase 01.8.2 context gathered`. Cero menciones de 069-079 |
| `admin-redesign-scope.md` | su tabla de 18 huecos compara sólo contra 059-065. El hueco **creció**, no se achicó |

---

## 5 · Dos pantallas del admin que 069-079 nunca tocó

Del inventario del 2026-09-22, para que no se planifiquen creyendo que están cubiertas:

- **`staff_live/index.ex`** (206 líneas, `/admin/staff`) — `Invitar` / `Quitar` con modal de confirmar.
  Sólo aparece en sketches 062-068. D-19f nombra *"Quitar del staff"* como caso de diálogo, pero
  **ningún sketch lo dibuja**.
- **`band_audit_live.ex`** (118 líneas, `/admin/niveles`) — `Corregir` / `Mantener`. El gap #18 de la
  nota de alcance quiere en su lugar una fila *"Pasar a …"* con el **significado** del nivel. Nunca
  se rediseñó en la generación 069-079.

Y `handle_event("validate")` (`form.ex:74`, `section_live/edit.ex:55`): **no hay sketch de un estado
de error inline** en ninguna parte del linaje.

---

## Cómo retomar

```
/gsd-sketch continuar 069 — decidir el reinicio de Estantes.
              Leé primero .planning/notes/admin-sketch-handoff.md sección 1:
              1 estante, 1 juego ubicado, 434 sin ubicar, y `shelf_position` NO EXISTE
              (games_on_shelf ordena por nombre). Decidir si se elige igual o si
              primero va el slice de datos.
```

```
/gsd-sketch continuar 075 — decidir el remedio, releyendo la pregunta:
              la 079 eliminó el slot de CTA que la 075 daba por sentado.
              Y resolver primero (o junto) el hueco de la sección 3 del handoff:
              si la hoja escribe, la 075 se vuelve moot como eje.
              A quién le pasa: 41 no_bgg_id + 8 bgg_missing, los 49 publicados y vivos.
```

```
/gsd-sketch --wrap-up
```

### Estado del árbol

Último commit del linaje: `e45d815` *docs(sketch-079): DECIDIDO — la edición en la hoja, y la página
queda sin variantes*. `ideas.txt` tiene cambios sin commitear que no son de este trabajo.

```
python3 -m http.server 8765
open http://127.0.0.1:8765/.planning/sketches/079-admin-lifecycle/index.html
node .planning/sketches/079-admin-lifecycle/verify.js     # 36/36
```

El arnés necesita `playwright-core` del caché de npx y usa el Chrome del sistema (`CHROME_BIN`, o
`/usr/bin/google-chrome`); el paquete no trae navegador propio en esta máquina.
