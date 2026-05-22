# L4D2-Player-Stats Integration

Este documento fija la dirección de integración entre `L4D2-Player-Stats` y otros plugins del stack antes de seguir ampliando el core.

## Goal

`L4D2-Player-Stats` debe funcionar como agregador moderno de estadísticas por ronda y por juego.

No debe reimplementar detección compleja que ya exista en otros plugins del ecosistema cuando esos plugins ya entregan una fuente de verdad mejor.

## Source Of Truth

La regla general del proyecto queda así:

- `L4D2-Player-Stats` es la fuente de verdad para estadísticas continuas y agregadas.
- `L4D2-Player-Skills` es la fuente de verdad para eventos de habilidad y sesiones de bosses.

## What PlayerStats Should Track Directly

Estas categorías deben seguir midiéndose dentro de `L4D2-Player-Stats`:

- daño base a SI
- daño base a Tank, si solo se usa como componente de MVP agregado
- daño base a Witch, si solo se usa como componente de MVP agregado
- common kills
- friendly fire dado y recibido
- deaths
- incaps
- presencia por ronda o por juego
- totales simples de survivor e infected

Estas estadísticas son continuas, frecuentes y no dependen de una detección semántica compleja.

## What PlayerStats Should Consume From PlayerSkills

No toda skill detectada por `L4D2-Player-Skills` debe entrar automáticamente a `L4D2-Player-Stats`.

La regla correcta es:

- consumir skills cuando agregan semántica que `PlayerStats` no trackea bien por sí mismo
- no consumir skills cuando ya existe una stat genérica local equivalente y suficiente

## First Accepted Skill Set

La primera tanda aceptada para `PlayerStats` queda así:

- `HunterSkeet`
- `HunterSkeetMelee`
- `HunterDeadstop`
- `BoomerPop`
- `ChargerLevel`
- `WitchDead` solo cuando `crown = true`
- `SmokerTongueCut`
- `SmokerSelfClear`
- `ChargerInstaKill`

Estas skills sí agregan una capa semántica útil y no compiten con una stat continua simple del core.

## Explicitly Deferred Skill Set

Estas skills no deben entrar todavía al core de stats:

- `HunterHighPounce`
- `JockeyHighPounce`
- `BoomerVomitLanded`
- `ChargerDeathSetup`
- `SpecialPinClear`
- `TankRockSkeet`
- `TankRockHit`
- `WitchIncap`
- `BunnyHopStreak`
- `CarAlarmTriggered`

Las razones se repiten en tres grupos:

- ya existe una stat genérica local suficiente
- son demasiado situacionales para el resumen base
- pertenecen más a una capa de analytics secundaria o a wrappers futuros

### Redundant With Local Stats

Estas skills no aportan suficiente diferencia frente a stats locales ya implementadas:

- `BoomerVomitLanded`
  - el core ya trackea `boomerVomitVictims`
- `HunterHighPounce`
  - el core ya trackea `hunterPouncesLanded`
- `JockeyHighPounce`
  - el core ya trackea `jockeyRidesLanded`

### Better For Later Layers

Estas skills pueden tener valor más adelante, pero no son parte del núcleo actual:

- `ChargerDeathSetup`
- `SpecialPinClear`
- `TankRockSkeet`
- `TankRockHit`
- `WitchIncap`
- `BunnyHopStreak`
- `CarAlarmTriggered`

## Why This Split Works

Con esta política, `PlayerStats` mantiene:

- stats genéricas continuas por su cuenta
- skills semánticas solo cuando realmente agregan valor nuevo

Eso evita dos problemas:

- duplicar una misma idea con dos fuentes distintas
- inflar el core con contadores demasiado situacionales

## Boss Sessions

Las sesiones de boss no deben reconstruirse en `L4D2-Player-Stats` si `L4D2-Player-Skills` ya las expone.

Eso incluye especialmente:

- sesiones de daño a `Tank`
- sesiones de daño a `Witch`
- crown detection
- rock tracking

La política es:

- si `PlayerStats` necesita resumir o reutilizar esa información, debe consumir la API de `PlayerSkills`
- no debe crear un segundo tracker equivalente para el mismo problema

## Integration Strategy

La integración objetivo con `L4D2-Player-Skills` es esta:

1. dependencia opcional del include `l4d2_player_skills`
2. detección de librería con `OnLibraryAdded` / `OnLibraryRemoved`
3. consumo del forward:
   - `PlayerSkills_OnSkillDetected`
4. lectura de payload mediante:
   - `PlayerSkills_GetEventType`
   - `PlayerSkills_GetEventInt`
   - `PlayerSkills_GetEventFloat`
   - `PlayerSkills_GetEventBool`
   - getters de player slot
   - opcionalmente `PlayerSkills_FillEventKeyValues`

## Current State

La primera vertical propia del core ya quedó establecida en una forma mínima útil:

- lifecycle de ronda
- gating por `round live`
- slots persistentes por mapa
- MVP survivor básico
- daño a SI / Tank / Witch
- common kills
- FF
- soporte survivor básico
- pressure infected básico
- primera atribución de deaths e incaps

Sobre esa base ya existe una primera integración real con `PlayerSkills`.

## Implemented Skill Counters

La primera integración implementada con `PlayerSkills` ya coincide con el primer set aceptado.

Actualmente consume estos contadores simples por jugador:

- skeets
- skeet melees
- deadstops
- boomer pops
- levels
- crowns
- tongue cuts
- smoker self clears
- instakills

Eso ya permite:

- enriquecer MVP y tablas
- validar la integración
- evitar depender todavía de estructuras más complejas

## Future Revisit

Las skills diferidas no están prohibidas para siempre.

Pueden reabrirse si más adelante aparece una necesidad concreta, por ejemplo:

- un wrapper legacy que realmente las necesite
- un HUD o scoreboard específico
- analytics secundarias del lado infected

## Non-Goals

Por ahora `L4D2-Player-Stats` no debe:

- reimplementar detección de skills ya resueltas por `PlayerSkills`
- duplicar sesiones de boss
- reconstruir tablas de daño de Tank/Witch si ya existen en otra librería
- migrar de golpe toda la lógica de `l4d2_playstats.sp`

## Legacy Wrapper Rule

Los wrappers legacy no deben prometer más semántica de la que el core nuevo sostiene realmente.

La política actual es:

- `survivor_mvp` puede ofrecer compatibilidad directa de consulta
- `l4d2_playstats` puede ofrecer compatibilidad mínima de broadcast

En particular:

- `PLAYSTATS_BroadcastRoundStats()` imprime el snapshot actual o final de ronda
- `PLAYSTATS_BroadcastGameStats()` hoy funciona como alias práctico del mismo broadcast

Eso no representa todavía una capa real de agregación por juego.

Por lo tanto, cualquier evolución futura de stats “por juego” debe decidirse primero en el core y recién después exponerse en el wrapper legacy.

## Working Rule

Cuando una estadística pueda surgir de dos formas:

- detección semántica compleja
- agregación simple y continua

la decisión será:

- usar `PlayerSkills` para la parte semántica compleja
- usar `PlayerStats` para la parte continua y agregada

Eso mantiene separados:

- `PlayerSkills`: detectar
- `PlayerStats`: acumular y presentar
