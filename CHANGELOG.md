# Changelog

All notable changes to Tarball's Dadabase will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

## [0.4.0] - 2026-02-03

### Added
- Custom prefix support per module (enable/disable, custom text input with 50 character limit)
- Automatic message splitting for long content (messages >255 chars split at word boundaries with 1.5s delay between chunks)
- Visual divider separating auto-save settings from manual-save content editor
- Content Editor section clearly labeled with explicit save instructions
- Save Changes and Reset to Defaults buttons now contained within editor frame with divider line
- Buttons disabled until text changes are detected (clearer UX for what requires saving)
- Helper functions for dynamic tab positioning (CreateTabButton) and control state management (SetControlState)
- Consolidated SanitizeText utility function for input sanitization

### Changed
- Simplified triggers UI by removing "Personal death" option (only wipe triggers remain)
- Combined trigger and group sections into single "Trigger on wipes in:" section
- Reduced randomized adjectives from 110 to 40 most fitting options
- Renamed "Saved Variables (legacy)" section to "Global Settings" for clarity
- Changed "Content" label to "Content Editor" to emphasize editor functionality
- Updated instructions text to explicitly mention "Save Changes" button
- Extracted sound options to SOUND_OPTIONS constant for easier maintenance
- Tab button positioning now uses dynamic helper function instead of hard-coded offsets
- Maximum global cooldown increased from 60 seconds to 600 seconds (10 minutes)
- Settings panel integration redesigned - Options > Addons > Tarball's Dadabase now shows a simple panel with a button to open the full configuration dialog
- Tab button positioning now uses absolute positioning for consistent layout regardless of display method

### Fixed
- **Critical:** Taint issue causing "blocked from Blizzard UI action" error (removed C_Timer.After from single message sending)
- **Critical:** Race condition in multi-message splits (now validates group still exists before sending delayed messages)
- **Critical:** Message splitting edge cases (empty chunks, infinite loops, proper word-boundary detection)
- Removed dead code: 3 unused legacy functions (AddContent, RemoveContent, GetContent) - 43 lines removed
- Removed orphaned death trigger logic from Database.lua after PLAYER_DEAD event was removed
- Message splitting now accounts for prefix length in total message size calculation
- Config panel toggle bug when switching between `/dadabase` command and Options menu (now uses IsVisible() instead of IsShown())
- Config panel no longer attempts to embed in Settings window, preventing button overflow and display issues

### Technical
- Message splitting with smart word-boundary detection (searches for spaces/punctuation within last 50 chars)
- Group validation in C_Timer callbacks prevents errors when player leaves group during multi-message send
- Consolidated all sanitization logic into single DB:SanitizeText() function (DRY principle)
- Trigger logic simplified: module enabled + group match = triggers (no longer checks triggers.wipe)
- RefreshControls function reduced from 58 to 38 lines using SetControlState helper
- Added safety limits to message splitting (max 20 iterations, progress detection)
- Removed SetModuleTrigger() function (dead code, never called)
- Removed triggers from module defaultSettings (new installs don't need them)
- Triggers field preserved in existing SavedVariables for backward compatibility but no longer used

## [0.3.0] - 2026-02-01

### Added
- Multiple content types (Dad Jokes, Demotivational, Guild Quotes)
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
- Flexible trigger system (wipes, personal death)
- Group targeting (raids, parties)
- 1100+ dad jokes and puns
- 60+ demotivational sayings
- `/dadabase on` and `/dadabase off` commands
- `/dadabase say` command for manual content sharing
- `/dadabase guild` command for guild chat
- `/dadabase status` command with detailed information
- `/dadabase debug` command for troubleshooting
- Migration system for existing SavedVariables data
- Rate limiting on manual commands (3 second cooldown)
- Content caching system for performance with large datasets
- Comprehensive input validation and sanitization
- Error handling for all critical operations
- Command hint in startup message
- Modular architecture for easy expansion

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
- Refactored to modular architecture
- Each content type has its own configuration tab

### Fixed
- Sound effect test button now properly plays sounds using numeric SOUNDKIT IDs
- Corrected sound effect IDs (removed incorrect ones causing voice lines)
- Personal death trigger now works when solo (not just in groups)
- Personal death trigger no longer requires group checkboxes to be enabled
- Guild Quotes text editor now accepts input (click handlers on parent frames)
- Manual commands (`/dadabase say`, `/dadabase guild`) no longer return "dadabase is empty" when modules are enabled but triggers/groups are not configured
- Race condition in SendContent that could bypass cooldown
- Message length validation prevents exceeding WoW's 255 character limit
- Memory leak from recreating tooltip handlers on every refresh
- Empty contentPool now returns valid moduleId instead of nil
- Initialization order errors with comprehensive nil checks
- Content management now handles large datasets (1100+ items) efficiently with caching
- New default content in updates automatically appears without restoring deleted items
- SavedVariables file size reduced significantly for users with default content
- Various typos in dad jokes

### Technical
- `GetEffectiveContent()` function merges defaults with user changes at runtime with caching
- Content cache automatically invalidates on any content modification
- `SetEffectiveContent()` includes comprehensive type validation and error handling
- `GetRandomContent()` now returns both content and moduleId for prefix handling
- `GetRandomContent()` supports optional `ignoreTriggers` parameter for manual commands
- `GetContentPrefix()` function generates dynamic prefixes with 108 randomized adjectives
- Input sanitization strips WoW formatting codes (colors, hyperlinks, textures, encrypted text)
- Race condition prevention in SendContent using pendingMessage flag
- Math.random properly seeded for better randomness (when available in environment)
- All magic numbers replaced with named constants
- Tooltip handlers reused instead of recreated to prevent memory leaks
- Backward compatibility maintained for legacy functions

## [0.2.0] - 2025-01-XX

### Added
- Configuration panel
- Slash commands

## [0.1.0] - 2025-01-XX

### Added
- Initial release
- Basic dad joke functionality on raid wipes
