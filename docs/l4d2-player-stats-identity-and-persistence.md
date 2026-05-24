# L4D2-Player-Stats Identity And Persistence

Este documento fija cómo debe resolver `L4D2-Player-Stats` la identidad de jugadores y cuánto debe durar la persistencia de sus estadísticas.

## Goal

El core debe evitar dos errores comunes:

- perder estadísticas cuando un jugador se desconecta y vuelve a entrar
- atar toda la estadística al `client index` actual

Al mismo tiempo, no necesita construir un historial entre mapas ni una base de datos persistente.

## Persistence Scope

La persistencia del core se divide en dos niveles:

- persistencia detallada por ronda/mapa actual
- historial agregado de rounds dentro de la campaña actual

La regla queda así:

- sí debe sobrevivir a reconnects
- sí debe sobrevivir a reemplazos entre player y bot
- sí puede agregar resúmenes cuando el mapa cambia de forma natural dentro de la misma campaña
- no debe sobrevivir al inicio de una campaña nueva

## Working Rule

Las estadísticas detalladas deben persistir mientras el mapa actual siga siendo el mismo contexto de juego.

Cuando el mapa cambia:

- la ronda detallada se resetea
- pero el resumen del round puede agregarse al historial de la campaña actual

La consulta del historial agregado debe poder filtrarse por mapa de la misión actual.

Regla recomendada:

- sin argumentos: consultar el mapa actual
- con nombre de mapa: consultar ese mapa dentro de la misión actual
- con `all`: consultar toda la misión actual

Cuando comienza una campaña nueva:

- se resetea el estado detallado
- se resetea también el historial agregado

## Human Players

Para jugadores humanos, la identidad persistente debe apoyarse principalmente en:

- `accountId`

Y como respaldo:

- `auth`

Eso permite que un jugador:

- se desconecte
- vuelva a entrar
- y recupere su slot persistente del mapa actual

## Bots

Los bots no deben tratarse como identidad de cuenta.

La política del proyecto es:

- los bots se modelan como personaje

Eso significa que la persistencia del bot depende del slot o personaje jugable que está representando, no de una cuenta artificial.

## Replace Events

Los eventos importantes para mantener continuidad de slot son:

- `player_bot_replace`
- `bot_player_replace`

La intención es que el slot persistente siga representando la continuidad del personaje en el mapa actual, aunque cambie quién lo controla.

## Ownership Policy

La política recomendada de ownership es esta:

- si un humano se desconecta y un bot lo reemplaza, el bot continúa el mismo slot persistente
- si un humano toma control de un bot, el humano continúa el slot persistente del personaje

Eso mantiene continuidad estadística sin partir artificialmente una misma participación jugable en dos registros distintos.

## Non-Goals

Este sistema no debe:

- crear historial por campaña completa
- persistir datos a disco
- construir una base de datos de sesiones pasadas

Todo eso queda fuera del alcance del core actual.

## Runtime Model

El modelo recomendado para `PlayerStats` es:

- un slot persistente interno por mapa
- una referencia runtime del `client` actual
- una referencia persistente del jugador o personaje

El `client index` debe verse como un puntero temporal al jugador online, no como la identidad primaria del storage.

## Implemented Shape

La implementación actual del core ya sigue esta forma:

- slots persistentes por mapa
- mapping runtime `client -> slot`
- reatachado por identidad persistente para humanos
- reatachado por personaje para bots survivor

Eso significa que el storage principal ya no depende del `client index` como índice de arreglo.

## Expected Behavior

Con esta política, el sistema debe comportarse así:

- reconnect dentro del mismo mapa: conserva stats
- cambio player/bot dentro del mismo mapa: conserva stats del slot
- cambio de mapa: resetea stats persistentes
- announce y rankings del resumen de ronda deben poder seguir leyendo slots persistentes aunque el jugador ya no esté online

## Current Rule

La identidad persistente de `PlayerStats` existe principalmente para proteger la coherencia del mapa actual.

El historial agregado entre mapas de una misma campaña solo guarda resúmenes de round y debe cortarse cuando el director limpia los campaign scores para una campaña nueva.

No existe para construir historial largo, sino para que las estadísticas no se rompan por:

- reconnect
- replace
- cambios de controlador del personaje
