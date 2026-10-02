# ADR-0013: Persist the Better Auth sign-in in the client's local store

Status: Accepted
Date: 2026-10-02
Doc: TECH_STACK.md

## Decision
The client persists the signed-in Person and their Better Auth auth cookie in the existing local drift (SQLite) store, so the sign-in survives an app relaunch. No OS secure-store (Keychain/Keystore) dependency is added.

## Context
Story #241 ("Stay signed in across app relaunches") requires the sign-in — and therefore the Better Auth auth cookie the sync API is authenticated by — to survive a relaunch, so a Visit queued offline is delivered without re-entering credentials. `TECH_STACK.md` pins drift as the client's only local store and pins no secure-storage library; adding one would be a technology-selection change (`/discover`), outside this build's scope. The cookie is a bearer credential, so storing it in plaintext SQLite is a security tradeoff made deliberately.

## Alternatives considered
- `flutter_secure_storage` / Keychain / Keystore — rejected for now: not in the approved stack (would require `/discover`), and the app is self-hosted and pre-release.
- Re-authenticate on every launch — rejected: defeats #241's requirement to deliver a queued Visit without re-entering credentials.

## Consequences
Locks in: the auth cookie is readable by anyone with access to the app's SQLite file (a device backup, a rooted or jailbroken device). To revisit, add a secure-storage dependency via `/discover`, move the cookie behind the same seam (`AuthSessionDao` has a small `save`/`read`/`clear` surface), and supersede this ADR.
