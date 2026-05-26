# L4D2-Player-Stats API

Este documento define el contrato actual de la API pública de `L4D2-Player-Stats`.

La implementación ya existe, pero el schema sigue siendo deliberadamente austero para poder crecer sin inflar el payload base.

## Goal

La API de `PlayerStats` debe exponer snapshots agregados de ronda de forma simple.

La meta no es reproducir todo el estado interno del plugin.

La meta es entregar:

- un resumen de ronda
- una lista de jugadores persistentes del mapa actual
- sus estadísticas base ya agregadas

## Preferred Shape

La estrategia base sigue siendo:

- forward corto para marcar el momento
- `KeyValues` para volcar el snapshot completo

El contrato mínimo actual es:

```sourcepawn
forward void PlayerStats_OnRoundFinalized(int roundId);

native bool PlayerStats_IsRoundPlayerSlotValid(int roundId, int slot);
native bool PlayerStats_FillRoundKeyValues(int roundId, Handle kv);
native bool PlayerStats_FillRoundPlayerKeyValues(int roundId, int slot, Handle kv);
```

## Current Availability

Estos natives ya están implementados en el core actual.

La validación recomendada para consumidores externos es:

1. escuchar `PlayerStats_OnRoundFinalized(roundId)`
2. llamar `PlayerStats_FillRoundKeyValues(roundId, kv)`
3. iterar los `slot` listados
4. validar cada `slot` con `PlayerStats_IsRoundPlayerSlotValid(roundId, slot)` si hace falta
5. pedir detalle con `PlayerStats_FillRoundPlayerKeyValues(roundId, slot, kv)`

## Current Rule

La API debe exponer estadísticas agregadas de `PlayerStats`.

No debe mezclar en este payload:

- sesiones completas de bosses de `PlayerSkills`
- eventos crudos de `PlayerSkills`
- tablas gigantes de debug

## First KV Scope

La primera versión del `KeyValues` de ronda incluye solo:

- identidad mínima de la ronda
- totales agregados
- lista corta de jugadores persistentes

## Minimal Metadata

La metadata mínima de ronda es:

- `id`

## Minimal Totals

La sección de totales incluye solo stats ya consolidadas y útiles para resumen:

- `si_damage`
- `tank_damage`
- `witch_damage`
- `common_kills`
- `ff`
- `deaths`
- `incaps`
- `heals_given`
- `revives_given`

No debe incluir en la primera versión:

- consumo de ítems
- arrojables usados
- stats específicas de modo

## Player Structure

El detalle completo de un jugador no vive dentro del snapshot general de ronda.

El snapshot general de ronda debe incluir solo una lista corta de jugadores persistentes para que otros plugins puedan descubrir los `slot` disponibles y luego pedir el detalle bajo demanda.

Cada jugador detallado se organiza en bloques cortos y predecibles.

La primera forma recomendada es:

- `identity`
- `combat`
- `survivability`
- `support`
- `items`
- `utils`
- `mode_*` opcional

## `identity`

Cada jugador persistente del snapshot detallado expone solo identidad básica:

- `userid`
- `name`
- `accountid`
- `bot`
- `team`

`team` debe quedar como `int` en la primera versión.

La idea es mantener el payload alineado con el runtime interno del plugin y evitar un mapeo extra a strings.

Si luego hace falta, se puede sumar:

- `auth`
- `character`

Pero no son obligatorios en la primera versión.

## `combat`

Este bloque incluye solo:

- `si_damage`
- `smoker_damage`
- `boomer_damage`
- `hunter_damage`
- `spitter_damage`
- `jockey_damage`
- `charger_damage`
- `tank_damage`
- `witch_damage`
- `common_kills`
- `smoker_kills`
- `boomer_kills`
- `hunter_kills`
- `spitter_kills`
- `jockey_kills`
- `charger_kills`
- `tank_kills`
- `ff_given`

## `survivability`

Este bloque incluye solo:

- `deaths`
- `incaps`

## `support`

Este bloque incluye solo:

- `heals_given`
- `heals_received`
- `revives_given`
- `revives_received`

## `items`

Este bloque incluye solo:

- `pills_used`
- `adrenaline_used`
- `medkits_used`
- `defibs_used`

## `utils`

Este bloque incluye solo:

- `molotovs_thrown`
- `pipebombs_thrown`
- `vomitjars_thrown`
- `zombies_ignited`
- `players_biled`
- `tanks_biled`

## Attribution Detail

La atribución de `deaths` e `incaps` sí tiene valor en la API base.

Por eso esta primera versión incluye:

- `death_by_survivor`
- `death_by_infected_player`
- `death_by_infected_ai`
- `incap_by_survivor`
- `incap_by_infected_player`
- `incap_by_infected_ai`

## `accuracy`

La API actual sí expone precisión en el snapshot detallado por jugador.

El contrato mantiene compatibilidad hacia atrás y tiene dos capas:

- campos planos por familia
- bloques agrupados por familia con detalle por arma

Los campos planos siguen siendo:

- `shotgun_shots`
- `shotgun_hits`
- `shotgun_headshots`
- `smg_rifle_shots`
- `smg_rifle_hits`
- `smg_rifle_headshots`
- `sniper_shots`
- `sniper_hits`
- `sniper_headshots`
- `pistol_shots`
- `pistol_hits`
- `pistol_headshots`

Además, el bloque `accuracy` ahora incluye:

- `shotgun`
- `smg_rifle`
- `sniper`
- `pistol`

Cada familia expone:

- `shots`
- `hits`
- `headshots`
- `details`

### `accuracy.shotgun.details`

Incluye:

- `pump`
- `auto`
- `chrome`
- `spas`

### `accuracy.smg_rifle.details`

Incluye:

