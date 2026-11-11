# 🌲 Lumber Empire — Roblox Studio Script

A fully original, server-authoritative Lumber Empire game system written in clean Luau.

---

## 📁 File Structure

```
LumberEmpire/
├── ReplicatedStorage/
│   └── GameConfig.lua          ← Shared constants (costs, upgrades, rebirth rates)
├── ServerScriptService/
│   ├── MainServer.lua          ← Entry point, remote handling
│   ├── DataManager.lua         ← DataStore save/load with auto-retry
│   ├── TreeManager.lua         ← Tree spawning, chopping, respawning
│   └── WorkerManager.lua       ← NPC workers, AI chop loop
└── StarterPlayerScripts/
    └── MainClient.lua          ← Full GUI (tabs, stats, upgrades, rebirth)
```

---

## ✨ Features

| Feature | Details |
|---|---|
| 🌲 Tree System | 8 trees spawn around the map, respawn after 15s when felled |
| 👷 Worker NPCs | Hire up to 10 workers; each auto-chops the nearest tree |
| ⬆️ Upgrades | Chop Speed, Log Value, Worker Speed, Auto Sell (10 levels each) |
| 🔁 Rebirth | Reset for +25% coin multiplier per rebirth (20 max) |
| 💾 Data Saving | Auto-saves every 60s via DataStore + save on leave/server close |
| 🖥️ GUI | Draggable 4-tab UI: Workers / Upgrades / Rebirth / Info |
| ⌨️ Manual Chop | Press **E** near a tree to chop manually |
| 🔄 Anti-AFK | Prevents idle disconnect via VirtualUser |

---

## 🛠 Setup in Roblox Studio

1. Place `GameConfig.lua` in **ReplicatedStorage** as a **ModuleScript**
2. Place `DataManager.lua`, `TreeManager.lua`, `WorkerManager.lua` in **ServerScriptService** as **ModuleScripts**
3. Place `MainServer.lua` in **ServerScriptService** as a **Script**
4. Place `MainClient.lua` in **StarterPlayerScripts** as a **LocalScript**
5. Hit **Play** — the game is ready!

---

## 🔒 Security Notes

- All economy logic runs **server-side only**
- Client requests are validated (proximity check, coin checks, level caps)
- No client-side coin/log manipulation possible
