# Code Review — Tarball's Dadabase (branch `feature/0.6.0-alpha-warcraft-jokes`)

Review of the addon as of `main` @ `51b72a7`, plus the first pass implemented on this branch.

**Scope of this pass (implemented):** split Warcraft-themed jokes out of the Dad Jokes
database into their own module/database, and add the enable/tab for it. Everything else
below is **catalogued only — not fixed**.

---

## 1. What was implemented in this pass

| Change | File | Status |
|---|---|---|
| New module/database `warcraftjokes` with 84 WoW-specific default jokes | `Modules/WarcraftJokes.lua` (new) | done |
| 84 WoW jokes removed from Dad Jokes defaults (1007 → 923) | `Modules/DadJokes.lua` | done |
| Dad Jokes `dbVersion` bumped `2 → 3` (defaults changed) | `Modules/DadJokes.lua` | done |
| Config tab registered (same shape as Guild Quotes) | `Modules/WarcraftJokes.lua` | done |
| Default prefix entry for the new module | `Database.lua` (`GetContentPrefix`) | done |
| TOC load order entry | `TarballsDadabase.toc` | done |
| Version `0.5.4-beta.1 → 0.6.0-alpha.1` | `Core.lua`, TOC | done |
| Vertical tab bar in a left gutter (fixes the 6-tab overflow) | `Config.lua` | done (was I-1) |
| Per-module descriptor pools + per-module start-up breakdown, empty databases skipped | `Core.lua`, `Database.lua` (`GetContentSummary`) | done (was I-8) |
| One-time migration carrying user deletions across moved content | `Migrations.lua` (new) | done (was I-3) |
| Help line explaining the shared random pool | `Config.lua` | done (was B.9) |
| About tab + Interface Options text | `Config.lua` | done (was I-15) |
| README feature list, counts, architecture, Saved Variables, version | `README.md` | done (was I-16) |

Behaviour notes for the new module:

- **Default off** (`defaultSettings.enabled = false`, `groups = {raid=false, party=false}`),
  persisted in `TarballsDadabaseDB.modules.warcraftjokes` — same persistence model as
  Demotivational / Guild Quotes.
- **Start-up count:** `GetTotalContentCount()` (`Database.lua:289`) iterates *all* registered
  modules, so the new database is already included in the load message and in
  `/dadabase status` and the Settings → Statistics list. No code change was needed.
  Total content is unchanged at 1007 (923 + 84).
- **Prefix:** `GetContentPrefix()` had no entry for the new module and would have returned
  `""` (no prefix at all). Added `warcraftjokes = "And now, for {a/an} {adj} Warcraft joke: "`.
  Longest generated form is 45 bytes, so the existing `MAX_CONTENT_ENTRY_LENGTH = 195`
  (derived from the 60-byte Guild Quotes prefix) still holds.

---

## 2. Issues catalog

Found during the review pass. Items marked **RESOLVED** were fixed; the rest remain open for
in-game testing. One additional load-breaking bug was found during syntax checking and fixed:
`Modules/DadJokes.lua` had a stray duplicate `}` at the end of the joke table from the content
split, which would have prevented the file from loading.

### P1 — Blocking for this feature

**I-1. Config panel tab bar overflows with a 6th tab. — RESOLVED**
`CreateTabButton` laid tabs out in a single row using accumulated widths:
`x = 20 + Σ(width + 5)`. With About(120) + Settings(120) + four large tabs (130 each), the
last button started at `x = 675` and ended at `x = 805` — 105px past the 700px panel.
Resolved by moving the tab bar to a left gutter (`TAB_GUTTER_WIDTH = 175`) with content
anchored to the right; editor/divider/prefix-input widths were reduced to fit. A gutter
scales to any number of modules, so this cannot recur.

**I-2. `string.trim` is not a Lua 5.1 / WoW API method. — NOT A BUG (verified in alpha)**
`Core.lua`, `Config.lua`, and `Database.lua` all call `:trim()`. WoW runs Lua 5.1 and the
documented API is `strtrim(s)`, so the risk was an
`attempt to call method 'trim' (a nil value)` error on the slash command, on every Save in the
content editor, and in `SanitizeText`. Alpha testing of 0.6.0-alpha.1 exercised all three paths
with no such error, so the current client does provide `trim`. A defensive `strtrim` shim is
still optional insurance if you want to support older clients.

