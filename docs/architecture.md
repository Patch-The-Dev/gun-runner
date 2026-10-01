# Architecture

This repository separates orchestration, game rules, persistence, and presentation. Knit provides lifecycle and remote plumbing. It is not used as the domain model.

## Dependency direction

```text
client controllers  -> shared contracts and state
server services     -> server domain + shared domain
server domain       -> shared domain/types
persistence         -> ProfileStore adapter + migrations
infrastructure      -> Roblox instances/services
shared domain       -> config + types only
```

Game rules should remain testable without a running place whenever Roblox APIs are not required.

## Server layers

### Services

Knit services are application boundaries. They validate requests, coordinate domain objects, and publish state. They should not contain large algorithms or direct datastore schemas.

Key responsibilities:

- `DataService`: owns player session lifecycle and snapshots.
- `BaseService`: assigns tagged player bases and teleports characters to server-owned markers.
- `TrackService`: creates deterministic track plans and renders one active track per player.
- `RaceService`: owns run state, rewards, checkpoints, gates, targets, pillars, evolvers, and finish validation.
- `WeaponService`: validates fire requests and performs server raycasts.
- `ProgressionService`: validates upgrades and rebirths.
- `EconomyService`: is the only service that mutates currency balances directly.
- `EntitlementService`: resolves game-pass effects into one typed entitlement state.
- `MonetizationService`: grants developer products and confirms receipt persistence before returning `PurchaseGranted`.

### Domain

`PlayerSession` and `RaceSession` are stateful server-owned objects. `ShotAudience` maintains a coarse spatial index for nearby shot visuals. Pure calculations remain in `src/shared/Domain`.

`RaceSession` tracks consumed world objects and ordered checkpoints. It checks checkpoint proximity, segment timing, sampled movement, and minimum finish time before accepting a payout.

### Persistence

`PlayerRepository` is the ProfileStore adapter. Other services do not access ProfileStore directly.

The saved schema is versioned. `Migrations.apply` converts older data before a `PlayerSession` is created. The repository uses ProfileStore's mock store while running in Studio.

Developer product purchase IDs are persisted in `ProcessedReceipts`. A receipt is only acknowledged after ProfileStore reports a save containing that purchase ID.

## Client layers

Controllers coordinate input, UI, and server calls. `ClientStore` is the single local snapshot store for player and race state. It copies and freezes nested snapshot data so consumers cannot change it. Controllers do not mutate authoritative values.

`RunnerController` owns local movement presentation and camera behavior. Movement is treated as untrusted. Server race completion requires ordered checkpoints, proximity, segment timing, sampled movement, and finish-time validation.

`WeaponController` sends aim direction only. The server chooses the origin, fire rate, weapon stats, range, projectile count, damage, and hit result.

## Networking

Knit creates the transport, while `shared/Network/Contract.luau` validates structured client requests. Client requests communicate intent, not outcomes.

Examples:

- client sends `weaponId`; server checks ownership and price
- client sends an aim direction; server raycasts and applies damage
- client requests rebirth; server calculates the current cost

No client endpoint accepts arbitrary cash, target, damage, price, or reward values.

## Lifetimes

Trove owns disposable connections and objects for long-lived controllers, sessions, tag binders, and services. Domain state that does not own resources stays free of cleanup abstractions.

Promise is limited to operations that are actually asynchronous, such as ProfileStore session loading, entitlement checks, and invite prompting.

## World integration

The code discovers Studio map behavior using CollectionService tags and attributes. See `world-contract.md`.

## Persistence completion and shutdown

Profile acquisition tracks the pending load through initialization and subscription setup. Any exception after acquisition releases the active session. Shutdown closes the repository to new loads, cancels pending acquisitions, releases registered sessions, and waits within one deadline. Late acquisitions also observe the closed state and release themselves.

Receipt save confirmation waits at most `GameConfig.ReceiptConfirmationSeconds`. Saved receipt data is the success condition. Session end, save failure, cancellation, and timeout disconnect listeners and return an unconfirmed result so the receipt can be retried.

Timed gifts use `GiftReward.apply` to validate and commit both currencies and the cooldown without yielding. A bad amount, overflow, or active cooldown changes none of those values. Snapshot delivery happens after the committed transaction.

## Verification

CI analyzes all runtime source without excluded service directories. The Studio runner executes TestEZ, a combined server bootstrap, and two-client integration against the production entrypoints. See [Studio CI](STUDIO_CI.md) for the optional dedicated runner and JSON reports.
