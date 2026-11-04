# Plan de refactorización interna de L4D2-Player-Stats

## Entrega a develop — 1 de noviembre de 2026

El usuario autoriza publicar el refactor en `develop` con la matriz runtime
incompleta. Reporta funcionamiento sin problemas en el uso observado; esa
observación y el smoke parcial no acreditan equivalencia completa de métricas.

Quedan pendientes los escenarios del [smoke](l4d2-player-stats-smoke.md) y de la
matriz de este plan: arrojables con tracking/accuracy apagados, carga tardía de
ReadyUp y saferoom despejado, modos y gates restantes, variantes terminales Tank,
órdenes/asistencias/reenvíos de Skills y lectura de cierres por API/Series.
No se repiten pruebas de juego ni se cambia la instalación al publicar.

## Evidencia previa y alcance

**Estado actual (4 de octubre de 2026):** las fases A–F están integradas y el core, paquete, release y acompañantes compilaron sin warnings según las validaciones anotadas abajo. D2 (correlación terminal Tank) y E2 (cierre/reentradas) están implementadas. El smoke local comparó baseline y refactor para golpes Tank ordinarios, incapacitantes y mortales en Versus, y observó campos públicos y cierre en esos casos. También probó sustituciones entre humanos, aplicación síncrona del snapshot con `Plugin_Continue` y `Plugin_Handled`, veto sin aplicación manual y restauración tardía con consumo único; probó la supresión de doble atribución `BoomerKill`/`BoomerPop` y dos `JockeySkeetMelee` sin `JockeyKill` genérico. La matriz operativa permanece parcial: faltan, entre otros, carga tardía de ReadyUp con saferoom ya despejado, otros modos, hittable, transferencia durante impacto, más variantes de Skills y debug apagado. Esta evidencia no demuestra equivalencia completa. Véase el [registro operativo](l4d2-player-stats-smoke.md). Las entradas de avance siguientes son cortes históricos; sus estados pendientes describen cada corte y no el estado actual.

Después de ese smoke se corrigió el gate de `weapon_fire` para permitir arrojables con tracking y accuracy apagados, se hizo autoritativo el forward de ReadyUp en el refresco live de Versus y se añadió resultado tipado a la traza de `tank_spawn`. El core, paquete, distribución, ZIP y los acompañantes API/Series compilaron y validaron tras esos cambios; el SMX está cargado en el SRCDS local. Estas tres rutas nuevas aún esperan smoke específico.

Sonda adicional de daño, 4 de octubre: en el SRCDS local se observaron `SDKHook_OnTakeDamageAlive` y `SDKHook_OnTakeDamageAlivePost` en golpes ordinarios y muerte directa de Tank, además de daño humano↔SI. En la incapacitación por Tank se ejecutó `OnTakeDamage` y `player_incapacitated_start`, pero ninguno de los hooks Alive. Se conserva la correlación actual D2; los hooks nuevos quedan solo en una sonda temporal y su evidencia está en el [registro operativo](l4d2-player-stats-smoke.md).

Este documento conserva el orden de fases y controles junto con notas cronológicas de implementación y validación.

**Corte histórico previo a D2/E2:** A1 contaba con inventarios estáticos; su baseline operativo aún esperaba el SRCDS. B1–C3 estaban en integración y el baseline funcional no se había observado. En ese corte, el Tank atacante seguía en la ruta legacy, la liquidación de pendientes Tank esperaba D2 y la cobertura de traza era parcial. La guarda de sustitución aún esperaba smoke. El estado posterior de estas fases y sus pruebas se registra en las actualizaciones siguientes y en el [registro operativo](l4d2-player-stats-smoke.md).

Validación del corte preparado: `make deps-smx`, `make build-smx` sin warnings, `make package-smx`, `ci-validate-artifact.sh` sobre paquete y distribución, `make release` y `git diff --check` terminaron correctamente. Los dos acompañantes opcionales compilaron individualmente después de la extracción de Skills. La extracción de 15 funciones Tank se comparó contra `HEAD` y sus cuerpos son idénticos. Esta validación cubre código y artefacto, no el comportamiento en juego.

