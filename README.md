# L4D2-Player-Stats

Modern player statistics core for competitive L4D2.

Current output surface:

- chat summary commands:
  - `sm_mvp`
  - `sm_stats`
  - `sm_mvpme`
- post-round server console table with survivor totals and MVP/LVP summary
- legacy compatibility wrappers:
  - `survivor_mvp`
  - `l4d2_playstats`

Documentation:

- [Build System](docs/build-system.md)
- [Player Stats API](docs/l4d2-player-stats-api.md)
- [Product Model](docs/l4d2-player-stats-product-model.md)

Debug categories:

- `l4d2_player_stats_debug`
  - `1` `Core`
  - `2` `Detect`
  - `4` `Api`
  - `8` `Announce`
  - `15` all current categories
