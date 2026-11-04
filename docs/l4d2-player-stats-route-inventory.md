# Inventario de rutas de métricas (fase A1)

Estado: inventario estático del código; no implementa la refactorización.

## Alcance y evidencia

Revisión del checkout `cacb3f05760dcc3c4d769637e9bc5e8257739ad7`, que coincide con la revisión de referencia del plan. Se inspeccionaron el main, `detect.sp`, `helpers.sp`, `rounds.sp`, el contrato propuesto y sus gates. Las líneas siguientes son de ese checkout.

Durante la revisión, `l4d2_player_stats.sp` recibió un cambio concurrente en el working tree que sustituye el registro directo `Detect_OnTakeDamage` por un stub `SDK_OnTakeDamage`. Este inventario describe el estado base de `HEAD` y la ruta de detección correspondiente, no ese cambio en curso.

- **Verificado en código** significa que se inspeccionó el registro, la lectura, los gates y/o la mutación indicada en SourcePawn.
- **No observado en runtime** significa que no se ejecutó SRCDS ni se capturó una secuencia de eventos, resultados KV/públicos o paneles. Este documento no establece orden efectivo de callbacks, cantidades de juego, equivalencia ni baseline operativo.
- Los destinos en la última columna son la arquitectura propuesta por el plan, no módulos ya presentes.

Referencias raíz (desde el repositorio):

- `addons/sourcemod/scripting/l4d2_player_stats.sp` — entradas y registro.
- `addons/sourcemod/scripting/l4d2_player_stats/detect.sp` — detección y escrituras actuales.
- `addons/sourcemod/scripting/l4d2_player_stats/helpers.sp` — gates, mapeo de slots y mutadores compartidos.
- Propuesta: `/home/lechuga/GitHub/l4d2_sourcemod/L4D2-Player-Skills/tmp/propuesta_refactorizacion_player_stats.md`.
- Secuencia y propiedad destino: `docs/l4d2-player-stats-refactor-plan.md`.

## Entradas, wrappers y gates compartidos

`OnPluginStart` registra eventos de daño, combate, utilidad, soporte y Scavenge en modo `EventHookMode_Post` (main, líneas 105–145). Los stubs del main delegan a `Detect_*`; `OnClientPutInServer` instala `SDKHook_OnTakeDamage` y `OnClientDisconnect` lo retira (main, líneas 321–333). El callback SDK actual es `Detect_OnTakeDamage`, de solo observación y retorno `Plugin_Continue` (detect, líneas 1043–1068). Que el callback exista en código no verifica cuándo ni con qué orden corre en un servidor.

Gates compartidos verificados en `helpers.sp`:

- `Stats_IsTrackingEnabled`, `Stats_IsAccuracyEnabled` y `Stats_IsThrowablesEnabled` combinan el modo activo con sus respectivos bits de ConVar (líneas 96–124); los valores predeterminados de configuración están en el main, líneas 90–98.
- `Stats_IsCompetitiveMode` es Versus o Scavenge (líneas 126–130).
- `Stats_ShouldCountVictimForDamage` exige víctima survivor válida y aplica la política de incap/ledge configurada (líneas 137–164). Se usa para daño infectado no Tank y daño de Tank, no como filtro universal de `player_hurt`.
- `Stats_GetSurvivorCurrentHealthTotal` suma salud permanente y `floor(m_healthBuffer)` (líneas 168–177); es la base de la captura terminal Tank observada en este código, no una medición de salud efectiva validada en juego.
- `Stats_EnsurePlayerRoundSlot` resuelve/reutiliza o crea slot y puede fallar con `-1` (líneas 1793–1822). Los mutadores `Stats_AddSpecial*` validan slot y escriben los deltas asociados (desde línea 878).

El contexto live que consumen los detectores se actualiza desde lifecycle (`OnRoundIsLive`, `L4D_OnFirstSurvivorLeftSafeArea_Post`, eventos de ronda/Scavenge y `L4D2_OnEndVersusModeRound_Post`; main, líneas 336–487, con delegación a `rounds.sp`). El gate `Stats_IsRoundLive()` está verificado en el código, pero la precedencia entre señales ReadyUp/saferoom y el momento en que cambia durante partidas no está observado aquí.

## Rutas actuales por familia

`Escritura` nombra tanto los campos por jugador como los totales de ronda actuales. `accuracy` no tiene total global equivalente en estas rutas; se actualiza en el slot del jugador.

