# ADR-0006: Hosting & deployment: Docker Compose, self-hosted, image on GHCR

Status: Accepted
Date: 2026-09-29
Doc: TECH_STACK.md

## Decision
Ship a docker-compose stack (API + PostgreSQL/PostGIS + media volume) that the
operator runs on a Linux host; the server image is published to GHCR.

## Context
A non-devops person must be able to self-host the server (a decided
requirement); there is one developer and no operations team.

## Alternatives considered
- Kubernetes — far beyond the scope and skill level this targets.
- Managed PaaS — breaks the self-hostable requirement.
- Per-OS installers — materially more work than Compose for no benefit.

## Consequences
The compose file and the image are release artifacts. Revisit if multi-node
scale or a hosted offering appears.
