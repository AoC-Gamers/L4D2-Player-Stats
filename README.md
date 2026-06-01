# L4D2-Player-Stats

Modern player statistics core for competitive L4D2.

Current output surface:

- chat summary commands:
  - `sm_stats_mvp` prints the MVP/LVP summary in chat and the round table in the user's console
  - `sm_stats_rank` prints the player's SI/CI/FF ranks in chat and the global rank table in the user's console
  - `sm_stats_acc` prints the grouped accuracy table in the user's console
- round detail commands:
  - `sm_stats_items`
  - `sm_stats_support`
  - `sm_stats_utils`
  - `sm_stats_infect`
  - `sm_stats_tank`
- post-round server console table with survivor totals and MVP/LVP summary

Documentation:

- [Build System](docs/build-system.md)
- [Player Stats Overview](docs/l4d2-player-stats-overview.md)
- [Player Stats API](docs/l4d2-player-stats-api.md)
- [Player Stats Architecture](docs/l4d2-player-stats-architecture.md)
- [Player Stats Data Model](docs/l4d2-player-stats-data-model.md)
- [Player Stats Series](docs/l4d2-player-stats-series.md)
- [Mode Lifecycle and Business Rules](docs/l4d2-mode-lifecycle-business-rules.md)

Bundled utility includes:

- `include/l4d2util_constants.inc`
- `include/l4d2util_weapons.inc`

Debug categories:

- `sm_stats_debug`
  - `1` `Core`
  - `2` `Event`
  - `4` `Detect`
  - `8` `Api`
  - `16` `Announce`
  - `31` all current categories

Optional debug probe:

- `sourcemod/scripting/l4d2_player_stats_api.sp`
  - consumes the public `PlayerStats` API and dumps finalized round/player payloads to logs

Optional companion plugins:

- `sourcemod/scripting/l4d2_player_stats_series.sp`
  - short-lived multi-round grouping for finalized `PlayerStats` snapshots