**Corte histórico F, antes del smoke integrado D2/E2:** `api.sp` quedó dividido en `api/forwards.sp` y `api/exports.sp`; `announce.sp` se movió íntegro a `presentation/announce.sp` y su contenido se comparó byte por byte. Los helpers de contexto, jugadores, rondas, resolución de daño, consultas y bootstrap quedaron en sus dueños; `helpers.sp` conserva la taxonomía de armas y la identificación de Witch. `SDK_OnTakeDamage` pasó parámetros por valor a una observación tipada y conservó entonces la captura legacy. El build sin warnings, validadores, ZIP y compilación individual de API/Series pasaron después del corte SDK. C3 seguía parcial y D2/E2 todavía no se habían integrado en esa fecha; su estado actual y evidencia se describen en las secciones superiores y en el smoke.

**Corte D2/E2/C3 del 4 de octubre:** D2 reemplazó `lastHealthByVictim` por operaciones Tank acotadas por ejecución, mapa, ronda, tick, vida, userids y sesión/controlador; E2 introdujo `Closing`, el tratamiento de operaciones pendientes, congelación del snapshot y validaciones tras forwards síncronos. Esta nota precede al smoke descrito arriba. Posteriormente se cargó el artefacto en SRCDS y se observó la evidencia acotada allí registrada; las variantes aún no ejecutadas siguen pendientes.

Fuente de diseño: `/home/lechuga/GitHub/l4d2_sourcemod/L4D2-Player-Skills/tmp/propuesta_refactorizacion_player_stats.md`, versión 1.0 del 4 de octubre de 2026. La propuesta fija los invariantes I01–I12 y el destino arquitectónico; este plan ordena el trabajo y sus comprobaciones. Referencia de código: `cacb3f05760dcc3c4d769637e9bc5e8257739ad7` (`develop` y `main` en la revisión inicial).

## Resultado buscado y límites

Mantener un solo `l4d2_player_stats.smx`. Todas las entradas externas propias quedan definidas en `l4d2_player_stats.sp`; los wrappers convierten fuentes externas en observaciones tipadas; cada métrica tiene un único propietario de escritura; el daño tiene una autoridad numérica explícita por ruta. API, comandos, traducciones y salidas existentes conservan su contrato salvo un cambio funcional documentado y decidido como trabajo separado.

No se modifican Player-Skills, los dos acompañantes opcionales, la política de daño del servidor ni las fuentes de cantidad ordinaria durante el movimiento estructural. No se añaden un bus, un tercer plugin, una API entre plugins ni infraestructura de pruebas al repositorio. El árbol propuesto en el diseño es un destino, no una lista de archivos vacíos que deban crearse.

## Referencia verificable

- El checkout inicial estaba limpio en `develop` y coincidía con el SHA de la propuesta.
- `make build-smx` compiló el core con SourcePawn `1.12.0.7255`, sin warnings. `make package-smx` y `SOURCEMOD_ARTIFACT_DIR=.build/package-smx bash scripts/ci-validate-artifact.sh` terminaron correctamente.
- Los acompañantes `l4d2_player_stats_api.sp` y `l4d2_player_stats_series.sp` también compilaron por separado, sin warnings. El build normal los omite porque no están en `build.plugins`.
- La compilación y el empaquetado no verifican orden de callbacks, atribución ni resultados dentro de SRCDS. El smoke posterior al corte inicial fue parcial, con los límites descritos arriba.

La fase A debe capturar un baseline operativo antes de afirmar equivalencia de métricas: modo, ConVars, secuencia de señales, snapshot público y tabla visible de cada escenario disponible. Cuando un escenario no pueda ejecutarse, se marca como **sin verificar**; no se reemplaza con una conclusión de compilación.

Inventarios estáticos A1: [rutas y propietarios](l4d2-player-stats-route-inventory.md) y [contrato público](l4d2-player-stats-public-baseline.md). Completar la observación en SRCDS sigue pendiente.

## Contrato que se congela en A

