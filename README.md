# pfQuest-Zero

A customized fork of [pfQuest](https://github.com/shagu/pfQuest) for the **Chromie/Zero** WoW private server (WotLK 3.3.5a).

This is not a standalone addon - it's pfQuest with Zero-specific modifications and enhancements.

## Installation

1. Download the latest release zip
2. Extract `pfQuest-Zero` folder to your `Interface\AddOns\` directory
3. (Optional) Install [LibSharedMedia-3.0](https://www.curseforge.com/wow/addons/libsharedmedia-3-0) for additional font options

## ZeroMod Features

### Synastria Perk Tracking
- New tracker mode for viewing active perk tasks
- Shows perk name with rank display `[Rank X]`
- Rank color gradient: red (0) → yellow (5) → green (10)
- Progress percentage and expandable task descriptions
- Requires [SynastriaCoreLib](https://github.com/differ-ence/SynastriaCoreLib) for perk data

### Achievement Tracking
- Track achievements directly in the pfQuest tracker
- Shows completion percentage and expandable criteria
- Shift-click to open Achievement panel
- Auto-refreshes when achievement progress updates

### Enhanced Tracker UI
- **Word wrap** for quest titles and objectives (no more truncation)
- **Quest timers** with gradient progress bar and optional max time display
- **Lock button** to prevent accidental tracker movement
- **Always show background** option
- **Always show config bar** option
- **Collapse timer with objectives** option

### Font Customization
- LibSharedMedia font support (use any installed fonts)
- Configurable font size
- Font style dropdown (OUTLINE, THICKOUTLINE, MONOCHROME, combinations)
- Wider dropdown menus to prevent text truncation

### Subzone Calibration Tools
For fixing coordinate mismatches in custom subzone maps:
- `/db cal begin` - Start calibration mode
- `/db cal <npc>` - Add calibration point at NPC location
- `/db cal done` - Calculate coordinate transform
- `/db cal status` - Show calibration progress

## Compatibility Notes

- **WDM and similar subzone map addons** may cause coordinate issues due to map ID mismatches
- **pfUI** is NOT required (despite original pfQuest notes)
- **LibSharedMedia-3.0** is optional but recommended for font variety

## Configuration

Type `/db config` or click the settings button on the tracker to open configuration.

## Credits

- Original [pfQuest](https://github.com/shagu/pfQuest) by **Shagu**
- Zero modifications by **[Zero]**

## Changelog

### v1.4.3
- Quest titles now word-wrap instead of being truncated
- Applied to all tracker modes (quests, givers, database, perks, achievements)

### v1.4.2
- Fix map position issues when using subzone map addons
- Ensure correct zone context for route/arrow calculations

### v1.4.1
- Add perk rank display with gradient coloring
- Fix perk description placeholder parsing
- Fix stale rank data after perk level-up

### v1.4.0
- Achievement tracking mode with criteria display
- Auto-refresh on achievement progress updates
