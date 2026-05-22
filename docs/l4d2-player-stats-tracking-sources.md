# L4D2-Player-Stats Tracking Sources

Este documento fija de dónde debe venir cada familia principal de estadísticas en `L4D2-Player-Stats`.

La meta es evitar dos errores:

- depender de eventos del juego cuando `left4dhooks` ofrece una señal más fuerte
- forzar `left4dhooks` en casos donde un `game event` simple ya resuelve bien la stat

## Goal

`L4D2-Player-Stats` debe usar un modelo híbrido:

- `game events` para hechos estadísticos genéricos, frecuentes y estables
- `left4dhooks` para atribución fuerte, estados complejos y transiciones internas más confiables

## Source Types

Las dos fuentes base del core quedan así:

- `HookEvent(...)`
- forwards y natives de `left4dhooks`

## Use Game Events For

Estas categorías deben seguir viniendo principalmente desde `game events`:

- daño bruto survivor e infected
- kills generales
- common kills
- friendly fire
- uso de consumibles
- uso de arrojables
- pickups
- heals
- revives
- rescues
- kills de `Tank`
- kills de `Witch`

## Preferred Game Events

La primera capa de tracking basada en eventos se apoya en:

- `player_death`
- `player_hurt`
- `infected_death`
- `infected_hurt`
- `weapon_fire`
- `pills_used`
- `adrenaline_used`
- `heal_success`
- `defibrillator_used`
- `revive_success`
- `survivor_rescued`
- `friendly_fire`
- `tank_killed`
- `witch_killed`

`item_pickup` y `spawner_give_item` siguen siendo candidatos válidos para futuras capas de inventario o supply tracking, pero no son necesarios para la primera implementación del core.

## Use Left4DHooks For

Estas categorías deben preferir `left4dhooks`, porque la librería entrega una señal más fuerte o una atribución más limpia:

- incapacitations con atribución detallada
- ledge grabs
- smoker grabs y releases
- hunter pounces landed
- jockey rides
- charger carry, slam y pummel
- vomit attribution
- caída fatal y contexto de caída
- otros estados de control survivor que se vuelven ambiguos en `game events`

## Preferred Left4DHooks Forwards

La primera ola de tracking con `left4dhooks` se apoya en:

- `L4D_OnIncapacitated_Post`
- `L4D_OnGrabWithTongue_Post`
- `L4D_OnPouncedOnSurvivor_Post`
- `L4D2_OnJockeyRide_Post`
- `L4D_OnVomitedUpon_Post`

Las siguientes señales siguen siendo recomendadas para la siguiente capa de crecimiento, pero no son necesarias todavía para la base actual:

- `L4D_OnLedgeGrabbed_Post`
- `L4D2_OnStartCarryingVictim_Post`
- `L4D2_OnSlammedSurvivor_Post`
- `L4D2_OnPummelVictim_Post`
- `L4D2_OnHitByVomitJar_Post`
- `L4D_OnFatalFalling`
- `L4D_OnFalling`

## Hybrid Cases

Hay casos donde la implementación correcta combina ambas capas.

### Infected kills by weapon

Para distinguir kills por arma o familia de arma:

- la muerte debe venir de `player_death` o `infected_death`
- el contexto de arma puede venir de `weapon_fire`
- melee puede reforzarse con `melee_kill`

No conviene depender de una sola fuente.

### Incap and death attribution

Para deaths e incaps:

- el conteo general puede venir del evento del juego
- la atribución fina debe preferir `left4dhooks`

Eso permite distinguir mejor:

- survivor
- infected controlado por jugador
- infected controlado por IA

### Boomer bile and pressure

Para vomit y presión de `Boomer`:

- `player_now_it` sirve como señal simple
- `L4D_OnVomitedUpon_Post` y `L4D2_OnHitByVomitJar_Post` mejoran la atribución

## Non-Goals

Por ahora el core no debe basarse en:

- eventos de instructor
- eventos de achievements
- eventos de awards como fuente principal
- eventos cosméticos o extremadamente ruidosos como `bullet_impact`

Los awards pueden servir más adelante para resúmenes o fun facts, pero no como base de la estadística primaria.

## Working Rule

Cuando una stat pueda obtenerse por dos caminos:

- un evento del juego simple
- un hook interno más confiable

la decisión será:

- usar el evento simple para conteos genéricos
- usar `left4dhooks` para atribución y semántica de estado

Eso mantiene el core estable sin renunciar a precisión donde realmente importa.
