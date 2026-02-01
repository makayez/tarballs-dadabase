# Tarball's Dadabase

World of Warcraft addon that automatically tells dad jokes in party/raid chat after wipes.

## Features

- Automatically tells jokes after party/raid wipes
- Configurable cooldown between jokes
- In-game configuration panel
- Custom joke management (add/remove jokes)
- Persistent settings across logins
- Joke database versioning for updates
- Manual joke commands for guild/say chat

## Installation

1. Download the addon files
2. Extract to `World of Warcraft/_retail_/Interface/AddOns/TarballsDadabase/`
3. Restart WoW or reload UI (`/reload`)

## Commands

```
/dadabase                    - Open configuration panel
/dadabase version            - Display addon version
/dadabase on                 - Enable jokes on wipes
/dadabase off                - Disable jokes on wipes
/dadabase joke               - Tell a joke in say chat
/dadabase joke guild         - Tell a joke in guild chat
/dadabase cooldown <seconds> - Set cooldown between jokes (0-60)
/dadabase test               - Display a random joke locally
/dadabase status             - Show current settings
/dadabase debug              - Toggle debug mode
```

## Configuration

Access the configuration panel via `/dadabase` or through the WoW Interface Options under Addons.

### Settings Tab
- Enable/disable automatic jokes on wipes
- Adjust cooldown slider (0-60 seconds)
- View current version

### Jokes Tab
- Browse all jokes in your pool
- Add custom jokes
- Remove jokes (default or custom)

## Joke Database

On first install, all default jokes are copied to your SavedVariables. You have full control to add, remove, or modify jokes. When the addon is updated with new default jokes, only new jokes are added to your collection, preserving your customizations.

## Saved Variables

Settings are stored in `WTF/Account/<account>/SavedVariables/TarballsDadabase.lua`:
- `enabled` - Enable/disable state (default: true)
- `cooldown` - Seconds between jokes (default: 10)
- `jokes` - User's joke pool
- `customJokes` - Tracks which jokes are custom
- `jokeDBVersion` - Database version for updates

## Version

Current version: 0.3.0
