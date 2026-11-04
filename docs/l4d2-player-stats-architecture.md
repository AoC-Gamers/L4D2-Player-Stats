# L4D2-Player-Stats Architecture

Este documento describe las reglas técnicas estables del core de `L4D2-Player-Stats`.

Su foco es:

- lifecycle
- identidad
- persistencia
- fuentes de tracking
- integración con otros plugins

## Organización interna del core

El artefacto sigue siendo un único `l4d2_player_stats.smx`. `l4d2_player_stats.sp` define los callbacks propios que reciben llamadas externas y delega a entradas internas sin cambiar sus firmas públicas.

| Directorio o archivo | Responsabilidad |
|---|---|
| `inputs/` | Lee eventos, forwards, comandos y natives; transforma payloads externos en datos locales. El adaptador de Player-Skills libera sus `KeyValues` antes de llamar al módulo. |
| `types/` | Define observaciones, resultados y razones de descarte para rutas tipadas. |
| `damage/` | Resuelve la autoridad y la base numérica de Witch y daño ordinario migrado. |
| `modules/` | Escribe métricas de combate, precisión, infectados, survivability/soporte, utilidad, Scavenge, sesiones Tank y consecuencias de Skills. |
| `runtime/` | Mantiene contexto de modo, bindings, sustituciones y ciclo de vida de ronda. |
| `queries.sp` | Calcula filtros, rankings y colecciones de lectura usados por API y presentación. |
| `trace.sp` | Conserva `Stats_Debug` y agrega contexto local para las rutas cubiertas en [traza](l4d2-player-stats-trace-coverage.md). |
| `api/` y `presentation/announce.sp` | Serializan el contrato público, emiten forwards y presentan resultados. La presentación conserva junto su formato de chat y consola porque ambos comparten helpers. |

La sesión Tank atacante y su correlación terminal D2 están integradas; el cierre E2 liquida o descarta operaciones pendientes antes de congelar el snapshot. El smoke local verificó una parte de los casos Tank, el cierre duplicado de `round_end` y rutas de sustitución síncrona y tardía. Esto no cubre toda la matriz ni establece equivalencia operativa completa. El detalle vigente de implementación, evidencia y casos pendientes está en el [plan](l4d2-player-stats-refactor-plan.md), la [traza](l4d2-player-stats-trace-coverage.md) y el [registro de smoke](l4d2-player-stats-smoke.md).

## Round Model

El core distingue dos estados:

- `round active`
- `round live`

Durante la finalización existe además una fase interna `closing`: corta nuevas
escrituras ordinarias antes de emitir `PlayerStats_OnRoundEnded` y mostrar el
resultado. Una reentrada que cambie o reinicie el snapshot impide que el
presentador anuncie datos de la ronda nueva como si fueran los de la cerrada.
Antes de congelar el snapshot, el cierre D2/E2 llama al finalizador de
operaciones Tank de esa ronda y generación de mapa. Este finalizador conserva
las operaciones ya aplicadas y descarta con razón las que no tienen evidencia
terminal suficiente o contexto vigente; no infiere ni añade daño. El orden y
las rutas de reentrada se describen en el [ciclo de cierre](l4d2-player-stats-close-lifecycle.md).

### round active

La ronda existe a nivel técnico y el core puede:

- resetear estructuras
- inicializar snapshot
- refrescar contexto de modo

Todavía no implica contar estadísticas.

### round live

La ronda ya empezó de verdad para efectos de stats.

Desde este punto el core puede contar:

- daño
- kills
- FF
- soporte
- consumibles
- arrojables
- pressure infected

## Live Signals

La entrada efectiva a `live` se determina así:

1. `OnRoundIsLive()` cuando la biblioteca `readyup` está presente.
2. `L4D_OnFirstSurvivorLeftSafeArea_Post` como autoridad cuando `readyup` no está presente.

Con `readyup` presente, una consulta que encuentre el saferoom despejado no
sustituye su señal. La ruta de carga tardía y el caso de inicialización con el
saferoom ya despejado aún requieren smoke específico; véase el [registro
operativo](l4d2-player-stats-smoke.md).

La regla es única:

- antes de live, no contar
- después de live, contar

## Lifecycle Scope By Mode

El scope de serie natural depende del modo:

- `Coop` -> ronda o intento del capítulo
- `Survival` -> run
- `Versus` -> mitad survivor
- `Scavenge` -> mitad survivor

En competitivo no se mezclan ambos lados en un mismo snapshot histórico survivor.

## Identity Model

La identidad persistente se resuelve así:

### Humanos

- `accountId` como clave principal
- `auth` como respaldo

### Bots survivor

Los bots survivor se modelan por continuidad del slot o personaje, no como cuenta.

### Bots infected

Los bots infected no se sostienen como columnas persistentes individuales.

Cuando hace falta mostrarlos:

- se agregan en una sola columna `IA`

## Replace Model

Eventos base:

- `player_bot_replace`
- `bot_player_replace`

La política actual es:

- si vuelve el mismo jugador persistente, el flujo continúa
- si entra otro jugador distinto, se snapshottea al saliente y el slot live se limpia
- el snapshot del saliente queda disponible de forma transitoria para rehidratación

Notas de implementación:

- buffer circular de `16`
- clave `accountid:timestamp`
- un hook público para interceptar la sustitución
- una vía pública para reaplicar manualmente el snapshot al slot

Si un consumidor bloquea la rehidratación automática:

- el slot queda limpio hasta que otro plugin decida reaplicarlo

## Tracking Sources

El core usa un modelo híbrido:

- `game events` para hechos estadísticos genéricos
- `left4dhooks` para atribución fuerte y estados complejos

### Usar game events para

- daño bruto
- kills
- common kills
- FF
- consumibles
- arrojables
- heals
- revives
- rescues

### Usar left4dhooks para

- incapacitations con mejor atribución
- estados de control survivor
- vomit attribution
- señales de lifecycle más confiables

## Kill Semantics

La regla oficial del core es:

- `kill` = último golpe válido
- `damage` = contribución total

`PlayerStats` no redefine una kill por mérito de daño acumulado.

La semántica especial de skills vive fuera de este plugin.

## Integration Rule

La regla del stack queda así:

- `PlayerStats` acumula hechos genéricos y continuos
- `PlayerSkills` detecta skills y sesiones semánticas complejas

`PlayerStats` ya consume skills agregables, pero no intenta replicar trackers complejos de bosses o detecciones especiales de alto nivel.

## Reduced-Team Versus Context

En `Versus`, el core detecta contexto reducido cuando:

- `survivor_limit == z_max_player_zombies`
- ambos son mayores que `0`
- existe al menos una clase SI habilitada por límites

El contexto expuesto representa solo la topología del enfrentamiento:

- `Versus1v1`
- `Versus2v2`
- `Versus3v3`
- `Versus4v4`
- `CustomTeamVersus`

Las reglas del pool SI quedan separadas en:

- `siPoolMask`
- `enabledSiClassCount`

Eso permite que un modo competitivo defina su propia semántica sin convertirla en categorías cerradas del core.
