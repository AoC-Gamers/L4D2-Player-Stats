# Round close lifecycle

`Round_FinalizeActiveSnapshot` owns an idempotent close. Each snapshot moves through `Idle -> Open -> Closing -> Finalized`; the public API remains unchanged.

## Close order

1. Capture the round ID and map generation, enter `Closing`, set `g_bRoundClosing`, and stop live writes.
2. Refresh terminal mode metadata, then call `Damage_FinalizeTankOperationsForRoundClose` for that captured round and map generation. Operations already applied are recorded as resolved; operations without sufficient terminal evidence or with stale context are discarded with a reason. This step does not infer or add damage.
3. End active Tank sessions after pending damage operations have been handled.
4. Freeze the snapshot as inactive, set its end reason/time, and enter `Finalized`.
5. Fire `PlayerStats_OnRoundEnded` synchronously. After it returns, verify snapshot ID, map generation, phase, end reason, and close guard before presenting. A reentrant new round or map transition therefore cannot announce the old snapshot against new state.

Ordinary damage gates remain closed during `Closing`. Public snapshot queries still work after `Finalized`. A terminal event received while a close is already in progress cannot start another round close.

## End type and reentrant match signal

Round/half/match are distinct. Versus and Scavenge match-finished reasons produce `StatsEndType_Match`; their half/end reasons retain their existing types. Match notifications for an already finalized snapshot are deduplicated by round ID and reason before firing the forward.

If `versus_match_finished` arrives synchronously from a consumer of a Half `PlayerStats_OnRoundEnded`, the Half snapshot is already frozen. The coordinator emits one separate Match forward for that same snapshot. It does not refinalize the snapshot or broadcast a second round panel. If the signal arrives earlier while the synchronous close is in `Closing`, it is queued for the captured round/map generation, then emitted after the ordinary close forward and before presentation. A new round or map generation invalidates that queued notification and the old panel. If match finish is itself the active close reason, the coordinator sets the dedup key before firing the forward, so a reentrant duplicate is ignored.

## Smoke checks

- Close a live Round, Half, and Match; inspect the end type/reason and query the frozen snapshot from the forward consumer.
- Deliver duplicate round-end signals and verify one close forward and one panel.
- Trigger Versus match finish during the synchronous Half forward; expect exactly one Half forward, one distinct Match forward, and one panel.
- Trigger a duplicate Match signal during a Match forward; expect no second Match forward or panel.
- Close with Tank operations already applied, pending without terminal evidence, and ambiguous. Confirm the close trace reports resolved/discarded counts before sessions close and before snapshot freeze.
- Trigger a new snapshot or map generation from an end-forward consumer; confirm post-forward presentation is skipped for stale state.
- After close, send a late ordinary damage event and Skills packet; neither may mutate the snapshot. Snapshot reads remain available.

Expected trace order is `Closing -> tank operations resolved/discarded -> Tank sessions closed -> snapshot frozen -> end forward -> presentation`, with round ID and map generation on each close-stage entry.
