# TEBBY.md - pickle_bailbounty

## Overview

`pickle_bailbounty` is a FiveM (GTA V multiplayer) resource by Pickle Mods that provides a complete **bail bond and bounty hunting system**. Police officers can place suspects on bail with ankle-monitor tracking; if a parolee misses a check-in or removes their tracker, they automatically become a bounty. Bounty hunters clock in at a duty location, accept active bounties (player or NPC), detain and transport targets to a holding cell, and earn rewards. NPC bounties are generated procedurally at configurable world locations. The system is backed by MySQL persistence and a React/Vite NUI panel.

---

## Code design

### Architecture

The resource follows a standard FiveM client/server/NUI split with a framework-bridge abstraction layer:

```
fxmanifest.lua
config.lua              ← shared config, loaded on both client and server
core/shared.lua         ← utility helpers (math, blips, animations, interactions)
core/client.lua         ← client-only helpers (CreateVeh, CreateNPC, CreateProp, PlayAnim, ShowInteractText)
modules/
  main/client.lua       ← NUI display, player init, command registration
  main/server.lua       ← player init, permission checks, MySQL schema, DB load
  bail/client.lua       ← ankle-monitor prop, bail registry UI, parole-mission runner
  bail/server.lua       ← bail CRUD, parole check-in, tracker-removal, bail-to-bounty escalation
  bounty/client.lua     ← bounty registry UI, NPC spawning, detain/drag/vehicle logic
  bounty/server.lua     ← bounty CRUD, NPC generation, reward distribution, duty toggle
bridge/
  esx/  qb/  custom/   ← framework adapters (client + server per folder)
  target/               ← target-system adapters (ox_target, qb-target, qtarget)
  xp/                   ← optional XP integration (pickle_xp)
locales/
  locale.lua            ← _L() helper
  translations/en.lua   ← all English strings
nui/                    ← committed build output (HTML + compiled JS/CSS)
web/                    ← React/Vite source (do NOT build in sandbox)
```

### Main flows

1. **Player load** – framework event fires (`esx:playerLoaded` / `QBCore:Client:OnPlayerLoaded`) → client triggers `pickle_bailbounty:initializePlayer` on server → server replies with the full bail registry, bounty registry, and permission set → client caches them and pushes to NUI.

2. **Bail placement** – officer uses `ankle_monitor` item → server verifies permissions and inventory → deducts item, records bail in SQL, broadcasts `pickle_bailbounty:addbail` to all clients. A server thread every 60 s checks compliance deadlines; a missed check-in calls `AddBountyToRegistry` and `RemoveBailFromRegistry`.

3. **Parole check-in** – player visits a parole officer NPC (configured in `Config.Bail.paroleOfficers`) → ox_lib interaction → `ParoleOfficerMenuQuery` → server callback returns bail info + check-in flag → client runs a `paroleMissions` task → on completion fires `pickle_bailbounty:completeParoleCheckin`.

4. **Tracker removal** – player runs the configured command (`removetracker`) with a sharp weapon equipped → server fires `pickle_bailbounty:revokeBail` with `selfRemove=true` → bail removed, bounty created, `onTrackerRemoval` callbacks invoked.

5. **Bounty hunting** – hunter clocks in at a duty location → `pickle_bailbounty:toggleDuty` → given loadout items. Hunter accepts a bounty from the NUI → `pickle_bailbounty:acceptBounty` → for NPC bounties the client spawns the NPC and sends its netId via `pickle_bailbounty:setCurrentBountyNPC`. Hunter detains → drags → places in vehicle → reaches a `cellLocations` point → interaction completes bounty → rewards distributed.

6. **Rewards** – `CompleteBounty` in `modules/bounty/server.lua` splits the reward: if a police officer takes custody (`custodyRewardFactor` × base reward to the hunter, flat `custodyRewardOfficer` to the officer), otherwise full reward to the hunter (with `backupRewardFactor` deducted if someone else helped deliver).

### Interaction system

A unified `CreateInteraction` / `DeleteInteraction` system in `core/client.lua` wraps both target-based (ox_target zone/model/network-id) and proximity keypress interactions. When `Config.UseTarget = true`, zones/models are registered with the active target bridge. When false, a draw-loop shows `lib.showTextUI` text and listens for key 51 (E).

### NUI communication

The React app (`web/src/`) uses `fetchNui` to call Lua callbacks. It is initialized via a `requestConfig` callback fired on mount. The Lua side pushes updates with `SendNUIMessage` for bounty list changes, bail registry changes, current bounty state, section visibility, and display show/hide.

---

## Important files

