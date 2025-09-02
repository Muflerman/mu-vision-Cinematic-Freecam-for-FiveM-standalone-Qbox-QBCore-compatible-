# mu-vision-Cinematic-Freecam-for-FiveM-standalone-Qbox-QBCore-compatible-
Toggle a cinematic freecam with F9 in FiveM: move with arrow keys, rotate with the mouse, zoom with the scroll wheel. HUD/minimap is hidden per-frame while active, and your ped stays frozen (no collision, invincible) until you exit.



# mu-vision — Cinematic Freecam for FiveM (standalone, Qbox/QBCore compatible)

Toggle a **cinematic freecam** with **F9**. Move the camera with **arrow keys**, rotate with the **mouse**, and **zoom** using the mouse wheel — all while your ped stays frozen safely in place. The HUD/minimap is hidden **per frame** only while active, so your global radar/HUD settings are not modified. Works standalone and is compatible with **Qbox/QBCore/ESX** (client-only).

---

## ✨ Features
- **F9** toggle (also `/muvision` command via KeyMapping).
- **Arrow keys** for movement:
  - **Left/Right** → strafe left/right
  - **Up/Down** → move forward/back
- **Mouse** to rotate the camera.
- **Scroll Wheel** to zoom (adjusts FOV within configurable range).
- **Space** to move up; **CTRL** to move down / go slow; **SHIFT** to move fast.
- HUD/minimap hidden only while freecam is active (`HideHudAndRadarThisFrame`).
- Ped is **frozen**, **no collision**, and **invincible** while active; state is restored on exit.
- No server-side scripts or dependencies; **standalone** and framework-agnostic.

---

## 📦 Installation
1. Drop the `mu-vision` folder into your server `resources/` directory.
2. Add the resource to your `server.cfg`:
   ```cfg
   ensure mu-vision
   ```
3. (Optional) Adjust settings in `config.lua` (speed, sensitivity, FOV, HUD, combat lock).

> **Note:** The resource is client-only and does not depend on Qbox/QBCore/ESX, but it is tested to work alongside them.

---

## 🎮 Controls
| Action | Key |
|---|---|
| Toggle Freecam | **F9** (or `/muvision`) |
| Move Forward / Back | **Arrow Up / Arrow Down** |
| Strafe Left / Right | **Arrow Left / Arrow Right** |
| Move Up | **Space** |
| Move Down / Slow Modifier | **CTRL** |
| Fast Modifier | **SHIFT** |
| Rotate | **Mouse** |
| Zoom (FOV) | **Mouse Wheel** |

> The HUD/minimap is hidden only while freecam is on, so your normal UI returns untouched when you exit.

---

## ⚙️ Configuration (`config.lua`)
```lua
Config = {}

-- Movement speed (m/s). Hold SHIFT to multiply, CTRL to slow.
Config.BaseSpeed = 6.0
Config.FastMultiplier = 4.0
Config.SlowMultiplier = 0.25

-- Mouse sensitivity for rotation (higher = faster)
Config.MouseSensitivity = 6.0

-- Camera FOV limits (zoom)
Config.MinFov = 15.0
Config.MaxFov = 90.0
Config.FovStep = 2.0

-- Hide HUD/radar while freecam is active
Config.HideHud = true

-- Disable combat controls while active (recommended)
Config.DisableCombat = true
```

---

## 🧠 How it works
- When you press **F9**, the script creates a scripted camera at your current view.
- Your **ped is frozen** and collisions are disabled to prevent unintended movement.
- While active, the script hides the HUD **every frame** and reads your inputs to move/rotate the camera.
- On exit, the camera is destroyed and your ped/camera state is restored, including position and heading.

---

## 🛠️ Files
- `fxmanifest.lua` — resource manifest
- `config.lua` — tweak speeds, sensitivity, FOV, HUD/combat options
- `client/main.lua` — client-only freecam logic
- `README.md` — this document

---

## ❓ FAQ / Troubleshooting
**The minimap pops up when I start freecam.**  
The resource no longer forces the radar on/off. Instead, it uses `HideHudAndRadarThisFrame()` while active. If you use other UI scripts, ensure they don’t force the radar each frame.

**I want different keys (e.g., WASD or PgUp/PgDn).**  
Tell me which keys you prefer and I’ll map them for you. The default is arrow keys for movement, Space/CTRL/SHIFT for vertical/slow/fast.

**Does it work without any framework?**  
Yes. It’s standalone and client-only. It simply coexists with Qbox/QBCore/ESX.

---

## 📜 License
MIT (or your preferred license).

---

## 🙌 Credits
Created for **alex (@nosovkboserovmp)**. Enjoy your cinematic shots! 🎬
