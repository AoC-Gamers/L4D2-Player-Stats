# L4D2-Player-Stats Base Model

Este documento define la primera tabla base de estadísticas que debe sostener `L4D2-Player-Stats`.

La idea es empezar por un modelo corto, estable y útil, antes de migrar tablas grandes del plugin legacy.

## Scope

La primera versión del core debe poder responder:

- quién lideró daño a SI
- quién lideró common kills
- quién hizo más FF
- quién murió o se incapacitó
- cuánto aportó cada survivor contra `SI`, `Tank` y `Witch`
- qué consumibles usó cada survivor
- qué arrojables usó cada survivor

No intenta todavía cubrir:

- fun facts
- accuracy avanzada
- tablas por arma
- tiempos de clear
- tablas de infected complejas
- escritura a archivo

## Base Unit

La unidad base inicial será:

- `player`
- `round`

Todo lo demás debe poder derivarse después desde esa base:

- team summary
- game summary
- MVP
- LVP
- rankings

## First Survivor Stat Table

La tabla base actualmente implementada por jugador y por ronda queda así:

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
- `deaths`
- `incaps`
- `deathBySurvivor`
- `deathByInfectedPlayer`
- `deathByInfectedAI`
- `incapBySurvivor`
- `incapByInfectedPlayer`
- `incapByInfectedAI`
- `healsGiven`
- `healsReceived`
- `revivesGiven`
- `revivesReceived`
- `rescuesGiven`
- `rescuesReceived`
- `tongueGrabs`
- `hunterPouncesLanded`
- `jockeyRidesLanded`
- `boomerVomitVictims`
- `pillsUsed`
- `adrenalineUsed`
- `medkitsUsed`
- `defibsUsed`
- `molotovsThrown`
- `pipebombsThrown`
- `vomitjarsThrown`

## Field Meaning

### `siDamage`

Daño total hecho a special infected que no sean `Tank` ni `Witch`.

Debe poder usarse para:

- MVP de daño
- resumen de ronda
- futuros rankings por clase

### Damage by SI class

Además del total `siDamage`, el core ya divide el daño survivor por clase SI:

- `smokerDamage`
- `boomerDamage`
- `hunterDamage`
- `spitterDamage`
- `jockeyDamage`
- `chargerDamage`

La regla es simple:

- `siDamage` = suma general de SI no `Tank`
- cada campo por clase = aporte del survivor a esa clase específica

### `tankDamage`

Daño total hecho a `Tank`.

Por ahora se usa como parte del score agregado de survivor damage.

Más adelante puede separarse en tablas específicas.

### `witchDamage`

Daño total hecho a `Witch`.

Por ahora se usa como parte del score agregado de survivor damage.

No reemplaza la sesión de boss que ya maneja `PlayerSkills`.

### `commonKills`

Cantidad de common infected muertos por el jugador.

Es una estadística base de PvE y de resumen survivor.

### Kills by SI class

Además de `commonKills`, el core ya divide kills de infected especiales por clase:

- `smokerKills`
- `boomerKills`
- `hunterKills`
- `spitterKills`
- `jockeyKills`
- `chargerKills`
- `tankKills`

La semántica sigue la regla definida en:

- [l4d2-player-stats-kill-interpretation.md](C:/GitHub/L4D2-Player-Stats/docs/l4d2-player-stats-kill-interpretation.md)

Eso significa:

- la kill cuenta para el último golpe
- el daño sigue contando como contribution separada

### `ffGiven`

Cantidad de friendly fire dada por el jugador.

Debe seguir la interpretación definida en:

- [l4d2-player-stats-kill-interpretation.md](C:/GitHub/L4D2-Player-Stats/docs/l4d2-player-stats-kill-interpretation.md)

### `deaths`

Cantidad de muertes del survivor en la ronda.

Debe convivir con un detalle de atribución del causante.

### `incaps`

Cantidad de incapacitations del survivor en la ronda.

Debe convivir con un detalle de atribución del causante.

### `deathBySurvivor`

Cantidad de muertes del survivor provocadas por otro survivor.

Esto cubre especialmente contextos de daño amigo extremo o errores de equipo.

### `deathByInfectedPlayer`

Cantidad de muertes del survivor provocadas por un infected controlado por jugador.

Esta es la base más útil para futuras estadísticas de infected.

