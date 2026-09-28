# Gun Runner

[![CI](https://github.com/Patch-The-Dev/gun-runner/actions/workflows/ci.yml/badge.svg)](https://github.com/Patch-The-Dev/gun-runner/actions/workflows/ci.yml)

Gun Runner is a Roblox runner game with generated tracks, shooting targets, weapon upgrades, and persistent progression. This repository presents its Luau source as a Rojo project for code review.

The server creates each track and owns race progress, combat results, currency, and saved data. Client code handles input, camera, UI, and shot presentation.

## Start reviewing

- **Track generation:** [TrackPlanner](src/shared/Domain/TrackPlanner.luau) produces seeded plans. [TrackRenderer](src/server/Infrastructure/TrackRenderer.luau) builds the server-owned instances.
- **Race rules:** [RaceSession](src/server/Domain/RaceSession.luau) tracks ordered checkpoints and one-time claims. [RaceService](src/server/Services/RaceService.luau) calculates rewards.
- **Combat:** [WeaponService](src/server/Services/WeaponService.luau) validates fire requests, limits cadence, and raycasts on the server.
- **Player data:** [PlayerRepository](src/server/Persistence/PlayerRepository.luau) manages ProfileStore sessions and receipt saves. [Migrations](src/server/Persistence/Migrations.luau) upgrades saved data.
- **Client:** [RunnerController](src/client/Controllers/RunnerController.luau) handles movement and camera presentation. [UIController](src/client/Controllers/UIController.luau) binds UI to state and actions.

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