| Superficie | Evidencia a conservar |
|---|---|
| Biblioteca e include | `l4d2_player_stats`, diez natives, tres forwards, firmas, orden y valores de enums, `SharedPlugin` y natives opcionales. `CreateNative` sigue registrándose en `AskPluginLoad2`. |
| KeyValues | Raíces `round` y `player`; claves, tipos, valores por defecto, lista de slots y disponibilidad del snapshot cerrado. `round_start_signal`/`StatsModeProperty_RoundStartSignal` mantienen su significado actual de señal **live**. |
| Sustitución | Formato `accountid:timestamp`, buffer de 16, rebind de la misma identidad, veto del forward y native de rehidratación. |
| Comandos y presentación | Once comandos del core, requisitos de modo/llamador, `client = 0` donde hoy funciona, chat/consola, textos, formatos y traducciones EN/ES. |
| Configuración y logs | Nombres y valores de ConVars. `sm_stats_debug` conserva bits `1` Core, `2` Event, `4` Detect, `8` Api, `16` Announce y ruta `logs/l4d2_player_stats.log`. |
| Artefacto | Core, main, directorio privado, include público y traducciones; los acompañantes continúan fuera del paquete principal. |

El inventario A se construye sobre `l4d2_player_stats.sp`, `types.sp`, `helpers.sp`, `detect.sp`, `rounds.sp`, `api.sp`, `announce.sp`, el include público, las frases y `plugin-package-map.json`. Para cada entrada se registra: fuente, gate, identificadores, cantidad o hecho, propietario actual, contador y total afectado, exposición por API y salida visible. Se registran por separado hechos del código y comportamientos todavía no observados en servidor.

## Propietarios y autoridades iniciales

La tabla es el punto de partida de la migración; una fuente distinta requiere una decisión y un corte independiente.

| Flujo | Cantidad o hecho autorizado inicialmente | Propietario destino |
|---|---|---|
| Survivor → SI/Tank y fuego amigo | `player_hurt.dmg_health` | `modules/combat.sp` |
| Survivor → Witch | `infected_hurt.amount`, entidad Witch validada | `modules/combat.sp` |
| Infected no Tank → survivor | `player_hurt.dmg_health`, política actual de incap/ledge | `modules/infected.sp` |
| Tank → survivor ordinario | `player_hurt.dmg_health` | `modules/tank.sp` |
| Tank → survivor terminal | Señal terminal y captura previa válida resueltas como una operación; no dos importes completos | `damage/` resuelve; `modules/tank.sp` escribe |
| Incap de survivor | `L4D_OnIncapacitated_Post` como transición de estado | `modules/survivor.sp` |
| Precisión | `weapon_fire` y eventos de impacto con los gates existentes | `modules/accuracy.sp` |
| Arrojables, soporte, consumibles y Scavenge | Eventos especializados actuales | `modules/utility.sp`, `survivor.sp`, `scavenge.sp` |
| Kills/asistencias y detalle de bosses de Skills | Consecuencias y lotes válidos de Skills | `modules/skills_import.sp` hacia `combat_assists`/`boss_detail`; nunca como daño continuo nuevo |

`signalId` identifica una recepción, `damageId` una operación correlacionada, y ninguno se presume equivalente a un ID de evento de Skills. `client`, `userid`, entidad, vida, slot y generación conservan roles distintos. Un dato ausente usa un indicador de disponibilidad, no un cero confirmado.

Los IDs externos de Player-Skills crecen por carga y vuelven a empezar al recargar el proveedor. E1 deduplica reenvíos del mismo `(generación del proveedor, stream, ID)`. El smoke real de `BoomerPop` reveló que `player_death` puede enviar primero un `kill_event` y `boomer_exploded` enviar después un `skill_event` con `implies_si_death=1` para la misma víctima, actor y tick. La supresión del proveedor alcanza el anuncio tardío, pero no retira el forward de kill ya emitido. Sin correlación entre streams, dos `BoomerPop` elevaron `boomer_kills` de cuatro muertes reales a seis. El importador ahora correlaciona ambas familias por generación, ronda, mapa, tick, actor, víctima y tipo; el retest registró cuatro kills para cuatro muertes. Véase el [registro operativo](l4d2-player-stats-smoke.md). La prueba de otros tipos y órdenes sigue pendiente.

## Secuencia de ejecución

Cada paquete de la tabla es un cambio revisable. Se conecta la ruta nueva y se desconecta su escritor anterior en el mismo paquete. Una fase no se declara terminada solo por mover archivos. Los cambios de fuente o política estadística se separan de los paquetes de movimiento estructural.

