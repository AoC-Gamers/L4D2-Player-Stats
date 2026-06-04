# L4D2-Player-Stats

Core moderno de estadísticas de jugador para L4D2 competitivo.

## Surface Principal

- comandos disponibles:
  - `sm_mvp` alias de `sm_stats_mvp`
  - `sm_stats_mvp` imprime el resumen MVP/LVP survivor actual en chat y la tabla detallada de la ronda en la consola del usuario
  - `sm_stats_rank` imprime los ranks actuales del jugador en SI/CI/FF en chat y la tabla global de ranking en consola
  - `sm_stats_acc` imprime la tabla de precisión de la ronda actual en la consola del usuario
  - `sm_stats_utils` imprime las estadísticas de utilidad throwable de la ronda actual
  - `sm_stats_items` imprime las estadísticas de consumibles usados en la ronda actual
  - `sm_stats_support` imprime las estadísticas de soporte de la ronda actual
  - `sm_stats_scav` imprime las estadísticas específicas de scavenge de la ronda actual
  - `sm_stats_infect` imprime las estadísticas de capturas y soporte del equipo infectado en la mitad actual
  - `sm_stats_tank` imprime las estadísticas de la sesión de tank en la mitad actual
  - `sm_stats_help` imprime en consola la ayuda con todos los comandos de estadísticas
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

- `addons/sourcemod/scripting/l4d2_player_stats_api.sp`
  - consume la API pública de `PlayerStats`
  - exporta a logs los payloads finalizados de `round` y `player`

Plugin acompañante opcional:

- `addons/sourcemod/scripting/l4d2_player_stats_series.sp`
  - agrega agrupado corto multi-ronda para snapshots finalizados de `PlayerStats`
  - no forma parte del artefacto principal
