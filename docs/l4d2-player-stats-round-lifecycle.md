# L4D2-Player-Stats Round Lifecycle

Este documento fija cuándo una ronda debe considerarse realmente viva para efectos de tracking en `L4D2-Player-Stats`.

La meta es evitar contar estadísticas en warmup, saferoom pre-live o estados previos al inicio real de la mitad.

## Goal

El core no debe depender de una idea abstracta de “modo competitivo” para decidir cuándo empezar a contar estadísticas.

La pregunta correcta es más simple:

- la ronda ya está viva o no

## Working Model

El lifecycle mínimo del core debe separarse en dos estados:

- `round active`
- `round live`

### `round active`

La ronda existe a nivel técnico:

- el mapa cargó
- ocurrió `round_start`
- el core puede inicializar o resetear estructura interna

Pero todavía no implica que las estadísticas deban empezar a contar.

### `round live`

La ronda ya empezó de verdad para efectos de stats.

Desde este punto el core puede contar:

- daño
- kills
- deaths
- incaps
- friendly fire
- consumibles usados
- arrojables usados
- soporte survivor
- pressure de infected

## Preferred Signal When ReadyUp Exists

Si la librería `readyup` está disponible, la señal preferida para pasar a `round live` debe ser:

- `OnRoundIsLive()`

Ese forward representa mejor el inicio real de una mitad competitiva que cualquier evento del juego base.

## Fallback Signal Without ReadyUp

Si `readyup` no está disponible, la señal preferida debe ser:

- `L4D_OnFirstSurvivorLeftSafeArea_Post`

Y como fallback secundario:

- `player_left_start_area`

Eso cubre modos normales y mantiene una frontera razonable entre:

- pre-live
- live

## Coop Findings From Real Runs

En `Coop`, el cierre de una ronda no depende de una sola señal canónica.

En logs reales de una campaña completa se observaron al menos estos patrones:

- capítulos intermedios:
  - `map_transition`
- intento fallido de un mapa final:
  - `round_end`
- cierre exitoso del mapa final:
  - `finale_win`

Eso implica que en `Coop` no es correcto asumir que:

- `round_end` siempre llega
- `map_transition` siempre representa el mismo tipo de cierre
- `OnMapEnd` es un buen punto primario para imprimir resultados visibles

La lectura correcta es:

1. usar `round_end` si aparece
2. usar `map_transition` como cierre natural de capítulos intermedios
3. usar `finale_win` como cierre natural del final exitoso
4. dejar `OnMapEnd` solo como fallback defensivo para persistencia

### Consecuencia para Broadcasts

Si la impresión visible de MVP o resumen depende solo de `OnMapEnd`, puede llegar demasiado tarde:

- el mapa ya está en transición
- el chat puede no mostrarse de forma confiable
- la consola puede sobrevivir más tiempo que el chat

Por eso, en `Coop`, los broadcasts visibles deben preferir:

- `round_end`
- `map_transition`
- `finale_win`

y no esperar a `OnMapEnd` como punto principal de salida.

### Consecuencia para Restarts

También se observó un caso real de retry del mismo mapa final:

- se cerró un intento del mapa
- luego volvió a empezar otra ronda en el mismo mapa
- eso representa un restart real del contexto `Coop`

Entonces, para `Coop`, un restart no debe modelarse solo con señales administrativas.

También debe contemplarse el patrón:

- mismo mapa
- nueva ronda
- intento previo terminado sin transición natural al siguiente mapa

Eso representa un retry funcional del capítulo actual.

## What Should Not Count Before Live

Por defecto, estas categorías no deben contar antes de `round live`:

- `SI` damage
- `Tank` damage
- `Witch` damage
- common kills
- special kills
- deaths
- incaps
- friendly fire
- revives
- heals
- rescues
- consumibles usados
- arrojables usados
- infected pressure

## What Can Exist Before Live

Antes de `round live`, el core solo necesita:

- inicializar la ronda
- registrar presencia básica si hace falta
- preparar estructuras internas

No hace falta producir estadísticas visibles todavía.

## Why This Is Better Than Gamemode Checks

Esta política es mejor que condicionar el core al modo de juego porque:

- funciona en competitivo con `readyup`
- funciona en modos normales sin `readyup`
- evita acoplar la semántica de stats al nombre del gamemode
- separa claramente lifecycle de tracking

## Integration Rule

La integración recomendada queda así:

1. detectar si `readyup` está cargado
2. si existe:
   - usar `OnRoundIsLive()`
3. si no existe:
   - usar `L4D_OnFirstSurvivorLeftSafeArea_Post`
   - o `player_left_start_area` como respaldo

## Current Rule

`PlayerStats` no debe empezar a contar estadísticas sensibles al flujo de la partida hasta que la ronda esté viva.

La fuente que declara ese momento puede cambiar según el stack cargado.

Pero la semántica del core debe seguir siendo una sola:

- antes de live, no contar
- después de live, contar

## Snapshot After Round End

Cuando ocurre `round_end`, el core deja de considerar la ronda como activa para tracking.

Eso no significa que el snapshot desaparezca inmediatamente.

La política actual es:

- `round_end` cierra el tracking
- el snapshot de la ronda terminada sigue disponible para consulta
- los broadcasts y wrappers legacy pueden seguir imprimiendo ese snapshot final

Esto permite compatibilidad práctica con:

- `PlayerStats_OnRoundFinalized`
- `PLAYSTATS_BroadcastRoundStats()`
- wrappers de consulta que necesiten leer la ronda ya terminada
- la impresión de una tabla resumen en la consola del servidor al cierre de la ronda
