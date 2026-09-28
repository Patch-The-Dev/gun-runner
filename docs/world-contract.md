# World Contract

The original game was authored directly in Studio. This portfolio repository intentionally separates code from map assets.

## Player bases

Tag each player base model with `PlayerBase`.

A base should contain:

- `Spawn`: character return point
- `TrackOrigin` or `BeginLine`: orientation and start point for generated tracks
- `MarketSpawn`: optional return point used when the base exposes a market portal

The server sets these attributes on the base:

- `OwnerUserId`
- `RaceActive`

## Interaction tags

| Tag | Expected instance | Attributes | Purpose |
| --- | --- | --- | --- |
| `RaceStart` | BasePart or model containing one | none | Start a race |
| `UpgradePad` | BasePart or model containing one | `UpgradeId: string` | Buy an upgrade |
| `WeaponPad` | BasePart or model containing one | `WeaponId: string` | Buy a weapon |
| `BaseFallZone` | BasePart or model containing one | none | Cancel the current race and return to the base spawn |
| `MarketPortal` | BasePart or model containing one | none | Cancel the current race and teleport to `MarketSpawn` |

Generated race content uses these internal tags:

- `RaceCheckpoint`
- `RaceGate`
- `RaceTarget`
- `RaceObstacle`
- `RacePillar`
- `RaceEvolver`
- `RaceFinish`

Generated objects include `OwnerUserId` so another player cannot consume a run's rewards or progression.

## UI tags

UI is bound by tags rather than hard-coded object paths.

Labels:

- `CashLabel`
- `TargetLabel`
- `RebirthLabel`
- `RaceCashLabel`
- `RaceTargetLabel`
- `RaceTargetsCollectedLabel`

Buttons:

- `UpgradePurchaseButton` with `UpgradeId`
- `RebirthButton`
- `WeaponPurchaseButton` with `WeaponId`
- `WeaponEquipButton` with `WeaponId`
- `DeveloperProductButton` with `ProductId`
- `GamePassButton` with `GamePassId`
- `GiftClaimButton`
- `InviteButton`

## Asset policy

The repository does not recreate the original Studio map in source code. Reviewers can inspect game logic without binary place files, while the contract above documents the integration points needed to attach the code to a place.
