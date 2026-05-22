# Lifecycle de un servidor competitivo de L4D2

## Objetivo

Este documento describe el ciclo de vida operativo de un servidor competitivo de Left 4 Dead 2 a partir de la lectura de dos plugins base:

- `C:\GitHub\L4D2-Competitive-Rework\addons\sourcemod\scripting\confoglcompmod.sp`
- `C:\GitHub\L4D2-Competitive-Rework\addons\sourcemod\scripting\readyup.sp`

El primero actúa como base arquitectónica para cargar el modo competitivo y aplicar reglas. El segundo controla el inicio de cada mitad de la partida mediante el flujo de ready-up.

## Componentes principales

### 1. `confoglcompmod`

`confoglcompmod` es el orquestador principal del entorno competitivo. Su responsabilidad no es solo aplicar reglas, sino también montar los módulos que hacen funcionar el servidor en modo match.

En `OnPluginStart()` inicializa utilidades internas y módulos como:

- `ReqMatch`
- `CvarSettings`
- `ScoreMod`
- `BossSpawning`
- `ClientSettings`
- `ItemTracking`
- `MapInfo`
- `PasswordSystem`
- `BotKick`

También registra la librería `confogl` y añade el tag de servidor `confogl`.

### 2. `readyup`

`readyup` controla el paso entre una ronda cargada y una ronda oficialmente viva. Su trabajo es impedir que la mitad comience hasta que se cumplan las condiciones de inicio.

Expone tres modos definidos por `l4d_ready_enabled`:

- `0`: deshabilitado
- `1`: ready manual por jugador
- `2`: auto-start
- `3`: ready por equipo

## Carga del modo competitivo

### Selección del modo

La selección del modo competitivo se hace mediante `ReqMatch`, que forma parte de `confoglcompmod`.

El comando administrativo principal es:

```text
sm_forcematch <config> [mapa]
```

Ejemplo conceptual:

```text
sm_forcematch zonemod
sm_forcematch zonemod c5m1_waterfront
```

El argumento `<config>` apunta a un subdirectorio dentro de:

```text
C:\GitHub\L4D2-Competitive-Rework\cfg\cfgogl
```

En este repositorio existen modos como:

- `zonemod`
- `zoneretro`
- `eq`
- `nextmod`
- `pmelite`
- variantes `1v1`, `2v2`, `3v3`

### Resolución de rutas de config

El módulo `configs.sp` define `cfgogl` como directorio de configs personalizadas. Cuando se selecciona un modo:

1. `SetCustomCfg(cfgfile)` construye la ruta `cfg/cfgogl/<cfgfile>/`
2. si ese directorio existe, lo guarda en la cvar interna `customcfg`
3. al ejecutar un `.cfg`, primero intenta usar el archivo del modo activo
4. si no existe en el modo, hace fallback a la config por defecto

Eso significa que el modo competitivo queda compuesto por:

- configs base comunes del framework
- overrides específicos del modo activo en `cfg/cfgogl/<modo>/`

## Secuencia de activación del match

Cuando se lanza `sm_forcematch`, el flujo observado es este:

1. `RM_UpdateCfgOn()` valida que el modo exista y fija `customcfg`.
2. `RM_Match_Load()` marca el match como activo.
3. Si los plugins competitivos aún no están cargados:
   - ejecuta `sm plugins load_unlock`
   - ejecuta `sm plugins unload_all`
   - ejecuta la cadena de configs de plugins definida en `match_execcfg_plugins`
   - por defecto: `generalfixes.cfg;confogl_plugins.cfg;sharedplugins.cfg`
4. Luego ejecuta la config principal definida en `match_execcfg_on`.
   - por defecto: `confogl.cfg`
5. Marca `RM_bIsMatchModeLoaded = true`.
6. Anuncia `Match mode loaded!`.
7. Si `match_restart` está activo, reinicia o cambia el mapa tras `MAPRESTARTTIME = 3.0`.