| Entrada/callback | Fuente leída | Gates y filtros verificados | Escritura actual | Destino propuesto |
|---|---|---|---|---|
| `player_hurt` → infectado jugador a survivor | `userid`, `attacker`, `dmg_health`, `weapon` | Ronda live; daño positivo y attacker válido; atacante infectado/víctima survivor; tracking y modo competitivo; Tank desvía a la ruta Tank; no Tank usa `Stats_ShouldCountVictimForDamage` | Grab por clase: Smoker/Hunter/Jockey/Charger a `infectedGrab.*Damage`, `totalDamage` y totales de clase/grab; Spitter a `infectedSupport.spitterDamage` y total. `detect.sp:6–69` | `modules/infected.sp`; si la separación de daño lo exige, frontera `damage/` conforme al plan |
| `player_hurt` → Tank a survivor | `userid`, `attacker`, `dmg_health`, `weapon` | Ronda live, tracking, attacker válido y rama infectado→survivor; Tank llama `Detect_RecordTankHurt`; gate de víctima mediante ConVar Tank/incap/ledge. El índice/slot se obtiene antes de la división por clase | `tankSessions[].totalDamage` y `controllers[].damage`; conteo de ataques por `tank_claw`, `tank_rock` u otra arma; `lastHealthByVictim` puede suprimir el evento si hay una captura pendiente. `detect.sp:31–37, 1290–1340` | `modules/tank.sp`; captura/correlación terminal en `damage/` |
| `player_hurt` → survivor a SI/Tank | `userid`, `attacker`, `dmg_health`, `hitgroup`, `weapon` | Ronda live; daño positivo y attacker válido; ambos supervivientes/infectado según rama; puerta inicial `tracking || accuracy`; arma/familia/detail del evento con fallback a última arma conocida. Registra precisión antes de retornar si tracking está apagado. No aplica la política incap/ledge de víctima survivor | Si tracking: `combat.tankDamage`, `tankHits`, total Tank; o daño por clase + `combat.siDamage` y total SI. Precisión se escribe aparte en accuracy familiar/detallada. `detect.sp:71–122`; mutadores de precisión `helpers.sp:1293–1392` | Daño de combate `modules/combat.sp`; precisión `modules/accuracy.sp`; resolver compartido solo para correlación si corresponde |
| `player_hurt` → fuego amigo survivor | `userid`, `attacker`, `dmg_health` | Ronda live; daño positivo y attacker válido; dos survivors distintos; tracking | `combat.ffGiven` y `survivorTotalFF`. `detect.sp:124–159` | `modules/combat.sp` |
| `infected_hurt` → Witch | `entityid`, `attacker`, `amount`, `hitgroup`, `weapon` | Ronda live; puerta amplia `tracking || accuracy || throwables`; entidad debe pasar `IsWitchEntity`; daño positivo y atacante survivor; slot válido. Precisión se registra antes de exigir tracking para el daño | Si tracking, `combat.witchDamage`, `witchHits`, `survivorTotalWitchDamage`; precisión familiar/detail por impacto. `detect.sp:305–365` | `modules/combat.sp`, y la vista de precisión en `modules/accuracy.sp` |
| `weapon_fire` → disparos y lanzamiento | `userid`, `weapon` | Live; puerta `tracking || accuracy` antes de resolver cliente/arma; survivor, arma no vacía, slot válido. Registra shots/historial de arma. Solo luego consulta `Stats_IsThrowablesEnabled` para reconocer lanzamiento | `accuracy.*Shots`, `accuracyDetails.shots[]`; con throwables: molotov/pipe/vomitjar thrown por jugador y totales. `detect.sp:414–491`; mutadores `helpers.sp:1293–1330` | `modules/accuracy.sp` y `modules/utility.sp` |
| `infected_death` → común muerto | `attacker`, `gender` (el segundo se conserva para traza) | Live; tracking; attacker resuelto como survivor; slot válido | `combat.commonKills` y `survivorTotalCommonKills`. `detect.sp:240–303` | `modules/combat.sp` |
| `player_death` → SI muerto / muerte survivor / Tank terminal | `userid`, `attacker`, `weapon` | Live y tracking; identifica ramas según equipos/clase. SI kill normal se acredita aquí si víctima es Tank **o** Player-Skills no está disponible; en caso contrario se omite para importar consecuencias de Skills. Survivor víctima incrementa muerte y clasifica atribución. Tank atacante ante muerte survivor intenta consumir captura previa. `detect.sp:160–238` | Kill por clase vía `Stats_AddSpecialKillByClass`; muerte survivor y total/atribución; Tank session puede consumir `lastHealthByVictim`, incrementar ataques/deaths y marcar wipe. | `modules/combat.sp` para kills/supervivencia; `modules/tank.sp` para sesión. Terminal resuelto conjuntamente en `damage/` |
| `player_incapacitated_start` por Tank | `userid`, `attacker`, `weapon` | Live, tracking, modo competitivo; survivor víctima y Tank atacante válidos | `Detect_RecordTankIncap`: ataque/incap de sesión y, si la víctima pasa política de daño, posible daño terminal desde `lastHealthByVictim`, que luego limpia. `detect.sp:493–512, 1342–1372` | `modules/tank.sp`; correlación en `damage/` |
| `L4D_OnIncapacitated_Post` → estado survivor | Parámetros forward: victim, attacker y metadatos; el cuerpo ignora explícitamente los campos no usados | Live, tracking, survivor víctima válida, slot válido | `survivability.incaps`, total de incaps y partición según tipo de atribución. `detect.sp:367–412` | `modules/survivor.sp` |
| `tank_spawn`, disconnect/controller updates y `SDKHook_OnTakeDamage` | `tank_spawn.userid`; client del lifecycle; para SDK, victim/attacker y parámetros de daño | Tank spawn solo live + tracking + modo competitivo; disconnect solo competitivo y controller actual; SDK requiere tracking + live + competitivo, survivor víctima y Tank attacker; captura solo si daño supera health total actual y cliente está en rango | Abre/actualiza sesión/controlador; SDK escribe `lastHealthByVictim[victim]`, sin cambiar daño ni sumar daño en ese callback. `detect.sp:1043–1068, 1070–1163`; main: líneas 321–333, 593–596 | Callback stub en main; wrapper `inputs/sdkhooks.sp`, captura/resolución `damage/`, aplicación `modules/tank.sp` |
| Forward de control SI (tongue, pounce, jockey, vomit) | Parámetros tipados victim/attacker/boomerExplosion | Stubs main y wrappers actuales; reglas/gates en `Detect_OnGrabWithTonguePost`, `Detect_OnPouncedOnSurvivorPost`, `Detect_OnJockeyRidePost`, `Detect_OnVomitedUponPost` (`detect.sp:966–1041`) | Grab/support/pressure por jugador y totales infectados; no es fuente de daño numérico continuo `player_hurt` | `inputs/libraries.sp` → `modules/infected.sp` |
| Utility: `player_now_it`, `vomit_bomb_tank`, `zombie_ignited` | userid/attacker, `by_boomer`, `fire_ammo`; ignición también exige throw ya registrado | Live + throwables; survivor válido/slot. `player_now_it` excluye `by_boomer`; `zombie_ignited` excluye `fire_ammo` y también requiere `molotovsThrown > 0` en el slot | Players/tanks biled y totals; zombies ignited y total. `detect.sp:514–607` | `modules/utility.sp` |
| Consumibles: pills/adrenaline/defib y heal/revive/rescue | Userid/subject/rescuer/victim | Live + tracking; cada participante se valida como survivor y se resuelve a slot independientemente | Pills, adrenaline, medkits, defibs usados y totales; support heals/revives/rescues given/received en slots correspondientes. `detect.sp:609–814` | Consumo y soporte a `modules/survivor.sp` (plan: soporte/consumibles sin daño numérico) |
| Scavenge objetivo: pour/drop/destroy | `userid` | Live + tracking + modo Scavenge; userid debe resolver a survivor; slot válido | `scavenge.gascansPoured/Dropped/Destroyed` y totals. `detect.sp:816–964` | `modules/scavenge.sp` |

