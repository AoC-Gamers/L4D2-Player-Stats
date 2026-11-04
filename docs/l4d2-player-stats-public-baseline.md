# Baseline público y operativo de L4D2-Player-Stats

Estado: inventario de referencia para A1. Describe el código y los documentos revisados; no certifica comportamiento dentro de SRCDS.

## Revisión y alcance

- Diseño: `L4D2-Player-Skills/tmp/propuesta_refactorizacion_player_stats.md`, versión 1.0, 4 de octubre de 2026.
- Plan: `docs/l4d2-player-stats-refactor-plan.md`, fase A1.
- Revisión de código que identifica el plan: `cacb3f05760dcc3c4d769637e9bc5e8257739ad7`.
- Checkout observado: `develop`; el plan ya estaba como archivo local no seguido antes de crear este baseline.
- Fuentes contrastadas: main, `types.sp`, `helpers.sp`, `rounds.sp`, `detect.sp`, `api.sp`, `announce.sp`, include público, traducciones y `plugin-package-map.json`.

Este documento congela nombres, firmas, valores declarados y estructura de serialización actuales. Los resultados de compilación indicados por el plan no prueban orden de callbacks, atribución ni resultados en servidor. En esta revisión no se ejecutó build ni smoke de SRCDS; los escenarios operativos quedan **sin verificar**.

## Biblioteca e include público

La biblioteca registrada es `l4d2_player_stats`; el plugin distribuido es `l4d2_player_stats.smx`. El include es `addons/sourcemod/scripting/include/l4d2_player_stats.inc`. `AskPluginLoad2` llama a `RegPluginLibrary`, crea forwards y registra las diez natives.

### Enums exportados

`StatsModeProperty` (índices implícitos consecutivos):

| Valor | Nombre |
|---:|---|
| 0 | `StatsModeProperty_BaseMode` |
| 1 | `StatsModeProperty_HasBosses` |
| 2 | `StatsModeProperty_HasRoundHalves` |
| 3 | `StatsModeProperty_SeriesScope` |
| 4 | `StatsModeProperty_EnabledSiClassCount` |
| 5 | `StatsModeProperty_VersusTeamSize` |
| 6 | `StatsModeProperty_RoundEndSignal` |
| 7 | `StatsModeProperty_RoundStartSignal` |
| 8 | `StatsModeProperty_RestartPolicy` |

`StatsEndType`: `StatsEndType_None = 0`, `StatsEndType_Half = 1`, `StatsEndType_Round = 2`, `StatsEndType_Match = 3`.

### Natives

| Firma pública | Contrato declarado |
|---|---|
| `bool PlayerStats_IsRoundActive()` | Si el snapshot de ronda actual está activo. |
| `bool PlayerStats_IsRoundLive()` | Si la ronda cruzó su señal efectiva de live. |
| `int PlayerStats_GetRoundId()` | ID actual; `0` si no hay snapshot disponible. |
| `bool PlayerStats_IsRoundPlayerSlotValid(int roundId, int slot)` | Valida el slot para el snapshot indicado. |
| `int PlayerStats_GetRoundPlayerClient(int roundId, int slot)` | Cliente enlazado al slot actual; `0` si no está disponible. El include advierte que un snapshot finalizado no garantiza un cliente vivo. |
| `int PlayerStats_GetCurrentModeProperty(StatsModeProperty property)` | Devuelve propiedad del perfil actual. |
| `bool PlayerStats_FillRoundKeyValues(int roundId, Handle kv)` | Serializa metadata y resumen del snapshot actual. |
| `bool PlayerStats_FillRoundPlayerKeyValues(int roundId, int slot, Handle kv)` | Serializa un jugador del snapshot actual. |
| `bool PlayerStats_ApplySubstitutionSnapshotToSlot(const char[] substitutionId, int slot, int client)` | Rehidrata el snapshot de sustitución identificado en un slot vivo. |
| `void PlayerStats_BroadcastRoundStats()` | Publica el resumen según la política actual de salida. |

`SharedPlugin` declara el archivo `l4d2_player_stats.smx`; `required` depende de `REQUIRE_PLUGIN`. En modo opcional el include marca las diez natives como opcionales.

### Forwards

| Firma | Tipo y efecto |
|---|---|
| `void PlayerStats_OnRoundLive(int roundId)` | `ET_Ignore`; se emite al marcar live. |
| `void PlayerStats_OnRoundEnded(int roundId, StatsEndType endType, int endReason)` | `ET_Ignore`; notifica el cierre terminal del snapshot. `endReason` usa el enum interno de razones de cierre. |
| `Action PlayerStats_OnPlayerSubstituted(const char[] substitutionId, int roundId, int slot, int incomingClient)` | `ET_Hook`; `Plugin_Handled` veta la rehidratación automática. |

