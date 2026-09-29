# ADR-0004: Mobile client framework: Flutter

Status: Accepted
Date: 2026-09-29
Doc: TECH_STACK.md

## Decision
One Flutter 3.47.5 / Dart 3.13 codebase targets both Android and iOS.

## Context
One developer must ship both mobile platforms, with heavy custom offline UI,
sensor access and offline maps. The brief rules out React Native.

## Alternatives considered
- React Native — ruled out by the brief.
- Native Swift + Kotlin — double the implementation for one developer.
- Kotlin Multiplatform — a younger, smaller iOS ecosystem.

## Consequences
Locks client work to Dart/Flutter and its plugin ecosystem. Revisit only if a
required native capability has no adequate plugin.