### `deathByInfectedAI`

Cantidad de muertes del survivor provocadas por la IA.

Esto incluye casos donde el causante final no fue un infected humano.

### `incapBySurvivor`

Cantidad de incapacitations del survivor provocadas por otro survivor.

### `incapByInfectedPlayer`

Cantidad de incapacitations del survivor provocadas por un infected controlado por jugador.

### `incapByInfectedAI`

Cantidad de incapacitations del survivor provocadas por la IA.

### `healsGiven`

Cantidad de curaciones exitosas realizadas por el survivor.

### `healsReceived`

Cantidad de curaciones exitosas recibidas por el survivor.

### `revivesGiven`

Cantidad de revives exitosos realizados por el survivor.

### `revivesReceived`

Cantidad de revives exitosos recibidos por el survivor.

### `rescuesGiven`

Cantidad de rescates de closet o rescue entity realizados por el survivor.

### `rescuesReceived`

Cantidad de rescates de closet o rescue entity recibidos por el survivor.

### `tongueGrabs`

Cantidad de grabs de `Smoker` iniciados por el jugador infected.

### `hunterPouncesLanded`

Cantidad de pounces de `Hunter` que conectaron sobre un survivor.

### `jockeyRidesLanded`

Cantidad de rides de `Jockey` que conectaron sobre un survivor.

### `boomerVomitVictims`

Cantidad de survivors alcanzados por vomit directo de `Boomer`.

### `pillsUsed`

Cantidad de píldoras usadas por el jugador.

Es una stat genérica de consumo y no depende del ruleset competitivo activo.

### `adrenalineUsed`

Cantidad de adrenalinas usadas por el jugador.

Es una stat genérica de consumo y no depende del ruleset competitivo activo.

### `medkitsUsed`

Cantidad de botiquines usados por el jugador.

Es una stat genérica de consumo y no depende del ruleset competitivo activo.

### `defibsUsed`

Cantidad de desfibriladores usados por el jugador.

Es una stat genérica de consumo y no depende del ruleset competitivo activo.

### `molotovsThrown`

Cantidad de molotovs lanzadas por el jugador.

Es una stat genérica de uso de arrojables y no depende del ruleset competitivo activo.

### `pipebombsThrown`

Cantidad de pipebombs lanzadas por el jugador.

Es una stat genérica de uso de arrojables y no depende del ruleset competitivo activo.

### `vomitjarsThrown`

Cantidad de bilis lanzadas por el jugador.

Es una stat genérica de uso de arrojables y no depende del ruleset competitivo activo.

## First Team Totals

Además de la tabla por jugador, el core debe mantener totales por ronda:

- `survivorTotalSiDamage`
- `survivorTotalSmokerDamage`
- `survivorTotalBoomerDamage`
- `survivorTotalHunterDamage`
- `survivorTotalSpitterDamage`
- `survivorTotalJockeyDamage`
- `survivorTotalChargerDamage`
- `survivorTotalTankDamage`
- `survivorTotalWitchDamage`
- `survivorTotalCommonKills`
- `survivorTotalSmokerKills`
- `survivorTotalBoomerKills`
- `survivorTotalHunterKills`
- `survivorTotalSpitterKills`
- `survivorTotalJockeyKills`
- `survivorTotalChargerKills`
- `survivorTotalTankKills`
- `survivorTotalFF`
- `survivorTotalDeaths`
- `survivorTotalIncaps`
- `survivorTotalHealsGiven`
- `survivorTotalRevivesGiven`
- `survivorTotalRescuesGiven`
- `infectedTotalTongueGrabs`
- `infectedTotalHunterPouncesLanded`
- `infectedTotalJockeyRidesLanded`
- `infectedTotalBoomerVomitVictims`
- `survivorTotalPillsUsed`
- `survivorTotalAdrenalineUsed`
- `survivorTotalMedkitsUsed`
- `survivorTotalDefibsUsed`
- `survivorTotalMolotovsThrown`
- `survivorTotalPipebombsThrown`
- `survivorTotalVomitjarsThrown`

Estos totales permiten calcular:

- porcentajes
- MVP
- LVP
- rankings

sin reescaneo costoso del estado.

## Attribution Detail

Las muertes e incapacitations no deben quedarse solo como conteo bruto.

El modelo debe poder responder también:

- quién provocó la incap
- quién provocó la muerte
- si el causante fue humano o IA

La primera partición útil es:

- survivor
- infected controlado por jugador
- infected controlado por IA

No hace falta todavía guardar en la tabla mínima:

- la clase exacta del infected en cada ocurrencia
- el arma exacta usada en cada ocurrencia
- una lista completa de eventos históricos

Pero sí conviene que el modelo base ya reserve la distinción de atribución.

## Infected-Oriented Growth

Esta atribución abre una segunda capa futura de estadísticas de infected que el plugin original no tenía de forma clara.

Ejemplos posibles:

- cuántas incaps provocó un infected humano
- cuántas muertes cerró un infected humano
- cuántas muertes provinieron de la IA
- qué tanto del castigo survivor vino de control humano contra presión del director

La regla del modelo queda así:

- las stats survivor siguen siendo la base
- pero la atribución de deaths e incaps debe permitir crecer luego hacia tablas de infected

## First Rankings

La primera capa de ranking debe ser:

- `SI MVP`
  daño total a `SI + Tank + Witch`
- `CI MVP`
  common kills
- `FF LVP`
  friendly fire dado

Esto replica el valor principal de `survivor_mvp.sp` sin arrastrar todavía todo el plugin viejo.

## Support Layer

Además de daño y kills base, el core ya considera una capa mínima de soporte survivor:

- heals
- revives
- rescues

La idea no es todavía construir un MVP de soporte visible, sino dejar una base estable para:

- tablas futuras
- ratings de soporte
- resúmenes más completos

## Infected Pressure Layer

Además de la base survivor, el core ya incluye una primera capa compacta de pressure del lado infected:

- `tongueGrabs`
- `hunterPouncesLanded`
- `jockeyRidesLanded`
- `boomerVomitVictims`

Eso no intenta todavía reemplazar tablas grandes del plugin legacy.

Su objetivo es:

- abrir estadísticas para infected
- fijar las primeras fuentes de verdad del lado SI
- evitar redetectar luego estos eventos desde cero

## Generic Item Usage

El core debe registrar consumo y uso de ítems de forma genérica.

La semántica base no cambia según el modo de juego competitivo cargado.

Eso significa:

- si el jugador usó una píldora, cuenta como `pillsUsed`
- si el jugador usó adrenalina, cuenta como `adrenalineUsed`
- si el jugador lanzó una pipebomb, cuenta como `pipebombsThrown`

No importa si el ruleset competitivo permite:

- `0`
- `1`
- o más copias del mismo ítem

Ese contexto pertenece al modo de juego, no a la definición de la stat.

## Working Rule For Item Usage

El core debe registrar consumo y uso de ítems como hechos genéricos del jugador.

No necesita distinguir si la ronda ocurre en un servidor casual, competitivo o bajo un ruleset comunitario específico.

La pregunta que responde la stat es simple:

- qué usó el jugador
- cuántas veces lo usó

No:

- bajo qué límite estaba permitido
- qué config comunitaria estaba cargada

## Current Kill Split Rule

Para infected especiales, el core ya usa una regla deliberadamente simple:

- `damage` por clase
- `kills` por clase

No intenta todavía desglosar:

- assists por kill
- arma exacta de la kill
- historial de daño por target

La meta es que al final de la ronda o del mapa se pueda responder de forma limpia:

- cuánto daño hizo cada survivor a cada clase SI
- cuántos remates hizo a cada clase SI

## First Integration With PlayerSkills

Aunque la base de survivor stats se trackea localmente, el modelo debe reservar espacio conceptual para contadores consumidos desde `PlayerSkills`.

La primera ola ya implementada de contadores de skill es:

- `skeets`
- `skeetMelees`
- `deadstops`
- `boomerPops`
- `levels`
- `crowns`
- `tongueCuts`
- `smokerSelfClears`
- `instaKills`

Eso ya forma parte del estado actual del core, aunque todavía no se muestre en los resúmenes visibles heredados de los plugins originales.

## Current Rule

Antes de ampliar el core, cualquier nueva stat debe cumplir al menos una de estas condiciones:

- sirve para MVP o resumen de ronda
- sirve como total base para tablas futuras
- evita retrackear algo costoso más adelante

Si no cumple una de esas tres, no entra en la primera tabla.
