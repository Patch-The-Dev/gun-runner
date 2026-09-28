# Gun Runner

Gun Runner is a Roblox progression game built around generated runner tracks, shooting targets, upgrading weapons, earning currency, and rebirthing. This repository contains a Rojo-based refactor of its Luau gameplay code.

The original Studio map, UI assets, animations, and place file are not included. This source is intended for code review and further development, not as a playable game out of the box. See [the world contract](docs/world-contract.md) for the tags, attributes, and objects required to connect it to a place.

## Project layout

- `src/server`: gameplay services, race state, persistence, and world adapters
- `src/client`: input, UI, and presentation controllers
- `src/shared`: configuration, types, validation, and gameplay calculations
- `tests`: TestEZ specs for progression, track planning, weapon math, race state, and data migration
- `docs`: architecture, security decisions, and Studio integration requirements

The server owns rewards, purchases, weapon hits, race state, and saved player data. Client requests are validated at the service boundary. [Architecture](docs/architecture.md), [security notes](docs/security.md), and [refactor scope](docs/refactor-scope.md) describe the design in more detail.

## Toolchain

Rojo maps the source tree into Roblox Studio. Rokit pins Rojo, Wally, StyLua, and Selene. Wally manages Knit, ProfileStore, and the other Luau dependencies. Git tracks the source and configuration.

```sh
rokit install
wally install
rojo serve default.project.json
```

Use the Rojo Studio plugin to connect to the running server. The Studio place must provide the assets and tags described in [docs/world-contract.md](docs/world-contract.md).

## Checks

```sh
stylua --check src tests
selene src tests
rojo build default.project.json -o GunRunner.rbxlx
rojo build test.project.json -o GunRunnerTests.rbxlx
```

The test place contains a TestEZ runner for the specs under `tests/`. GitHub Actions checks formatting, linting, dependency installation, and both Rojo builds. It does not run the Studio tests.

For a quick code review, start with [TrackPlanner](src/shared/Domain/TrackPlanner.luau), [RaceSession](src/server/Domain/RaceSession.luau), [WeaponService](src/server/Services/WeaponService.luau), and [PlayerRepository](src/server/Persistence/PlayerRepository.luau).