**I-3. SavedVariables migration for moved jokes. — RESOLVED (risk assessed)**
Content tracking is per-module (`userAdditions` / `userDeletions`), so a user who had
**deleted** a WoW joke in Dad Jokes would see it reappear in the new database.
Resolved by `Migrations.lua`: a one-time, idempotent, flag-guarded pass that copies matching
deletions to the destination module and prunes them from the source.
Why this is low risk: it only touches strings in the moved set, never rewrites
`userAdditions`, is guarded by `TarballsDadabaseDB.migrations["from->to"]` so it runs once,
and the worst failure mode is a no-op. The alternative — a generic "deletions follow content
across all modules" rule — was rejected because a user can add the same line to one module
while deleting it from another, which that rule would corrupt.

### P2 — Correctness / robustness

**I-4. `GetContentPrefix` silently returns `""` for any module not in its hardcoded table. — RESOLVED**
`Database.lua:337` was keyed by moduleId with a special case for `guildquotes`. Any future
module got no prefix. Now driven by a `PREFIX_TEMPLATES` table, so a new module only needs an
entry there.

**I-5. `MAX_CONTENT_ENTRY_LENGTH = 195` is hardcoded against the longest prefix. — RESOLVED**
It was derived from the Guild Quotes prefix (60 bytes) and was not recomputed when a prefix
grew, so a longer prefix in any module could push `prefix + content` past the 255-byte chat
limit and cause silent truncation. `Dadabase.MAX_PREFIX_LENGTH` is now computed from the
longest template, and `Config.lua` derives the per-line cap from it.
Also the editor says "max 195 **characters** per line" while the check is `#line > 195`
(**bytes**) — non-ASCII entries are rejected earlier than the label implies.

**I-6. Duplicate lines are not collapsed, contradicting the comment.**
`Config.lua:758` claims saved content has "collapsed duplicates", but
`Database.SetEffectiveContent` (`Database.lua:463-470`) inserts every non-default line,
including duplicates, into `userAdditions`. Duplicates are only deduped for the
*deletion* side (`newContentSet`). Behaviour and comment disagree.

**I-7. `ShowTab` hardcoded `i == 2` to refresh statistics — RESOLVED**, now matched by tab
identity via a captured `settingsTab` reference.

**I-8. Load message wording vs. actual content. — RESOLVED**
`Core.lua` now prints a per-module breakdown (`923 dad jokes, 84 Azeroth groaners, 68
demotivational sayings`) via `DB:GetContentSummary()`, sorted by module name, and omits
modules with no content. Descriptor word pools are now per-module with a `default` fallback.
Remaining nuance: counts still include disabled modules — an enabled-but-empty database is
omitted, but a disabled database with content is still counted.

**I-9. `SOUNDKIT` fallbacks are hardcoded numeric IDs.**
`Core.lua` and `Config.lua` fall back to literals (`888`, `8960`, `12867`, …) when the
`SOUNDKIT` field is nil. These IDs are not stable across patches; a nil value would make
`PlaySound` fail (it is pcall-guarded, but the dropdown would still show the name).

**I-10. Wipe detection is instance-only.**
`ENCOUNTER_END` is gated on `IsInInstance()` returning `party|raid|scenario` (`Core.lua`), so
outdoor/overworld raid wipes (world bosses, open-world encounters) never trigger, even though
the README and the UI say "Party/Raid wipes". Worth documenting or widening the check.

**I-11. `pendingMessage` is a skip, not a queue.**
If a send is already pending, `SendContent` drops the message entirely. Combined with the
0.5s timer this is fine for wipes, but the flag is deliberately not shared with the manual
path, so a manual send and a wipe send can interleave. Documented in the code, but the
behaviour is surprising to users.

