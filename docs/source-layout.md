# Source Layout

Gun Runner's Luau source is organized for Rojo sync, review, and maintenance. [Play the game on Roblox](https://www.roblox.com/games/18336486336/Gun-Runner) or see the [project page](https://www.patchthedev.com/work/gun-runner) for gameplay and media.

## Gameplay systems

- player bases and generated runner tracks
- stat gates, speed pads, obstacles, targets, finish pillars, and evolver rewards
- weapons, currency, upgrades, rebirths, gifts, and chests
- friend invite bonuses, game passes, and developer products

## Code organization

Repeated world interactions are handled through CollectionService tags and attributes. Player data is accessed through a ProfileStore repository and schema migrations. Server-owned race state is separated from track planning and rendering. Client requests carry intent and are validated on the server.

The [world contract](world-contract.md) lists the Studio objects and tags used by the code.
