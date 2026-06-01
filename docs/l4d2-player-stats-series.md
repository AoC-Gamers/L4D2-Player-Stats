# L4D2-Player-Stats-Series

`L4D2-Player-Stats-Series` is a lightweight consumer of `L4D2-Player-Stats`.

It listens to finalized round snapshots and groups them into short-lived in-memory series using mode-aware boundaries.

## Responsibility

- consume finalized `PlayerStats` round snapshots
- keep a small in-memory set of active/closed series
- detect when a new series must begin based on base mode and lifecycle rules

This plugin does not try to replace `L4D2-Player-Stats`.

`L4D2-Player-Stats` remains the source of truth for round snapshots. `L4D2-Player-Stats-Series` only aggregates those snapshots into a higher temporal unit.

This module is intentionally internal to the `PlayerStats` family. It does not publish its own SourceMod library or public native API.

It is also optional. It is not part of the main `PlayerStats` artifact/package.

## Boundary Rules

Series detection follows the lifecycle rules described in:

- [l4d2-mode-lifecycle-business-rules.md](C:/GitHub/L4D2-Player-Stats/docs/l4d2-mode-lifecycle-business-rules.md)

Current behavior:

- `Coop`
  - series scope is `mission`
  - a new series starts when the mission key changes
- `Versus`
  - series scope is `mission`
  - a new series starts when the mission key changes
- `Scavenge`
  - series scope is `map`
  - a new series starts when the map changes
- `Survival`
  - series scope is `map`
  - a new series starts when the map changes

The current mission key is derived from the map prefix before `m`, for example:

- `c2m3_coaster` -> `c2`
- `l4d_hospital01_apartment` -> `l4d_hospital01_apartment`

## Lifecycle

- snapshots are accepted only when `PlayerStats_OnRoundFinalized(roundId)` fires
- the plugin keeps one active series
- older series are kept in a short closed buffer
- storage is memory-only

No persistence, disk history, or long-term archive is implemented here.

## Commands

- `sm_stats_series`
  - prints the current in-memory series buffer
- `sm_stats_series <id>`
  - prints the aggregated totals for the requested series
  - prints the aggregated player table for the requested series
  - then prints the entry table for that same series

## Table Behavior

`sm_stats_series <id>` prints the aggregated player table ordered by competitive contribution:

- total combat damage: `SI + Tank + Witch` descending
- `Common Infected` descending
- `Friendly Fire` ascending
- `Rounds` descending
- `Player` name ascending

This keeps the most relevant survivor rows near the top without requiring a separate MVP-style score.

## Build

Example compile command:

```powershell
& 'C:\sourcemodAPI\addons\sourcemod\scripting\spcomp.exe' `
  'C:\GitHub\L4D2-Player-Stats\sourcemod\scripting\l4d2_player_stats_series.sp' `
  '-oC:\SourcemodCompiled\l4d2_player_stats_series.smx' `
  '-iC:\GitHub\L4D2-Player-Stats\sourcemod\scripting\include' `
  '-iC:\GitHub\L4D2-Player-Stats\sourcemod\scripting' `
  '-iC:\sourcemodAPI\addons\sourcemod\scripting\include'
```
