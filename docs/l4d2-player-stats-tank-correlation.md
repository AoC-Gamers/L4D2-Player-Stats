# Correlación del daño causado por Tank

El corte D2 está implementado y compilado. El baseline del SRCDS local observó golpes ordinarios, incapacitantes y mortales; falta la pasada del artefacto refactorizado. La correlación usa una ventana estricta de un tick basada en esas señales observadas; no afirma que todos los servidores emitan el mismo orden.

## Rutas y autoridad actual

| Señal | Dato actual | Efecto actual |
|---|---|---|
| `SDKHook_OnTakeDamage` | Daño entrante y salud permanente más `floor(m_healthBuffer)` antes del impacto. | Si parece terminal y hay sesión activa, guarda salud por índice de cliente. |
| `player_hurt` | `dmg_health`, atacante, víctima y arma. | Registra golpe y daño ordinario; omite el evento completo si hay captura terminal. |
| `player_incapacitated_start` | Atacante, víctima y arma. | Registra incap y golpe; consume salud capturada como daño terminal si la política de víctima lo permite. |
| `player_death` | Atacante, víctima y arma. | Registra death; consume captura terminal si existe. |

La captura actual se indexa solo por client slot. Puede sobrevivir a una desconexión, carece de userid/vida/actor y puede cruzar una sesión distinta. El código tampoco prueba qué señal terminal llega primero ni si ambas llegan para el mismo impacto.

## Modelo implementado

Cada operación conserva `runId`, generación de mapa, ronda, tick/señal, `damageId`, cliente/userid y epoch de vida de la víctima, cliente/userid del atacante, sesión/controlador Tank y salud previa. Al recibir `player_hurt`, incap o muerte, el resolver acepta solo una coincidencia inequívoca de ese contexto en el mismo tick. La sesión y el controlador se revalidan antes de aplicar. El identificador de daño es monotónico por carga; el índice de la tabla puede reutilizarse.

El resultado es uno de: daño ordinario por `dmg_health`, daño terminal por captura corroborada, delta terminal después de una aplicación parcial, o descarte con razón. Una operación consumida no vuelve a sumar su importe completo. Los contadores de golpes, incaps y deaths mantienen sus decisiones separadas de la cantidad de daño. La aplicación final pertenece a `modules/tank.sp`, una vez por vista estadística.

Una captura se invalida cuando cambia la vida, userid, ronda, mapa o sesión, al desconectar/reemplazar víctima o atacante, al caducar su tick y en el cierre. Capacidad y colisión producen razones explícitas; no se reasigna una captura a otra identidad. El cierre cuenta las operaciones ya aplicadas y descarta pendientes sin señal terminal antes de publicar el snapshot. Un recibo de `player_hurt` del mismo tick permite ajustar un importe ya aplicado si SDK llega después y aún puede leer salud previa válida.

## Evidencia y límites de la ventana

El [smoke](l4d2-player-stats-smoke.md) registró en baseline un golpe ordinario SDK→`player_hurt`, un golpe incapacitante SDK→`player_incapacitated_start` sin `player_hurt`, y un golpe mortal SDK→`player_hurt`→`player_death`, todos los pares de señales en el mismo tick. Falta repetir con el refactor y comparar daño, golpes, incaps y deaths por separado. Siguen sin evidencia equivalente los hittables, la salud temporal, la transferencia durante un impacto, dos sesiones simultáneas y la reutilización inmediata de un client slot.

Una señal que cae fuera del tick se descarta con razón en vez de atribuirla por proximidad. Si `player_hurt` llega antes de SDK y la salud previa ya no está disponible al recibir la captura, el importe terminal no puede reconstruirse con certeza: el resultado debe tratarse como limitación observable en el smoke, no como paridad demostrada. La compilación valida el código; D2 aún necesita el contraste operativo del artefacto refactorizado.
