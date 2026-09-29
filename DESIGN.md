# Drop a Bot – Design-Leitfaden (hell & bunt)

Referenz-Stil: knallbunte Cartoon-Welt, fette Icon-Buttons, dicke schwarze Konturen, Verläufe mit Glanz.
Übernommen werden Stilprinzipien, keine fremden Icons, Namen oder Texturen.

## Einbauen (Copy-Paste)

1. Studio öffnen, `StarterPlayer > StarterPlayerScripts` > neues **LocalScript**.
2. Inhalt von `src/StarterPlayerScripts/DropABotUI.client.lua` komplett hineinkopieren.
3. **Play** drücken. Mit `DEMO = true` (Standard) erscheinen Beispielwerte, Klicks gehen ins Leere.
4. Ein altes HUD, das dasselbe zeigt (Schrauben, DROP, Menüs), vorübergehend ausschalten, sonst überlappt es.

## Regeln

| Element | Regel |
|---|---|
| Schrift | `FredokaOne`, weiß, schwarze `UIStroke` 2–4 px |
| Kontur | alle Flächen: schwarz `#0A0A12`, 3–4 px |
| Knöpfe | Verlauf oben hell → unten satt, weißer Glanz oben, dunkle Unterkante (3D), Hover wackelt, Klick quetscht und federt zurück |
| Fenster | Header in Blau mit Glanz und Diagonalstreifen, roter X-Knopf, dunkle Karten |
| Karten | aktiv = grün, gesperrt = anthrazit mit Schloss, Preis gold (bezahlbar) oder grau |
| Meldungen | dunkles Banner mit Diagonalstreifen, Name in Seltenheitsfarbe, Kosmisch = Regenbogen |

## Farben (oben / unten)

| Name | Oben | Unten | Nutzung |
|---|---|---|---|
| Grün | `#9EF454` | `#2EB224` | Upgrades, aktive Karten, AUTO an |
| Blau | `#70D8FF` | `#1C8CE8` | Header, Aufgaben, Index |
| Lila | `#C698FF` | `#6E3ED6` | Forschung, Zahnräder |
| Rot | `#FF7C7C` | `#D62030` | Shop, Schließen |
| Pink | `#FF98D8` | `#DE3E98` | Rebirth |
| Gold | `#FFE45C` | `#FF9614` | DROP, Preise, Schrauben |
| Grau | `#686C7C` | `#3E414E` | nicht bezahlbar, AUTO aus |

Seltenheiten wie im Prototyp: Gewöhnlich `#A3ADC2`, Ungewöhnlich `#4ADE80`, Selten `#38BDF8`, Episch `#A78BFA`,
Legendär `#FBBF24`, Mythisch `#FB4B6E`, Göttlich `#FFF1A8`, Kosmisch Regenbogen.

## Layout (Basis 900 px Höhe, skaliert automatisch)

- **Oben Mitte:** Schrauben (Haufen aus drei Goldschrauben, darunter grün die Rate pro Sekunde) und die lila Schraube (zweite Währung, erscheint erst, wenn > 0)
- **Links Mitte:** Upgrades (grüne Kreispfeile), Aufgaben (Klemmbrett), Forschung (Kolben). **Rechts Mitte:** Shop (roter Korb), Index (blaues Buch), Rebirth (aufspringende Kapsel), Teleport (Joystick)
- **Unten links:** Klee mit "+12%" und kleinem Plus, daneben aktive Boosts (Tränke, Eiswürfel `kind = "eis"`) mit Restzeit darunter
- **Unten Mitte:** roter Druckknopf DROP auf grauer Platte (Beschriftung "DROP" darunter, Fortschrittsbalken ganz unten), links der Rucksack (öffnet das Bots-Fenster), rechts der AUTO-Schalter mit "AUTO / AUS" darunter; Banner erscheint darüber
- **Oben links unter der Roblox-Leiste:** Drop-Feed ("1 in 100K")

## Anbindung ans Spiel (`shared.DropABotUI`)

```lua
local UI = shared.DropABotUI
UI.setSchrauben(1500, 42)            -- Wert, pro Sekunde
UI.setZahnraeder(3, "Rebirth 2")
UI.setLuck(12)
UI.setDropProgress(0.4)
UI.setAuto(true)
UI.setBoosts({ { name = "Glückstrank", seconds = 200, color = Color3.fromRGB(74, 222, 128) } })
UI.setUpgrades({ { id = "kerne", name = "Mehr Kerne", emoji = "⚪", level = 2, valueText = "3 Kerne", cost = 210, state = "active" } })
UI.banner({ emoji = "🤖", name = "Nerd", text = "hat einen Samurai-Mech gebaut!", color = Color3.fromRGB(251, 75, 110) })
UI.feed({ player = "Nerd", userId = 1234, rarity = "Kosmisch", bot = "Prototyp Null", oneIn = 100000 })
UI.popup("+52")                     -- Zahl steigt über dem DROP-Knopf auf
UI.onDrop = function() end          -- ebenso: onAutoToggle, onUpgradeBuy(id), onAutoUpgrade, onOpen(key)
```

Danach `DEMO = false` setzen.

## Glänzende Knöpfe (Bild-Atlas)

Alle Knöpfe, Karten und Symbole liegen als **eine** Bilddatei vor: `assets/ui/atlas.png` (1024 x 1024).
Ohne dieses Bild zeichnet das Skript die Knöpfe selbst (schlichter). Mit Bild sehen sie aus wie Spiel-Grafik:
freistehende 3D-Icons ohne Platte, Beschriftung mit dicker Kontur darüber.