**I-12. `SetCustomPrefix` byte cap vs. `SetMaxLetters(50)` character cap.**
`Config.lua:550` allows 50 characters; `Database.SetCustomPrefix` truncates to 50 **bytes**.
A non-ASCII prefix is silently shortened. Minor, but the UI promise and the stored value can
differ.

**I-13. `Config:BuildModuleContent` returns early if the module DB is not initialized.**
If a tab is built before `DatabaseManager:Initialize()` (possible if a module registers a tab
but `Initialize` is skipped/errored), the tab is blank with no error. Worth a guard message.

**I-14. No validation that `RegisterModule` and `RegisterModuleTab` agree.**
A module registered without a tab (or a tab registered for an unregistered module) fails
silently or errors at runtime. `RegisterModule` errors on duplicates, but nothing checks the
tab side.

### P3 — Hygiene / consistency

- **I-15.** About tab text — **RESOLVED** (now lists Warcraft Jokes; the About and Interface
  Options descriptions mention Warcraft puns).
- **I-16.** README — **RESOLVED** (feature list, per-database counts, architecture file list,
  Saved Variables `migrations` entry, pooling note, version, and the message-splitting claim
  corrected: over-length lines are skipped on save and messages are truncated on send, there
  is no multi-message splitting).
- **I-17.** CHANGELOG — entry added for this branch.
- **I-18.** Statistics list order is non-deterministic (`pairs` in `GetModuleStats`), so the
  Settings tab reshuffles rows between opens.
- **I-19.** `math.randomseed(time())` is pcall-guarded but WoW's `math.randomseed` is
  effectively a no-op in some client versions; distribution is fine, just don't rely on it.
- **I-20.** No lint / static analysis in CI (only packaging). No test harness for the
  change-tracking logic, which is the most bug-prone part of the addon.

---

## 3. Improvements catalog (not applied)

**A. Content / database**
1. **[applied] Per-module prefix template.** Moved the prefix strings into a `PREFIX_TEMPLATES`
   table so new modules do not need a branch in `Database.GetContentPrefix`. Fixes I-4
   structurally.
2. **Warcraft-flavoured adjective pool** for the WoW module (e.g. "Lag-terning", "punny",
   "lore-accurate", "tank-tastic") — the shared adjective list is generic.
3. **[applied] Migration helper** for moved content (fixes I-3): `Migrations.lua` carries
   `userDeletions` for moved items from `dadjokes` to `warcraftjokes` on first run.
4. **Borderline jokes need a decision.** 26 jokes are WoW-adjacent but not clearly
   game-specific and were deliberately left in Dad Jokes. Recommend a second pass to confirm:
   Left in Dad Jokes: `Sighborg`, `psychic gnome`, `gnome king / amazing ruler`,
   `metro-gnome (lawn statue)`, `dwarf signaling hello / microwave`, `pickaxe / miner injury`,
   `miner / granite`, `ketchup gear`, `cake in tiers`, `holy water / boil the hell out of it`,
   `elementree school`, `low elf esteem`, `rogues' kleptomaniac championships`, `rouges + Twix`,
   `feral (lion / mice water / hot air balloon)`, `hunter (11 rabbits / prime)`,
   `engineer (coat hangers + duct tape)`, `keyboard` jokes, `pumpkin patch`,
   `monkey in a mine field`, `non-binary prospector / gold`, `blacksmith dog / bolt`.
   Already moved but arguable: `6 out of 7 dwarves aren't happy`, `undead cross the road`,
   `dwarves lightbulb`, `shaman / elementary school`, `snail mount`, `When I raid...count on them`.
   Current split: 84 moved, 923 kept.
5. **Deduplicate on save** (fixes I-6) or drop the misleading comment.
6. **Compute `MAX_CONTENT_ENTRY_LENGTH` from the longest prefix** instead of hardcoding 195.

**B. UI / UX**
7. **Tab bar wrapping / scrolling** (fixes I-1) — required before shipping a 6th tab.
8. **Group the content tabs** so the panel reads: About · Settings · Content (Dad Jokes,
   Warcraft, Demotivational, Guild Quotes). Or a dropdown for content type.
