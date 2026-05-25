# L4D2 Player Stats Reduced-Team Versus Implementation

Este documento define como `L4D2-Player-Stats` debe detectar contextos `NvN` reducidos dentro de `Versus` y que producto debe ofrecer para reemplazar progresivamente a `1v1_skeetstats`.

## Objetivo

No portar `1v1_skeetstats` como codigo legacy.

Si reutilizar su objetivo funcional:

- detectar cuando la ronda actual corresponde a un contexto `NvN` reducido
- adaptar el reporte a ese contexto
- usar el tracking moderno de:
  - `L4D2-Player-Stats`
  - `L4D2-Player-Skills`

## Regla Base

Un contexto `NvN` reducido solo existe cuando:

- el modo actual es `Versus`
- el limite efectivo de survivors esperados es `N`
- el limite efectivo de infected esperados es `N`
- hay al menos una clase SI habilitada por limites `z_versus_*_limit`

Adicionalmente, el runtime puede reforzar esa deteccion verificando:

- `N` survivors humanos activos o el maximo consistente con el estado real de la mitad
- `N` infected humanos activos o el maximo consistente con el pool habilitado

La deteccion por configuracion es la señal primaria.
La validacion por jugadores conectados es una señal secundaria de consistencia.

## Contexto General

El sistema no debe modelar solo `1v1`.

Debe clasificar al menos:

- `1v1`
- `2v2`
- `3v3`
- `4v4`

Donde:

- `4v4` es el contexto competitivo estandar
- `1v1`, `2v2` y `3v3` son contextos reducidos

La misma base tambien puede soportar otros tamaños si el stack los usa.

## Heuristica

El detector debe exponer un resultado tipado, no solo un booleano.

Forma sugerida:

- `None`
- `Versus4v4`
- `MixedPool2v2`
- `MixedPool3v3`
- `MixedPool1v1`
- `Hunter1v1`
- `Smoker1v1`
- `Boomer1v1`
- `Spitter1v1`
- `Jockey1v1`
- `Charger1v1`

No se debe inferir `1v1` solo porque haya un survivor vivo o un infected vivo.
Debe existir coherencia entre:

- modo `Versus`
- limites de jugadores
- limites de clase SI

Adicionalmente, el detector debe exponer:

- `teamSize`
- `siPool`
- `isReducedTeamVersus`
- `isStandardVersus`

## Pool de Clases

El detector debe calcular el pool efectivo de SI habilitadas:

- `Smoker`
- `Boomer`
- `Hunter`
- `Spitter`
- `Jockey`
- `Charger`

Eso permite distinguir dos variantes en cualquier `NvN`:

### Single-class 1v1

Solo una clase SI habilitada.

Ejemplos:

- solo `Hunter`
- solo `Smoker`
- solo `Boomer`

En este caso el detector puede devolver el tipo especifico:

- `Hunter1v1`
- `Smoker1v1`
- `Boomer1v1`
- `Spitter1v1`
- `Jockey1v1`
- `Charger1v1`

### Mixed-pool 1v1

Mas de una clase SI habilitada, pero el limite de jugadores sigue siendo:

- `1 survivor`
- `1 infected`

Ejemplo real:

```cfg
survivor_limit 1
z_max_player_zombies 1
z_versus_hunter_limit 1
z_versus_jockey_limit 1
z_versus_boomer_limit 0
z_versus_smoker_limit 0
z_versus_charger_limit 0
z_versus_spitter_limit 0
```

Ese contexto sigue siendo `1v1`, pero el pool es mixto:

- `Hunter`
- `Jockey`

El tipo sugerido para ese caso es:

- `MixedPool1v1`

La misma idea debe aplicarse a:

- `MixedPool2v2`
- `MixedPool3v3`
- y eventualmente `MixedPool4v4` si alguna vista necesita diferenciarlo

## Limites de Clase

La politica ya usada en `Player-Skills` y `Player-Stats` aplica tambien aqui:

- solo en `Versus`
- `z_versus_*_limit == 0` implica que esa clase no existe

Para cualquier contexto `NvN`, al menos una de estas clases debe quedar habilitada:

- `Smoker`
- `Boomer`
- `Hunter`
- `Spitter`
- `Jockey`
- `Charger`

Si hay mas de una clase SI habilitada, el contexto sigue siendo valido mientras:

- `survivor_limit == N`
- `z_max_player_zombies == N`

Lo que cambia es que deja de ser `single-class` y pasa a ser `mixed-pool`.

## Limites de Jugadores

El detector debe apoyarse en la configuracion efectiva del servidor o stack para responder:

- survivors esperados
- infected esperados

La implementacion concreta puede resolver esto desde:

- convars del servidor
- configuracion del stack
- o un helper integrado si el entorno ya expone esos limites

Contrato deseado:

