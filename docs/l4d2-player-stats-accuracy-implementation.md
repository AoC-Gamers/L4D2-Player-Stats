# L4D2-Player-Stats Accuracy Implementation

Este documento fija cómo implementar accuracy en `L4D2-Player-Stats` sin copiar ciegamente el plugin legacy.

La meta es definir:

- qué debe medir `sm_mvp_acc`
- qué datos base necesita el core
- qué parte vale la pena portar del legacy
- qué parte conviene dejar fuera en la primera versión

## Goal

`sm_mvp_acc` debe mostrar una tabla clara de precisión para survivors.

Debe integrarse con el modelo moderno de `PlayerStats`, no como un bloque aislado.

La primera versión debe resolver:

- precisión de la ronda actual
- tabla en consola
- datos consistentes por arma o familia de armas

## Command Shape

El comando nuevo queda así:

- `sm_mvp_acc`

Comportamiento esperado:

- renderiza una tabla de accuracy en la consola del usuario
- si lo ejecuta servidor, renderiza la tabla en consola servidor

Extensiones futuras posibles:

- `sm_mvp_acc more`
- `sm_mvp_acc game`
- `sm_mvp_acc team`
- `sm_mvp_acc all`

La primera versión no necesita esas variantes.

## Product Questions

La accuracy debe poder responder al menos estas preguntas:

- cuántos disparos hizo cada survivor
- cuántos impactos consiguió
- cuál fue su porcentaje de precisión
- cuál fue su porcentaje de headshots sobre impactos
- cómo se reparte eso por familia de armas

## Data Model

Accuracy no debe mezclarse dentro de `combat`.

Debe vivir en un bloque nuevo:

- `accuracy`

## `accuracy`

Campos base por jugador:

- `shotgunShots`
- `shotgunHits`
- `shotgunHeadshots`
- `smgRifleShots`
- `smgRifleHits`
- `smgRifleHeadshots`
- `sniperShots`
- `sniperHits`
- `sniperHeadshots`
- `pistolShots`
- `pistolHits`
- `pistolHeadshots`

Campos opcionales para una segunda versión:

- `tankHits`
- `tankHeadshots`
- `siHits`
- `siHeadshots`
- `meleeSwings`
- `meleeHits`

## Weapon Families

Para la primera versión conviene mantener el agrupamiento del legacy:

- `Shotgun`
- `SMG/Rifle`
- `Sniper`
- `Pistol`

Motivo:

- mantiene la tabla compacta
- evita ruido por arma individual
- es suficiente para reemplazar `acc` de forma útil

No conviene arrancar con:

- una fila por arma exacta
- stats separadas por `uzi`, `silenced_smg`, `ak47`, etc.

Eso puede venir después si se necesita exportación más fina.

## Event Sources

La accuracy necesita dos tipos de información:

1. disparos realizados
2. impactos logrados

### Shots

Fuente principal:

- `weapon_fire`

Uso:

- identificar familia de arma
- incrementar contador de disparos

La clasificación de arma debe apoyarse en:

- `l4d2util_constants.inc`
- `l4d2util_weapons.inc`

En particular:

- `WeaponNameToId()`
- `WeaponId`

Eso evita heurísticas frágiles por substring y deja estable el mapeo de:

- shotgun
- smg/rifle
- sniper
- pistol

## Hits

Fuentes principales:

- `player_hurt`
  - impactos a `SI`
  - impactos a `Tank`
  - friendly fire si alguna vez se decide mostrarlo aparte
- `infected_hurt`
  - impactos a `Witch`
- `infected_death`
  - no sirve por sí solo para accuracy, pero sí como apoyo de interpretación

### Headshots

Si el evento trae flag confiable de headshot, se usa.

Si no existe una señal limpia y estable para todos los casos, la primera versión puede:

- omitir headshots
- o dejarlos solo para impactos contra `SI` cuando el evento lo soporte claramente

No conviene inventar headshots con heurísticas débiles.

## Accuracy Math

Reglas:

- `accuracy% = hits / shots * 100`
- `headshot% = headshots / hits * 100`

Si el denominador es `0`:

- el porcentaje debe imprimirse como `0%`

## Console Table

La tabla objetivo de primera versión debería verse así:

```text
| Accuracy Stats -- Round 2                                                   |
|-----------------------------------------------------------------------------|
| Player             | Shotgun      | SMG/Rifle   | Sniper      | Pistol      |
|-----------------------------------------------------------------------------|
| Coach              | 12 / 30  40% | 45 / 90 50% |  0 /  0  0% |  4 / 10 40% |
| >lechuga           |  8 / 20  40% | 30 / 60 50% |  2 /  4 50% |  0 /  0  0% |
|-----------------------------------------------------------------------------|
```

Si entran headshots en v1, el formato puede pasar a:

- `hits/shots acc hs`

Ejemplo:

- `45/90 50% 22%`

## Ranking

La accuracy no debe mezclarse con:

- `sm_mvp`
- `sm_mvp_rank`

Debe ser un dominio aparte.

Por ahora no hace falta un `accuracy mvp`.

Primero conviene resolver:

- medición correcta
- tabla estable

## API Direction

Si accuracy entra al core, también debe entrar al snapshot público.

El bloque esperado sería:

- `player`
  - `accuracy`
    - `shotgun_shots`
    - `shotgun_hits`
    - `shotgun_headshots`
    - `smg_rifle_shots`
    - `smg_rifle_hits`
    - `smg_rifle_headshots`
    - `sniper_shots`
    - `sniper_hits`
    - `sniper_headshots`
    - `pistol_shots`
    - `pistol_hits`
    - `pistol_headshots`

## Scope For V1

La primera implementación debe incluir solo esto:

- bloque `accuracy` en `types.sp`
- tracking por `weapon_fire`
- tracking por `player_hurt` e `infected_hurt`
- tabla `sm_mvp_acc`
- salida solo de ronda actual

## Deferred

Queda fuera de v1:

- `game` acumulado entre mapas
- detalle `more`
- `team / all / other`
- paneles automáticos al final de ronda
- infected accuracy
- melee accuracy
- breakdown por arma exacta

## Open Questions

Antes de codificar, todavía hay que cerrar estas decisiones:

1. si headshots entran en v1 o v2
2. si Tank/Witch cuentan dentro de alguna familia o quedan fuera del panel inicial
3. si el porcentaje debe usar:
   - `hits / shots`
   - o lógica especial para shotgun por pellets
4. si la tabla debe ordenar por:
   - total hits
   - accuracy%
   - o daño total como tie-break

## Recommended Path

Orden recomendado de implementación:

1. agregar `accuracy` al modelo
2. mapear armas a familias
3. contar `shots`
4. contar `hits`
5. renderizar `sm_mvp_acc`
6. validar con logs en servidor
7. recién después discutir `more` y `game`

## Current Rule

`sm_mvp_acc` debe nacer como una tabla simple y correcta.

No hay que portar toda la complejidad del legacy de una vez.

Primero:

- que mida bien
- que explique bien
- que encaje bien con el modelo moderno
