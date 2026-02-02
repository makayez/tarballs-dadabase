# Changelog

All notable changes to Tarball's Dadabase will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- Global enable/disable toggle in Settings tab to override all module settings
- Red warning banner on module tabs when addon is globally disabled
- Statistics tracking showing content count and times told per module
- Statistics now increment for manual commands (`/dadabase say`, `/dadabase guild`)
- Sound effects with dropdown selection (15 short, punchy sound effects)
- Test button next to sound effect dropdown to preview selected sound
- About tab with usage instructions, GitHub link, and thank you message
- Tooltips on disabled controls explaining addon is globally disabled or module is disabled
- Clarifying help text for cooldown setting explaining its behavior
- Multi-line text editor for content management (one item per line)
- Save Changes button with visual feedback in configuration UI
- Save Changes button now disabled until content is actually edited
- Reset to Defaults button to clear all user customizations
- Dynamic prefixes for all content types with 108 randomized adjectives
  - Dad Jokes: "And now, for a [adjective] dad joke: "
  - Demotivational: "And now, for a [adjective] motivational quote: "
  - Guild Quotes: "And now, for some [adjective] famous words from a friend: "
- Automatic grammar handling (a/an) based on adjective
- 32 additional demotivational sayings
- Migration system for existing SavedVariables data
- Rate limiting on manual commands (3 second cooldown)
- Content caching system for performance with large datasets
- Comprehensive input validation and sanitization
- Error handling for all critical operations
- Command hint in startup message

### Changed
- Sound effects now only play when Test button is clicked (not on dropdown selection)
- Replaced long sound effects with shorter ones suitable for raid announcements
- About tab now appears first in the configuration panel (before Settings)
- All tab buttons widened to 120-130px for better text display
- Configuration panel height increased to 650px to prevent content overlap
- Module enable checkbox now always active (allows configuration when globally disabled)
- Module tab controls now gray out dynamically when module is disabled (in addition to global disable)
- `/dadabase say` and `/dadabase guild` commands now ignore trigger and group settings, only respecting module enabled state
- `/dadabase status` command now formatted better with statistics included
- Content storage system now tracks only user changes (additions/deletions) instead of full content arrays
- Default content is now stored in addon code rather than SavedVariables
- Configuration UI replaced scrollable list with individual delete buttons with a text editor
- SavedVariables structure now uses `userAdditions` and `userDeletions` arrays
- DB versioning now preserves user deletions (deleted jokes stay deleted on upgrade)
- Debug output now properly conditional (no spam in chat on load)
- All magic numbers replaced with named constants
- README updated to reflect all new features

### Fixed
- Sound effect test button now properly plays sounds using numeric SOUNDKIT IDs
- Corrected sound effect IDs (removed incorrect ones causing voice lines)
- Personal death trigger now works when solo (not just in groups)
- Personal death trigger no longer requires group checkboxes to be enabled
- Guild Quotes text editor now accepts input (removed from disabled controls)
- Manual commands (`/dadabase say`, `/dadabase guild`) no longer return "dadabase is empty" when modules are enabled but triggers/groups are not configured
- Race condition in SendContent that could bypass cooldown
- Message length validation prevents exceeding WoW's 255 character limit
- Memory leak from recreating tooltip handlers on every refresh
- Empty contentPool now returns valid moduleId instead of nil
- Content management now handles large datasets (1100+ items) efficiently with caching
- New default content in updates automatically appears without restoring deleted items
- SavedVariables file size reduced significantly for users with default content

### Technical
- `GetEffectiveContent()` function merges defaults with user changes at runtime with caching
- Content cache automatically invalidates on any content modification
- `SetEffectiveContent()` includes comprehensive type validation and error handling
- `GetRandomContent()` now returns both content and moduleId for prefix handling
- `GetRandomContent()` supports optional `ignoreTriggers` parameter for manual commands
- `GetContentPrefix()` function generates dynamic prefixes with 108 randomized adjectives
- Input sanitization strips WoW formatting codes (colors, hyperlinks, textures, encrypted text)
- Race condition prevention in SendContent using pendingMessage flag
- Math.random properly seeded for better randomness
- All magic numbers replaced with named constants
- Tooltip handlers reused instead of recreated to prevent memory leaks
- Backward compatibility maintained for legacy functions

## [0.3.0] - 2026-02-01

### Added
- Multiple content types (Dad Jokes, Demotivational, Guild Quotes)
- Flexible trigger system (wipes, personal death)
- Group targeting (raids, parties)
- `/dadabase on` and `/dadabase off` commands
- `/dadabase say` command for manual content sharing
- `/dadabase guild` command for guild chat
- Modular architecture for easy expansion

### Changed
- Refactored to modular architecture
- Each content type has its own configuration tab

## [0.2.0] - 2025-01-XX

### Added
- Configuration panel
- Slash commands

## [0.1.0] - 2025-01-XX

### Added
- Initial release
- Basic dad joke functionality on raid wipes