Este reinicio es importante: el modo no solo “se carga”, sino que busca arrancar sobre un mapa limpio con los plugins y reglas ya montados.

## Qué ocurre al iniciar un mapa

Cuando un mapa empieza y el match mode ya está cargado:

1. `confoglcompmod` recibe `OnMapStart()`
2. despacha ese evento a varios módulos:
   - `MapInfo`
   - `ReqMatch`
   - `ScoreMod`
   - `BossSpawning`
   - `ItemTracking`
3. `ReqMatch` vuelve a ejecutar `RM_Match_Load()`
4. eso reaplica la config de match del modo activo en el nuevo mapa

Este detalle es central para entender el lifecycle: el servidor no trata la config competitiva como algo “one shot”, sino como un estado que debe reafirmarse cada vez que entra un mapa.

## Qué reglas se aplican realmente

Las reglas internas del modo no viven solo dentro del `.sp`. Gran parte de la política competitiva está externalizada en configs.

Hay dos capas:

### Capa 1. Framework competitivo

La provee `confoglcompmod` y sus módulos:

- enforcement de cvars
- score handling
- control de jefes
- seguimiento de items
- restricciones de clientes
- utilidades de match mode

### Capa 2. Modo de juego específico

La provee el directorio del modo en `cfg/cfgogl/<modo>/`. Ahí se definen ajustes concretos del ruleset, por ejemplo:

- límites
- cvars competitivas
- plugins opcionales
- variantes 1v1 / 2v2 / 3v3
- reglas particulares del formato

## Inicio de cada mitad: flujo de `readyup`

Una vez que el mapa y las reglas ya están cargadas, `readyup` controla el comienzo real de la mitad.

### Disparo inicial

`readyup` hace `HookEvent("round_start", RoundStart_Event, EventHookMode_Pre)`.

Cuando llega `round_start`, llama a:

```text
InitiateReadyUp()
```

### Estado de ready-up

Al entrar a ready-up:

- `inReadyUp = true`
- `inLiveCountdown = false`
- `isForceStart = false`
- resetea el estado ready de todos los jugadores
- crea y actualiza el panel visual de ready
- puede bloquear spawns SI si `l4d_ready_disable_spawns = 1`
- activa:
  - `sv_infinite_primary_ammo = 1`
  - `god = 1`
  - `sb_stop = 1`
- congela el flujo normal de inicio hasta que se cumplan condiciones

Si `l4d_ready_survivor_freeze = 1`, los survivors quedan congelados o restringidos al saferoom durante esta fase.

### Condiciones de salida de ready-up

Hay tres caminos principales:

#### A. Ready manual por jugador

Cada jugador usa:

```text
sm_ready
sm_r
```

Cuando todos los jugadores requeridos están ready, `CheckFullReady()` devuelve verdadero y comienza el countdown a live.

#### B. Ready por equipo

Con `l4d_ready_enabled = 3`, no hace falta que todos los individuos estén ready; basta con que cada equipo tenga al menos un ready válido según la lógica del plugin.

#### C. Auto-start

Con `l4d_ready_enabled = 2`, el plugin espera una cantidad mínima de jugadores y luego dispara un countdown automático usando:

- `l4d_ready_autostart_wait`
- `l4d_ready_autostart_delay`
- `l4d_ready_autostart_min`

## Countdown a live

Cuando el servidor detecta que puede iniciar la mitad:

1. ejecuta `InitiateLiveCountdown()`
2. devuelve a survivors al saferoom
3. muestra mensajes de cuenta regresiva
4. reproduce sonidos de countdown
5. usa `l4d_ready_delay` como duración base
6. si hubo `sm_forcestart`, añade `l4d_ready_force_extra`

Al llegar a cero:

1. muestra `RoundIsLive`
2. ejecuta `InitiateLive()`
3. reproduce el sonido de live

