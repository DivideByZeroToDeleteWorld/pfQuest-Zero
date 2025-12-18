# pfQuest - ZeroMod

**ZeroMod for pfQuest** adds support for LibSharedMedia-3.0 fonts with customizable font sizes, outlines, and enhanced tracker configuration options.

---

## Features

### Enhanced Tracker Configuration

#### **Tracker Max Height**
- Sets the maximum height for the quest tracker frame
- When quest content exceeds this height, the tracker becomes **scrollable**
- Scroll using your **mousewheel** to view all tracked quests
- **No visible scrollbar** - just scroll naturally with your mouse
- The tracker dynamically shrinks when you have fewer quests

#### **Tracker Max Width**
- Sets the maximum width for the quest tracker frame
- Text that exceeds the width will be truncated
- *(Note: Text wrapping is being improved in future updates)*

#### **Font Selection (LibSharedMedia-3.0)**
- Choose from any font registered with LibSharedMedia-3.0
- Applies to all quest titles and objectives in the tracker
- Changes take effect immediately - no reload required
- Includes default WoW fonts plus any custom fonts you've installed

#### **Font Size**
- Customize the font size for all tracker text
- Adjustable to your preferred readability
- Changes apply instantly to all tracked quests

#### **Font Outline**
- Add text outlines for better readability
- Options: None, Outline, Thick Outline
- Helps text stand out against any background

---

## Installation

1. Download or clone this repository
2. Place the `pfQuest-Zero` folder in your `World of Warcraft/Interface/AddOns/` directory
3. Restart World of Warcraft or `/reload` if already running

---

## Requirements

- **pfUI** (or compatible UI framework)
- **LibSharedMedia-3.0** (for custom fonts)
- World of Warcraft 3.3.5 (WotLK)

---

## Configuration

Open the pfQuest configuration panel:
- Type `/pfquest` or `/pq` in chat
- Navigate to the **Tracker** section
- Adjust the settings to your preference

All changes apply immediately!

---

## Credits

Based on [pfQuest](https://github.com/shagu/pfQuest) by Shagu

ZeroMod enhancements by the Chromie community