El identificador de sustitución tiene formato `accountid:timestamp`. El buffer es fijo de 16 snapshots; el include dice que cada ID permanece válido hasta que esa entrada se sobrescribe. El veto del forward permite que otro plugin aplique manualmente la copia mediante la native pública.

## ConVars

Estas ocho ConVars las crea el plugin. Valores son los defaults pasados a `CreateConVar`, no una observación de configuración efectiva en un servidor.

| ConVar | Default | Bits/alcance indicado por el código |
|---|---:|---|
| `sm_stats_debug` | `0` | Máscara: `1` Core, `2` Event, `4` Detect, `8` Api, `16` Announce; `31` todos. |
| `sm_stats_enable` | `1` | Habilita el plugin. |
| `sm_stats_tracking` | `3` | `1` registrar, `2` anunciar, `3` ambos. |
| `sm_stats_accuracy` | `1` | `1` habilita precisión. |
| `sm_stats_throwables` | `3` | `1` registrar, `2` anunciar, `3` ambos. |
| `sm_stats_gamemode` | `15` | `1` Coop, `2` Versus, `4` Scavenge, `8` Survival, `15` todos. |
| `sm_stats_infected_valid_damage` | `3` | `0` todo; `1` excluye incap; `2` excluye ledge; `3` excluye ambos. |
| `sm_stats_tank_valid_damage` | `3` | Igual máscara para daño válido de Tank. |

El plugin también consulta, sin crearlas, `survivor_limit`, `z_max_player_zombies`, `z_versus_{boomer,smoker,hunter,spitter,jockey,charger}_limit`; con ReadyUp, `l4d_ready_cfg_name`; con Confogl, `confogl_{adrenaline,pipebomb,molotov,vomitjar}_limit` y `confogl_remove_defib`. Su existencia/valor predeterminado depende del servidor y de las librerías presentes.

## Comandos registrados

Todos se registran con `RegConsoleCmd` y procesan la salida con handlers del plugin. El `client = 0` no se rechaza explícitamente en la mayoría de los handlers de panel; `sm_stats_rank` exige `IsValidSurvivor(client)`, y `sm_mvp`/`sm_stats_mvp` solo dibujan panel de consola cuando el cliente es válido. La ruta de chat de MVP emite el resumen. Los requisitos detallados de modo y entrega dependen del renderizador llamado.

| Comando | Handler / salida declarada |
|---|---|
| `sm_mvp`, `sm_stats_mvp` | `Command_MVP`: resumen MVP y panel de ronda. |
| `sm_stats_rank` | `Command_Rank`: rangos MVP del cliente y tabla global. |
| `sm_stats_acc` | `Command_Acc`: tabla de precisión en consola. |
| `sm_stats_utils` | `Command_Utils`: estadísticas de arrojables. |
| `sm_stats_items` | `Command_Items`: consumo de objetos. |
| `sm_stats_support` | `Command_Support`: estadísticas de soporte. |
| `sm_stats_scav` | `Command_Scavenge`: estadísticas específicas de Scavenge. |
| `sm_stats_infect` | `Command_Infect`: control/soporte infectado. |
| `sm_stats_tank` | `Command_Tank`: sesiones de Tank. |
| `sm_stats_help` | `Command_Help`: ayuda en consola. |

## Traducciones y salida visible

Se carga `l4d2_player_stats.phrases` desde `addons/sourcemod/translations/l4d2_player_stats.phrases.txt`. El archivo contiene textos `en` y `es`, incluidos ayuda, anuncios MVP/rank, títulos, totales, columnas y paneles de precisión, consumibles, soporte, Scavenge, infectados y Tank. Esos identificadores y formatos de frase forman parte de la superficie visible consumida por los renderizadores.

Discrepancia de código: el comando registrado es `sm_stats_scav`, pero el texto de ayuda localizado lo nombra `sm_stats_scavenge`. Se conserva aquí como divergencia observada; no implica que alguno de los dos nombres esté aliasado.

## KeyValues público

Ambas natives validan que `roundId` sea positivo y coincida con `g_Round.meta.id`, hacen `KvRewind`, crean el root si falta y regresan el cursor al root antes de devolver éxito. Por ello la API serializa el snapshot residente actual; no consulta un historial de snapshots finalizados. Los valores escritos por estos serializers son numéricos salvo `identity.name`. Los subbloques se crean cuando se escriben; `mode_coop` es condicional.