## Estado live

Cuando la ronda pasa a live:

- `inReadyUp = false`
- `inLiveCountdown = false`
- desactiva freeze de survivors
- restaura:
  - `sv_infinite_primary_ammo = 0`
  - `god = 0`
  - `sb_stop = 0`
- desactiva listeners especiales del ready system
- reinicia countdowns internos del juego
- limpia progreso/estado temporal de survivors

En ese punto la mitad ya está oficialmente en juego.

## Eventos que cancelan el countdown

Si el servidor ya estaba en countdown pero ocurre una interrupción, `readyup` cancela el arranque y vuelve al estado de ready-up.

Las causas explícitas detectadas en el código son:

- un jugador se marca `unready`
- un jugador cambia de equipo
- un jugador se desconecta
- un admin aborta el forzamiento

En esos casos:

1. se destruye el timer del countdown
2. se reejecuta `InitiateReadyUp(false)`
3. se vuelve a congelar/restringir según configuración
4. se informa a todos el motivo de cancelación

Esto evita arranques inválidos en mitad de un shuffle, disconnect o cambio de decisión.

## Fin de mapa y persistencia del estado

### En `readyup`

Si el mapa termina mientras el servidor seguía en ready-up:

- cancela auto-start
- ejecuta `InitiateLive(false)`
- limpia el estado transitorio para no arrastrarlo al siguiente mapa

### En `confoglcompmod`

`OnMapEnd()` y `OnConfigsExecuted()` permiten que distintos módulos:

- limpien su estado
- reapliquen enforcement
- rehidraten información necesaria al siguiente mapa

En especial, el diseño de `ReqMatch` hace que el match mode siga siendo un estado persistente entre mapas hasta que se descargue explícitamente.

## Descarga del match mode

Cuando se ejecuta `sm_resetmatch`, `ReqMatch` descarga el modo competitivo:

1. marca `RM_bIsMatchModeLoaded = false`
2. desactiva el estado de plugins competitivos
3. anuncia `Match mode unloaded!`
4. ejecuta la config de salida `match_execcfg_off`
   - por defecto: `confogl_off.cfg`
5. resetea flags internas para permitir una nueva carga limpia

Esto devuelve al servidor a un estado no competitivo o neutral.

## Resumen del lifecycle

El ciclo de vida completo del servidor competitivo, simplificado, queda así:

1. El servidor arranca SourceMod y carga `confoglcompmod` y `readyup`.
2. `confoglcompmod` monta módulos base y deja disponible la infraestructura de configs.
3. Un admin activa un modo con `sm_forcematch <modo> [mapa]`.
4. El framework selecciona `cfg/cfgogl/<modo>/` como ruleset activo.
5. Carga plugins/configs competitivas y reinicia el mapa.
6. Al comenzar el mapa, el match mode reaplica la config competitiva.
7. En `round_start`, `readyup` detiene el arranque normal y entra en fase de ready.
8. Jugadores o equipos marcan ready, o el sistema hace auto-start.
9. Se ejecuta countdown.
10. Si nadie interrumpe, la ronda pasa a live.
11. Al cambiar de mapa, el modo competitivo persiste y se reaplica.
12. Solo `sm_resetmatch` descarga formalmente el estado competitivo.

## Conclusión

La arquitectura observada separa bien dos problemas:

- `confoglcompmod` define y sostiene el estado competitivo del servidor
- `readyup` regula el momento exacto en que cada mitad puede empezar

En términos operativos, el lifecycle real del servidor competitivo no es solo “cargar un config”, sino:

1. elegir un ruleset
2. cargar plugins y cvars asociadas
3. reiniciar el mapa para fijar el estado
4. bloquear la ronda hasta que exista una condición válida de inicio
5. llevar la mitad a live
6. repetir el proceso de ready-up en cada nueva mitad o mapa, manteniendo persistente el modo competitivo hasta su descarga
