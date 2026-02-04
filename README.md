# Tarball's Dadabase

World of Warcraft addon that automatically shares content (dad jokes, demotivational sayings, guild quotes) in party/raid chat based on configurable triggers.

## Features

- **Multiple Content Types:**
  - Dad Jokes - Classic groaners and puns
  - Demotivational Sayings - For when things go wrong
  - Guild Quotes - Your guild's memorable moments
- **Automatic Triggers:**
  - Party/Raid wipes
- **Group Targeting:**
  - Enable separately for raids and parties
- **Customizable Prefixes:**
  - Enable/disable prefixes per module
  - Default prefixes with 40 randomized adjectives for variety
  - Custom prefix support (up to 50 characters)
  - Automatic grammar handling (a/an)
- **Sound Effects:**
  - 15 short, punchy sound effects
  - Optional audio notification when content triggers
- **Statistics Tracking:**
  - Track how many times each module has been used
  - View counts in Settings tab
- **Full Content Management:**
  - Multi-line text editor (one item per line)
  - Add/remove content for each type
  - Import new default content on updates
  - Smart Save and Reset buttons (only enabled when text is edited)
  - Buttons visually contained within editor frame for clarity
  - Automatic message splitting for content over 255 characters
  - Smart word-boundary detection prevents mid-word splits
- **Global Controls:**
  - Master enable/disable toggle
  - Controls gray out when disabled with helpful tooltips
- In-game configuration panel with About, Settings, and content type tabs
- Persistent settings across logins
- Manual commands for guild/say chat (ignore trigger/group settings)
- Modular architecture for easy expansion

## Installation

1. Download the addon files
2. Extract to `World of Warcraft/_retail_/Interface/AddOns/TarballsDadabase/`
3. Restart WoW or reload UI (`/reload`)

## Commands

```
/dadabase                    - Open configuration panel
/dadabase version            - Display addon version
/dadabase on                 - Enable all modules
/dadabase off                - Disable all modules
/dadabase say                - Send content (to party if grouped, raid if in raid, otherwise /say)
/dadabase guild              - Send content to guild chat
/dadabase cooldown <seconds> - Set global cooldown between messages (0-60)
/dadabase status             - Show current settings and module status
/dadabase debug              - Toggle debug mode
```

## Configuration

Access the configuration panel via `/dadabase` or through the WoW Interface Options under Addons.

### About Tab
- Overview of what the addon does
- Instructions for adding custom content
- GitHub repository link
- Thank you message

### Settings Tab
- **Global Enable/Disable:** Master toggle that overrides all module settings
- **Statistics:** View content counts and usage statistics for each module
- **Global Cooldown:** Slider to adjust seconds between messages (0-60)
  - Prevents messages if one was sent within the specified time
- **Sound Effects:** Optional audio notification when content triggers
  - 15 short, punchy sound effects to choose from
  - Test button to preview selected sound

### Content Type Tabs (Dad Jokes, Demotivational, Guild Quotes)
Each content type has its own tab with:

**Warning Banner:**
- Red warning appears at top when addon is globally disabled
- Always visible reminder to enable in Settings tab

**Enable/Disable:**
- Module toggle (always enabled for configuration, even when globally disabled)
- Other controls gray out when disabled
- Disabled modules won't trigger even if global is enabled

**Trigger on wipes in:**
- Raids - Enable for raid groups
- Parties - Enable for party groups

Note: Content automatically triggers on party/raid wipes when the module is enabled and at least one group type is selected.

**Message Prefix:**
- Enable prefix - Toggle prefix on/off
- Use custom prefix - Use your own custom text instead of default
- Custom prefix input - Enter up to 50 characters (press Enter to save)

Default prefixes use randomized adjectives like "And now, for an inspiring dad joke:" while custom prefixes let you personalize the message format.

**Note:** Manual commands (`/dadabase say`, `/dadabase guild`) ignore trigger and group settings and only respect module enabled state.

**Content Editor:**
A visual divider separates auto-saving settings (above) from manual-save content (below).

