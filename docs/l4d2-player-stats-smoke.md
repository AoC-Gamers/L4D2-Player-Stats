# Smoke de SRCDS para la refactorización de Player-Stats

**Estado:** smoke ejecutado parcialmente en SRCDS local el 4 de octubre de 2026. Hay comparación baseline/refactor para golpes Tank ordinarios, incapacitantes y mortales en Versus, además de observaciones del cierre duplicado, sustituciones y casos concretos de Player-Skills. La matriz completa sigue pendiente; las conclusiones se limitan a los escenarios con evidencia descrita aquí.

## Propósito y comparación

Ejecutar la misma secuencia sobre dos artefactos y comparar los deltas, no solo los valores finales:

| Pasada | Código / artefacto | Identificación requerida |
|---|---|---|
| Baseline | Código de referencia `cacb3f05760dcc3c4d769637e9bc5e8257739ad7` indicado por el plan; se preparó un artefacto temporal local con SourcePawn `1.12.0.7255`. | SHA del código, SHA-256 del `.smx`, versión de SourceMod/compiler. |
| Refactor | Revisión que se evalúa; instalar el `.smx` producido para esa revisión. | SHA del código, SHA-256 del `.smx`, versión de SourceMod/compiler. |

Usar la misma instancia y configuración, mapa, modo, clientes, plugin companions y secuencia de juego en ambas pasadas. Reiniciar o limpiar el entorno de prueba entre pasadas; no sumar una ejecución a la otra. Si no se puede igualar algún dato, anotarlo y no tratar la comparación como equivalente.

El artefacto baseline instalado en esta sesión se compiló desde el HEAD exacto en `.build/smoke/baseline-src/.build/smx/addons/sourcemod/plugins/l4d2_player_stats.smx`, SHA-256 `0221c407c5b6af85d74203b5b9a57393f0d14c6bea87052e61f7c0b5ac17f4e6`. `.build/smoke/` es local e ignorado por Git; volver a compilar y verificar el hash si se reconstruye la sesión.

No se prescribe una ruta de conexión, despliegue ni comando remoto. La persona que opera el SRCDS usa su método habitual y anota la instancia examinada. Se puede usar un probe temporal fuera del repositorio para observar forwards o invocar natives de prueba; debe anotarse su versión y retirarse al terminar. Si un caso no puede ejecutarse, marcarlo **no ejecutado**.

La sesión usa dos sondas temporales de observación compiladas en `.build/smoke/`: `tank-probe.smx` (SHA-256 `9743c9d0de727c174016a18c1e59c8550efa41bbad91538eedcc95288fff41d2`) y `full-probe.smx` (SHA-256 `d89d39305130d0015b608ae9045f7ea736709046873e80fa8f8cd61a9a3d1949`). La primera registra señales Tank y terminales; la segunda registra timestamps, secuencia, tick, mapa, modo, ronda, eventos, forwards y capturas KeyValues anonimizadas. Los logs y snapshots baseline se copiaron a `.build/smoke/server-baseline/`. Verificar los hashes antes de la pasada refactor y retirar ambas sondas al finalizar.

## Resultado baseline observado

Servidor local `dev_aoc`, SourceMod `1.12.0.7230`, compilador `1.12.0.7255`, mapa `c2m1_highway`, modo Versus, dos cuentas humanas. La configuración de aislamiento para Tank fue `director_no_specials=1` y `sb_stop=1`; `sm_stats_debug=31`. Los archivos exactos de la sesión están en `.build/smoke/server-baseline/` y los cambios temporales para restaurar constan en `.build/smoke/session-notes.md`.

| Escenario | Señales observadas | Resultado base |
|---|---|---|
| Golpe ordinario, ronda 6 | `SDK_OnTakeDamage` y `player_hurt` para daño 24 en el mismo tick. | Una señal de golpe ordinario; queda por comparar el acumulado de sesión con el refactor. |
| Golpe incapacitante, ronda 6 | SDK daño 24 con salud previa 4; `player_incapacitated_start` en el mismo tick; sin `player_hurt` para ese golpe. | La lógica base acredita la salud previa 4 a la sesión Tank y registra la incap por separado. |
| Muerte directa, ronda 7, `survivor_max_incapacitated_count=0` | SDK daño 24 con salud previa 6, `player_hurt` daño 24/salud 0 y `player_death` atribuido al Tank humano en el mismo tick 31345. | La captura base evita acreditar 24 desde `player_hurt` y acredita solo la salud previa 6 al resolver la muerte; `survivability.deaths=1`, `death_by_infected_player=1`, `incaps=0` en la captura cerrada del superviviente. |