9. **Per-module "share with dad jokes" pool indicator** — the user asked for WoW jokes to be
   enable-able *separately from* dad jokes; today that is exactly the module enable checkbox,
   but the panel doesn't explain that both pools are combined into one random pick. A short
   help line ("Content is pooled across all enabled modules") would prevent confusion.
10. **Deterministic tab + stats ordering** (fixes I-7, I-18).
11. **Load message breakdown** — e.g. `1007 jokes loaded (923 dad jokes, 84 Warcraft, 30
    demotivational, 0 guild quotes)` and only count enabled modules, or state which are off.
12. **`/dadabase status` should show the WoW module's enabled state in the summary block**
    (it already lists per-module lines, but the header total mixes everything).
13. **Slash command shortcuts** for the new module, e.g. `/dadabase warcraft on|off`,
    consistent with the existing `on`/`off` which toggles *all* modules.
14. **Editor: show which module a line belongs to** when content is pooled — currently a user
    can't tell whether a joke came from Dad Jokes or Warcraft when reading chat.

**C. Architecture**
15. **`GetTotalContentCount` should optionally count only enabled modules** — the "loaded"
    number currently includes content that can never fire.
16. **Cache invalidation is manual.** `contentCache` is cleared in three places
    (`Initialize`, `SetEffectiveContent`, the Reset button). A `DB:InvalidateCache(moduleId)`
    helper would prevent future drift.
17. **`GetEffectiveContent` returns a shared mutable table.** It is documented as read-only,
    but nothing enforces it. Consider returning a copy for UI use, or freezing it.
18. **No `SavedVariablesPerCharacter` option** — stats and settings are account-wide. Worth
    documenting at minimum.
19. **CI: add luacheck / lua-lint** and a small unit test for the change-tracking
    (additions/deletions) logic, which is where the migration risk lives.
20. **`.pkgmeta` has no `interface` / `ignored` fields**; packaging relies entirely on the TOC.
    Fine, but a `## X-...` category/keywords block would improve CurseForge metadata.

---

## 4. Decisions — resolved during the alpha

1. Branch/version naming: branch `feature/0.6.0-alpha-warcraft-jokes`, version bumped in
   `Core.lua` + TOC. Alpha promoted to `0.6.0-beta.1` after in-game testing.
2. The 26 borderline jokes stay in Dad Jokes for now (see A.4) — revisit before the stable
   0.6.0 release.
3. The tab overflow fix (I-1) was brought into scope; the left-gutter layout verified in-game.
4. `string.trim` (I-2) confirmed available on the current client during alpha testing.
5. Start-up counts include populated but disabled modules; only empty databases are omitted.
   Kept as is.

---

## 5. Performance — opportunities

Honest answer: there is very little left. The addon has no `OnUpdate`, no per-frame work, no
per-item allocation in the hot path, a minimal event set (4 events), and a cache for the only
data structure that is read repeatedly. Nothing here is measurable in a running client.

The only real (micro) wins:

1. **`GetContentPrefix` allocates a `prefixes` table on every call.** Hoist it to a file-scope
   `PREFIX_TEMPLATES` with `string.format("%s", adjective)`. One table allocation saved per
   message. Worth doing for clarity more than for speed.
2. **`GetRandomContent` allocates a `matching` table per trigger.** Reuse a module-level
   scratch table (cleared with `table.wipe`) instead of allocating per call. Only matters on
   raid wipes with many modules; negligible, but it is free.
3. **`GetTotalContentCount()` materializes every module's effective content just to count it.**
   A `#defaults - #deletions + #additions` count avoids building ~1007-entry tables at login.
   **Not recommended**: it is only correct if every stored deletion still refers to a default
   item, and the cache is needed for the random pick anyway. The current code is correct and
   the win is a single login-time allocation.
4. **`contentCache` holds all module arrays (~1007 strings, ~60-70 KB).** Could cache only
   enabled modules. Not worth the complexity.
5. **`SanitizeText` runs 6 `gsub` passes per line** on Save (923 lines ≈ 5,500 gsubs in one
   click). Fine — it is a user action, not a hot path.
