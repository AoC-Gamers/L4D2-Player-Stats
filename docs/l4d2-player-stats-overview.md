# L4D2-Player-Stats Overview

Este documento resume el producto actual de `L4D2-Player-Stats`.

Su objetivo es describir:

- qué hace el plugin
- qué salidas expone
- en qué modos funciona cada salida
- qué partes ya están implementadas

## Goal

`L4D2-Player-Stats` es el agregador de estadísticas de ronda y de histórico corto del stack.

La meta del plugin es:

- acumular estadísticas genéricas y agregables
- exponerlas por API para otros plugins
- imprimir resúmenes y tablas útiles para jugadores y administradores

No busca reemplazar la semántica de `L4D2-Player-Skills`.

## Product Surface

El producto actual se organiza en estas salidas principales.

### Survivor Round Stats

Comandos:

- `sm_stats_mvp`
- `sm_stats_rank`
- `sm_stats_acc`
- `sm_stats_acc_details`
- `sm_stats_items`
- `sm_stats_support`
- `sm_stats_utils`

Cobertura:

- `Coop`
- `Versus`
- `Scavenge`
- `Survival`

Estas vistas responden preguntas como:

- quién lideró daño a SI
- quién hizo más common kills
- quién dio más friendly fire
- qué consumibles y arrojables usó cada survivor
- qué soporte aportó cada survivor
- cómo fue su precisión

### Historical Stats

Comando:

- `sm_stats_history`

Permite consultar el histórico compacto del contexto actual.

La unidad histórica depende del modo:

- `Coop` -> ronda/intento
- `Survival` -> run
- `Versus` -> mitad survivor
- `Scavenge` -> mitad survivor

### Infected Stats

Comando:

- `sm_stats_infect`

Disponible en:

- `Versus`
- `Scavenge`

Se divide en dos tablas:

- `infected_grab`
- `infected_support`

La consola agrega una columna `IA` al final para consolidar bots infected.

### Tank Stats

Comando:

- `sm_stats_tank`

Disponible en:

- `Versus`
- `Scavenge`

La unidad principal es la `tank_session`, con desglose por `tank_controller`.

### Substitution Snapshots

Comando operativo:

- `sm_stats_subs`

Esta capa existe para:

- snapshotear al ocupante saliente de un slot survivor
- permitir restauración automática o manual
- exponer esos snapshots a otros plugins

## Data Exposure

`L4D2-Player-Stats` expone datos por:

- tablas y resúmenes visibles
- API pública de `KeyValues`
- forwards
- natives

La API principal está documentada en:

- [l4d2-player-stats-api.md](C:/GitHub/L4D2-Player-Stats/docs/l4d2-player-stats-api.md)

## Relationship With PlayerSkills

La regla del stack es:

- `L4D2-Player-Stats` acumula estadísticas genéricas y continuas
- `L4D2-Player-Skills` detecta skills y sesiones semánticas complejas

`PlayerStats` ya consume un conjunto acotado de skills agregables, pero no intenta reconstruir toda la lógica de `PlayerSkills`.

## Current Competitive Context

En `Versus`, el plugin ya detecta contexto `NvN` reducido.

Ese contexto hoy sirve como metadata interna:

- `versusContext`
- `versusTeamSize`
- `siPoolMask`
- `enabledSiClassCount`

La clasificación actual describe solo la topología del enfrentamiento:

- `Versus1v1`
- `Versus2v2`
- `Versus3v3`
- `Versus4v4`
- `CustomTeamVersus`

No existe todavía una vista especializada de producto para `1v1`.

## Current State

### Implemented

- survivor stats por ronda
- histórico compacto por modo
- infected stats
- tank stats
- substitution snapshots
- integración base con `PlayerSkills`
- API pública para lectura de snapshots

### Partial

- contexto competitivo reducido como metadata visible por API/logs
- UX de chat para `tank`

### Not Implemented

- renderer especializado para `1v1`
- adaptación automática de `sm_stats_mvp` al contexto `NvN`