El valor de daño Tank acreditado descrito arriba procede de la ruta de código baseline y la secuencia observada; la sonda externa no lee el acumulado interno de sesión. Esa cifra requiere una comprobación directa de `sm_stats_tank` en una repetición comparable. Las observaciones no demuestran equivalencia operativa completa.

## Resultado refactor observado

El SMX integrado `5b6dd2ba2f17c25ece832a4824a17454bf66406353f328f534ddca0da37ffefc` se cargó temporalmente en la misma instancia, verificado por hash dentro del contenedor, y se reinició `c2m1_highway`. La pasada está separada por las marcas `refactor_loaded_sha5b6dd2ba` y `refactor_round1_start`; sus logs y snapshots se copiaron a `.build/smoke/server-refactor/`. El servidor informó cero errores de SourceMod durante estos casos.

| Escenario | Señales y cantidad observadas | Comparación acotada |
|---|---|---|
| Golpes ordinarios e incapacidad, ronda 1 | Cuatro golpes de 24; SDK terminal 24 con salud previa 4 y `player_incapacitated_start` en el mismo tick, sin `player_hurt` terminal. La traza vinculó ambas señales con `damageId=1`. `sm_stats_tank` mostró 100 de daño, 5 puñetazos, 1 incap y 0 muertes. | La secuencia de señales coincide con baseline ronda 6; `4×24+4=100` es la política de cantidad base. En los KV cerrados de la víctima: `incaps=1`, `deaths=1`, `incap_by_infected_player=1`; los mismos valores del baseline después de morir por sangrado. |
| Muerte directa, ronda 4, `survivor_max_incapacitated_count=0` | SDK terminal 24 con salud previa 4, `player_hurt` 24/salud 0 y `player_death` del Tank humano en el mismo tick. La traza vinculó las tres señales con `damageId=3`, resolvió `applied` en hurt y `already_applied` en death. | Misma política que baseline ronda 7: se acredita una sola vez la salud previa, aunque los casos comenzaron con salud terminal distinta (4 frente a 6). Los KV cerrados de la víctima coinciden: `deaths=1`, `incaps=0`, `death_by_infected_player=1`. No se capturó `sm_stats_tank` antes del cierre de esta ronda. |

La ronda 2 del refactor se descarta de la comparación: el Tank bot actuó antes del traspaso humano y la ronda terminó. En estas pasadas Tank faltan transferencia durante un impacto, hittable, víctima ya incapacitada, dos sesiones/controladores y debug apagado. La sustitución reentrante síncrona, el veto y la restauración tardía se probaron después en runs separados descritos abajo. Los casos observados sustentan solo la correlación y los campos públicos indicados, no equivalencia operativa completa.

En la ronda 4 el juego emitió un segundo `round_end` quince segundos después del primero. La sonda guardó otro KV público, pero observó un solo `PlayerStats_OnRoundEnded` para esa ronda. Los archivos de ronda y de los cinco slots en las capturas 32 y 33 son idénticos byte por byte. El snapshot adicional es una lectura de diagnóstico; no indica un segundo cierre del core.

ZoneMod `v2.9.1b` se activó después para probar sustituciones. En la ronda 1 de esa pasada, ReadyUp emitió un solo `PlayerStats_OnRoundLive`. Un humano disparó una vez, pasó a espectador (`player_bot_replace`), regresó al mismo bot dos segundos después (`bot_player_replace`) y disparó otra vez. El core mantuvo el slot 0 y la misma cuenta; no emitió `PlayerStats_OnPlayerSubstituted`. Los KV posteriores registran dos disparos de escopeta en ese slot, y dos capturas sucesivas conservaron ese total. Es una comprobación del retorno de la misma cuenta en el refactor, sin pasada baseline equivalente para este subcaso.

La sustitución posterior entre dos humanos emitió un forward para el slot 0. Antes del cambio, ese slot tenía dos disparos de escopeta y estaba vinculado al primer humano; después quedó vinculado al segundo con cero disparos, sin transferir automáticamente el contador. La misma captura posterior mostró una anomalía: `PlayerStats_GetRoundPlayerClient` devolvía el cliente entrante tanto para el nuevo slot 0 como para su anterior slot infectado 1. El código baseline comparte la misma función de asignación y también permite esta vinculación duplicada. Se añadió una corrección local que desprende el cliente del slot histórico conservando los contadores; falta repetir el smoke con el nuevo SMX antes de darla por verificada.