| Path | Why it matters |
|---|---|
| `fxmanifest.lua` | Declares all script, NUI, and streaming assets; controls load order; lists escrow-ignored files |
| `config.lua` | All operator-tunable settings: debug flag, target mode, tazer permissions, NPC bounty config, player bounty blip, duty locations, bail parameters, parole missions, jail event hook |
| `core/shared.lua` | Shared utility functions (`lerp`, `dprint`, `NumberWithCommas`, `GetRandomInt`) |
| `core/client.lua` | Client helpers; the `CreateInteraction` / `DeleteInteraction` / `ShowInteractText` framework used everywhere; the main proximity-loop thread |
| `modules/main/server.lua` | MySQL schema creation, DB load on startup, player-init handler, permission resolver, tazer event filter |
| `modules/main/client.lua` | NUI open/close, `requestConfig` NUI callback, `/bounties` and `/bail` commands, player permission cache |
| `modules/bail/server.lua` | `AddBailToRegistry`, `RemoveBailFromRegistry`, bail check-in loop, tracker-removal handler, escalation to bounty |
| `modules/bail/client.lua` | Ankle-monitor prop attachment, bail registry NUI updates, parole mission runner, blip management for bail players |
| `modules/bounty/server.lua` | `AddBountyToRegistry`, `RemoveBountyFromRegistry`, NPC bounty generation, duty toggle, `CompleteBounty` reward logic |
| `modules/bounty/client.lua` | NPC spawn/scenario logic, detain/drag/vehicle interaction, duty location rendering, bounty-target target-menu |
| `bridge/esx/client.lua` | ESX client bridge: `ShowNotification`, `ServerCallback`, `CanAccessGroup`, inventory fallback, `esx:playerLoaded` hook |
| `bridge/esx/server.lua` | ESX server bridge: `GetIdentifier`, `GetMoney`, `AddMoney`, `CheckPermission`, inventory CRUD, job-change resync |
| `bridge/qb/client.lua` | QBCore client bridge (same interface as ESX bridge) |
| `bridge/qb/server.lua` | QBCore server bridge (same interface as ESX bridge) |
| `bridge/custom/client.lua` | Stub that prints a warning; operators fill this for non-ESX/QBCore frameworks |
| `bridge/target/ox_target/client.lua` | ox_target adapter; also contains `AddTargetNetworkId` / `AddTargetGlobalPlayer` used by bounty module |
| `locales/locale.lua` | `_L()` helper; returns `ERR_TRANSLATE_<key>_404` for missing keys |
| `locales/translations/en.lua` | All English UI strings; operators add translation files here |
| `nui/index.html` + `nui/assets/` | Committed compiled NUI build; this is what the game loads |
| `web/` | React/Vite source for the NUI; **do not build in sandbox** — compile via CI only |
| `__INSTALL/Items/` | SQL/Lua item definitions for the `ankle_monitor` item per inventory system |

---

## Intended behaviors

### Escrow / partial source protection

`fxmanifest.lua` lists an `escrow_ignore` block that explicitly keeps `config.lua`, bridge files, locale files, and install assets editable. The core module scripts (`modules/`, `core/`) are **not** in `escrow_ignore`, meaning they ship obfuscated through Tebby escrow. Do **not** report missing content in those files as a bug — they are intentionally protected.

### Resource name sensitivity

The resource folder **must** be named `pickle_bailbounty` exactly. The NUI image path is hard-coded as `cfx-nui-pickle_bailbounty` (see `GenerateNPCBounty` in `modules/bounty/server.lua`). A misnamed folder breaks NPC images and locale loading silently. This is documented in `INSTALL.md` step 1.

### `Config.Debug = true` default

The shipped `config.lua` has `Config.Debug = true`. This is intentional for new installs to aid setup. Operators should flip it to `false` in production. Debug prints via `dprint()` in `core/shared.lua` are gated on this flag.

### Tazer permission filter

`modules/main/server.lua` intercepts `weaponDamageEvent` for `WEAPON_STUNGUN` (hash `911657153`) and cancels the event unless the shooter is in `Config.TazerPermissions.jobs` **or** is an active on-duty bounty hunter targeting their active bounty. This is a deliberate design to restrict tazers to authorized jobs and bounty hunters — it is not a bug.

### NPC bounty image URLs

NPC bounty images use `https://cfx-nui-pickle_bailbounty/nui/images/<model>.png`. The ped models allowed are locked to the six defined in `Config.NPCBounties.characters` (three male, three female), and matching PNG files are shipped in `nui/images/`. Requests for unlisted ped models will show a broken image — this is expected; operators must add both a ped entry and an image.

### Bail-to-bounty escalation is automatic and irreversible

When a parolee misses their compliance window (server-side thread checks every 60 s), or when the tracker is self-removed, `RemoveBailFromRegistry` is called immediately followed by `AddBountyToRegistry`. There is no intermediate state. This is by design.

### NPC bounty generation uses `ignoreSync` variable undefined in thread

