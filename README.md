# L4D2-Player-Stats

Modern player statistics core for competitive L4D2.

Current output surface:

- chat summary commands:
  - `sm_mvp` prints the MVP/LVP summary in chat and the round table in the user's console
  - `sm_mvp_rank` prints the player's SI/CI/FF ranks in chat and the global rank table in the user's console
  - `sm_mvp_stats` prints the aggregated mission history in the user's console
    - no args: current map inside the current mission
    - `sm_mvp_stats c2m1_highway`: specific map inside the current mission
    - `sm_mvp_stats all`: all maps in the current mission
  - `sm_mvp_acc` prints the current round accuracy table in the user's console
- post-round server console table with survivor totals and MVP/LVP summary
- game-history panel available through `PlayerStats_BroadcastGameStats`
- restart integrations:
  - `PlayerStats_MarkRestart(source)` lets external plugins report direct restarts to the historical layer
- legacy compatibility wrappers:
  - `survivor_mvp`
  - `l4d2_playstats`

Documentation:

- [Build System](docs/build-system.md)
- [Player Stats API](docs/l4d2-player-stats-api.md)
- [Product Model](docs/l4d2-player-stats-product-model.md)
- [Mode Lifecycle and Business Rules](docs/l4d2-mode-lifecycle-business-rules.md)
- [Accuracy Implementation](docs/l4d2-player-stats-accuracy-implementation.md)
- [Reduced-Team Versus Implementation](docs/l4d2-player-stats-1v1-implementation.md)
- [Vendor l4d2util](docs/vendor-l4d2util.md)

Bundled utility includes:

- `include/l4d2util_constants.inc`
- `include/l4d2util_weapons.inc`

Debug categories:

- `l4d2_player_stats_debug`
  - `1` `Core`
  - `2` `Detect`
  - `4` `Api`
  - `8` `Announce`
  - `15` all current categories