En el retest `zm1v1`, el `forcestart` produjo `OnRoundIsLive` de ReadyUp en el tick 35951. El core registró `reason=readyup_live` y emitió un solo `PlayerStats_OnRoundLive` en ese tick. La primera salida del saferoom ocurrió después, en el tick 45003; su callback dejó el estado sin cambios porque ReadyUp estaba presente. Esto verifica la ruta usada en esta ronda, pero no descarta la asimetría de `Round_RefreshLiveState`: su rama `ReadyUpOrSafeArea` aún puede marcar live por una consulta al saferoom aunque ReadyUp esté presente. Falta probar ese camino por separado y decidir su política antes de considerarlo equivalente.

ZoneMod impide recargar plugins manualmente durante el match. Para probar el SMX final de la corrección de slots, SHA-256 `f97441a91fc28b898227ac5073169ae05c6d268fb73824b55e4250b080358622`, se cambió de nuevo a `zm1v1` con `sm_forcechangematch` y se verificó el hash dentro del contenedor. En el run `20261004_214559_c2m1_highway`, la captura 1 antes del traspaso mostraba slot 0→cliente 2 superviviente y slot 1→cliente 3 infectado. Tras `player_bot_replace` y `bot_player_replace` del segundo humano, la captura 2 mostró slot 0→cliente 3 superviviente y slot 1→cliente 0 sin equipo. El forward de sustitución ocurrió una vez y la traza de identidad cambió `slot=1>0`: la vinculación duplicada quedó resuelta en este caso. Hubo un `weapon_fire` antes del traspaso, pero los contadores de precisión de ambos slots permanecieron en cero; esta secuencia no verifica preservación de métricas de disparos.

En otro run limpio de `zm1v1` (`20261004_214947_c2m1_highway`) se activó `sm_stats_smoke_substitution_reenter=1` y se dejó `sm_stats_smoke_substitution_handled=0`. Tras dos `weapon_fire` del superviviente y su reemplazo por bot, el segundo humano tomó el único bot. Dentro de `PlayerStats_OnPlayerSubstituted`, el probe invocó síncronamente `PlayerStats_ApplySubstitutionSnapshotToSlot` y registró `apply_ok=1`, `slot_client_before=0`, `slot_client_after=3`, `return=Plugin_Continue`. La traza del core registró una restauración de la native y el cambio de slot `1>0`. Las capturas 2 y 3 del slot 0 son idénticas byte por byte y muestran un disparo de escopeta y uno de pistola; el slot 1 no tiene cliente activo. Esta secuencia verifica que no hubo una segunda restauración visible al regresar del forward con `Plugin_Continue`; el veto `Plugin_Handled` se prueba aparte.

En el run limpio `20261004_215228_c2m1_highway` se usaron `sm_stats_smoke_substitution_reenter=1` y `sm_stats_smoke_substitution_handled=1`. El forward del traspaso registró `apply_ok=1`, `slot_client_before=0`, `slot_client_after=3` y `return=Plugin_Handled`. La captura 2 mostró un disparo de escopeta en el slot 0 del humano entrante y ningún cliente activo en el slot 1. Se observó así la aplicación manual síncrona con veto de la ruta automática. Aún falta el caso de veto sin aplicación manual y la llamada tardía después del forward.

El veto sin aplicación manual se ejecutó en el run `20261004_215544_c2m1_highway` con `sm_stats_smoke_substitution_reenter=0` y `sm_stats_smoke_substitution_handled=1`. Hubo un `weapon_fire` del superviviente antes de `player_bot_replace`. El forward del traspaso registró `apply_ok=0`, `slot_client_before=0`, `slot_client_after=0` y `return=Plugin_Handled`; no apareció una traza de restauración de la native. En la captura posterior, el nuevo humano estaba en el slot 0 con `shotgun_shots=0`, y su antiguo slot 1 quedó sin cliente activo. El disparo previo no se rehidrató automáticamente bajo el veto. La llamada tardía se prueba por separado a continuación.

La llamada tardía se probó con una sonda temporal nueva, SHA-256 `38c50c1663fa2639fee1e0b4db6d98efad5fab9324793531e42d16779e356762`, en `zm1v1`. La opción `sm_stats_smoke_substitution_late=1` guarda el ID solo en memoria, devuelve `Plugin_Handled` y, 0,2 segundos después, valida ronda, slot, cliente y userid antes de llamar dos veces a la native. En el run `20261004_224252_c2m1_highway`, el cambio de equipos durante la preparación produjo un traspaso adicional sin métricas; no se usa como prueba de preservación. Después de marcar `late_native_ready`, Test-Subject disparó una vez con escopeta (`weapon_fire` tick 11470) y dejó el único superviviente; >lechuga tomó ese bot en tick 11708. La sonda registró `validation_ok=1`, `attempt1_ok=1`, `attempt2_ok=0` en tick 11731. El core trazó exactamente una restauración y un rechazo. El slot 1 tenía `shotgun_shots=0` en la captura 3 anterior al disparo; en la captura 4, ya vinculado a >lechuga (userid 27), tenía `shotgun_shots=1`. Esto verifica la llamada posterior al forward para una transición vigente y el consumo único del ID en este caso. Se devolvió la cvar tardía a `0`; evidencia local en `.build/smoke/server-refactor/late-native/`.

