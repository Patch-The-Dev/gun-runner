# Security Notes

## Trust model

The client is treated as untrusted input.

The client may request actions and provide identifiers or aiming direction. It does not choose prices, rewards, entitlement effects, damage values, race payouts, or profile mutations.

## Network validation

Knit is the transport layer. Request payloads are validated with `t` before service methods use them.

The weapon endpoint validates finite direction vectors and applies a server rate limiter. Raycasts and damage are calculated on the server from the authoritative race weapon state.

## Race authority

Character movement remains client responsive, as expected for Roblox player characters. Race state and rewards are server-owned.

Generated tracks contain invisible server-owned checkpoints spanning each segment. Checkpoints must be observed in order before a finish can be accepted. Finish triggers also enforce a minimum elapsed time based on track distance and the fastest configured runner speed. These checks reject direct finish teleports and impossible instant completions. They remain plausibility guards rather than a full server-authoritative character controller.

## Economy

Currency awards and spending occur only in `EconomyService` from server-controlled values. Upgrade and weapon prices come from configuration modules.

Rebirth cost and reset behavior are server-calculated.

## Purchases

Developer product grants use `MarketplaceService.ProcessReceipt` and a persisted purchase-id set. A receipt is reported as granted only after ProfileStore confirms a save containing the purchase id.

Game pass ownership is checked with `UserOwnsGamePassAsync`. Client purchase prompts do not grant effects directly.

## Persistence

ProfileStore owns session locking. Profiles are migrated first, then reconciled with the current template before a `PlayerSession` is created. Studio uses the mock store.

A future schema version causes an explicit load error rather than silently downgrading data.

## Social prompt bonus

The invite-session bonus is activated from the server-observed `SocialService.GameInvitePromptClosed` event. There is no client endpoint that directly grants the bonus. Roblox does not expose proof that a recipient accepted an invite, so the bonus intentionally represents completing the prompt flow rather than a verified referral.