- Edit all content in a multi-line text editor (one item per line)
- Add custom content or remove any lines
- Save Changes and Reset to Defaults buttons (disabled until text is edited)
- Buttons are contained within the editor frame with a divider for visual clarity
- Long content (over 255 characters) automatically splits across multiple messages with smart word-boundary detection

## Content Database

The addon uses a change-tracking system to manage content efficiently. Default content is stored in the addon code, while only your customizations (additions and deletions) are saved to your SavedVariables. This means:
- New default content automatically appears when you update the addon
- Items you delete stay deleted (won't reappear in updates)
- Custom items you add are preserved across updates
- SavedVariables stays small regardless of content size

**Default Content:**
- Dad Jokes: 100+ classic dad jokes and puns (enabled by default for wipes in raids/parties)
- Demotivational: 30 demotivational sayings (disabled by default)
- Guild Quotes: Empty - populate with your guild's memorable quotes (disabled by default)

**How It Works:**

**Automatic Triggers (wipes):**
1. Checks if addon is globally enabled
2. Checks which content types are enabled
3. Filters by the current group type (raid/party)
4. Combines all matching content into a pool
5. Randomly selects one item to send
6. Adds prefix (default with random adjective or custom)
7. Splits message if over 255 characters (1.5s delay between chunks)
8. Plays sound effect if enabled
9. Increments usage statistics

**Manual Commands (`/dadabase say`, `/dadabase guild`):**
1. Checks if addon is globally enabled
2. Checks which content types are enabled
3. Ignores trigger and group settings
4. Combines all enabled content into a pool
5. Randomly selects one item to send
6. Adds prefix (default with random adjective or custom)
7. Splits message if over 255 characters (1.5s delay between chunks)
8. Increments usage statistics

**Note:** Manual commands have a 3-second rate limit to prevent spam.

## Security & Performance

### Security Features
- **Input Sanitization:** All user-entered content is sanitized to remove WoW formatting codes (colors, hyperlinks, textures, encrypted text)
- **Length Validation:** Content limited to 255 characters (WoW chat message limit)
- **Type Validation:** Comprehensive error handling validates all data types
- **Race Condition Prevention:** Pending message flag prevents concurrent sends

### Performance Optimizations
- **Content Caching:** Effective content cached for each module (critical for 1100+ jokes)
- **Cache Invalidation:** Automatic cache clearing when content is modified
- **Efficient Lookups:** Sets used instead of arrays for deletion checks
- **String Building:** table.concat() used instead of concatenation in loops
- **Random Seeding:** math.random properly seeded for better distribution

## Saved Variables

Settings are stored in `WTF/Account/<account>/SavedVariables/TarballsDadabase.lua`:
- `globalEnabled` - Master enable/disable toggle (default: true)
- `cooldown` - Global seconds between messages (default: 10)
- `soundEnabled` - Sound effects on/off (default: false)
- `soundEffect` - Selected sound effect ID (default: LEVEL_UP)
- `stats` - Usage statistics per module
- `debug` - Debug mode toggle (default: false)
- `modules` - Per-module settings:
  - `enabled` - Module enable/disable
  - `triggers` - (Legacy) Preserved for backward compatibility, no longer used
  - `groups` - Which groups are active (raid, party)
  - `prefixEnabled` - Enable/disable prefix (default: true)
  - `useCustomPrefix` - Use custom prefix instead of default (default: false)
  - `customPrefix` - Custom prefix text (max 50 characters)
  - `userAdditions` - Custom content items you've added
  - `userDeletions` - Default items you've removed
  - `dbVersion` - Database version for tracking updates

## Architecture

The addon uses a modular architecture:
- `Database.lua` - Generic content management for all modules
- `Core.lua` - Event handling, triggers, slash commands
- `Config.lua` - Configuration panel framework
- `Modules/DadJokes.lua` - Dad jokes module
- `Modules/Demotivational.lua` - Demotivational sayings module
- `Modules/GuildQuotes.lua` - Guild quotes module

New content types can be easily added by creating a new module file.

## Version

Current version: 0.4.0
