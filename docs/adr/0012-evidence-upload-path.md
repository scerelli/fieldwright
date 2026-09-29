# ADR-0012: Evidence upload through the API, presigned S3 when configured

Status: Accepted
Date: 2026-09-29
Doc: ARCHITECTURE.md

## Decision
Evidence files are uploaded to the API, which writes them to the Docker volume
by default or returns a presigned S3 URL when an S3 backend is configured.
Files are content-hashed and never mutated.

## Context
The default self-host must require no object storage, while some operators
want S3 (ADR-0007). Evidence is immutable once attached to a Visit.

## Alternatives considered
- Direct-to-S3 only — forces every self-hoster to run or buy S3.
- Evidence stored as database blobs — database bloat and poor streaming.

## Consequences
One upload path behind a storage abstraction; the API sits on the evidence
path by default. Revisit if upload volume warrants client-direct upload
everywhere.