- `N survivors` esperados
- `N infected` esperados

Si no se puede demostrar ese par de limites simetricos, no debe activarse un contexto `NvN` especializado.

## Contexto Estandar

Si:

- `survivor_limit == 4`
- `z_max_player_zombies == 4`

entonces el contexto debe clasificarse como:

- `Versus4v4`

Ese es el baseline estandar del producto competitivo.

## Producto Objetivo

El reemplazo de `1v1_skeetstats` debe construirse con los datos modernos ya disponibles.

La primera especializacion sigue siendo `1v1`, pero la arquitectura debe servir tambien para:

- `2v2`
- `3v3`
- `4v4`

Fuentes:

- `Player-Stats`
  - damage SI
  - tank damage
  - witch damage
  - SI kills
  - common kills
  - accuracy
- `Player-Skills`
  - skeets
  - melee skeets
  - deadstops
  - boomer pops
  - tongue cuts
  - smoker self clears
  - charger levels
  - jockey and hunter high pounces
  - boomer vomit
  - charger instakills

## Vista Inicial Recomendada

Primera version:

- no cambiar `sm_mvp` por defecto
- agregar una vista o renderer dedicado para contextos reducidos
- activarlo solo cuando el contexto `NvN` este confirmado

Opciones validas:

- `sm_mvp_1v1`
- o reutilizar `sm_mvp` con salida especializada solo en contexto `1v1`

La recomendacion inicial es:

- renderer dedicado primero
- reemplazo automatico despues

Eso reduce riesgo y facilita comparar contra el plugin legacy.

Para `2v2` y `3v3`, se puede extender el mismo renderer con otro layout o columnas.

## Contenido Minimo del Reporte 1v1

Segun la clase o pool:

### Hunter 1v1

- skeets
- melee skeets
- deadstops
- hunter damage
- hunter kills
- accuracy relevante

### Smoker 1v1

- tongue cuts
- smoker self clears
- smoker damage
- smoker kills
- accuracy relevante

### Boomer 1v1

- boomer pops
- boomer vomit landed
- boomer damage
- boomer kills
- accuracy relevante

### Charger 1v1

- charger levels
- charger death setups
- charger instakills
- charger damage
- charger kills
- accuracy relevante

### Jockey 1v1

- jockey high pounces
- jockey damage
- jockey kills
- accuracy relevante

### Spitter 1v1

Hoy `Player-Skills` no tiene una superficie 1v1 rica equivalente a Hunter/Smoker/Boomer/Charger/Jockey.

Entonces:

- el contexto `Spitter1v1` puede existir
- pero el producto inicial puede limitarse a damage, kills y accuracy

### Mixed-pool 1v1

Si el contexto es `MixedPool1v1`, la vista debe:

- mostrar solo metricas relevantes para las clases habilitadas
- ocultar clases con limite `0`
- seguir usando el mismo backend moderno

Ejemplo:

- pool `Hunter + Jockey`
  - mostrar skeets, melee skeets, deadstops, hunter high pounces, jockey high pounces, damage, kills, accuracy
  - no mostrar pops, tongue cuts, charger levels, vomit, etc.

## Extensiones 2v2 y 3v3

La misma logica de pool aplica a:

- `2v2`
- `3v3`

La diferencia principal no es el detector, sino la presentacion:

- `1v1`
  - foco en duelo individual
- `2v2`
  - foco en pareja y comparacion compacta
- `3v3`
  - foco en micro-team
- `4v4`
  - reporte competitivo estandar

## Prioridad

El orden recomendado de implementacion es:

1. clasificador general `NvN`
2. soporte completo de `1v1`
3. extension de renderers a `2v2`
4. extension de renderers a `3v3`

## Persistencia

Las vistas `1v1` deben seguir el mismo modelo general del sistema:

- detalle tactico: por ronda/mapa actual
- historico: por mision actual si luego se agrega una vista `stats`

La primera version debe ser solo de ronda actual.

## Compatibilidad con Legacy

`1v1_skeetstats` puede seguir existiendo durante la transicion.

Criterio para retirarlo:

- la vista nueva cubre el mismo caso competitivo
- los valores principales coinciden en pruebas reales
- la salida del usuario final no pierde informacion critica

## Fases

### Fase 1

- helper de deteccion `1v1`
- tipo de contexto `1v1`
- renderer dedicado

### Fase 2

- mapeo clase por clase de metricas visibles
- comparacion contra `1v1_skeetstats`

### Fase 3

- opcion de reemplazo automatico
- retiro del legacy si ya no aporta nada unico

## Regla de Implementacion

No duplicar tracking legacy.

Siempre preferir:

- damage moderno
- skills modernas
- agregados modernos

La capa `1v1` debe ser principalmente:

- deteccion de contexto
- seleccion de metricas
- presentacion especializada