| Paquete | Dependencia y trabajo | Salida comprobable |
|---|---|---|
| **A1. Mapa y baseline** | Partir del SHA indicado; inventariar callbacks, gates, escrituras y superficies públicas. Guardar resultados operativos disponibles por modo y la matriz de escenarios de abajo. Clasificar discrepancias como movimiento estructural, aclaración de contrato, protección de integridad o cambio de política. | Cada contador afectado tiene fuente, propietario y resultado observable de referencia o marca de falta de smoke. |
| **B1. Tipos y entradas** | Tras A1, crear solo los tipos de observación/resultado usados y el orden de includes necesario. Llevar al main los stubs de SourceMod, eventos, Left4DHooks, ReadyUp, Skills, SDKHooks, comandos y handlers de natives; mantener firmas y fase de registro. Un callback registrado apunta a una función del main y delega exactamente una vez al handler vigente hasta migrar esa ruta. | Compila; hay una entrada visible por señal, ninguna señal perdida y ningún contador nuevo. `Stats_ConsumeEventContext()` desaparece de cada ruta migrada una vez que la adaptación real reemplaza su firma. |
| **B2. Rutas sin daño numérico** | Tras B1, migrar por familia lifecycle, identidad, soporte/consumibles, utilidad, control infectado y Scavenge a `inputs/` y módulos propios. Cada wrapper lee una vez, devuelve razón tipada y evita llevar `Event` al módulo de dominio. | Cada familia conserva su gate, efectos y salida pública; el código viejo deja de escribir esa familia. |
| **B3. Entradas de daño sin nueva autoridad** | Tras B1, adaptar `player_hurt`, `infected_hurt`, SDKHooks e incap/muerte a datos tipados. Mantener los hooks de eventos en `Post`. El stub SDK solo observa/captura y devuelve `Plugin_Continue`; ningún hook posterior acredita daño por su cuenta. | La fuente numérica y los contadores siguen siendo los de A1. Queda una sola ruta de escritura activa por métrica. |
| **C1. Estado e identidad** | Tras B, separar `config.sp`, `runtime/context.sp`, `runtime/players.sp` y `runtime/rounds.sp`. Mantener un snapshot de ronda, límites de arrays y semántica active/live. El estado de sustitución y las generaciones tienen un dueño claro. | Carga tardía y cambio de librería no instalan dos escritores; slot desconectado o reutilizado no recibe trabajo pendiente anterior. |
| **C2. Consultas y salidas** | Tras C1, extraer de `announce.sp` las lecturas compartidas a `queries.sp`; conservar `presentation/` y la serialización pública en `api/`. La consulta no crea slots ni modifica estadísticas. | Resúmenes, ranking, paneles y KV concuerdan con A1 para los escenarios comprobados. |
| **C3. Traza** | Tras B/C1, centralizar `trace.sp` con run/mapGeneration/roundId/signalId, `damageId` cuando exista, etapa, consumidor y razón tipada. Mantener máscara y ruta actuales; limitar volumen y registrar anomalías de integridad de manera acotada. | Se puede seguir recepción → adaptación → resolución/aplicación/descarte; debug activado o apagado no cambia cifras. Corregir la discrepancia de debug en `docs/build-system.md`. |
| **D1. Daño ordinario** | Tras B3/C, migrar Witch, survivor→SI/Tank/FF e infected no Tank en cortes separados. El resolver entrega cantidad con base declarada (`event_reported` inicialmente) y cada módulo aplica jugador + total juntos. Precisión puede ser otra vista del mismo impacto. | `combat`, `infected`, `accuracy` y sus totales conservan autoridades y gates; una segunda observación no duplica un contador. |
| **D2. Tank terminal** | Tras D1 y baseline de callbacks, reemplazar `lastHealthByVictim` por captura/operación pendiente vinculada a víctima, vida, actor, sesión, ronda y generación. Correlacionar `SDKHook_OnTakeDamage`, `player_hurt`, incap y muerte sin asumir orden universal. Resolver antes de aplicar cuando sea posible; una compensación aplica solo el delta pendiente de la misma operación. | Golpe ordinario, incapacitante y mortal cuentan una sola cantidad autorizada; ataques, incaps y deaths conservan su métrica separada. Ambigüedad, caducidad y desbordamiento producen una razón, no atribución inventada. |
| **E1. Skills** | Tras C1/D, adaptar cada uno de los cuatro forwards en `inputs/player_skills.sp`; validar disponibilidad de cada native, copiar solo campos necesarios y liberar los KeyValues propios. Definir propiedad/supresión de kills por familia y deduplicación local por generación, stream, ID y contexto; controlar aplicaciones parciales. | Repetir un lote no repite contribuciones; `boss_detail` nunca vuelve a sumar `combat.*Damage`; participantes no resueltos no se reasignan por client reutilizado. |
| **E2. Cierre y reentradas** | Tras D2/E1, introducir una fase interna `Closing`: bloquear nuevas escrituras ordinarias, resolver o descartar pendientes atribuibles de la misma ronda, fijar snapshot, emitir forward y presentar. Revalidar generación/slot tras el forward de sustitución. Mantener el cierre diferenciado Half/Round/Match. | El snapshot cerrado es legible y estable; señales terminales repetidas no duplican daño, forward ni panel, excepto la notificación de Match diferenciada ya prevista. |
| **F. Limpieza y documentación** | Tras aceptar A–E, retirar rutas antiguas sin uso y actualizar `README.md`, arquitectura, modelo, API y build. Revisar si la propuesta se copia como registro de decisión o se integra en la documentación vigente. | `rg` no encuentra escritores duplicados ni módulos que reciben `Event`/KV de Skills; build, paquete y escenarios aceptados; no hay dos descripciones vigentes contradictorias. |

