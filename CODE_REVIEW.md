# Code Review — Tarball's Dadabase (branch `feature/0.6.0-alpha-warcraft-jokes`)

Review of the addon as of `main` @ `51b72a7`, plus the first pass implemented on this branch.

**Scope of this pass (implemented):** split Warcraft-themed jokes out of the Dad Jokes
database into their own module/database, and add the enable/tab for it. Everything else
below is **catalogued only — not fixed**.

---

## 1. What was implemented in this pass

| Change | File |
|---|---|
| New module/database `warcraftjokes` with 84 WoW-specific default jokes | `Modules/WarcraftJokes.lua` (new) |
| 84 WoW jokes removed from Dad Jokes defaults (1007 → 923) | `Modules/DadJokes.lua` |
| Dad Jokes `dbVersion` bumped `2 → 3` (defaults changed) | `Modules/DadJokes.lua` |
| Config tab registered (same shape as Guild Quotes) | `Modules/WarcraftJokes.lua` |
| Default prefix entry for the new module | `Database.lua:337` (`GetContentPrefix`) |
| TOC load order entry | `TarballsDadabase.toc` |
| Version `0.5.4-beta.1 → 0.6.0-alpha.1` | `Core.lua`, TOC |

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

## 2. Issues catalog (found, NOT fixed)

### P1 — Blocking for this feature

**I-1. Config panel tab bar overflows with a 6th tab.**
`CreateTabButton` (`Config.lua:66`) lays tabs out in a single row using accumulated widths:
`x = 20 + Σ(width + 5)`. With About(120) + Settings(120) + four large tabs (130 each), the
last button starts at `x = 675` and ends at `x = 805` — 105px past the 700px panel.
The Warcraft Jokes tab is the 6th button, so it renders outside the panel.
Options: wrap to a second row, shrink `TAB_BUTTON_WIDTH_LARGE`, widen the panel, or make the
tab bar scrollable. (Left unfixed per instructions.)

**I-2. `string.trim` is not a Lua 5.1 / WoW API method.**
`Core.lua:357`, `Config.lua:737`, `Database.lua:106` all call `:trim()`. WoW runs Lua 5.1 and
exposes `strtrim(s)`, not `string.trim`. If `trim` is not present this is an
`attempt to call method 'trim' (a nil value)` error on the slash command, on every Save in the
content editor, and in `SanitizeText`. Needs in-game verification; if confirmed, replace with
`strtrim` (or a local shim).

**I-3. SavedVariables migration for moved jokes.**
Content tracking is per-module (`userAdditions` / `userDeletions`). Moving 84 jokes from
`dadjokes` to `warcraftjokes` means:
- A user who had **deleted** a WoW joke in Dad Jokes will see it reappear in the new database
  (the deletion stays in `dadjokes.userDeletions` and is never applied to the new module).
- A user's **own additions** that are WoW-flavoured stay in Dad Jokes and are not moved.
- Users who deleted a moved joke now have stale entries in `dadjokes.userDeletions`
  (harmless, but they inflate the "preserved deletions" debug count).
Needs a one-time migration map (old moduleId → new moduleId for moved items) if we want
deletions to follow the jokes.

### P2 — Correctness / robustness

**I-4. `GetContentPrefix` silently returns `""` for any module not in its hardcoded table.**
`Database.lua:337` is keyed by moduleId with a special case for `guildquotes`. Any future
module gets no prefix. The new module is only correct because we added a line.

**I-5. `MAX_CONTENT_ENTRY_LENGTH = 195` is hardcoded against the longest prefix.**
It is derived from the Guild Quotes prefix (60 bytes). It is not recomputed when a prefix
grows, so a longer prefix in any module can push `prefix + content` past the 255-byte chat
limit and cause silent truncation (`SendContent` truncates rather than splitting).
Also the editor says "max 195 **characters** per line" while the check is `#line > 195`
(**bytes**) — non-ASCII entries are rejected earlier than the label implies.

**I-6. Duplicate lines are not collapsed, contradicting the comment.**
`Config.lua:758` claims saved content has "collapsed duplicates", but
`Database.SetEffectiveContent` (`Database.lua:463-470`) inserts every non-default line,
including duplicates, into `userAdditions`. Duplicates are only deduped for the
*deletion* side (`newContentSet`). Behaviour and comment disagree.

**I-7. `ShowTab` hardcodes `i == 2` to refresh statistics** (`Config.lua:114`).
Adding/reordering tabs breaks the stats refresh. Should key off the tab's role, not its index.

**I-8. Load message wording vs. actual content.**
`Core.lua:240-242` prints `"<total> <random name> loaded"` where the total is across *all*
modules (including disabled and empty ones such as Guild Quotes) and the noun is picked from a
list of joke names. With a separate Warcraft database this is now more misleading: a user with
only WoW jokes enabled still sees "dad jokes", and a user with 0 enabled content still sees a
non-zero count. Also `GetRandomContentTypeName()` has no Warcraft-flavoured names.

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

- **I-15.** About tab text (`Config.lua:165`) lists "Dad Jokes, Demotivational, or Guild
  Quotes tabs" — now stale, missing Warcraft Jokes.
- **I-16.** README "Default Content" section says "Dad Jokes: 100+" (actual 923 after the
  split, 1007 total) and has no entry for the new database; the Saved Variables section needs
  the new module and any new settings.
- **I-17.** CHANGELOG has no entry for this branch yet.
- **I-18.** Statistics list order is non-deterministic (`pairs` in `GetModuleStats`), so the
  Settings tab reshuffles rows between opens.
- **I-19.** `math.randomseed(time())` is pcall-guarded but WoW's `math.randomseed` is
  effectively a no-op in some client versions; distribution is fine, just don't rely on it.
- **I-20.** No lint / static analysis in CI (only packaging). No test harness for the
  change-tracking logic, which is the most bug-prone part of the addon.

---

## 3. Improvements catalog (not applied)

**A. Content / database**
1. **Per-module prefix template.** Move the prefix strings into `RegisterModule` config
   (`prefixTemplate = "And now, for {article} {adjective} {noun}: "`) so new modules don't
   need a branch in `Database.GetContentPrefix`. Fixes I-4 structurally.
2. **Warcraft-flavoured adjective pool** for the WoW module (e.g. "Lag-terning", "punny",
   "lore-accurate", "tank-tastic") — the shared adjective list is generic.
3. **Migration helper** for moved content (fixes I-3): carry `userDeletions` for moved items
   from `dadjokes` to `warcraftjokes` on `dbVersion` bump.
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

## 4. Decisions to confirm before the 0.6.0 release

1. Branch/version naming: this branch bumps to `0.6.0-alpha.1` (alpha, since this needs testing). If you prefer to keep the
   version bump at release time, revert `Core.lua` + TOC.
2. Whether the 26 borderline jokes move too (see A.4).
3. Whether the tab overflow fix (I-1) is in scope for this pass — the feature is visually
   broken without it.
4. Whether `string.trim` (I-2) is actually available in the current client — if not, it is a
   live bug on `main` today, independent of this feature.
