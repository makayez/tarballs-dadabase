# Changelog

All notable changes to Tarball's Dadabase will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- Multi-line text editor for content management (one item per line)
- Save Changes button with visual feedback in configuration UI
- Reset to Defaults button to clear all user customizations
- Dynamic prefixes for all content types with 49 randomized adjectives
  - Dad Jokes: "And now, for a [adjective] dad joke: "
  - Demotivational: "And now, for a [adjective] motivational quote: "
  - Guild Quotes: "And now, for some [adjective] famous words from a friend: "
- Automatic grammar handling (a/an) based on adjective
- 32 additional demotivational sayings
- Migration system for existing SavedVariables data

### Changed
- Content storage system now tracks only user changes (additions/deletions) instead of full content arrays
- Default content is now stored in addon code rather than SavedVariables
- Configuration UI replaced scrollable list with individual delete buttons with a text editor
- SavedVariables structure now uses `userAdditions` and `userDeletions` arrays
- README updated to reflect new change-tracking system

### Fixed
- Content management now handles large datasets (1000+ items) efficiently
- New default content in updates automatically appears without restoring deleted items
- SavedVariables file size reduced significantly for users with default content

### Technical
- `GetEffectiveContent()` function merges defaults with user changes at runtime
- `SetEffectiveContent()` function diffs editor content to determine additions/deletions
- `GetRandomContent()` now returns both content and moduleId for prefix handling
- `GetContentPrefix()` function generates dynamic prefixes with randomized adjectives
- Backward compatibility maintained for legacy functions

## [0.3.0] - 2025-01-XX

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