## Importación de Player-Skills

Los forwards externos se reciben en el main y delegan a `Detect_OnPlayer*`; los cuatro tipos relevantes son skill, kill, boss event y boss session finalized (main, líneas 372–394). Los gates compartidos de las rutas de importación son tracking, biblioteca Player-Skills disponible, live y validez del event/session mediante native del proveedor.

| Entrada | Lectura y gate específico | Escritura actual / autoridad | Destino propuesto |
|---|---|---|---|
| `PlayerSkills_OnKillDetected(eventId,type)` | Evento válido; `FillKillEventKeyValues`; raíz `kill_event`; actor_userid resuelve a survivor; slot válido; tipo convertido a clase. Lee asistencias `userid` y `damage` | Kill SI por clase; asistentes y su daño en `combatAssists.*` y totals. `detect.sp:1560–1710` | `inputs/player_skills.sp` → `modules/skills_import.sp` |
| `PlayerSkills_OnSkillDetected(eventId,type)` | Además rechaza `None`; evento/raíz/actor/slot válidos. Lee `properties.implies_si_death` y `suppressed_kill_type_id`; opcionalmente consume la lista assists | Si implica muerte SI: kill por clase + assists/daño de assist. No importa daño continuo de combate. `detect.sp:1711–1814` | `inputs/player_skills.sp` → `modules/skills_import.sp` |
| `PlayerSkills_OnBossEventDetected(eventId,type)` | Boss event válido; actor leído por `FillBossEventKeyValues` desde `boss_event.actor_userid`; survivor y slot válidos | Witch crown/dead → `Stats_AddWitchKill`; otros tipos no incrementan este contador en el switch actual. `detect.sp:1477–1514, 1815–1870` | `inputs/player_skills.sp` → `modules/skills_import.sp` |
| `PlayerSkills_OnBossSessionFinalized(sessionId,type)` | Sesión válida; `FillBossSessionKeyValues`; raíz `boss_session`; recorre `damage_entries`, cada userid debe resolver a survivor y slot válido | Solo `bossDetail.tankDamage/tankShots` o `witchDamage/witchShots` por jugador. Es detalle del boss; no modifica `combat.tankDamage`/`witchDamage`. `detect.sp:1871–1978` | `inputs/player_skills.sp` → `modules/skills_import.sp` |