In `modules/bounty/server.lua`, the startup `CreateThread` calls `GenerateNPCBounty(true, ignoreSync)` where `ignoreSync` is not defined — it evaluates to `nil`, which is harmless because `GenerateNPCBounty` only accepts one argument (`ignoreSync`). This is a cosmetic code issue, not a runtime error.

### `permission` vs `permissions` typo in `takeCustody`

In `modules/bounty/server.lua`, the `pickle_bailbounty:takeCustody` handler reads `permission.bailPlacement` (no 's') on the same line as `permissions.bailManage`. This is a latent bug (would cause a nil index error on the `permission` variable) — it is **not** intended behavior.

### `bounty_canceled` locale key defined twice

`locales/translations/en.lua` defines `bounty_canceled` twice. Lua will use the second definition silently. Not a crash, just dead code.

---

## Common issues & fixes

| Symptom | Likely cause | Fix |
|---|---|---|
| Locale strings show as `ERR_TRANSLATE_<key>_404` | Resource folder not named `pickle_bailbounty`, or `Config.Language` does not match a file in `locales/translations/` | Rename the folder; confirm `Config.Language = "en"` matches `en.lua` |
| NPC bounty images are broken (404) | Resource name mismatch (the `cfx-nui-pickle_bailbounty` URL is hard-coded) | Ensure the folder is named exactly `pickle_bailbounty` |
| Players are never initialized (no bounties/bail shown in NUI) | Framework bridge not loading (resource state check fails) | Confirm `es_extended` or `qb-core` is started **before** `pickle_bailbounty`; check console for bridge warning |
| `ankle_monitor` item use does nothing | Item not registered in inventory, or player lacks `bailManage` permission | Run the matching SQL/Lua from `__INSTALL/Items/`; verify officer job grade matches `Config.BailOfficers.permissions.management` |
| Bail officers cannot place bail | Missing `ankle_monitor` in officer inventory, or target player has insufficient cash | Confirm item exists; `placeBail` checks `Inventory.GetItemCount` and `GetMoney` before proceeding |
| `takeCustody` crashes server (nil index `permission`) | Typo in `modules/bounty/server.lua` line referencing `permission.bailPlacement` | Change `permission` to `permissions` on that line |
| NPC bounties not spawning on server start | `mysql-async` not started before `pickle_bailbounty`, so DB load fails | Ensure `@mysql-async/lib/MySQL.lua` is reachable; check `server.cfg` load order |
| Bounty hunter cannot use tazer on their bounty target | Shooter's bounty target `netId` lookup distance check is 10 m but check is for NPC only, not player targets | This is a design gap — tazer on player bounties is not currently validated; use `Config.TazerPermissions.jobs` to grant blanket permission |
| Target interactions not appearing | `Config.UseTarget = true` but target resource not started | Set `Config.UseTarget = false` for keypress mode, or start the target resource first |

---

## Conventions

- **Lua 5.4** (`lua54 'yes'` in manifest). Use `<const>`, bitwise operators, and proper integer division where appropriate.
- **Event / callback namespacing**: all net events and server callbacks are prefixed `pickle_bailbounty:` (camelCase after the colon). New events must follow this pattern.
- **Global tables**: `BailRegistry` and `BountyRegistry` are globals shared between modules on both client and server. Do not shadow them with locals.
- **Bridge functions**: never call ESX/QBCore APIs directly in module code. Use the bridge functions (`ShowNotification`, `AddMoney`, `GetIdentifier`, `CheckPermission`, `Inventory.*`, etc.). This keeps the resource framework-agnostic.
- **`_L(key, ...)`** for all user-facing strings. Add new keys to `locales/translations/en.lua`; never hardcode English strings in module code (a few exist as legacy — treat them as bugs to fix, not patterns to follow).
- **`dprint(...)`** for all debug output (gated by `Config.Debug`). Never use bare `print()` in module code.
- **`NumberWithCommas(x)`** (defined in `core/shared.lua`) for all currency display. It prepends `$` and inserts commas.
- **SQL**: use `MySQL.Async.execute` / `MySQL.Async.fetchAll` (mysql-async API). Table names are `pickle_bailbounty_bounties` and `pickle_bailbounty_bail`.
- **NUI messages**: use `SendNUIMessage({ type = "...", ... })`. New message types must be handled in `web/src/` and a CI rebuild triggered — do not modify committed `nui/assets/` directly.
- **File placement**: client code in `modules/**/client.lua`, server code in `modules/**/server.lua`, shared utilities in `core/shared.lua`. Bridge adapters go in `bridge/<framework>/client.lua` or `bridge/<framework>/server.lua`.
- **Escrow awareness**: `modules/` and `core/` files are escrowed in production builds. Any fix must be applied to the **source** files in this repo, not the compiled output. Do not edit `nui/assets/` manually.
