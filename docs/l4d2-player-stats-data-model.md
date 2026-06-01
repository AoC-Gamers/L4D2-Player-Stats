# L4D2-Player-Stats Data Model

Este documento fija la forma conceptual y práctica del snapshot de `L4D2-Player-Stats`.

Su objetivo es responder:

- qué bloques existen
- qué significan
- qué parte del modelo ya está implementada

## Goal

El plugin debe sostener un snapshot por ronda suficientemente estable para:

- alimentar resúmenes visibles
- exponer una API legible
- crecer sin agregar campos aislados sin dueño conceptual

## Player Blocks

La estructura del jugador se organiza por bloques.

## identity

Describe al ocupante actual o histórico del slot.

Ejemplos:

- nombre
- identidad persistente
- team
- slot

## combat

Representa aporte ofensivo survivor.

Campos actuales relevantes:

- `siDamage`
- `smokerDamage`
- `boomerDamage`
- `hunterDamage`
- `spitterDamage`
- `jockeyDamage`
- `chargerDamage`
- `tankDamage`
- `tankHits`
- `witchDamage`
- `witchHits`
- `commonKills`
- `smokerKills`
- `boomerKills`
- `hunterKills`
- `spitterKills`
- `jockeyKills`
- `chargerKills`
- `tankKills`
- `witchKills`
- `ffGiven`

Regla:

- `kill` = último golpe válido
- `damage` = contribución total

Fallback local de bosses:

- `tankHits`
- `witchHits`

sirven para el modo base sin `PlayerSkills`, donde `stats` solo puede sostener
una lectura compacta `dmg/hit`.

Nota:

- `SI` no incluye bosses;
- `Tank` y `Witch` viven como categorías separadas dentro del mismo bloque
  survivor de combate.

## combat_assists

Representa contribución survivor a kills SI no-boss cuando otro jugador hizo
el último golpe acreditado.

Campos actuales:

- `siKillAssists`
- `siAssistDamage`
- `smokerKillAssists`
- `boomerKillAssists`
- `hunterKillAssists`
- `spitterKillAssists`
- `jockeyKillAssists`
- `chargerKillAssists`
- `smokerAssistDamage`
- `boomerAssistDamage`
- `hunterAssistDamage`
- `spitterAssistDamage`
- `jockeyAssistDamage`
- `chargerAssistDamage`

Reglas:

- `*_KillAssists`
  - cuenta contribuciones válidas a kills SI no-boss
- `*_AssistDamage`
  - usa el daño visible acreditado por `PlayerSkills`
  - puede venir de:
    - `kill_event.assists`
    - `skill_event.assists` cuando la skill principal absorbió una kill default
- este bloque no reemplaza `combat`
  - lo complementa
- `combat`
  - sigue siendo daño continuo y kill principal
- `combat_assists`
  - modela solo contribución de cierre semántico de kill

## boss_detail

Representa el detalle enriquecido de daño survivor a bosses cuando
`PlayerSkills` finaliza una `boss_session`.

Campos actuales:

- `tankDamage`
- `tankShots`
- `witchDamage`
- `witchShots`

Reglas:

- este bloque se llena desde `boss_session.damage_entries`
- no reemplaza `combat`
- complementa el snapshot base local de bosses
- su semántica visible es:
  - `Tank = dmg/shots`
  - `Witch = dmg/shots`

Relación con `combat`:

- `combat.tankDamage` / `combat.witchDamage`
  - siguen siendo el acumulado local general
- `combat.tankHits` / `combat.witchHits`
  - describen el fallback sin `PlayerSkills`
- `boss_detail`
  - describe el camino enriquecido con autoridad de `PlayerSkills`

## survivability

Representa lo que le ocurrió al survivor.

Campos actuales relevantes:

- `deaths`
- `incaps`
- `deathBySurvivor`
- `deathByInfectedPlayer`
- `deathByInfectedAI`
- `incapBySurvivor`
- `incapByInfectedPlayer`
- `incapByInfectedAI`

## support

Representa ayuda dada o recibida.

Campos actuales:

- `healsGiven`
- `healsReceived`
- `revivesGiven`
- `revivesReceived`
- `rescuesGiven`
- `rescuesReceived`

## items

Representa consumibles usados.

Campos actuales:

- `pillsUsed`
- `adrenalineUsed`
- `medkitsUsed`
- `defibsUsed`

## utils

Representa arrojables y efectos asociados.

Campos actuales:

- `molotovsThrown`
- `pipebombsThrown`
- `vomitjarsThrown`
- `zombiesIgnited`
- `playersBiled`
- `tanksBiled`

## accuracy

Representa precisión agregada por familia de armas.

Familias actuales:

- `shotgun`
- `smg_rifle`
- `sniper`
- `pistol`

También existe detalle por arma para la vista de consola.

## skills integration

`PlayerStats` ya no modela un bloque `skills` propio.

Regla:

- la autoridad semántica de skills vive en `L4D2-Player-Skills`
- `PlayerStats` solo consume consecuencias útiles para su snapshot
- si una skill implica muerte de SI
  - `PlayerStats` traduce esa consecuencia a `combat.*Kills`
  - esa traducción viene de `skill_event.properties`
  - no mantiene un contador paralelo de la skill como producto interno

## infected_grab

Bloque competitivo de infected por control y daño de agarre.

Campos actuales:

- `smokerDamage`
- `hunterDamage`
- `jockeyDamage`
- `chargerDamage`
- `totalDamage`
- `tongueGrabs`
- `hunterPounces`
- `jockeyRides`

## infected_support

Bloque competitivo de infected de soporte.

Campos actuales:

- `boomerVomitVictims`
- `spitterDamage`

## tank

El tank no vive como bloque simple por jugador.

Su unidad es:

- `tank_session`
- `tank_controller`

Esto permite modelar:

- múltiples tanks
- cambio de control humano
- continuidad en bot

## scavenge

`Scavenge` agrega métricas específicas del objetivo.

Campos actuales relevantes:

- `gascansPoured`
- `gascansDropped`
- `gascansDestroyed`

## Round Totals

Además de los bloques por jugador, el snapshot guarda totales por ronda.

Ejemplos:

- daño total a SI
- daño total de asistencia a SI
- kill assists totales a SI
- common kills totales
- FF total
- consumibles totales
- arrojables totales
- pressure infected total

Estos totales sirven para:

- porcentajes
- MVP
- LVP
- ranking relativo

## Context Block

El snapshot de ronda también guarda contexto estructural.

Campos actuales relevantes:

- `baseMode`
- `seriesScope`
- `versusContext`
- `versusTeamSize`
- `siPoolMask`
- `enabledSiClassCount`
- `scavengeRoundNumber`
- `secondHalf`

## Design Rules

Toda nueva estadística debe cumplir dos condiciones:

1. responder una pregunta real del producto
2. pertenecer claramente a un bloque conceptual

Si no cumple ambas, no debe entrar al snapshot base.

## API Direction

La API pública debe reflejar esta estructura por bloques, no una lista plana sin organización.

Eso mantiene alineados:

- tracking
- render
- histórico
- consumo externo