## Sonda temporal de `OnTakeDamageAlive` y `OnTakeDamageAlivePost`

La sonda completa se recompiló con `SDKHook_OnTakeDamage`, `SDKHook_OnTakeDamageAlive` y `SDKHook_OnTakeDamageAlivePost` para clientes existentes y nuevos. El SMX temporal probado tiene SHA-256 `062541045aa84cb12734da5b7095fa2409cfc0f943875cd3f5ac8d8437d07ec0`; el plugin de producto no cambió de hooks en esta prueba. Log, traza del core y KV de la ronda Tank: `.build/smoke/server-refactor/alive-hooks-tank/`. La sonda muestrea algunos `player_hurt` de daño ajeno al Tank cada ocho eventos; por eso la ausencia de una línea `player_hurt` en ella no demuestra ausencia del evento.

| Caso observado | Secuencia en el mismo tick | Lectura acotada |
|---|---|---|
| Superviviente humano dispara a Hunter humano, tick 4181 de `zm1v1` | `OnTakeDamage` 138.87, `Alive` 138.00, `player_hurt` 138/vida 112, `AlivePost` 138/vida 112. | `Alive` recibió 138.00 frente a 138.87 del hook anterior en este disparo; `AlivePost` vio la vida posterior. |
| Segundo disparo, mortal, tick 4256 | `OnTakeDamage` 138.97/vida previa 112, `Alive` 138.00/vida previa 112, `AlivePost` 138.00/vida −26, `player_death`. La traza del core también confirma `player_hurt` en este tick; la sonda lo omitió por muestreo. | El hook post se ejecutó en daño mortal a infectado especial y leyó vida interna negativa. No sirve inferir el orden exacto de `player_hurt` desde el log muestreado. |
| Un golpe de garra de Hunter humano a superviviente humano, tick 12048 | `OnTakeDamage` 24/vida 100, `Alive` 24/vida 100, `AlivePost` 24/vida 76; la traza del core confirma `player_hurt`. | Los tres hooks se ejecutaron para daño recibido por el superviviente. Solo se observó un golpe en ese intento. |
| Tank humano a superviviente humano, ticks 21288, 24301, 24509 y 24711, ZoneMod normal | Cada golpe de garra de 24 siguió `OnTakeDamage` → `Alive` → `player_hurt` → `AlivePost`; la vida humana pasó 100→76→52→28→4. | El hook post leyó el estado posterior en golpes ordinarios. Se desactivaron disparos de bots con `sb_dont_shoot=1` y aparición de commons con `z_common_limit=0` e intervalos de horda en 3600 durante la parte final. |
| Tank humano mata directamente al superviviente humano, tick 24911 | Con 4 de vida previa: `OnTakeDamage` 24 → `Alive` 24 → `player_hurt` 24/vida 0 → `AlivePost` 24/vida interna −20 → `player_death`; mismo atacante userid 27 y víctima userid 26 en todas las señales. | `AlivePost` ocurrió antes de `player_death`. El core capturó `damageId=1`, resolvió `applied` en hurt y `already_applied` en death. El KV posterior de la víctima tiene `deaths=1`, `death_by_infected_player=1`, `incaps=0`. |
| Tank humano incapacita al superviviente humano, tick 17766 de otra ronda ZoneMod con `survivor_max_incapacitated_count=2` | Con 4 de vida previa: `OnTakeDamage` 24 → `player_incapacitated_start`. **No se invocaron `Alive` ni `AlivePost` para ese golpe**. | El core capturó `damageId=1` en `OnTakeDamage` y resolvió `applied` en la incapacidad. El KV posterior de la víctima tiene `incaps=1`, `incap_by_infected_player=1`, `deaths=0`; `sm_stats_tank` mostró 100 de daño, 5 puñetazos, 1 incap y 0 muertes. |

