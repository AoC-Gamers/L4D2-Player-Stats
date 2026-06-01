# L4D2-Player-Stats-Series

`L4D2-Player-Stats-Series` es un consumidor liviano de `L4D2-Player-Stats`.

Escucha snapshots finalizados de ronda y los agrupa en series cortas en memoria
usando boundaries dependientes del modo.

## Responsabilidad

- consumir snapshots finalizados de `PlayerStats`
- mantener un conjunto pequeño de series activas/cerradas en memoria
- detectar cuándo debe comenzar una serie nueva según modo base y lifecycle

Este plugin no intenta reemplazar `L4D2-Player-Stats`.

`L4D2-Player-Stats` sigue siendo la fuente de verdad del snapshot de ronda.
`L4D2-Player-Stats-Series` solo agrega esos snapshots en una unidad temporal
superior.

Este módulo es intencionalmente interno a la familia `PlayerStats`.

- no publica librería SourceMod propia
- no publica natives públicos
- no publica forwards públicos

También es opcional. No forma parte del artefacto principal de `PlayerStats`.

## Boundary Rules

La detección de series sigue las reglas de lifecycle descritas en:

- [l4d2-mode-lifecycle-business-rules.md](C:/GitHub/L4D2-Player-Stats/docs/l4d2-mode-lifecycle-business-rules.md)

Comportamiento actual:

- `Coop`
  - el scope de serie es `mission`
  - una serie nueva comienza cuando cambia la mission key
- `Versus`
  - el scope de serie es `mission`
  - una serie nueva comienza cuando cambia la mission key
- `Scavenge`
  - el scope de serie es `map`
  - una serie nueva comienza cuando cambia el mapa
- `Survival`
  - el scope de serie es `map`
  - una serie nueva comienza cuando cambia el mapa

La `mission key` actual se deriva del prefijo del mapa antes de `m`, por ejemplo:

- `c2m3_coaster` -> `c2`
- `l4d_hospital01_apartment` -> `l4d_hospital01_apartment`

## Lifecycle

- los snapshots solo se aceptan cuando `PlayerStats` finaliza una ronda
- el plugin mantiene una sola serie activa
- las series viejas quedan en un buffer corto de cerradas
- el storage es solo en memoria

No hay persistencia, historial en disco ni archivo de largo plazo.

## Commands

- `sm_stats_series`
  - imprime el buffer actual de series en memoria
- `sm_stats_series <id>`
  - imprime los totales agregados de la serie pedida
  - imprime la tabla agregada por jugador de la serie pedida
  - luego imprime la tabla de entries de esa misma serie

## Table Behavior

`sm_stats_series <id>` imprime la tabla agregada por jugador ordenada por contribución competitiva:

- daño total de combate: `SI + Tank + Witch` descendente
- `Common Infected` descendente
- `Friendly Fire` ascendente
- `Rounds` descendente
- nombre de `Player` ascendente

Eso mantiene las filas survivor más relevantes cerca del tope sin introducir un score MVP separado.

## Build

Comando de compilación de ejemplo:

```powershell
& 'C:\sourcemodAPI\addons\sourcemod\scripting\spcomp.exe' `
  'C:\GitHub\L4D2-Player-Stats\sourcemod\scripting\l4d2_player_stats_series.sp' `
  '-oC:\SourcemodCompiled\l4d2_player_stats_series.smx' `
  '-iC:\GitHub\L4D2-Player-Stats\sourcemod\scripting\include' `
  '-iC:\GitHub\L4D2-Player-Stats\sourcemod\scripting' `
  '-iC:\sourcemodAPI\addons\sourcemod\scripting\include'
```