Los helpers que leen KeyValues crean/eliminan los handles en las rutas inspeccionadas. El código no prueba que un lote no pueda repetirse ni que dos señales distintas sean una sola muerte; no se encontró aquí deduplicación local por generación/ID de lote.

## Lectura del inventario y asuntos a preservar al migrar

1. `player_hurt` es hoy una entrada compartida con ramas infectado→survivor, survivor→infectado y FF. No es una sola política de cantidad: las dos rutas de daño a survivor usan `dmg_health`, Witch usa `infected_hurt.amount`, y el daño terminal Tank puede usar un valor capturado antes (`health + floor(buffer)`).
2. Precisión está acoplada a daño por `player_hurt`/`infected_hurt`, y los tiros están acoplados a `weapon_fire`. `weapon_fire` retorna antes del conteo de arrojables si tracking y accuracy están apagados. Es la ruta/gate presente en código; la combinación solo-throwables no se verificó en servidor.
3. El callback SDK actual solo prepara `lastHealthByVictim`; la escritura de daño Tank ocurre en `player_hurt` para golpes ordinarios o como consumo terminal en incap/death. El código inspeccionado no demuestra el orden real entre estas señales ni la correspondencia de la captura con un único impacto.
4. Player-Stats mantiene dos fuentes condicionales de kills SI: `player_death` cuando Skills no está disponible y forwards de Skills cuando lo está; Player-Skills boss session alimenta detalle separado. La ausencia de duplicados, lotes tardíos/repetidos y atribución tras reutilización de slot son preguntas de runtime/integridad, no resultados de esta inspección.
5. No se observaron sesiones Coop, Versus/ReadyUp, Scavenge, Survival, daño terminal Tank, precision/utilidad ni outputs KV/paneles. La matriz de escenarios y el baseline operativo de A1 permanecen pendientes de smoke SRCDS.

## Destinos estructurales resumidos

| Área actual | Destino previsto en la propuesta/plan |
|---|---|
| Stubs y callbacks públicos | Firmas externas en `l4d2_player_stats.sp`; delegación única a handlers |
| Adaptación de eventos, forwards y disponibilidad externa | `inputs/` (`events`, `libraries`, `sdkhooks`, `player_skills`) |
| Cantidad/correlación de daño y captura Tank | `damage/` |
| Daño SI, Tank survivor-victim, Witch, FF y combat kills | `modules/combat.sp` más `modules/tank.sp` donde corresponda |
| Daño/grab/support de infectados y control | `modules/infected.sp` |
| Accuracy shots/hits/headshots | `modules/accuracy.sp` |
| Lanzamientos y efectos de utility | `modules/utility.sp` |
| Incaps/muertes/soporte/consumibles de survivor | `modules/survivor.sp` |
| Scavenge | `modules/scavenge.sp` |
| Consecuencias SI/assist y boss detail de Skills | `modules/skills_import.sp` |

Este inventario es evidencia de código para A1. No declara completado el baseline operativo ni valida runtime.
