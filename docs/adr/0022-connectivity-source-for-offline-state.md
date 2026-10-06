# ADR-0022: Connectivity source for the shell's offline state

Status: Accepted
Date: 2026-10-07
Doc: TECH_STACK.md

## Decision
Pin `connectivity_plus` (7.3.2) as the client's network-connectivity source, so the app shell can show UX-008's offline state.

## Context
UX-008 and UX-007 require a persistent, non-modal shell indicator that distinguishes offline from sync-failed, and `docs/brief.md` lists "offline, syncing, sync failed" as states to design. `TECH_STACK.md` pinned no connectivity source and `ARCHITECTURE.md`'s client module map had no connectivity module, so the offline state had no truthful source. The app is offline-first: capture and submission never depend on connectivity, and only delivery waits.

## Alternatives considered
- `internet_connection_checker_plus` and similar reachability-probing packages — rejected: they perform live reachability probes (themselves network-dependent and battery-costly) where the transport state suffices, adding a heavier surface for a solo developer.
- Derive offline from the outbox's `SyncState.failed` — rejected: `outbox.dart` collapses transport failure and server rejection into one state, conflating UX.md's distinct Offline and Sync-failed states, and it cannot report "no connection".
- No connectivity source, omitting the offline state — rejected: contradicts UX-007/UX-008.

## Consequences
Locks in a client dependency plus a connectivity provider feeding the shell indicator. `connectivity_plus` reports the network transport type, not internet reachability, so network code stays guarded by timeouts and errors (the package's own guidance); a transport type is not a reachability guarantee. Revisit if a truthful reachability signal (captive portal / internet-yes) is later required, or if the transport-type signal proves insufficient.