En esta ejecución, `Alive` y `AlivePost` aportan una observación de vida antes y después de los golpes ordinarios y de la muerte directa; `AlivePost` ofrece una señal adicional entre `player_hurt` y `player_death` para el golpe letal del Tank. La vida interna −20 no es el valor público: `player_hurt` informó 0. **La incapacitación exige mantener `OnTakeDamage` y `player_incapacitated_start`**: los hooks Alive no se ejecutaron en su golpe terminal. La sonda no probó daño temporal de salud, FF, Witch, impactos simultáneos ni otro modo; estos datos no justifican cambiar todavía la correlación Tank del producto. La salida `sm_stats_tank` tras la muerte directa mostró 172 de daño y una muerte en la sesión, pero incluye impactos sobre bots y no se usa como comparación de daño humano aislado. No se generaron archivos `errors*` de SourceMod en estas pasadas. La evidencia de incapacitación está en `.build/smoke/server-refactor/alive-hooks-incap/`.

## Player-Skills: BoomerPop y JockeySkeetMelee

Para aislar el caso, el `confogl.cfg` temporal de `zm1v1` fijó `z_common_limit=0` y dejó a Boomer como único infectado especial; se recargó el modo y se verificaron las cvars efectivas. En el run `20261004_230405_c4m1_milltown_a`, ronda 2, Test-Subject fue el superviviente y >lechuga el Boomer humano. La captura 3 registró `boomer_kills=0`. Hubo cuatro muertes de Boomer; dos produjeron también `BoomerPop` en el mismo tick de su `BoomerKill` (30396 y 33476, con `time_a` de 1,5 y 2,02 segundos). En ambas, Player-Skills envió primero el `kill_event` y luego el `skill_event` con `implies_si_death=1` y `suppressed_kill_type=BoomerKill`. La captura 5 registró `boomer_kills=6` para esas cuatro muertes. Esto confirma una duplicación entre streams distintos; la deduplicación por `(stream, ID)` no la cubre. Los logs y KV de ambos productores quedaron en `.build/smoke/server-refactor/skills-boomerpop-before-fix/`.

El importador pasó a correlacionar muertes entre ambos streams mediante generación del proveedor, ronda, generación de mapa, tick observado, userid de actor y víctima, y tipo de kill. El segundo forward coincidente no añade otro kill ni sus asistencias; se conserva el primer crédito. El SMX corregido SHA-256 `b65a0f4532f2ee8b1b78772ce9ef287d51213cf4a2f7cdc1ce583a3f601cb09c` compiló sin warnings, se verificó por hash en el servidor y se cargó al recargar `zm1v1`. En el run `20261004_231958_c4m1_milltown_a`, ronda 1, cuatro muertes Boomer generaron cuatro `BoomerKill` y dos `BoomerPop`; las parejas de ticks 38743 y 42401 registraron `duplicate SI death suppressed`. Las capturas 1 y 2 del mismo slot humano muestran `boomer_kills=0→4`. No apareció un log `errors_*.log` de SourceMod en esta pasada. La evidencia está en `.build/smoke/server-refactor/skills-boomerpop-after-fix/`. Esta prueba cubre la pareja BoomerKill→BoomerPop en el mismo tick y sin asistencias; orden inverso, otros tipos, asistencias y límite de tick siguen pendientes.

Para contrastar una habilidad que absorbe la kill sin un forward genérico previo, el `zm1v1` temporal dejó solo Jockey, sin commons. En `c4m1_milltown_a` se aplicaron `sm_safeitemkill_saferooms=0` y `sm_safeitemkill_items=0` mediante `cfgogl/zonemod/shared_settings.cfg` y recarga del modo; así quedaron disponibles las melee del saferoom. El usuario habilitó temporalmente `director_allow_infected_bots` para obtener Jockeys bot y después lo devolvió a `0`. En el run `20261004_234703_c4m1_milltown_a`, ronda 1, >lechuga controló el único superviviente. Dos muertes de Jockey bot con melee, ticks 20822 y 21328, produjeron únicamente `JockeySkeetMelee` IDs 1 y 2: ambos payloads tienen `implies_si_death=1`, `suppressed_kill_type=JockeyKill`, `shots=1` y `perfect=1`. Stats aceptó una consecuencia por evento, sin `JockeyKill` genérico en esos ticks; la captura 6 del slot de >lechuga muestra `jockey_kills=2`. No apareció `errors_*.log` de SourceMod. Evidencia en `.build/smoke/server-refactor/skills-jockey-melee/`. Esta prueba no cubre asistencias ni reenvíos del mismo ID.

## Siguiente pasada preparada