### `PlayerStats_FillRoundKeyValues`: raíz `round`

- `id`.
- `context`: `base_mode`, `is_versus`, `has_bosses`, `has_round_halves`, `scavenge_round_number`, `second_half`, `scavenge_items_goal`, `scavenge_overtime`, `scavenge_score_tied`, `series_scope`, `survivor_limit`, `infected_limit`, `si_pool_mask`, `enabled_si_classes`, `team_size`, `versus_context`, `round_start_signal`, `round_end_signal`, `restart_policy`, `end_reason`.
- `totals`: `si_damage`, `tank_damage`, `witch_damage`, `common_kills`, `ff`, `deaths`, `incaps`, `heals_given`, `revives_given`.
- `players`: hijos numerados consecutivamente desde `"0"`, solo para slots activos; cada uno incluye `slot` e `identity`.

### `PlayerStats_FillRoundPlayerKeyValues`: raíz `player`

Siempre incluye `context` y `slot`. También incluye estos bloques:

| Bloque | Campos serializados |
|---|---|
| `identity` | `userid`, `accountid`, `name`, `bot`, `team` |
| `combat` | `si_damage`, `smoker_damage`, `boomer_damage`, `hunter_damage`, `spitter_damage`, `jockey_damage`, `charger_damage`, `tank_damage`, `tank_hits`, `witch_damage`, `witch_hits`, `common_kills`, `smoker_kills`, `boomer_kills`, `hunter_kills`, `spitter_kills`, `jockey_kills`, `charger_kills`, `tank_kills`, `witch_kills`, `ff_given` |
| `combat_assists` | `si_kill_assists`, `si_assist_damage`, `{smoker,boomer,hunter,spitter,jockey,charger}_kill_assists`, `{smoker,boomer,hunter,spitter,jockey,charger}_assist_damage` |
| `boss_detail` | `tank_damage`, `tank_shots`, `witch_damage`, `witch_shots` |
| `survivability` | `deaths`, `incaps`, `death_by_survivor`, `death_by_infected_player`, `death_by_infected_ai`, `incap_by_survivor`, `incap_by_infected_player`, `incap_by_infected_ai` |
| `support` | `heals_given`, `heals_received`, `revives_given`, `revives_received` |
| `infected_grab` | `smoker_damage`, `hunter_damage`, `jockey_damage`, `charger_damage`, `total_damage`, `tongue_grabs`, `hunter_pounces`, `jockey_rides` |
| `infected_support` | `boomer_vomit_victims`, `spitter_damage` |
| `scavenge` | `gascans_poured`, `gascans_dropped`, `gascans_destroyed` |
| `items` | `pills_used`, `adrenaline_used`, `medkits_used`, `defibs_used` |
| `utils` | `molotovs_thrown`, `pipebombs_thrown`, `vomitjars_thrown`, `zombies_ignited`, `players_biled`, `tanks_biled` |
| `accuracy` | Totales `{shotgun,smg_rifle,sniper,pistol}_{shots,hits,headshots}`; por familia, `{shots,hits,headshots}` y `details` con las armas disponibles. |
| `mode_coop` | `rescues_given`, solo si hay rescates y el modo base es Coop. |

Las claves `accuracy.*.details` pueden ser `pump`, `auto`, `chrome`, `spas`; `smg`, `silenced_smg`, `mp5`, `rifle`, `ak47`, `desert_rifle`, `sg552`, `m60`; `hunting`, `military`, `awp`, `scout`; `pistol`, `magnum`. Cada entrada contiene `shots`, `hits`, `headshots`.

Excepción semántica congelada: `context.round_start_signal` y la propiedad `StatsModeProperty_RoundStartSignal` leen `g_Round.meta.roundLiveSignal`; representan el origen/estado de señal **live**, aunque el nombre dice start. No renombrar ni reinterpretar durante un movimiento estructural.

Los campos públicos `totals.si_damage` y `player.combat.si_damage` se calculan con filtros de clases SI habilitadas; no son una copia directa de los acumuladores internos `survivorTotalSiDamage` y `combat.siDamage`. La refactorización debe preservar ese filtro mientras mantenga el contrato actual.

## Lifecycle y cierres públicos

