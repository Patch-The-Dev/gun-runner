# Gun Runner

[![CI](https://github.com/Patch-The-Dev/gun-runner/actions/workflows/ci.yml/badge.svg)](https://github.com/Patch-The-Dev/gun-runner/actions/workflows/ci.yml)

Gun Runner is a Roblox runner game with generated tracks, shooting targets, weapon upgrades, and persistent progression. This repository presents its Luau source as a Rojo project for code review.

The server creates each track and owns race progress, combat results, currency, and saved data. Client code handles input, camera, UI, and shot presentation.

## Start reviewing

| Area | Code | What it shows |
| --- | --- | --- |
| Track generation | [TrackPlanner](src/shared/Domain/TrackPlanner.luau) and [TrackRenderer](src/server/Infrastructure/TrackRenderer.luau) | Seeded plans kept separate from Roblox instance creation |
| Race rules | [RaceSession](src/server/Domain/RaceSession.luau) and [RaceService](src/server/Services/RaceService.luau) | Ordered checkpoints, one-time claims, and server-calculated rewards |
| Combat | [WeaponService](src/server/Services/WeaponService.luau) | Request validation, fire-rate limits, and server raycasts |
| Player data | [PlayerRepository](src/server/Persistence/PlayerRepository.luau) and [Migrations](src/server/Persistence/Migrations.luau) | ProfileStore sessions, schema upgrades, and receipt save confirmation |
| Client | [RunnerController](src/client/Controllers/RunnerController.luau) and [UIController](src/client/Controllers/UIController.luau) | Movement presentation and UI bindings |

The [architecture](docs/architecture.md), [security notes](docs/security.md), and [world contract](docs/world-contract.md) explain the boundaries between these systems. The [tests](tests) cover the domain rules and migrations.

## Work with the source

Rokit pins the tools, Wally installs the Luau packages, and Rojo connects the source tree to Studio.

```sh
rokit install
wally install
rojo serve default.project.json
```

Use the Rojo Studio plugin to connect to the running server. To build the game and test places without opening Studio:

```sh
rojo build default.project.json -o GunRunner.rbxlx
rojo build test.project.json -o GunRunnerTests.rbxlx
```

## Verification

GitHub Actions installs dependencies, checks formatting with StyLua, lints with Selene, and builds both Rojo projects. To run the TestEZ specs, open `GunRunnerTests.rbxlx` in Studio, start a play test, and check the Output window. Studio tests are not part of CI.

## Repository scope

The original Studio map, UI assets, animations, and playable place are not included. The Rojo build demonstrates the code structure but needs the Studio objects listed in the [world contract](docs/world-contract.md) to run as a game. Product and game-pass IDs in [ProductConfig](src/shared/Config/ProductConfig.luau) are specific to the original experience.

More about my work: [PatchTheDev](https://www.patchthedev.com).
