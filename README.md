# L4D2-Player-Stats

Core moderno de estadísticas de jugador para L4D2 competitivo.

## Surface Principal

- comandos de resumen en chat:
  - `sm_stats_mvp` imprime el resumen MVP/LVP en chat y la tabla de ronda en la consola del usuario
  - `sm_stats_rank` imprime los ranks actuales de SI/CI/FF del jugador y la tabla global en consola
  - `sm_stats_acc` imprime la tabla agrupada de precisión en la consola del usuario
- comandos de detalle por ronda:
  - `sm_stats_items`
  - `sm_stats_support`
  - `sm_stats_utils`
  - `sm_stats_infect`
  - `sm_stats_tank`
- tabla de consola post-ronda con totales survivor y resumen MVP/LVP

## Documentación

- [Build System](docs/build-system.md)
- [Player Stats Overview](docs/l4d2-player-stats-overview.md)
- [Player Stats API](docs/l4d2-player-stats-api.md)
- [Player Stats Architecture](docs/l4d2-player-stats-architecture.md)
- [Player Stats Data Model](docs/l4d2-player-stats-data-model.md)
- [Player Stats Series](docs/l4d2-player-stats-series.md)
- [Mode Lifecycle and Business Rules](docs/l4d2-mode-lifecycle-business-rules.md)

Includes utilitarios compartidos:

- `include/l4d2util_constants.inc`
- `include/l4d2util_weapons.inc`

## Categorías de Debug

- `sm_stats_debug`
  - `1` `Core`
  - `2` `Event`
  - `4` `Detect`
  - `8` `Api`
  - `16` `Announce`
  - `31` todas las categorías actuales

## Herramientas Opcionales

Probe opcional de debug:

- `sourcemod/scripting/l4d2_player_stats_api.sp`
  - consume la API pública de `PlayerStats`
  - exporta a logs los payloads finalizados de `round` y `player`

Plugin acompañante opcional:

- `sourcemod/scripting/l4d2_player_stats_series.sp`
  - agrega agrupado corto multi-ronda para snapshots finalizados de `PlayerStats`
  - no forma parte del artefacto principal