El SMX SHA-256 `91c22c15c3b0b64b6d611f77f9a607f43433bd52c859b0db8385eddfd465a67b` está instalado en `dev_aoc` bajo `zm1v1`; contiene el gate independiente de arrojables, la corrección del refresco live con ReadyUp y el resultado tipado de `tank_spawn`. `sm_stats_tracking=0`, `sm_stats_accuracy=0` y `sm_stats_throwables=1` están fijados para el próximo lanzamiento; commons=0 y survivor_limit=1. La sonda y el helper temporal `sm_stats_smoke_give_throwable <survivor_userid> <molotov|pipe_bomb|vomitjar>` están cargados. La recarga desconectó a Test-Subject; el usuario pidió esperar a su regreso para reconectar ambas cuentas y ejecutar la prueba. **No hay todavía resultado de SRCDS para estos cambios nuevos.** El procedimiento y restauración de cvars constan en `.build/smoke/session-notes.md`.

## Ficha de cada pasada

Copiar esta ficha para **Baseline** y **Refactor**, y una vez por modo/escenario cuando cambie el entorno.

```text
Fecha/hora y zona:
Operador:
Instancia SRCDS (referencia local del operador):
Mapa / campaña / variante:
Modo base y submodo (Coop, Versus, Scavenge, Survival):
Fase inicial (saferoom, live, mitad, run, cierre):
Código SHA / smx SHA-256:
SourceMod y compiler:
Extensiones y versiones (incl. Left4DHooks):
Plugins y versiones: l4d2_player_stats, Player-Stats API/Series,
  Player-Skills, ReadyUp, Confogl y otros que afecten el escenario:
Clientes, equipo, identidad estable y rol (humano/bot; anonimizar en el informe):
ReadyUp / Confogl presente y configuración relevante:
ConVars efectivas:
  sm_stats_enable=
  sm_stats_tracking=
  sm_stats_accuracy=
  sm_stats_throwables=
  sm_stats_gamemode=
  sm_stats_infected_valid_damage=
  sm_stats_tank_valid_damage=
  sm_stats_debug=
Otras ConVars relevantes:
  survivor_limit=  z_max_player_zombies=
  z_versus_*_limit=
  l4d_ready_cfg_name=
  confogl_*_limit=  confogl_remove_defib=
Precondiciones y diferencias frente a la otra pasada:
```

Registrar los valores **efectivos** del servidor; los valores por defecto del código no son evidencia de la configuración activa. `sm_stats_debug` usa máscara: `1` Core, `2` Event, `4` Detect, `8` Api, `16` Announce; `31` los activa todos. Para cambiarlo durante una pasada se puede usar el comando SourceMod `sm_cvar sm_stats_debug <valor>` desde el mecanismo administrativo ya disponible. Volver a `0` después de la ventana de diagnóstico y comparar con la pasada sin debug.

## Evidencia que se conserva

Para cada caso, registrar valores iniciales y finales y su **delta**. Adjuntar o referenciar capturas tomadas en el mismo punto lógico de ambas pasadas:

- Log existente `logs/l4d2_player_stats.log`, con timestamps y máscara de debug anotada.
- KeyValues obtenidos mediante un consumer/probe API ya instalado: salida `round` de `PlayerStats_FillRoundKeyValues` y `player` de `PlayerStats_FillRoundPlayerKeyValues`. Anotar `round.id`, `context`, `totals`, slot e identidad, y los bloques pertinentes (`combat`, `combat_assists`, `boss_detail`, `survivability`, `support`, `infected_grab`, `infected_support`, `scavenge`, `items`, `utils`, `accuracy`, `mode_coop`). La API actual serializa el snapshot residente; no usarla como si fuera historial de rondas cerradas. Si no hay consumer, marcar **KV no observado**.
- Salidas de comandos existentes, usando el comando registrado adecuado: `sm_mvp`/`sm_stats_mvp`, `sm_stats_rank`, `sm_stats_acc`, `sm_stats_utils`, `sm_stats_items`, `sm_stats_support`, `sm_stats_scav`, `sm_stats_infect`, `sm_stats_tank`, `sm_stats_help`. Ejecutarlos desde un cliente/entorno permitido por el handler y anotar destino (chat/consola) y texto. El nombre registrado es `sm_stats_scav`.
- Con un probe de forwards, secuencia y argumentos de `PlayerStats_OnRoundLive`, `PlayerStats_OnRoundEnded` y `PlayerStats_OnPlayerSubstituted`; anotar la cantidad de emisiones y el orden observado. Si no puede instalarse un probe temporal, marcar **forward no observado**.
- Resultado por pasada: `coincide`, `diferencia`, `no ejecutado` o `no comparable`; descripción del primer delta discrepante y evidencia que lo demuestra.

