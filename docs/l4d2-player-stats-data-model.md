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
- `witchDamage`
- `commonKills`
- `smokerKills`
- `boomerKills`
- `hunterKills`
- `spitterKills`
- `jockeyKills`
- `chargerKills`
- `tankKills`
- `ffGiven`

Regla:

- `kill` = último golpe válido
- `damage` = contribución total

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

## skills

Representa skills consumidas desde `L4D2-Player-Skills`.

Contadores actuales:

- `skeets`
- `skeetMelees`
- `deadstops`
- `boomerPops`
- `levels`
- `crowns`
- `tongueCuts`
- `smokerSelfClears`
- `instaKills`

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
- `historyScope`
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
