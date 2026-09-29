# Drop a Bot – Roblox

Ein Plinko-Idle-Spiel: Kerne fallen durch ein Glücksbrett, aus Bauteilen entstehen Bots (Verteidiger und Arbeiter).

## Ordner

| Ordner | Inhalt |
|---|---|
| `src/StarterPlayerScripts/DropABotUI.client.lua` | Komplettes HUD und alle Menüs (nur Optik, mit Demo-Modus und API) |
| `src/ServerScriptService/WorldLook.server.lua` | Licht, Himmel, Farben und Deko der Welt |
| `assets/ui/atlas.png` | Bilddatei mit allen Buttons, Karten und 3D-Icons (einmal in Studio hochladen) |
| `tools/` | Zeichnet und rendert die Bilder neu (`make_ui_atlas.py`, `icons3d.py`, `render3d/`) |
| `DESIGN.md` | Stil, Farben, Einbauen, Anbindung ans Spiel |

Einbauen und Anbindung stehen in `DESIGN.md`.