### Orden de cortes dentro de daño

1. `infected_hurt`/Witch, por ser una ruta numérica separada.
2. `player_hurt` survivor→SI/Tank/FF, conservando el fallback de arma y precisión independiente.
3. `player_hurt` infected no Tank→survivor, conservando su gate de modo y daño válido.
4. Tank atacante→survivor ordinario y terminal como corte vertical conjunto: captura SDK, evento ordinario, incap, muerte, sesión y controlador. El daño survivor→Tank ya pertenece al corte 2. No dejar dos escritores de compensación entre pasos.

## Comprobaciones por paquete y por fase

En cada paquete con `.sp`/`.inc`: `make deps-smx`, `make build-smx`, `git diff --check` y revisión de firmas, gates y escritores. Corregir cualquier warning nuevo. Si se toca un include público, una native, un forward o su schema, compilar también ambos acompañantes como consumidores. En los cierres B, C, D, E y F, compilar ambos acompañantes aunque no se publiquen.

Cuando cambie la estructura o el empaquetado: `make package-smx`, validación con `SOURCEMOD_ARTIFACT_DIR=.build/package-smx bash scripts/ci-validate-artifact.sh` y revisión del árbol resultante. `make release` se ejecuta al cierre final para comprobar el ZIP; no implica publicar una release. Los nuevos `.sp` internos deben permanecer bajo `addons/sourcemod/scripting/l4d2_player_stats/`, que el manifiesto ya copia de forma recursiva.

El smoke de SRCDS compara los deltas de contadores, KV y salidas con A1. No se crea un plugin de pruebas permanente. Como mínimo:

| Escenario | Observación exigida |
|---|---|
| Coop | Antes de salir del saferoom no se cuenta; `mission_lost` separa reintento; `map_transition` y `finale_win` cierran su intento. |
| Versus con y sin ReadyUp | Pre-live no cuenta; live se emite una vez; `L4D2_OnEndVersusModeRound_Post` cierra la mitad, y `versus_match_finished` distingue Match. Revisar carga tardía de ReadyUp y saferoom ya despejado. |
| Scavenge | Bidones por actor/mitad; overtime y empate como contexto; halftime, segunda mitad y Match sin atribuir una señal tardía a la siguiente mitad. |
| Survival | Cada run empieza live y se cierra sin mezclar intentos del mismo mapa. |
| Daño y gates | SI, Tank, Witch, FF, precisión y arrojables con tracking/accuracy/throwables combinados. Arma desconocida no suprime daño válido. Debug `0` y `31` producen los mismos totales. |
| Tank terminal | Golpe ordinario, incapacitante, mortal y a víctima ya incapacitada; cambio de controlador, dos sesiones y client reutilizado. Comparar daño, ataques, incaps y deaths por separado. |
| Skills | Kill/asistencia, skill que absorbe kill, boss detail, lote repetido, lote parcial, desconexión y paquete tardío; no duplicar ni reabrir snapshot. |
| Sustitución y API | Mismo humano, humano diferente, veto, native durante y después del forward; comparar totales, slots, campos KV y cierre leído por API probe/Series. |

