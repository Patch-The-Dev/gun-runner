# Security Notes

## Trust model

The client is treated as untrusted input.

The client may request actions and provide identifiers or aiming direction. It does not choose prices, rewards, entitlement effects, damage values, race payouts, or profile mutations.

## Network validation

Knit is the transport layer. Request payloads are validated with `t` before service methods use them. A per-player token budget bounds snapshot, purchase, rebirth, gift, and fire calls. The fire budget is checked before payload validation and allows bursts above the maximum configured weapon rate. Budgets are cleared when a player leaves; business rules still validate every accepted request.

The weapon endpoint validates finite direction vectors, limits aim to a narrow cone around the run direction, and applies a server fire-rate limiter. Raycasts and damage are calculated on the server from the authoritative race weapon state. Shot visuals are replicated only to nearby players.

## Race authority

Character movement remains client responsive, as expected for Roblox player characters. Race state and rewards are server-owned.

Generated tracks contain invisible server-owned checkpoints spanning each segment. The server checks checkpoint order, character proximity, and minimum travel time from the previous checkpoint. Gates, obstacles, and the evolver are accepted only in the current segment with nearby character position and plausible travel time. Touch events also verify the character's root position against the touched part. The server samples active races at a fixed 0.1-second interval and at interaction time, cancelling runs with implausible jumps. Finish triggers enforce a minimum elapsed time based on track distance and the fastest configured runner speed. These checks reduce teleport and shortcut payouts, but client-owned character physics cannot prove every movement was legitimate.

In published servers, completed and cancelled runs are recorded as Roblox custom analytics events with an outcome reason and maximum observed horizontal speed. This makes cancellation rates and movement thresholds measurable without putting player IDs in custom fields or changing payouts. Studio cannot send these events; live data must be inspected before changing the thresholds.

## Economy

Currency awards and spending occur only in `EconomyService` from server-controlled values. Upgrade and weapon prices come from configuration modules.

Rebirth cost and reset behavior are server-calculated.

## Purchases

Developer product grants use `MarketplaceService.ProcessReceipt` and a persisted purchase-id set. A receipt is reported as granted only after ProfileStore confirms a save containing the purchase id.

Game pass ownership is checked with `UserOwnsGamePassAsync`. Failed lookups retry with backoff; verified results from other passes remain available. Client purchase prompts do not grant effects directly.

## Persistence

ProfileStore owns session locking. Profiles are migrated and bounded against the current upgrade configuration, then reconciled with the current template before a `PlayerSession` is created. Studio uses the mock store.

A future schema version causes an explicit load error rather than silently downgrading data.

## Social prompt bonus

The invite-session bonus is activated from the server-observed `SocialService.GameInvitePromptClosed` event. There is no client endpoint that directly grants the bonus. Roblox does not expose proof that a recipient accepted an invite, so the bonus intentionally represents completing the prompt flow rather than a verified referral.
