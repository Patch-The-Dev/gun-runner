# Gun Runner

**A Roblox runner game built around generated tracks, weapon combat, and persistent progression.**

[![CI](https://github.com/Patch-The-Dev/gun-runner/actions/workflows/ci.yml/badge.svg)](https://github.com/Patch-The-Dev/gun-runner/actions/workflows/ci.yml)

This is the Luau code portfolio for Gun Runner, organized as a Rojo project by [PatchTheDev](https://www.patchthedev.com). It covers the gameplay systems behind a run, from track generation and shooting to rewards, upgrades, and saved player data.

## How a run works

1. [DataService](src/server/Services/DataService.luau) loads a player profile, and [BaseService](src/server/Services/BaseService.luau) assigns a base.
2. Starting a race turns the player's upgrade levels into a seeded track plan. The server renders its segments, gates, speed pads, targets, obstacles, checkpoints, and finish.
3. [RunnerController](src/client/Controllers/RunnerController.luau) handles local movement and camera presentation. [WeaponController](src/client/Controllers/WeaponController.luau) requests shots, while the server chooses the firing origin, cadence, range, damage, and hit result.
4. [RaceSession](src/server/Domain/RaceSession.luau) records checkpoints in order and prevents repeated claims. A finish requires every checkpoint and a minimum elapsed time. The server then calculates the run's cash and target rewards.
5. Players can buy weapons and upgrades, claim timed gifts, and rebirth. Game-pass entitlements affect rewards and combat; developer products award currency through receipt processing.

## Engineering highlights

- **Seeded generation:** [TrackPlanner](src/shared/Domain/TrackPlanner.luau) produces a plan from a seed and upgrade settings. [TrackRenderer](src/server/Infrastructure/TrackRenderer.luau) handles Roblox instances, tags, and ownership. Keeping planning separate makes the generation rules straightforward to test.
- **Server-owned results:** [RaceService](src/server/Services/RaceService.luau) owns race state and payouts. [WeaponService](src/server/Services/WeaponService.luau) validates fire requests, rate limits them, and raycasts on the server. Network payloads are checked at the boundary in [Contract](src/shared/Network/Contract.luau).
- **Progression and data:** [ProgressionService](src/server/Services/ProgressionService.luau) calculates purchase costs and rebirth resets from shared configuration. [PlayerRepository](src/server/Persistence/PlayerRepository.luau) manages ProfileStore sessions, with [Migrations](src/server/Persistence/Migrations.luau) handling older data. [MonetizationService](src/server/Services/MonetizationService.luau) acknowledges developer product receipts after their purchase IDs appear in a saved profile.
- **Client boundaries:** [ClientStore](src/client/State/ClientStore.luau) holds local snapshots. Controllers handle input and presentation, while services handle authoritative changes. [UIController](src/client/Controllers/UIController.luau) binds tagged UI elements rather than relying on fixed object paths.

The [architecture](docs/architecture.md), [security notes](docs/security.md), and [world contract](docs/world-contract.md) cover the service boundaries, validation rules, and Studio objects in more detail. The [TestEZ specs](tests) cover progression, track planning, weapon math, race state, rate limiting, and migrations.

## Toolchain

The repository uses **Rojo** for source sync, **Rokit** to pin tools, **Wally** for Luau packages, **StyLua** for formatting, and **Selene** for linting. Knit connects services and controllers, ProfileStore manages saved data, Trove cleans up long-lived connections, and `t` validates structured requests. Source is split into `src/shared`, `src/server`, and `src/client`.

```sh
rokit install
wally install
rojo serve default.project.json
```

Connect through the Rojo Studio plugin to work with a Studio place. To build the source and the separate test place:

```sh
rojo build default.project.json -o GunRunner.rbxlx
rojo build test.project.json -o GunRunnerTests.rbxlx
```

GitHub Actions runs dependency installation, formatting, linting, and both Rojo builds. To run the TestEZ specs, open `GunRunnerTests.rbxlx` in Studio, start a play test, and check Output. Studio execution is not part of CI.

## Scope

This repository contains gameplay source and documentation. The original Studio map, UI assets, animations, and playable place are not included, so a Rojo build alone is not a playable game. The [world contract](docs/world-contract.md) lists the objects needed to integrate the code with a place. Product and game-pass IDs in [ProductConfig](src/shared/Config/ProductConfig.luau) belong to the original experience.
