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
| Knöpfe | Verlauf oben hell → unten satt, weißer Glanz auf der oberen Hälfte, dunkle Unterkante (3D), Hover ×1,06, Klick ×0,96 |
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

- **Oben Mitte:** Schrauben (Schraubenmutter-Symbol) und Zahnräder (erscheint erst, wenn > 0)
- **Links Mitte:** Upgrades, Aufgaben, Forschung. **Rechts Mitte:** Shop, Rebirth, Index
- **Unten links:** Glück-Pille mit gelbem Plus, darüber aktive Tränke
- **Unten Mitte:** großer DROP-Knopf mit Fortschrittsbalken, links davon AUTO; Banner erscheint darüber
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
UI.onDrop = function() end          -- ebenso: onAutoToggle, onUpgradeBuy(id), onAutoUpgrade, onOpen(key)
```

Danach `DEMO = false` setzen.

## Noch offen

- Icons sind Emojis. Eigene Icon-Bilder hochladen und in `ICON_IMAGES` eintragen.
- Shop-, Index-, Rebirth-, Aufgaben- und Forschungsfenster sind Platzhalter im neuen Look.
- Welt und Licht (Himmel, Bloom, Farbkorrektur, Terrain-Farben) folgen als nächster Schritt.
