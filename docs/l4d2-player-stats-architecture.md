# L4D2-Player-Stats Architecture

Este documento describe las reglas técnicas estables del core de `L4D2-Player-Stats`.

Su foco es:

- lifecycle
- identidad
- persistencia
- fuentes de tracking
- integración con otros plugins

## Round Model

El core distingue dos estados:

- `round active`
- `round live`

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

Orden preferido:

1. `OnRoundIsLive()` si `readyup` existe
2. `L4D_OnFirstSurvivorLeftSafeArea_Post`
3. `player_left_start_area` como respaldo

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
- forward `PlayerStats_OnPlayerSubstituted(...)`
- native `PlayerStats_ApplySubstitutionSnapshotToSlot(...)`

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
