# Refactor Scope

This repository contains the code side of a Studio-first Gun Runner project. The original place and asset export are not included, so this document describes the refactor's scope rather than claiming a line-by-line comparison with the live game.

## Gameplay represented in source

- player bases and generated runner tracks
- stat gates, speed pads, obstacles, targets, finish pillars, and evolver rewards
- weapons, currency, upgrades, rebirths, gifts, and chests
- friend invite bonuses, game passes, and developer products

## Code organization

Repeated world interactions are handled through CollectionService tags and attributes. Player data is accessed through a ProfileStore repository and schema migrations. Server-owned race state is separated from track planning and rendering. Client requests carry intent and are validated on the server.

The [world contract](world-contract.md) lists the Studio objects and tags needed to connect this code to a place. The project does not include those assets, and the Rojo build alone is not a playable recreation of the original game.
