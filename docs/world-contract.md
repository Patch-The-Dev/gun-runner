# World Contract

The live game uses Studio-authored map and interface assets. This document records the objects, tags, and attributes that connect those assets to the Rojo source.

## Player bases

Tag each player base model with `PlayerBase`.

A base should contain:

- `Spawn`: character return point
- `TrackOrigin` or `BeginLine`: orientation and start point for generated tracks, facing along the horizontal run direction
- `MarketSpawn`: optional return point used when the base exposes a market portal

The server sets these attributes on the base:

- `OwnerUserId`
- `RaceActive`

## Interaction tags

| Tag | Expected instance | Attributes | Purpose |
| --- | --- | --- | --- |
| `RaceStart` | BasePart or model containing one inside a `PlayerBase` | none | Start a race for that base's owner |
| `UpgradePad` | BasePart or model containing one | `UpgradeId: string` | Buy an upgrade |
| `WeaponPad` | BasePart or model containing one | `WeaponId: string` | Buy a weapon |
| `BaseFallZone` | BasePart or model containing one | none | Cancel the current race and return to the base spawn |
| `MarketPortal` | BasePart or model containing one | none | Cancel the current race and teleport to `MarketSpawn` |

Generated race content uses these internal tags:

- `RaceCheckpoint`
- `RaceSpeedPad` with `OwnerUserId` and `PadNegative`
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

## Asset integration

Studio-authored assets supply the bases, map, and interface. The tags and attributes above are their contract with the source modules.