6. **The Dad Jokes editor builds a ~40 KB string and a ~13,000 px edit box on first open.**
   Only on first open. Fine.

Explicitly checked and already good: weighted two-step pick (no pool materialization),
adjective/vowel tables hoisted, sets instead of arrays for deletion checks, `table.concat`
instead of string concatenation in loops, tooltip handlers attached only on state change,
panel built lazily, `pcall` around `PlaySound`/`math.randomseed`, SavedVariables stores only
deltas.

## 6. Code cleanup / idiomatic Lua

Status legend: **[applied]** in this pass, **[open]** left for in-game testing.

1. **[applied] Normalize `GetChecked()` to a boolean.** `Config.lua` stores `self:GetChecked()` straight
   into SavedVariables. On some clients this returns `1`/`nil` rather than `true`/`false`, and
   `moduleDB.groups[group] == true` would then never match — a module could be enabled and
   never trigger. `ToBoolean()` is now used at every write and read, and `GetRandomContent`
   uses a truthy group test so a stored `1` still counts.
2. **[applied]** `local DB = Dadabase.DatabaseManager` reads like the SavedVariables global**
   (`TarballsDadabaseDB`). Renamed to `Manager` in `Config.lua` and `Database.lua`.
3. **[applied]** `Config:BuildModuleContent` is ~500 lines in one function.** Split into widget
   factories (`AddCheckbox`, `AddHelpText`, `AddSectionLabel`, `AddWarningBanner`) plus the
   editor and control-state sections. The five near-identical checkbox blocks were the main
   duplication.
4. **[applied]** `TriggerContent` and `SendManualContent` duplicate** prefix building, length validation,
   truncation, and stats increment. Extracted `BuildMessage`, `RecordUsage`, and
   `PlaySelectedSound` in `Core.lua`.
5. **[applied]** `GetManualChatChannel` duplicates the instance/raid/party branch** in `GetCurrentGroup`.
   One helper now returns `(group, chatType)` for both paths.
6. **[applied]** `Config` pokes `DB.contentCache[moduleId] = nil` directly.** `Manager:InvalidateCache(moduleId)`
   is now the only place cache clearing happens.
7. **[applied]** `for moduleId, _ in pairs(...)`** → `for moduleId in pairs(...)`.
8. **[applied]** `msg:match("^cooldown%s+%d+$")` then `tonumber(msg:match("%d+"))`** matches twice; the
   value is captured once.
9. **[applied]** `RegisterModule` calls `error()` at load time.** A load-time error aborts the addon's
   remaining files. Now prints and returns.
10. **[applied]** `GetEffectiveContent` returns a shared mutable table.** Added
    `Manager:GetContentCount(moduleId)` for read-only callers (Config stats, status, load
    message). Counting still goes through the cache — see performance note 3.
11. **[open]** `SetControlState` mixes enable/disable, colouring, and tooltip wiring.** Left as
    is: splitting it would fragment the tooltip-state closure that stops handlers being
    recreated on every refresh.
12. **[applied]** `MAX_CONTENT_ENTRY_LENGTH` is derived** from the longest prefix template
    (`Dadabase.MAX_PREFIX_LENGTH`), so adding a module cannot silently exceed the chat limit.
13. **[open]** `GetTotalContentCount` and `GetContentSummary` overlap** — the total can be computed from
    the summary. Left for now; both now share `GetContentCount`.
14. **[partially applied]** `SOUNDKIT` numeric fallbacks** — the default sound is centralised as
    `Dadabase.DefaultSound`. Per-option fallbacks stay as literals because each option needs a
    different fallback id, and collapsing them to one value would collide with the explicit `888`
    entry in the dropdown table.
15. **[resolved — verified in-game] `string.trim` is not guaranteed on the WoW client.**
    `Core.lua`, `Config.lua`, and `Database.lua` call `:trim()`. No `attempt to call method
    'trim' (a nil value)` error surfaced during alpha testing, so the current client provides
    it. A `strtrim` shim remains optional for older clients.
