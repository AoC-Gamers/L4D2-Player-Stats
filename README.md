# L4D2-Player-Stats

Modern player statistics core for competitive L4D2.

Current output surface:

- chat summary commands:
  - `sm_mvp` prints the MVP/LVP summary in chat and the round table in the user's console
    - no args: current round
    - `sm_mvp c2m1_highway`: latest historical occurrence of that map in the current run
  - `sm_mvp_rank` prints the player's SI/CI/FF ranks in chat and the global rank table in the user's console
  - `sm_mvp_stats` prints the aggregated mission history in the user's console
    - no args: current map inside the current mission
    - `sm_mvp_stats c2m1_highway`: specific map inside the current mission
    - `sm_mvp_stats all`: all maps in the current mission
  - `sm_mvp_acc` prints the accuracy summary table in the user's console
    - no args: current round
    - `sm_mvp_acc c2m1_highway`: latest historical occurrence of that map in the current run
  - `sm_acc_details` prints detailed per-weapon accuracy in the user's console
    - no args: current round
    - `sm_acc_details c2m1_highway`: latest historical occurrence of that map in the current run
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
  - `2` `Event`
  - `4` `Detect`
  - `8` `Api`
  - `16` `Announce`
  - `31` all current categories
