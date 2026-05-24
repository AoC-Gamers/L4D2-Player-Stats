# L4D2-Player-Stats

Modern player statistics core for competitive L4D2.

Current output surface:

- chat summary commands:
  - `sm_mvp` prints the MVP/LVP summary in chat and the round table in the user's console
  - `sm_mvp_rank` prints the player's SI/CI/FF ranks in chat and the global rank table in the user's console
- post-round server console table with survivor totals and MVP/LVP summary
- game-history panel available through `PlayerStats_BroadcastGameStats`
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
