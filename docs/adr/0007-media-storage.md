# ADR-0007: Evidence storage: local volume by default, optional S3-compatible

Status: Accepted
Date: 2026-09-29
Doc: TECH_STACK.md

## Decision
Photos and audio are stored on a Docker volume by default, with an opt-in
S3-compatible backend (MinIO or any S3).

## Context
Non-devops self-hosting must work with zero external services, while some
operators will want object storage for scale. Evidence files are immutable
once attached to a Visit.

## Alternatives considered
- S3-only — forces every self-hoster to run or buy an S3 service.
- Evidence stored as database blobs — database bloat and poor streaming.

## Consequences
A single storage abstraction must serve both backends. Revisit at media scale
or if CDN delivery is needed.