Entradas relevantes observadas en el main: `AskPluginLoad2`, `OnPluginStart`, `OnAllPluginsLoaded`, `OnLibraryAdded/Removed`, `OnMapStart/End`, `OnConfigsExecuted`, `OnPluginEnd`, `OnClientPutInServer/Disconnect`, `OnRoundIsLive`, Left4DHooks (`L4D_OnFirstSurvivorLeftSafeArea_Post`, `L4D_OnGameModeChange`, `L4D2_OnEndVersusModeRound_Post`), hooks de control, cuatro forwards de Player-Skills y el hook `SDKHook_OnTakeDamage`. Los eventos de juego están registrados en `Post`.

Se inicia un snapshot con un ID creciente; puede marcarse live de inmediato según política, por ReadyUp o por señal de saferoom/refresh. Al marcar live se dispara `PlayerStats_OnRoundLive`. Antes de cerrar, el código desactiva `active` y `roundLive`, escribe `end_reason`, fija `endedAt`, finaliza sesiones de Tank y llama `PlayerStats_OnRoundEnded`; el anuncio automático es condicional a `broadcast` y al bit de announce.

| Señal de cierre | Razón interna | `StatsEndType` actual |
|---|---|---|
| `round_end` canónico | `GenericRoundEnd` | `Round` |
| `L4D2_OnEndVersusModeRound_Post` | `VersusModeRoundEnd` | `Half` si el perfil indica mitades |
| `versus_match_finished` | `VersusMatchFinished` | Si aún hay snapshot activo, el código de referencia emite `Round`; si ya estaba cerrado, emite `Match` para el último snapshot. La diferencia es un comportamiento preexistente pendiente de smoke y decisión funcional. |
| `scavenge_round_halftime` | `ScavengeRoundHalftime` | `Half` |
| `scavenge_round_finished` | `ScavengeRoundFinished` | `Half` si el perfil indica mitades |
| `scavenge_match_finished` | `ScavengeMatchFinished` | `Match` |
| `mission_lost` | `MissionLost` | `Round` |
| `map_transition` | `MapTransition` | `Round` |
| `finale_win` | `FinaleWin` | `Round` |
| `OnMapEnd` | `MapEnd` | `Round`; broadcast según helper del modo |
| `OnPluginEnd` | `PluginEnd` | `Round`, cierre sin broadcast |

El enum interno además contiene `None`. Un `round_end` genérico se ignora en Versus; la selección de señales canónicas se basa en el contexto/lifecycle. Scavenge overtime y empate actualizan metadatos, no cierran por sí solos. No se presenta esta secuencia como verificada dentro de un servidor.

## Paquete y acompañantes

`plugin-package-map.json` compila como plugin root solo `l4d2_player_stats`. El artefacto incluye `l4d2_player_stats.sp`, recursivamente `scripting/l4d2_player_stats/`, el include `l4d2_player_stats.inc` y la traducción `l4d2_player_stats.phrases.txt`. Los consumidores `l4d2_player_stats_api.sp` y `l4d2_player_stats_series.sp` existen como acompañantes, pero quedan fuera de `build.plugins` y del artefacto principal.

## Diferencias entre diseño, plan, código y documentación

1. **Smoke pendiente:** la propuesta y el plan describen escenarios para Coop, Versus/ReadyUp, Scavenge, Survival, daño, Tank terminal, Skills, sustitución y API. No se aportan resultados de servidor en esta fase; todos quedan sin verificar operativamente.
2. **`round_start_signal`:** plan/API lo documentan como la señal efectiva de live. El serializer lee `roundLiveSignal`; el nombre y el miembro fuente difieren. Se congela el significado actual, sin declarar el nombre correcto.
3. **Ayuda Scavenge:** registro y descripción del comando usan `sm_stats_scav`; la frase localizada usa `sm_stats_scavenge`.
4. **Debug documental:** el plan y el código fijan `sm_stats_debug`, bits `1/2/4/8/16` y `logs/l4d2_player_stats.log`. La divergencia que señaló la propuesta en `docs/build-system.md` se corrigió durante B1; esto no constituye evidencia de runtime.
5. **Estado cerrado:** aunque forwards notifican cierre y la API exporta snapshot actual, los natives validan únicamente el ID residente en `g_Round`; no se observa un almacén de snapshots históricos consultable.

## Límites de esta línea base

El contenido anterior congela contrato declarativo y comportamiento visible en las rutas de código inspeccionadas. No congela resultados numéricos por escenario: faltan capturas operativas de modo, valores efectivos de ConVars, secuencias reales de señales, snapshot serializado y tablas visibles. Hasta que esos escenarios se ejecuten, no afirmar equivalencia métrica ni orden universal de callbacks a partir de este documento.