- `smg`
- `silenced_smg`
- `mp5`
- `rifle`
- `ak47`
- `desert_rifle`
- `sg552`
- `m60`

### `accuracy.sniper.details`

Incluye:

- `hunting`
- `military`
- `awp`
- `scout`

### `accuracy.pistol.details`

Incluye:

- `pistol`
- `magnum`

Cada arma específica expone:

- `shots`
- `hits`
- `headshots`

## Excluded For Now

Estas categorías siguen fuera del KV base:

- contadores de skills consumidos desde `PlayerSkills`
- pressure de infected
- snapshots de boss session
- debug state
- histórico por mapa en la API pública

## Mode Sections

Algunas estadísticas no deben vivir en el bloque base del jugador porque dependen demasiado del modo de juego.

Esas estadísticas deben ir en subsecciones dinámicas por modo y solo aparecer cuando apliquen.

La convención actual es:

- `mode_coop`
- `mode_versus`

Y, si más adelante hace falta:

- `mode_survival`
- `mode_scavenge`

La regla es:

- el bloque base contiene solo stats universales
- cada bloque `mode_*` contiene solo stats específicas de ese modo

### `mode_coop`

La primera sección contextual prevista es:

- `mode_coop`

Su primer campo útil sería:

- `rescues_given`

### `rescues_given`

Este campo solo debe aparecer dentro de `mode_coop`.

La idea es no inflar el payload base con una stat que no tiene el mismo valor general en otros contextos.

### `rescues_received`

`rescues_received` no debe entrar en la primera versión del KV.

Es una stat demasiado contextual y no aporta suficiente valor en el snapshot base como para fijarla todavía en el contrato.

### `mode_versus`

La sección `mode_versus` queda reservada para crecimiento futuro.

No se puebla en la primera versión actual.

## Why Skills Stay Out

Aunque `PlayerStats` ya consume una primera tanda de skills desde `PlayerSkills`, no hace falta meterlas todavía en el KV base.

Las razones son simples:

- agrandan mucho el payload
- no forman parte del resumen survivor original
- siguen siendo una capa derivada, no el núcleo del snapshot

Si luego hace falta, pueden agregarse en:

- una subsección opcional
- otro native
- o una segunda versión del contrato

## Draft Example

```text
round
{
    "id"            "7"

    "totals"
    {
        "si_damage"         "4200"
        "tank_damage"       "1500"
        "witch_damage"      "800"
        "common_kills"      "340"
        "ff"                "120"
        "deaths"            "2"
        "incaps"            "5"
        "heals_given"       "3"
        "revives_given"     "2"
    }

    "players"
    {
        "0"
        {
            "slot"                  "0"

            "identity"
            {
                "userid"                "41"
                "name"                  "Lechuga"
                "accountid"             "123456"
                "bot"                   "0"
                "team"                  "1"
            }
        }
    }
}
```

## Player Detail Example

```text
player
{
    "slot"                  "0"

    "identity"
    {
        "userid"                "41"
        "name"                  "Lechuga"
        "accountid"             "123456"
        "bot"                   "0"
        "team"                  "1"
    }

    "combat"
    {
        "si_damage"             "1400"
        "smoker_damage"         "250"
        "boomer_damage"         "200"
        "hunter_damage"         "300"
        "spitter_damage"        "150"
        "jockey_damage"         "200"
        "charger_damage"        "300"
        "tank_damage"           "500"
        "witch_damage"          "200"
        "common_kills"          "90"
        "smoker_kills"          "1"
        "boomer_kills"          "1"
        "hunter_kills"          "2"
        "spitter_kills"         "1"
        "jockey_kills"          "1"
        "charger_kills"         "1"
        "tank_kills"            "0"
        "ff_given"              "10"
    }

    "survivability"
    {
        "deaths"                    "0"
        "incaps"                    "1"
        "death_by_survivor"         "0"
        "death_by_infected_player"  "0"
        "death_by_infected_ai"      "0"
        "incap_by_survivor"         "0"
        "incap_by_infected_player"  "1"
        "incap_by_infected_ai"      "0"
    }

    "support"
    {
        "heals_given"           "1"
        "heals_received"        "0"
        "revives_given"         "1"
        "revives_received"      "0"
    }

    "items"
    {
        "pills_used"            "1"
        "adrenaline_used"       "0"
        "medkits_used"          "1"
        "defibs_used"           "0"
    }

    "utils"
    {
        "molotovs_thrown"       "1"
        "pipebombs_thrown"      "0"
        "vomitjars_thrown"      "0"
        "zombies_ignited"       "6"
        "players_biled"         "0"
        "tanks_biled"           "0"
    }

    "mode_coop"
    {
        "rescues_given"         "0"
    }
}
```

## Slot Rule

El native de detalle por jugador debe resolver por `slot`, no por `client`.

La razón es simple:

- `slot` representa la identidad persistente del mapa actual
- `client` solo representa el runtime actual

Por eso el contrato recomendado es:

- `PlayerStats_FillRoundKeyValues(roundId, kv)` para resumen general
- `PlayerStats_FillRoundPlayerKeyValues(roundId, slot, kv)` para detalle por jugador
- `PlayerStats_IsRoundPlayerSlotValid(roundId, slot)` para validación externa explícita

## Current Notes

- `team` se expone como `int`
- `userid` forma parte de `identity`
- `accountid` forma parte de `identity`
- `players_count` no forma parte del snapshot de ronda actual
- `mode_coop` solo se escribe cuando:
  - el jugador tiene `rescues_given > 0`
  - y `mp_gamemode` contiene `coop`

## Open Refinements

Estos son los puntos que todavía conviene seguir refinando sobre la implementación actual:

- si `support`, `items` y `utils` conviene mantenerlos separados o condensar parte de esos datos en una vista más compacta
