# Repository guidance

This repository is a portfolio refactor of a Roblox Studio project. Treat server authority and architectural boundaries as invariants, not stylistic preferences.

## Invariants

- Clients request actions. They never choose rewards, prices, damage, ownership, or persisted values.
- Knit services coordinate application flow. Domain modules contain gameplay rules that can be tested without networking.
- Persistent data is accessed through `PlayerRepository` and owned at runtime by `PlayerSession`.
- Long-lived objects own cleanup through Trove.
- Promise is used only at genuine asynchronous boundaries.
- Network payloads are validated at the receiving boundary.
- Shared configuration contains tunable values. Avoid scattering balance numbers through services.
- Generated race content is server-created and identified by CollectionService tags and attributes.
- Do not add a dependency unless it replaces meaningful project code or establishes a clear boundary.

## Before changing behavior

Read `README.md`, `docs/architecture.md`, `docs/security.md`, and `docs/world-contract.md`. New gameplay systems should fit an existing boundary or introduce a narrowly defined one.

## Verification

Run:

```sh
wally install
stylua --check src tests
selene src tests
rojo build default.project.json --output build/GunRunner.rbxlx
rojo build test.project.json --output build/GunRunnerTests.rbxlx
```

Tests are TestEZ specs under `tests/shared` and `tests/server`.