No interpretar ausencia de log/forward como prueba de que no se ejecutó si no hay probe para observarlo. Las trazas de debug deben permitir explicar una diferencia, no definir por sí solas el resultado correcto.

## Procedimiento común

1. Completar la ficha y confirmar que el plugin/consumidores y el mapa corresponden a la pasada.
2. Anotar ConVars efectivas, clientes, modo y fase. Capturar KV/contadores iniciales si están disponibles.
3. Ejecutar un escenario aislado; no mezclarlo con otro antes de registrar el cierre o delta.
4. Capturar log, salidas visibles, KV y forwards disponibles. Anotar señales reales en el orden en que se observaron; no asumir orden universal entre callbacks.
5. Repetir desde un estado limpio con la otra revisión y la misma secuencia.
6. Comparar deltas campo a campo y salidas. Separar diferencias atribuibles a ConVars, roster, plugin opcional o señal no observada de diferencias reproducibles del artefacto.

## Escenarios

### Lifecycle y cierres por modo

| Modo / preparación | Acción controlada | Comprobar en ambas pasadas |
|---|---|---|
| Coop | Actividad antes de salir del saferoom; avanzar live; perder misión y reintentar; completar transición y finale en ejecuciones separadas. | Pre-live no aporta deltas; `mission_lost` separa intentos; `map_transition` y `finale_win` cierran el intento. ID, razón, una notificación de cierre y salida automática según tracking/broadcast. |
| Versus sin ReadyUp | Entrar, cruzar live, completar una mitad y después el match. | Pre-live no cuenta; live una vez; cierre de mitad y cierre de match diferenciados; comparar `StatsEndType` y razón mediante forward si se puede observar. |
| Versus con ReadyUp | Repetir el caso con ReadyUp activo; repetir con carga tardía solo si la configuración de prueba permite hacerlo sin cambiar la secuencia. Incluir el caso de saferoom ya despejado al inicializar. | Fase efectiva, un solo live, ninguna activación temprana. Registrar nombre/valor efectivo de `l4d_ready_cfg_name`, orden de señales y disponibilidad real de la librería. |
| Scavenge | Jugar ambas mitades; registrar vertidos de bidones por actor, overtime/empate y cierre de mitad/match. | Gascans y slot/actor correctos por mitad; overtime y empate como contexto; una señal tardía no se atribuye a la mitad siguiente. |
| Survival | Ejecutar dos runs sobre el mismo mapa, con cierre entre runs. | Cada run obtiene live/cierre propios; los totales no se fusionan entre intentos. |
| Cierre de mapa/plugin | Llegar a `OnMapEnd` mediante el flujo normal; observar unload/reload solo si forma parte de la matriz administrada. | Razón/cierre, snapshot residente y política de broadcast. Para unload, comprobar cleanup y que no queden hooks/escritores duplicados tras la recarga; no tratar una recarga como recuperación de historia perdida. |

Para carga/descarga de bibliotecas opcionales, anotar si ReadyUp/Confogl estaban presentes y cuándo. Comparar callbacks y ConVars relevantes. Si no se dispone de un entorno que permita verificar carga tardía o retirada, marcar esos subcasos como no ejecutados; no inferirlos del build.

### Métricas, filtros y comandos

Con el modo permitido por `sm_stats_gamemode`, preparar acciones separadas para daño SI, Tank, Witch, FF, precisión y arrojables. Anotar los valores efectivos de `sm_stats_tracking`, `sm_stats_accuracy`, `sm_stats_throwables`, `sm_stats_infected_valid_damage` y `sm_stats_tank_valid_damage` en cada ejecución.

- Comprobar el daño autorizado por clase y el filtro público de clases SI habilitadas en `round.totals.si_damage` y `player.combat.si_damage`; comparar también los campos por clase.
- Comparar `sm_stats_debug=0` y `31` sobre secuencias idénticas: las trazas pueden variar, los totales, KV y salidas públicas no.
- Incluir al menos un daño válido con arma no reconocida y verificar que no oculte el delta de daño.
- Ejecutar los comandos visibles que correspondan, especialmente `sm_stats_acc`, `sm_stats_utils`, `sm_stats_items`, `sm_stats_support` e `sm_stats_infect`; registrar texto y canal exactos.
- Si se combinan gates, probar una combinación por pasada y registrar cada valor. No atribuir diferencias de gates a la extracción estructural sin aislarlas.

### Tank: daño ordinario y terminal

Ejecutar cada variante separadamente, conservando un atacante Tank identificable y registrando víctima, vida/incapacidad previa, controlador y sesión.

