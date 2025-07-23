# SlyBars

![Screenshot](SlyBars.png)

## What is it?

**SlyBars** is a lightweight and minimalistic energy and combo point tracker addon for **WoW WOTLK 3.3.5a**.

This version is designed for custom 3.3.5a servers that include energy ticks, such as **Endless**, **Warmane's Onyxia**, or **Project Epoch**.

**Features:**
- Energy, combo point, and energy tick tracking
- Auto-hiding when out of combat
- Poison reminders for rogues
- Configurable frame position, size, and visual style

---

## 🔻 How to Install

1. Go to the [Releases](https://github.com/nullfoxh/SlyBars-WOTLK-custom/releases) page.
2. Download `SlyBars.zip`.
3. Extract the contents to your `World of Warcraft/Interface/AddOns` folder.

The final path should look like:

`World of Warcraft/Interface/AddOns/SlyBars/SlyBars.toc`

---

## 🛠️ How to Configure SlyBars

Type **`/sb`** or **`/slybars`** in the chat while in-game to enter config mode or run a command.

---

### 🔧 Basic Commands

| Command | Description |
|--------|-------------|
| **`/sb config`** | Enable/disable config mode |
| **`/sb reset`** | Reset all settings to default |
| **`/sb xpos <number>`** | Set horizontal position offset |
| **`/sb ypos <number>`** | Set vertical position offset |
| **`/sb width <number>`** | Set frame width |
| **`/sb comboheight <number>`** | Set combo point bar height |
| **`/sb energyheight <number>`** | Set energy bar height |
| **`/sb fontsize <number>`** | Set energy text font size |
| **`/sb text`** | Toggle energy text on/off |
| **`/sb spark`** | Toggle energy tick spark |
| **`/sb smooth`** | Toggle bar smoothing animation |
| **`/sb fade`** | Toggle fading when no target exists |
| **`/sb fadein <number>`** | Set fade-in duration (in seconds) |
| **`/sb fadeout <number>`** | Set fade-out duration (in seconds) |
| **`/sb reminder`** | Toggle poison reminder |
| **`/sb ignoremh`** | Toggle main-hand poison reminder |

---

### 🎛️ Using Mouse Scroll in Config Mode

When **config mode** is active, use your mouse wheel to adjust the frame:

- **Scroll Up/Down** → Move frame left/right  
- **Hold Shift + Scroll** → Move frame up/down  
- **Hold Ctrl + Scroll** → Adjust frame width  
- **Hold Alt + Scroll** → Adjust energy bar height  
- **Hold Ctrl + Alt + Scroll** → Adjust combo point bar height

---

### 💡 Tip

Type **`/sb help`** in-game to view all available commands at any time.

---

## 🙏 Credits & Acknowledgements

- **kuuff** — for bugfix contributions.
