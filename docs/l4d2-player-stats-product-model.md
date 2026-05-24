# L4D2-Player-Stats Product Model

Este documento fija cómo debería terminar viéndose `L4D2-Player-Stats` como producto, más allá del orden técnico en que implementemos cada parte.

La meta es dejar claro:

- qué preguntas debe responder el plugin
- qué bloques conceptuales componen la estadística final
- qué parte ya existe
- qué parte sigue pendiente

## Goal

`L4D2-Player-Stats` debe funcionar como agregador moderno de estadísticas de ronda y de mapa.

No debe ser solo un reemplazo literal de los plugins legacy.

Debe terminar siendo una base ordenada para:

- resumen visible de ronda
- consumo por otros plugins
- tablas y rankings futuros

## Product Outputs

El producto final debe poder alimentar tres salidas principales:

### 1. Immediate Round Summary

El resumen visible inmediato debe responder cosas como:

- quién fue el `SI MVP`
- quién fue el `CI MVP`
- quién fue el `FF LVP`
- cuánto aportó cada survivor

### 2. Structured Data

El producto debe poder exponer un snapshot estructurado y reutilizable para:

- wrappers legacy
- plugins de HUD
- logs externos
- análisis o dashboards futuros

### 3. Growth Base

El modelo debe servir como base para crecer hacia:

- tablas más finas
- rankings por rol
- estadísticas infected más ricas
- integración más profunda con `PlayerSkills`

## Main Product Questions

El modelo final debe poder responder al menos estas familias de preguntas.

### Survivor Combat

- cuánto daño hizo cada survivor a `SI`
- cuánto daño hizo a `Tank`
- cuánto daño hizo a `Witch`
- cuántos common mató
- cuántos special remató
- a qué clases remató

### Survivor Survivability

- cuántas veces murió
- cuántas veces se incapacitó
- quién o qué provocó esas muertes o incaps

### Survivor Support

- cuántas curaciones dio
- cuántas recibió
- cuántos revives hizo
- cuántos revives recibió
- cuántos rescates realizó
- cuántos rescates recibió

### Resource Usage

- qué consumibles usó
- qué arrojables usó
- cuánto del inventario del equipo pasó por cada jugador

### Infected Pressure

- cuántos grabs hizo un `Smoker`
- cuántos pounces conectó un `Hunter`
- cuántos rides conectó un `Jockey`
- a cuántos survivors vomitó un `Boomer`
- cuánta presión humana hubo frente a presión de IA

### Semantic Skills

- qué skills especiales consiguió cada survivor
- sin redetectarlas dentro de `PlayerStats`
- consumiéndolas desde `PlayerSkills`

## Final Conceptual Shape

El modelo final debería organizarse por bloques conceptuales por jugador.

## `combat`

Este bloque representa el aporte ofensivo base del jugador.

Campos esperados:

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

## `survivability`

Este bloque representa qué le ocurrió al jugador durante la ronda.

Campos esperados:

- `deaths`
- `incaps`
- `deathBySurvivor`
- `deathByInfectedPlayer`
- `deathByInfectedAI`
- `incapBySurvivor`
- `incapByInfectedPlayer`
- `incapByInfectedAI`

## `support`

Este bloque representa el soporte dado o recibido.

Campos esperados:

- `healsGiven`
- `healsReceived`
- `revivesGiven`
- `revivesReceived`
- `rescuesGiven`
- `rescuesReceived`

## `resources`

Este bloque representa uso de consumibles y arrojables.

Campos esperados:

- `pillsUsed`
- `adrenalineUsed`
- `medkitsUsed`
- `defibsUsed`
- `molotovsThrown`
- `pipebombsThrown`
- `vomitjarsThrown`

## `accuracy`

Este bloque representa precisión agregada por familia de armas.

Campos esperados:

- `shotgunShots`
- `shotgunHits`
- `shotgunHeadshots`
- `smgRifleShots`
- `smgRifleHits`
- `smgRifleHeadshots`
- `sniperShots`
- `sniperHits`
- `sniperHeadshots`
- `pistolShots`
- `pistolHits`
- `pistolHeadshots`

## `pressure`

Este bloque representa presión generada por infected o estados similares de control.

Campos esperados:

- `tongueGrabs`
- `hunterPouncesLanded`
- `jockeyRidesLanded`
- `boomerVomitVictims`

## `skills`

Este bloque representa habilidades consumidas desde `PlayerSkills`.

Campos esperados:

- `skeets`
- `skeetMelees`
- `deadstops`
- `boomerPops`
- `levels`
- `crowns`
- `tongueCuts`
- `smokerSelfClears`
- `instaKills`

## `mode_*`

Este bloque representa estadísticas específicas del modo.

No debe contaminar el bloque base.

Ejemplo:

- `mode_coop`
- `mode_versus`

## Current Implementation Status

El estado actual del core ya cubre una parte importante del modelo.

### Implemented

- `combat`
  - `siDamage`
  - daño por clase SI
  - `tankDamage`
  - `witchDamage`
  - `commonKills`
  - kills por clase SI
- `survivability`
  - `deaths`
  - `incaps`
  - atribución básica de ambas
- `support`
  - heals
  - revives
  - rescues
- `resources`
  - pills
  - adrenaline
  - medkits
  - defibs
  - molotovs
  - pipebombs
  - vomitjars
- `accuracy`
  - shotgun
  - smg/rifle
  - sniper
  - pistol
- `pressure`
  - smoker grabs
  - hunter pounces
  - jockey rides
  - boomer vomit victims
- `skills`
  - primera tanda consumida desde `PlayerSkills`

### Not Implemented Yet

- pressure más rica de infected
- tablas por arma
- precisión
- snapshots de boss session consumidos desde `PlayerSkills`
- secciones `mode_*` reales

## Design Rule

La implementación puede avanzar por capas, pero el producto debe seguir siempre este shape conceptual.

Eso significa:

- no agregar campos sueltos sin decidir a qué bloque pertenecen
- no mezclar resumen survivor con payload completo de skills
- no mezclar stats universales con stats exclusivas de un modo

## API Direction

Cuando la API pública se implemente, debería seguir esta misma lógica.

El snapshot ideal de ronda debería poder organizarse como:

- `round`
  - `totals`
  - `players`
    - `identity`
    - `combat`
    - `survivability`
    - `support`
    - `resources`
    - `pressure`
    - `skills`
    - `mode_*`

Aunque el primer KV no exponga todavía todos esos bloques, esa debe ser la dirección.

## Current Rule

Antes de seguir ampliando el core, toda nueva estadística debe responder dos preguntas:

1. qué pregunta del producto ayuda a responder
2. a qué bloque conceptual pertenece

Si no podemos responder ambas con claridad, la stat todavía no está lista para entrar al modelo.