1. Golpe ordinario a survivor vivo.
2. Golpe que incapacita.
3. Golpe que mata.
4. Golpe a víctima ya incapacitada.
5. Cambio de controlador del Tank y dos sesiones distintas.
6. Desconectar/reutilizar un client slot antes de una nueva secuencia controlada.

Comparar por separado `combat.tank_damage`/`totals.tank_damage`, `tank_hits`/ataques observables, `tank_kills`, `survivability.incaps` y `survivability.deaths`, más la salida `sm_stats_tank`. No confundir daño de survivor al Tank con daño que la sesión Tank inflige a survivor. Guardar log con `sm_stats_debug=31` durante la secuencia terminal y repetir con `0` para comprobar invariancia de resultados. Registrar explícitamente cualquier callback ambiguo, cantidad ausente o evento fuera de orden; no convertirlo en una atribución asumida.

### Player-Skills: lotes, supresión y boss detail

Requiere `l4d2_player_skills` cargado y sus versiones registradas. Usar sesiones de juego o un consumer de diagnóstico ya disponible; no fabricar mensajes ni volver a enviar paquetes manualmente.

- Kill y asistencia normales; comparar kill/assist y slot/identidad.
- Una habilidad que absorbe/suprime una kill ordinaria; confirmar que la consecuencia aparece una vez, según la familia propietaria, y que no se duplica desde ambas fuentes.
- Evento y finalización de sesión de boss; comparar `boss_detail` con `combat.tank_damage`/`combat.witch_damage` y tiros, comprobando que el detalle no vuelve a sumar daño.
- Repetir el mismo lote solo si el propio flujo existente de Skills permite una repetición controlada; verificar delta cero en la segunda recepción.
- Probar lote parcial, participante desconectado y paquete tardío después del cierre cuando el flujo/harness existente los produzca. Registrar IDs, generación/round y participantes observados si el probe los expone. No reasignar un client slot reutilizado ni reabrir el snapshot.

Para cada caso anotar forwards recibidos, contribución atribuida/suprimida y handles/KV observables si el diagnóstico existente lo expone. Si no se puede generar un lote repetido/parcial o paquete tardío de manera soportada, dejarlo pendiente en vez de simularlo.

### Sustitución, reentrada y API

Requiere el consumidor API/Series existente y, para probar invocación síncrona dentro del forward, un consumer o probe temporal capaz de hacerlo.

- Sustitución del mismo humano y de un humano diferente; comparar slot, identidad, generaciones expuestas, totales previos/posteriores y KeyValues del slot.
- Caso de veto con `Plugin_Handled`; confirmar que la rehidratación automática queda vetada y que una aplicación manual documentada ocurre como máximo una vez.
- Desde el forward, si un consumer instalado invoca síncronamente `PlayerStats_ApplySubstitutionSnapshotToSlot`, comprobar que al regresar el core no rehidrata otra vez ni pisa una identidad/slot cambiado. Repetir native después del forward, con ID/snapshot todavía válido, y comprobar contrato de expiración/capacidad observado.
- Reentradas con slot invalidado/reutilizado o un segundo cambio de sustitución: comprobar que la operación no aplica estado pendiente a otra identidad. Registrar orden y resultado del veto.
- Leer snapshot mediante API probe/Series antes y después de cierre. El contrato actual consulta el snapshot residente, no un historial; comparar `round.id`, campos KV y disponibilidad de cliente, sin exigir cliente vivo para snapshot cerrado.

Si no hay un consumer que invoque la native durante el forward, el punto de reentrada queda **no ejecutado**; un caso de llamada posterior no lo sustituye.

## Registro de resultados

Completar una fila por combinación de modo/variante/artefacto. Adjuntar referencias a las capturas y no copiar secretos ni datos personales sin anonimizar.

| ID | Modo / escenario | Baseline: delta y evidencia | Refactor: delta y evidencia | Estado | Diferencia / explicación pendiente |
|---|---|---|---|---|---|
| | | | | No ejecutado | |

```text
Artefacto baseline SHA-256:
Artefacto refactor SHA-256:
ConVars que difirieron:
Plugins/extensiones que difirieron:
Señales/forwards no observados:
Diferencias reproducibles:
Escenarios no ejecutados y motivo:
Conclusión: equivalencia operativa aún no establecida / diferencias enumeradas
```

En esta sesión se observó en SRCDS el subconjunto descrito en las secciones anteriores; las variantes sin fila o evidencia siguen **no ejecutadas**. Un build correcto no prueba la correlación de callbacks del juego, y el smoke parcial no establece equivalencia de la matriz completa.