1. Studio: **Ansicht › Asset-Manager**, Bereich **Bilder** › **Massen-Import** › `atlas.png` wählen.
2. Nach dem Import Rechtsklick auf das Bild › **Asset-ID kopieren**.
3. Im LocalScript oben `local ATLAS_ID = "123456789"` (die kopierte Zahl) eintragen.
4. Play. Falls die Knöpfe weiß bleiben, ist das Bild noch in der Prüfung oder die ID falsch.

Die Bilder werden von `tools/make_ui_atlas.py` erzeugt. Die großen Buttons und Währungs-Symbole sind **deine fertigen Bilder**
(`assets/ui/buttons/*.png`, freigestellt aus den JPGs von `Buttons.zip` mit `python3 tools/import_buttons.py <Ordner>`):
Upgrade, Aufgaben, Forschung, Shop, Index, Rebirth, Teleport, Backpack, Drop, Schrauben gelb/lila (Haufen und einzeln), Luck.
Platten sind Vektorgrafik, Eiswürfel, Tränke, Schloss, Stern, Hand und AUTO-Schalter sind 3D-Modelle (three.js, `tools/render3d`,
Kontur in `tools/icons3d.py`; einmalig `cd tools/render3d && npm install`). Ein Button-Bild austauschen: neue Datei in
`assets/ui/buttons/` mit gleichem Namen ablegen. Größen lassen sich in `BUTTONS` und `ICONS3D` ändern: `python3 tools/make_ui_atlas.py` erzeugt `atlas.png` und `atlas_rects.lua` neu.
Die Plätze im Bild werden automatisch gesucht. Danach den Block `local SPR = { ... }` im Skript durch den Inhalt von `atlas_rects.lua` ersetzen.

### Bot-Bilder (optional)

`assets/ui/atlas_bots.png` enthält alle 24 3D-Bots (drei pro Seltenheit, wie im Prototyp) und 12 Upgrade-Symbole
(`up_kerne`, `up_tempo`, ... werden in den Upgrade-Karten automatisch über die Upgrade-ID gewählt). Genauso hochladen und oben
`local BOT_ATLAS_ID = "..."` eintragen. Sie erscheinen im Index, im neuen **Bots-Fenster** (Teleport › Bots) und im
Banner (`UI.banner({ bot = "bot_samurai", ... })`). Für eigene Stellen: `shared.DropABotUI.botSprite(parent, "bot_katze", { sz = UDim2.fromOffset(96, 96) })`.
Weitere Bots: Modell in `tools/render3d/icons.html` ergänzen und in `BOTS` (`tools/make_ui_atlas.py`) eintragen.

## Farbe der Icons

Die 3D-Icons werden bewusst nicht zu hell gerendert: Mitteltöne abgedunkelt (`GAMMA`), Farben satt (`SAT`), dicke dunkle Kontur
(`OUTLINE`). Regler oben in `tools/icons3d.py`.

## Größe

`UI_SCALE` oben im Skript (Standard 1.15) macht die ganze Oberfläche größer oder kleiner. DROP und AUTO behalten
ihre Größe (`k()` rechnet sie um). Alles andere wächst mit.

## Animationen

- Darüberfahren: Knopf wächst leicht und wackelt kurz.
- Drücken: Knopf wird gequetscht, beim Loslassen federt er elastisch zurück.
- Klick: Ring und Funken. Kauf: zusätzlich Kauf-Geräusch. DROP: Zahl steigt auf (`UI.popup`).
- AUTO: kleiner 3D-Kippschalter. Aus = dunkel, weißer Knopf links, Beschriftung "AUTO / AUS". An = grün, Knopf rechts, "AUTO / AN".
- DROP: roter Druckknopf auf grauer Metallplatte (Vorbild: dein Referenzbild). Ältere Entwürfe bleiben in `tools/render3d/icons.html`: Würfel (`drop_cube`), Trichter (`drop_c`), Kristall (`drop_d`), Arcade (`drop_arcade`).
- Klick-Sound aller Knöpfe: eigene Audio-ID `139719503904449` (`SOUND_IDS.click`). Lädt sie nicht, nimmt das Skript automatisch den weichen Ersatzton und schreibt eine Zeile in den Output.
- Geräusche: leise und sanft. Eigene Töne: `assets/audio/click.wav` und `buy.wav` in Studio hochladen (Asset-Manager › Audio) und die IDs in `SOUND_IDS` eintragen. Ohne eigene IDs nimmt das Skript weiche Töne, die in Roblox eingebaut sind, und wählt nur, was wirklich lädt.

## Welt und Licht (WorldLook)

`src/ServerScriptService/WorldLook.server.lua` als **Script** in `ServerScriptService` einfügen. Es setzt beim Start warmes
Tageslicht, blauen Dunst, Bloom, kräftigere Farben, Cartoon-Farben für Terrain und Baseplate und stellt Deko
(Bäume, Felsen, Pilze, Blumen) rund um die Mitte. `DEKO = false` schaltet die Deko ab.
Für die schönsten Schatten in Studio: `Lighting > Technology` auf `Future` stellen.

## Fenster

Aufgaben, Forschung, Shop, Index und Rebirth haben jetzt eigene Layouts mit Beispieldaten
(Listen mit Fortschrittsbalken, Preis-Buttons, Rebirth-Fortschritt). Befüllen über
`UI.setRows("aufgaben", rows)`, `UI.onRowAction = function(fenster, id) end`, `UI.onRebirth = function() end`.

## Noch offen

- Die Werte in den Fenstern (Aufgaben, Forschung, Shop-Preise für Tränke) sind Beispiele.
- Eigene Welt-Modelle (Insel, Wege, Brett-Optik) folgen; bisher gibt es nur Licht, Farben und Deko.
