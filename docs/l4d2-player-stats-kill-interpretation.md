# L4D2-Player-Stats Kill Interpretation

Este documento fija la interpretación oficial de `kills`, `damage` y métricas relacionadas dentro de `L4D2-Player-Stats`.

## Goal

`L4D2-Player-Stats` debe producir estadísticas genéricas y agregables.

No debe reinterpretar una muerte especial como si fuera una habilidad.

La semántica de una `kill` en stats no es la misma que la semántica de una `skill` en `L4D2-Player-Skills`.

## Core Rule

La regla principal del sistema es esta:

- `kill` = último golpe válido que mata al objetivo
- `damage` = contribución total de daño al objetivo
- `assist` = contribución de daño sin haber dado el golpe final

Esto separa con claridad:

- quién remató
- quién aportó daño
- quién participó sin quedarse con la kill

## Kills

En `L4D2-Player-Stats`, una kill pertenece al jugador que da el golpe final.

Ejemplo:

- jugador A hace 99% del daño a un `Boomer`
- jugador B hace el 1% final

Resultado:

- `kill` para B
- `damage contribution` para A y B
- `assist` para A, si esa categoría existe o se habilita más adelante

La kill no se reasigna por mérito de daño acumulado.

## Damage

`damage` representa la contribución real hecha al objetivo.

Debe poder agregarse por:

- jugador
- ronda
- juego
- clase de infectado
- tipo de target, cuando aplique

Ejemplos:

- daño a `Smoker`
- daño a `Boomer`
- daño a `Hunter`
- daño a `Tank`
- daño a `Witch`

## Assists

`assist` no debe reemplazar la kill.

Su significado oficial es:

- el jugador hizo daño relevante al objetivo
- pero no fue quien dio el último golpe

La existencia o no de `assist` como stat visible puede decidirse después.

Pero si se implementa, debe seguir esta semántica.

## Generic Stats Vs Skill Stats

`L4D2-Player-Stats` debe registrar hechos generales.

Ejemplos:

- kills
- damage
- assists
- common kills
- FF
- incaps
- deaths

`L4D2-Player-Skills` debe registrar eventos semánticos especiales.

Ejemplos:

- `HunterSkeet`
- `BoomerPop`
- `ChargerLevel`
- `WitchDead` con `crown`

Por eso:

- `PlayerStats` sí debe trackear kills generales por su cuenta
- `PlayerSkills` no debe expandirse para volverse tracker universal de kills

## Special Infected Kills

Para special infected, la kill cuenta para el último golpe válido.

Las stats deben poder separarse por clase:

- `Smoker kills`
- `Boomer kills`
- `Hunter kills`
- `Spitter kills`
- `Jockey kills`
- `Charger kills`
- `Tank kills`

Y en paralelo, el daño a esas clases debe agregarse por separado.

## Common Infected

Los `common kills` son una categoría independiente.

No dependen de skills ni de eventos especiales.

Deben trackearse como estadística general de PvE/PvP.

## Common Vs Uncommon

La categoría `common kills` no debe mezclar infected uncommon.

La política actual del core sigue la misma dirección del legacy:

- `commonKills` cuenta commons regulares
- los uncommons no entran en ese total

La idea es mantener:

- consistencia con `survivor_mvp`
- una lectura más estable de `CI MVP`
- y evitar inflar el total de common kills con variantes especiales del mapa

## Witch And Tank

`Tank` y `Witch` siguen la misma regla base:

- `kill` = último golpe válido
- `damage` = contribución total

Eso no reemplaza la utilidad de las sesiones de boss en `PlayerSkills`.

La política correcta es:

- `PlayerStats` puede usar kills y damage base para agregados
- `PlayerSkills` sigue siendo la fuente de verdad para sesiones complejas y eventos especiales de boss

## Non-Goals

`L4D2-Player-Stats` no debe:

- redefinir una kill como “quien hizo más daño”
- mezclar kill tracking con skill semantics
- convertir toda muerte de infectado en una skill

## Working Rule

Cuando una estadística tenga dos lecturas posibles:

- una lectura semántica especial
- una lectura genérica agregable

la decisión será:

- `PlayerSkills` maneja la lectura semántica
- `PlayerStats` maneja la lectura genérica

En consecuencia:

- `kill` es una estadística genérica
- `skill` es una interpretación especial del evento