El código de D2/E2 está integrado y se observó en los escenarios enumerados en el estado actual y el [registro operativo](l4d2-player-stats-smoke.md). Esta comprobación no cubre todas las señales, configuraciones ni modos; las filas no ejecutadas se mantienen como pendientes y no se infiere equivalencia completa.

## Decisiones antes de los cambios funcionales

Estas diferencias se documentan en A1 y se resuelven antes del paquete que las toca. Hasta entonces se conserva el comportamiento medido o, si no hay medición, el comportamiento del código de referencia. Una corrección elegida se entrega separada del movimiento estructural.

| Punto | Comportamiento de referencia y decisión propuesta |
|---|---|
| Solo arrojables habilitado | En la referencia, `weapon_fire` retornaba cuando tracking y accuracy estaban apagados. Se corrigió el gate para que arrojables habilitados llegue a `Utility_ApplyThrow` sin activar contadores de precisión. Compilación validada; falta el smoke con tracking=0, accuracy=0 y throwables=1. |
| ReadyUp y saferoom | Con ReadyUp presente, `OnRoundIsLive()` es la autoridad y el refresco no debe inferir live por saferoom. Sin ReadyUp, se usa la salida del saferoom. La corrección está en el código; smoke de carga tardía y de inicialización con saferoom ya despejado siguen pendientes. |
| Bibliotecas opcionales | `OnLibraryAdded/Removed` refresca hoy ConVars, modo o live de inmediato según la biblioteca; `OnAllPluginsLoaded` no refresca modo. La extracción estructural conserva ese orden. Una reconciliación diferida y la comprobación de cada native opcional requieren un corte posterior y smoke de carga tardía. |
| Salud temporal de Tank | La lectura actual suma salud permanente y `m_healthBuffer` almacenado. Mantener la base y etiquetarla; una normalización a salud temporal efectiva requiere política y comprobación separadas. |
| Sesión de Tank | La muerte puede buscar la última sesión activa. La migración debe vincularla al actor/sesión verificables; una ambigüedad se registra y no se asigna arbitrariamente. Clasificar cualquier delta perdido por esta protección. |
| Reemplazos y reentrada | Mantener el veto y la rehidratación; definir qué hacer si una native aplica el snapshot dentro del forward. Revalidar antes de cualquier aplicación automática. |
| Ayuda de Scavenge | El comando registrado es `sm_stats_scav`, pero una frase de ayuda dice `sm_stats_scavenge`. Inventariar la discrepancia; corregirla, si se decide, en un cambio de UX separado. |
| Correlación terminal | Antes de D2 definir capacidad de capturas por víctima, caducidad, evidencia mínima para asociar señales, política de desborde y qué cantidad queda autorizada si la correlación falla. No usar `(attacker,victim,tick)` como identidad suficiente. |

## Dirección de agentes y reversión

El coordinador mantiene el mapa de propiedad y decide el orden de integración. Los subagentes GPT-6 Luna en alto reciben tareas acotadas por familia de rutas o contrato, con archivos y salida esperada claros. No se les asignan escrituras concurrentes sobre `l4d2_player_stats.sp`, `types` o `runtime/rounds.sp`. Al recibir cada lote, el coordinador revisa invariantes, compara con A1 y ejecuta las comprobaciones pertinentes antes de encargar el siguiente. La revisión final une los resultados de código, compilación, artefacto y smoke, indicando los escenarios no ejecutados.

Ante un fallo, se revierte el paquete afectado o se desactiva explícitamente su consumidor con razón trazable; no se reactivan dos escritores en paralelo. Capturas de otra ronda/vida/mapa se invalidan. Una recarga no reconstruye estadísticas históricas perdidas: el snapshot afectado se declara incompleto en el informe operativo hasta que exista un contrato concreto para exponer esa condición. Ninguna fase presupone un commit, push o despliegue automático.
