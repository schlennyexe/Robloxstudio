--[[
	Drop a Bot – UI-Design v1  (nur Optik, keine Spiellogik)

	EINFÜGEN
	  Studio > StarterPlayer > StarterPlayerScripts > neues LocalScript > diesen Text hineinkopieren.
	  Play drücken: das komplette HUD baut sich zur Laufzeit auf.
	  DEMO = true zeigt Beispielwerte, damit du den Look sofort siehst.

	SPÄTER AN DAS SPIEL ANBINDEN
	  Alles läuft über shared.DropABotUI (API ganz unten): setSchrauben, setUpgrades, banner, feed ...
	  Dann DEMO = false setzen.

	Stil: knallbunt, dicke schwarze Konturen, Verläufe mit Glanz, fette runde Schrift (FredokaOne).
	Icons sind vorerst Emojis. Eigene Icons: ICON_IMAGES unten mit rbxassetid befüllen.
]]

local DEMO = true

-- Eigene Icon-Bilder (optional). Beispiel: ICON_IMAGES.shop = "rbxassetid://123456"
local ICON_IMAGES = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =====================================================================
--  THEME
-- =====================================================================
local FONT = Enum.Font.FredokaOne
local AX = Enum.TextXAlignment

local C = {
	ink = Color3.fromRGB(10, 10, 18),
	white = Color3.fromRGB(255, 255, 255),
	plate = Color3.fromRGB(30, 32, 40),
	soft = Color3.fromRGB(214, 220, 238),
}

-- Farbpaare { oben, unten } für Verläufe
local P = {
	green = { Color3.fromRGB(158, 244, 84), Color3.fromRGB(46, 178, 36) },
	blue = { Color3.fromRGB(112, 216, 255), Color3.fromRGB(28, 140, 232) },
	purple = { Color3.fromRGB(198, 152, 255), Color3.fromRGB(110, 62, 214) },
	red = { Color3.fromRGB(255, 124, 124), Color3.fromRGB(214, 32, 48) },
	pink = { Color3.fromRGB(255, 152, 216), Color3.fromRGB(222, 62, 152) },
	gold = { Color3.fromRGB(255, 228, 92), Color3.fromRGB(255, 150, 20) },
	gray = { Color3.fromRGB(104, 108, 124), Color3.fromRGB(62, 65, 78) },
	dark = { Color3.fromRGB(70, 73, 86), Color3.fromRGB(40, 42, 52) },
	plate = { Color3.fromRGB(54, 57, 70), Color3.fromRGB(28, 30, 38) },
}

-- Seltenheiten wie im Prototyp
local RARITY = {
	{ name = "Gewöhnlich", color = Color3.fromRGB(163, 173, 194) },
	{ name = "Ungewöhnlich", color = Color3.fromRGB(74, 222, 128) },
	{ name = "Selten", color = Color3.fromRGB(56, 189, 248) },
	{ name = "Episch", color = Color3.fromRGB(167, 139, 250) },
	{ name = "Legendär", color = Color3.fromRGB(251, 191, 36) },
	{ name = "Mythisch", color = Color3.fromRGB(251, 75, 110) },
	{ name = "Göttlich", color = Color3.fromRGB(255, 241, 168) },
	{ name = "Kosmisch", color = Color3.fromRGB(232, 121, 249), rainbow = true },
}

-- =====================================================================
--  HELFER
-- =====================================================================
local SUFFIX = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }
local function fmt(n)
	if n ~= n then
		return "0"
	end
	if n < 1000 then
		return tostring(math.floor(n))
	end
	local i = 1
	while n >= 1000 and i < #SUFFIX do
		n /= 1000
		i += 1
	end
	local s
	if n < 10 then
		s = string.format("%.2f", n)
	elseif n < 100 then
		s = string.format("%.1f", n)
	else
		s = tostring(math.floor(n))
	end
	s = (s:gsub("%.", ","))
	return s .. SUFFIX[i]
end

local function darker(c, f)
	return Color3.new(c.R * f, c.G * f, c.B * f)
end

local function make(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do
		o[k] = v
	end
	o.Parent = parent
	return o
end

local function round(o, r)
	return make("UICorner", { CornerRadius = UDim.new(0, r) }, o)
end

local function outline(o, thickness, color, mode)
	return make("UIStroke", {
		Thickness = thickness or 3,
		Color = color or C.ink,
		ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Contextual,
		LineJoinMode = Enum.LineJoinMode.Round,
	}, o)
end

local function vgrad(o, pair)
	return make("UIGradient", { Color = ColorSequence.new(pair[1], pair[2]), Rotation = 90 }, o)
end

-- Text mit dicker Kontur. o: color, ax, sz, pos, anchor, z, stroke, wrap, name
local function text(parent, str, size, o)
	o = o or {}
	local l = make("TextLabel", {
		Name = o.name or "Text",
		BackgroundTransparency = 1,
		Font = FONT,
		Text = str,
		TextSize = size,
		TextColor3 = o.color or C.white,
		TextXAlignment = o.ax or AX.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = o.wrap or false,
		Size = o.sz or UDim2.fromScale(1, 1),
		Position = o.pos or UDim2.new(),
		AnchorPoint = o.anchor or Vector2.zero,
		ZIndex = o.z or 3,
	}, parent)
	if o.stroke ~= 0 then
		outline(l, o.stroke or 3)
	end
	return l
end

-- Emoji ohne Kontur
local function glyph(parent, ch, size, o)
	o = o or {}
	return make("TextLabel", {
		Name = "Glyph",
		BackgroundTransparency = 1,
		Font = FONT,
		Text = ch,
		TextSize = size,
		TextColor3 = C.white,
		Size = o.sz or UDim2.fromScale(1, 1),
		Position = o.pos or UDim2.new(),
		AnchorPoint = o.anchor or Vector2.zero,
		ZIndex = o.z or 3,
	}, parent)
end

-- Text passt sich der Box an (für Zahlen und lange Namen)
local function fit(l, maxSize)
	l.TextScaled = true
	make("UITextSizeConstraint", { MaxTextSize = maxSize }, l)
end

-- weißer Glanz auf der oberen Hälfte
local function gloss(parent, radius, strength)
	local g = make("Frame", {
		Name = "Gloss",
		BackgroundColor3 = C.white,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 4, 0, 3),
		Size = UDim2.new(1, -8, 0.48, 0),
		ZIndex = 2,
	}, parent)
	round(g, math.max(2, radius - 3))
	make("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, strength or 0.55),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, g)
	return g
end

-- Diagonalstreifen (Header, Banner)
local function stripes(parent, w, h, color, alpha, pitch, thick, angle)
	local holder = make("Frame", {
		Name = "Stripes",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
		ZIndex = 1,
	}, parent)
	local span = w + h
	for i = 0, math.ceil(span / pitch) + 1 do
		make("Frame", {
			BackgroundColor3 = color,
			BackgroundTransparency = alpha,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(i * pitch - h / 2, h / 2),
			Size = UDim2.fromOffset(thick, span),
			Rotation = angle or 35,
			ZIndex = 1,
		}, holder)
	end
	return holder
end

local function tween(o, t, props, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

-- Regenbogen-Text (Kosmisch)
local rainbows = {}
local rainbowPhase = 0
local function rainbow(parent)
	local g = make("UIGradient", {}, parent)
	table.insert(rainbows, g)
	return g
end

-- Zähler, die weich zum Zielwert laufen
local counters = {}
local function newCounter(label)
	local c = { target = 0, shown = 0, label = label, last = "" }
	table.insert(counters, c)
	return c
end

RunService.Heartbeat:Connect(function(dt)
	for _, c in ipairs(counters) do
		if c.shown ~= c.target then
			c.shown += (c.target - c.shown) * (1 - math.exp(-dt * 9))
			if math.abs(c.target - c.shown) < 0.5 then
				c.shown = c.target
			end
		end
		local s = fmt(c.shown)
		if s ~= c.last then
			c.last = s
			c.label.Text = s
		end
	end
	if #rainbows > 0 then
		rainbowPhase = (rainbowPhase + dt * 0.35) % 1
		for i = #rainbows, 1, -1 do
			local g = rainbows[i]
			if not g.Parent then
				table.remove(rainbows, i)
			else
				local kps = {}
				for k = 0, 6 do
					table.insert(kps, ColorSequenceKeypoint.new(k / 6, Color3.fromHSV((rainbowPhase + k / 6) % 1, 0.7, 1)))
				end
				g.Color = ColorSequence.new(kps)
			end
		end
	end
end)

-- =====================================================================
--  BAUSTEINE
-- =====================================================================

-- Dicker 3D-Knopf: Schatten-Unterseite + Verlaufs-Oberseite mit Glanz.
-- cfg: Name, Size, Position, AnchorPoint, pal, radius, depth, text, textSize, z, onClick
local function chunky(parent, cfg)
	local depth = cfg.depth or 5
	local r = cfg.radius or 14
	local holder = make("Frame", {
		Name = cfg.Name or "Button",
		BackgroundTransparency = 1,
		Size = cfg.Size,
		Position = cfg.Position or UDim2.new(),
		AnchorPoint = cfg.AnchorPoint or Vector2.zero,
		LayoutOrder = cfg.LayoutOrder or 0,
		ZIndex = cfg.z or 1,
	}, parent)
	local sc = make("UIScale", {}, holder)
	local base = make("Frame", {
		Name = "Base",
		BackgroundColor3 = darker(cfg.pal[2], 0.5),
		Position = UDim2.new(0, 0, 0, depth),
		Size = UDim2.new(1, 0, 1, -depth),
		ZIndex = 1,
	}, holder)
	round(base, r)
	outline(base, 3)
	local face = make("TextButton", {
		Name = "Face",
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = C.white,
		Size = UDim2.new(1, 0, 1, -depth),
		ZIndex = 2,
	}, holder)
	round(face, r)
	outline(face, 3, C.ink, Enum.ApplyStrokeMode.Border)
	local grad = vgrad(face, cfg.pal)
	gloss(face, r)
	local label
	if cfg.text then
		label = text(face, cfg.text, cfg.textSize or 28, { stroke = cfg.textStroke or 3 })
	end

	face.MouseEnter:Connect(function()
		tween(sc, 0.12, { Scale = 1.06 })
	end)
	face.MouseLeave:Connect(function()
		face.Position = UDim2.new()
		tween(sc, 0.12, { Scale = 1 })
	end)
	face.MouseButton1Down:Connect(function()
		face.Position = UDim2.new(0, 0, 0, depth - 1)
		tween(sc, 0.06, { Scale = 0.96 })
	end)
	face.MouseButton1Up:Connect(function()
		face.Position = UDim2.new()
		tween(sc, 0.1, { Scale = 1.06 })
	end)
	local function shake()
		sc.Scale = 0.88
		tween(sc, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	if cfg.onClick then
		face.Activated:Connect(function()
			cfg.onClick(shake)
		end)
	end

	local function recolor(pal)
		grad.Color = ColorSequence.new(pal[1], pal[2])
		base.BackgroundColor3 = darker(pal[2], 0.5)
	end
	return holder, face, label, recolor
end

-- Schraubenmutter (Sechseck aus drei gedrehten Rechtecken), Währungs-Symbol
local function hexNut(parent, size, fill, edge)
	local holder = make("Frame", {
		Name = "Nut",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		ZIndex = 3,
	}, parent)
	local w, h = size * 0.92, size * 0.92 * 0.866
	for layer = 1, 2 do
		local pad = layer == 1 and math.max(4, size * 0.13) or 0
		for i = 0, 2 do
			local f = make("Frame", {
				BackgroundColor3 = layer == 1 and edge or fill,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(w + pad, h + pad),
				Rotation = i * 60,
				ZIndex = layer,
			}, holder)
			round(f, math.max(2, size * 0.06))
		end
	end
	local hole = make("Frame", {
		BackgroundColor3 = darker(edge, 0.55),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size * 0.36, size * 0.36),
		ZIndex = 3,
	}, holder)
	round(hole, 999)
	local shine = make("Frame", {
		BackgroundColor3 = C.white,
		BackgroundTransparency = 0.35,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.3, 0.24),
		Size = UDim2.fromOffset(size * 0.24, size * 0.12),
		Rotation = -35,
		ZIndex = 4,
	}, holder)
	round(shine, 999)
	return holder
end

local NUT_FILL = Color3.fromRGB(255, 200, 48)
local NUT_EDGE = Color3.fromRGB(150, 84, 0)

-- =====================================================================
--  SCREEN
-- =====================================================================
local old = playerGui:FindFirstChild("DropABotUI")
if old then
	old:Destroy()
end

local gui = make("ScreenGui", {
	Name = "DropABotUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 10,
}, nil)

local root = make("Frame", { Name = "Root", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, gui)
local rootScale = make("UIScale", {}, root)
local function rescale()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
	local s = math.clamp(vp.Y / 900, 0.6, 1.25)
	rootScale.Scale = s
	root.Size = UDim2.fromScale(1 / s, 1 / s)
end
rescale()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
end

local UI: any = {}
UI.state = { money = 0, gears = 0, auto = false }
local windows = {}

-- =====================================================================
--  WÄHRUNG (oben Mitte)
-- =====================================================================
local currencyRow = make("Frame", {
	Name = "Currency",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 14),
	Size = UDim2.fromOffset(0, 60),
	AutomaticSize = Enum.AutomaticSize.X,
}, root)
make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 12),
	SortOrder = Enum.SortOrder.LayoutOrder,
	VerticalAlignment = Enum.VerticalAlignment.Center,
}, currencyRow)

local function currencyPlate(cfg)
	local rim = make("Frame", {
		Name = cfg.name,
		BackgroundColor3 = cfg.rim,
		Size = UDim2.fromOffset(cfg.width, 60),
		LayoutOrder = cfg.order,
	}, currencyRow)
	round(rim, 18)
	outline(rim, 3)
	local bump = make("UIScale", {}, rim)
	local inner = make("Frame", {
		Name = "Inner",
		BackgroundColor3 = C.white,
		Position = UDim2.fromOffset(3, 3),
		Size = UDim2.new(1, -6, 1, -6),
	}, rim)
	round(inner, 15)
	vgrad(inner, P.plate)
	local iconBox = make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(6, 3),
		Size = UDim2.fromOffset(48, 48),
		ZIndex = 3,
	}, inner)
	cfg.icon(iconBox)
	local value = text(inner, "0", 30, {
		name = "Value", ax = AX.Left, sz = UDim2.new(1, -66, 0, 32), pos = UDim2.fromOffset(60, 1),
	})
	fit(value, 30)
	local sub = text(inner, "", 15, {
		name = "Sub", ax = AX.Left, color = cfg.subColor, stroke = 2, sz = UDim2.new(1, -66, 0, 18), pos = UDim2.fromOffset(60, 32),
	})
	return { frame = rim, counter = newCounter(value), sub = sub, bump = bump }
end

local moneyPlate = currencyPlate({
	name = "Schrauben", order = 1, width = 260, rim = P.gold[2], subColor = Color3.fromRGB(255, 230, 150),
	icon = function(p)
		hexNut(p, 44, NUT_FILL, NUT_EDGE)
	end,
})
local gearPlate = currencyPlate({
	name = "Zahnraeder", order = 2, width = 170, rim = P.purple[2], subColor = Color3.fromRGB(226, 208, 255),
	icon = function(p)
		local disc = make("Frame", {
			BackgroundColor3 = C.white, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(44, 44), ZIndex = 3,
		}, p)
		round(disc, 999)
		outline(disc, 3)
		vgrad(disc, P.purple)
		glyph(disc, "⚙️", 28)
	end,
})
gearPlate.frame.Visible = false

-- =====================================================================
--  SEITEN-KNÖPFE
-- =====================================================================
local function column(name, anchorX, posX)
	local col = make("Frame", {
		Name = name,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(anchorX, 0.5),
		Position = UDim2.new(anchorX, posX, 0.5, 0),
		Size = UDim2.fromOffset(124, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, root)
	make("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, col)
	return col
end

local tiles = {}
local function tile(parent, cfg)
	local holder = make("Frame", {
		Name = cfg.key,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(124, 116),
		LayoutOrder = cfg.order,
	}, parent)
	local _, face = chunky(holder, {
		Name = "Btn", Size = UDim2.fromOffset(84, 84), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0),
		pal = cfg.pal, radius = 16, depth = 5,
		onClick = function()
			if UI.onOpen then
				UI.onOpen(cfg.key)
			end
			UI.toggleWindow(cfg.key)
		end,
	})
	local img = ICON_IMAGES[cfg.key]
	if img then
		make("ImageLabel", {
			BackgroundTransparency = 1, Image = img, Size = UDim2.fromScale(0.72, 0.72),
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46), ZIndex = 3,
		}, face)
	else
		glyph(face, cfg.emoji, 46, { pos = UDim2.fromOffset(0, -2) })
	end
	local lbl = text(holder, cfg.label, 20, {
		name = "Label", sz = UDim2.new(1, 0, 0, 24), pos = UDim2.fromOffset(0, 90),
	})
	fit(lbl, 20)
	local badge = make("Frame", {
		Name = "Badge", BackgroundColor3 = C.white, Visible = false, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 36, 0, 4), Size = UDim2.fromOffset(28, 28), ZIndex = 6,
	}, holder)
	round(badge, 999)
	outline(badge, 3)
	vgrad(badge, P.red)
	local badgeText = text(badge, "!", 18, { stroke = 2, z = 7 })
	tiles[cfg.key] = {
		badge = function(v)
			badge.Visible = v ~= nil and v ~= false and v ~= 0
			badgeText.Text = type(v) == "number" and tostring(v) or "!"
		end,
	}
	return holder
end

do
	local left = column("Left", 0, 16)
	local right = column("Right", 1, -16)
	tile(left, { key = "upgrades", label = "UPGRADES", emoji = "⬆️", pal = P.green, order = 1 })
	tile(left, { key = "aufgaben", label = "AUFGABEN", emoji = "📋", pal = P.blue, order = 2 })
	tile(left, { key = "forschung", label = "FORSCHUNG", emoji = "🔬", pal = P.purple, order = 3 })
	tile(right, { key = "shop", label = "SHOP", emoji = "🛒", pal = P.red, order = 1 })
	tile(right, { key = "rebirth", label = "REBIRTH", emoji = "🔄", pal = P.pink, order = 2 })
	tile(right, { key = "index", label = "INDEX", emoji = "📖", pal = P.blue, order = 3 })
end

-- =====================================================================
--  UNTEN LINKS: Glück + Boosts
-- =====================================================================
local luckLabel
do
	local luck = make("Frame", {
		Name = "Luck", BackgroundColor3 = C.white, AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 16, 1, -16), Size = UDim2.fromOffset(260, 56),
	}, root)
	round(luck, 28)
	outline(luck, 3)
	vgrad(luck, P.plate)
	local clover = make("Frame", {
		BackgroundColor3 = C.white, Position = UDim2.fromOffset(5, 5), Size = UDim2.fromOffset(46, 46), ZIndex = 3,
	}, luck)
	round(clover, 999)
	outline(clover, 3)
	vgrad(clover, P.green)
	glyph(clover, "🍀", 28)
	luckLabel = text(luck, "+0% Glück", 24, { ax = AX.Left, sz = UDim2.new(1, -118, 1, 0), pos = UDim2.fromOffset(60, 0) })
	fit(luckLabel, 24)
	chunky(luck, {
		Name = "Plus", Size = UDim2.fromOffset(42, 42), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, -2),
		pal = P.gold, radius = 10, depth = 4, text = "+", textSize = 30, z = 4,
		onClick = function()
			if UI.onOpen then
				UI.onOpen("shop")
			end
			UI.openWindow("shop")
		end,
	})
end

local boostList = make("Frame", {
	Name = "Boosts", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 16, 1, -82), Size = UDim2.fromOffset(260, 0), AutomaticSize = Enum.AutomaticSize.Y,
}, root)
make("UIListLayout", {
	Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom,
}, boostList)

-- =====================================================================
--  UNTEN MITTE: DROP + AUTO
-- =====================================================================
local dropFill, dropHint, autoRecolor
do
	local _, face = chunky(root, {
		Name = "Drop", Size = UDim2.fromOffset(290, 100), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24),
		pal = P.gold, radius = 26, depth = 9,
		onClick = function()
			if UI.onDrop then
				UI.onDrop()
			end
		end,
	})
	local lbl = text(face, "DROP", 50, { sz = UDim2.new(1, 0, 0, 62), pos = UDim2.fromOffset(0, 4), stroke = 4 })
	lbl.TextColor3 = C.white
	local track = make("Frame", {
		Name = "Track", BackgroundColor3 = Color3.fromRGB(120, 52, 0), BackgroundTransparency = 0.35,
		Position = UDim2.new(0.1, 0, 0, 68), Size = UDim2.new(0.8, 0, 0, 12), ZIndex = 3,
	}, face)
	round(track, 999)
	dropFill = make("Frame", {
		Name = "Fill", BackgroundColor3 = C.white, BackgroundTransparency = 0.05, Size = UDim2.fromScale(0, 1), ZIndex = 4,
	}, track)
	round(dropFill, 999)

	local _, aFace, _, recolor = chunky(root, {
		Name = "Auto", Size = UDim2.fromOffset(120, 64), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(0.5, -170, 1, -30),
		pal = P.gray, radius = 16, depth = 6, text = "AUTO", textSize = 26,
		onClick = function()
			UI.setAuto(not UI.state.auto)
			if UI.onAutoToggle then
				UI.onAutoToggle(UI.state.auto)
			end
		end,
	})
	autoRecolor = recolor
	local aState = text(aFace, "AUS", 14, { sz = UDim2.new(1, 0, 0, 16), pos = UDim2.new(0, 0, 1, -22), stroke = 2, name = "State" })
	UI._autoState = aState

	dropHint = glyph(root, "👇", 64, {
		sz = UDim2.fromOffset(80, 80), anchor = Vector2.new(0.5, 1), pos = UDim2.new(0.5, 0, 1, -128),
	})
	dropHint.Visible = false
	TweenService:Create(dropHint, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Position = UDim2.new(0.5, 0, 1, -146),
	}):Play()
end

-- =====================================================================
--  FENSTER (Upgrades, Shop, ...)
-- =====================================================================
local windowLayer = make("Frame", { Name = "Windows", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 10 }, root)

local function makeWindow(cfg)
	local overlay = make("TextButton", {
		Name = cfg.key .. "Overlay", Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false,
	}, windowLayer)
	local win = make("Frame", {
		Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(cfg.width, cfg.height), BackgroundColor3 = C.plate, ClipsDescendants = true, Active = true,
	}, overlay)
	round(win, 18)
	outline(win, 4)
	local sc = make("UIScale", { Scale = 0.85 }, win)

	local head = make("Frame", {
		Name = "Header", BackgroundColor3 = C.white, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 64),
	}, win)
	vgrad(head, cfg.pal)
	stripes(head, cfg.width, 64, C.white, 0.9, 30, 14, 35)
	gloss(head, 12, 0.6)
	local iconBox = make("Frame", {
		BackgroundColor3 = C.white, Position = UDim2.fromOffset(14, 9), Size = UDim2.fromOffset(46, 46), ZIndex = 4,
	}, head)
	round(iconBox, 12)
	outline(iconBox, 3)
	vgrad(iconBox, cfg.iconPal or P.green)
	glyph(iconBox, cfg.emoji, 28)
	text(head, cfg.title, 32, { ax = AX.Left, sz = UDim2.new(1, -150, 1, 0), pos = UDim2.fromOffset(72, 0), z = 4 })

	local isOpen = false
	local closeWin
	chunky(head, {
		Name = "Close", Size = UDim2.fromOffset(60, 46), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, -2),
		pal = P.red, radius = 10, depth = 4, text = "X", textSize = 30, z = 5,
		onClick = function()
			closeWin()
		end,
	})
	make("Frame", { Name = "Line", BackgroundColor3 = C.ink, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 64), Size = UDim2.new(1, 0, 0, 4) }, win)
	local body = make("Frame", {
		Name = "Body", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 68), Size = UDim2.new(1, 0, 1, -68),
	}, win)

	local function openWin()
		if isOpen then
			return
		end
		isOpen = true
		overlay.Visible = true
		overlay.BackgroundTransparency = 1
		sc.Scale = 0.85
		tween(overlay, 0.2, { BackgroundTransparency = 0.45 })
		tween(sc, 0.28, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	closeWin = function()
		if not isOpen then
			return
		end
		isOpen = false
		tween(overlay, 0.15, { BackgroundTransparency = 1 })
		tween(sc, 0.15, { Scale = 0.85 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.17, function()
			if not isOpen then
				overlay.Visible = false
			end
		end)
	end
	overlay.Activated:Connect(closeWin)

	local w = { body = body, open = openWin, close = closeWin, isOpen = function() return isOpen end }
	windows[cfg.key] = w
	return w
end

function UI.openWindow(key)
	for k, w in pairs(windows) do
		if k ~= key then
			w.close()
		end
	end
	if windows[key] then
		windows[key].open()
	end
end

function UI.toggleWindow(key)
	local w = windows[key]
	if not w then
		return
	end
	if w.isOpen() then
		w.close()
	else
		UI.openWindow(key)
	end
end

function UI.closeAll()
	for _, w in pairs(windows) do
		w.close()
	end
end

-- ---------- Upgrade-Fenster ----------
local upScroll, footerMoney, footerIncome
local cardRefs = {}
do
	local w = makeWindow({ key = "upgrades", title = "Verbesserungen", emoji = "⬆️", pal = P.blue, width = 780, height = 500 })
	upScroll = make("ScrollingFrame", {
		Name = "Cards", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(14, 6),
		Size = UDim2.new(1, -28, 1, -92), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 8, ScrollBarImageColor3 = Color3.fromRGB(120, 126, 150), ScrollingDirection = Enum.ScrollingDirection.Y,
	}, w.body)
	make("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 12) }, upScroll)
	make("UIGridLayout", {
		CellSize = UDim2.new(0.5, -6, 0, 92), CellPadding = UDim2.fromOffset(10, 12), SortOrder = Enum.SortOrder.LayoutOrder,
	}, upScroll)

	-- Fußleiste: Geld, Einkommen, Auto-Upgrade
	local foot = make("Frame", {
		Name = "Footer", BackgroundColor3 = C.white, Position = UDim2.new(0, 14, 1, -74), Size = UDim2.new(1, -28, 0, 62),
	}, w.body)
	round(foot, 14)
	outline(foot, 3)
	vgrad(foot, P.plate)
	local nutBox = make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 7), Size = UDim2.fromOffset(44, 44), ZIndex = 3 }, foot)
	hexNut(nutBox, 38, NUT_FILL, NUT_EDGE)
	footerMoney = text(foot, "0", 28, { ax = AX.Left, sz = UDim2.fromOffset(190, 32), pos = UDim2.fromOffset(60, 4) })
	fit(footerMoney, 28)
	footerIncome = text(foot, "", 16, { ax = AX.Left, color = Color3.fromRGB(255, 230, 150), stroke = 2, sz = UDim2.fromOffset(190, 18), pos = UDim2.fromOffset(60, 34) })
	local _, autoFace = chunky(foot, {
		Name = "AutoUpgrade", Size = UDim2.fromOffset(210, 50), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, -2),
		pal = P.gray, radius = 12, depth = 5, z = 4,
		onClick = function()
			if UI.onAutoUpgrade then
				UI.onAutoUpgrade()
			end
		end,
	})
	text(autoFace, "Automatisches Upgrade", 15, { sz = UDim2.new(1, -10, 0, 20), pos = UDim2.fromOffset(5, 3), stroke = 2 })
	text(autoFace, "R$ 199", 16, { sz = UDim2.new(1, -10, 0, 18), pos = UDim2.fromOffset(5, 22), stroke = 2, color = Color3.fromRGB(150, 255, 170) })
end

local function upgradeCard(u)
	local card = make("Frame", { Name = u.id or "Card", BackgroundColor3 = C.white, LayoutOrder = u._order or 0 }, nil)
	round(card, 12)
	outline(card, 3)
	if u.state == "locked" then
		vgrad(card, P.dark)
		glyph(card, "🔒", 40, { sz = UDim2.fromOffset(64, 64), pos = UDim2.new(0, 10, 0.5, 0), anchor = Vector2.new(0, 0.5) })
		text(card, u.lockedText or "Noch gesperrt", 22, {
			ax = AX.Left, sz = UDim2.new(1, -92, 1, 0), pos = UDim2.fromOffset(84, 0), wrap = true, color = C.soft,
		})
		return card
	end
	vgrad(card, u.state == "max" and { Color3.fromRGB(96, 200, 90), Color3.fromRGB(30, 130, 50) } or P.green)
	gloss(card, 12, 0.5)

	local ic = make("Frame", { BackgroundColor3 = C.white, Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(64, 64), ZIndex = 2 }, card)
	round(ic, 12)
	outline(ic, 3)
	vgrad(ic, { Color3.fromRGB(46, 126, 42), Color3.fromRGB(24, 82, 30) })
	glyph(ic, u.emoji or "⭐", 36)

	local badge = make("Frame", {
		BackgroundColor3 = C.white, Position = UDim2.fromOffset(-8, -8), Size = UDim2.fromOffset(44, 44), ZIndex = 5,
	}, card)
	round(badge, 999)
	outline(badge, 3)
	vgrad(badge, { Color3.fromRGB(70, 150, 60), Color3.fromRGB(28, 90, 34) })
	text(badge, u.max and (u.level .. "/" .. u.max) or tostring(u.level), 15, { sz = UDim2.new(1, 0, 0, 20), pos = UDim2.fromOffset(0, 6), stroke = 2, z = 6 })
	text(badge, "Stufe", 10, { sz = UDim2.new(1, 0, 0, 12), pos = UDim2.fromOffset(0, 24), stroke = 2, z = 6 })

	local title = text(card, u.name, 20, { ax = AX.Left, sz = UDim2.new(1, -212, 0, 26), pos = UDim2.fromOffset(88, 8), stroke = 3 })
	fit(title, 20)
	local val = text(card, u.valueText or "", 32, { ax = AX.Left, sz = UDim2.new(1, -212, 0, 44), pos = UDim2.fromOffset(88, 36), stroke = 3 })
	fit(val, 32)

	if u.state == "max" then
		local tag = make("Frame", {
			BackgroundColor3 = C.white, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(108, 46), ZIndex = 3,
		}, card)
		round(tag, 12)
		outline(tag, 3)
		vgrad(tag, P.gold)
		text(tag, "MAX", 26, { stroke = 3 })
		return card
	end

	local _, face, _, recolor = chunky(card, {
		Name = "Buy", Size = UDim2.fromOffset(108, 54), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, -2),
		pal = P.gray, radius = 12, depth = 5, z = 4,
		onClick = function(shake)
			if UI.state.money >= u.cost then
				if UI.onUpgradeBuy then
					UI.onUpgradeBuy(u.id)
				end
			else
				shake()
			end
		end,
	})
	local nutBox = make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(24, 40), ZIndex = 3 }, face)
	hexNut(nutBox, 22, NUT_FILL, NUT_EDGE)
	local price = text(face, fmt(u.cost), 22, { ax = AX.Left, sz = UDim2.new(1, -42, 1, -8), pos = UDim2.fromOffset(36, 0) })
	fit(price, 22)
	cardRefs[u.id] = { cost = u.cost, recolor = recolor }
	return card
end

local function refreshAffordability()
	for _, ref in pairs(cardRefs) do
		ref.recolor(UI.state.money >= ref.cost and P.gold or P.gray)
	end
end

-- ---------- Platzhalter-Fenster ----------
do
	local defs = {
		{ key = "aufgaben", title = "Aufgaben", emoji = "📋", pal = P.green },
		{ key = "forschung", title = "Forschung", emoji = "🔬", pal = P.purple },
		{ key = "shop", title = "Shop", emoji = "🛒", pal = P.red },
		{ key = "rebirth", title = "Rebirth", emoji = "🔄", pal = P.pink },
		{ key = "index", title = "Index", emoji = "📖", pal = P.blue },
	}
	for _, d in ipairs(defs) do
		local w = makeWindow({ key = d.key, title = d.title, emoji = d.emoji, pal = d.pal, iconPal = d.pal, width = 640, height = 420 })
		glyph(w.body, d.emoji, 90, { sz = UDim2.new(1, 0, 0, 110), pos = UDim2.fromOffset(0, 40) })
		text(w.body, "Dieses Fenster bekommt den neuen Look als Nächstes.", 24, {
			sz = UDim2.new(1, -60, 0, 60), pos = UDim2.fromOffset(30, 170), wrap = true, color = C.soft,
		})
	end
end

-- =====================================================================
--  BANNER + DROP-FEED
-- =====================================================================
local banner, bIcon, bGlyph, bName, bText
do
	banner = make("CanvasGroup", {
		Name = "Banner", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -140), Size = UDim2.fromOffset(620, 100),
		BackgroundColor3 = Color3.fromRGB(26, 22, 46), GroupTransparency = 1, Visible = false,
	}, root)
	round(banner, 10)
	outline(banner, 4)
	stripes(banner, 620, 100, Color3.fromRGB(46, 40, 82), 0.25, 26, 12, 35)
	bIcon = make("Frame", { BackgroundColor3 = C.white, Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(72, 72), ZIndex = 3 }, banner)
	round(bIcon, 999)
	outline(bIcon, 4)
	bGlyph = glyph(bIcon, "🤖", 40)
	bName = text(banner, "", 32, { ax = AX.Left, sz = UDim2.new(1, -110, 0, 38), pos = UDim2.fromOffset(100, 10) })
	bText = text(banner, "", 26, { ax = AX.Left, sz = UDim2.new(1, -110, 0, 40), pos = UDim2.fromOffset(100, 48) })
end

local bannerQueue, bannerBusy = {}, false
local function playBanner(cfg)
	bGlyph.Text = cfg.emoji or "⭐"
	local col = cfg.color or P.pink[1]
	bIcon.BackgroundColor3 = col
	bName.Text = cfg.name or ""
	bName.TextColor3 = cfg.rainbow and C.white or col
	for _, ch in ipairs(bName:GetChildren()) do
		if ch:IsA("UIGradient") then
			ch:Destroy()
		end
	end
	if cfg.rainbow then
		rainbow(bName)
	end
	bText.Text = cfg.text or ""
	banner.Position = UDim2.new(0.5, 0, 1, -110)
	banner.GroupTransparency = 1
	banner.Visible = true
	tween(banner, 0.35, { Position = UDim2.new(0.5, 0, 1, -140), GroupTransparency = 0 }, Enum.EasingStyle.Back)
	task.wait(cfg.time or 3.5)
	tween(banner, 0.3, { Position = UDim2.new(0.5, 0, 1, -160), GroupTransparency = 1 })
	task.wait(0.32)
	banner.Visible = false
end

local feedList = make("Frame", {
	Name = "Feed", BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 72), Size = UDim2.fromOffset(360, 0), AutomaticSize = Enum.AutomaticSize.Y,
}, root)
make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, feedList)
local feedCount, feedSlots = 0, {}

-- =====================================================================
--  API
-- =====================================================================
UI.onDrop = nil -- function()
UI.onAutoToggle = nil -- function(an)
UI.onAutoUpgrade = nil -- function()
UI.onUpgradeBuy = nil -- function(id)
UI.onOpen = nil -- function(key)

function UI.setSchrauben(n, proSek)
	local up = n > UI.state.money
	UI.state.money = n
	moneyPlate.counter.target = n
	footerMoney.Text = fmt(n)
	if proSek then
		moneyPlate.sub.Text = "+" .. fmt(proSek) .. "/s"
		footerIncome.Text = "+" .. fmt(proSek) .. " pro Sekunde"
	end
	if up then
		moneyPlate.bump.Scale = 1.06
		tween(moneyPlate.bump, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	refreshAffordability()
end

function UI.setZahnraeder(n, info)
	UI.state.gears = n
	gearPlate.frame.Visible = n > 0
	gearPlate.counter.target = n
	if info then
		gearPlate.sub.Text = info
	end
end

function UI.setLuck(prozent)
	luckLabel.Text = "+" .. fmt(prozent) .. "% Glück"
end

function UI.setDropProgress(p)
	tween(dropFill, 0.08, { Size = UDim2.fromScale(math.clamp(p, 0, 1), 1) })
end

function UI.setAuto(on)
	UI.state.auto = on
	autoRecolor(on and P.green or P.gray)
	UI._autoState.Text = on and "AN" or "AUS"
end

function UI.showHint(on)
	dropHint.Visible = on
end

function UI.setBadge(key, v)
	if tiles[key] then
		tiles[key].badge(v)
	end
end

-- list: { { name = "Glück", seconds = 240, color = Color3 }, ... }
function UI.setBoosts(list)
	for _, ch in ipairs(boostList:GetChildren()) do
		if ch:IsA("GuiObject") then
			ch:Destroy()
		end
	end
	for i, b in ipairs(list) do
		local pillFrame = make("Frame", { BackgroundColor3 = C.white, Size = UDim2.fromOffset(200, 34), LayoutOrder = i }, boostList)
		round(pillFrame, 17)
		outline(pillFrame, 3)
		vgrad(pillFrame, P.plate)
		local dot = make("Frame", { BackgroundColor3 = b.color or P.green[1], Position = UDim2.fromOffset(9, 9), Size = UDim2.fromOffset(16, 16), ZIndex = 3 }, pillFrame)
		round(dot, 999)
		outline(dot, 2)
		text(pillFrame, b.name, 17, { ax = AX.Left, sz = UDim2.new(1, -90, 1, 0), pos = UDim2.fromOffset(34, 0), stroke = 2 })
		text(pillFrame, string.format("%d:%02d", math.floor(b.seconds / 60), b.seconds % 60), 17, {
			ax = AX.Right, sz = UDim2.fromOffset(60, 34), pos = UDim2.new(1, -10, 0, 0), anchor = Vector2.new(1, 0), stroke = 2, color = Color3.fromRGB(255, 230, 150),
		})
	end
end

-- list: { { id, name, emoji, level, max, valueText, cost, state = "active"|"max"|"locked", lockedText } }
function UI.setUpgrades(list)
	cardRefs = {}
	for _, ch in ipairs(upScroll:GetChildren()) do
		if ch:IsA("GuiObject") then
			ch:Destroy()
		end
	end
	for i, u in ipairs(list) do
		u._order = i
		upgradeCard(u).Parent = upScroll
	end
	refreshAffordability()
end

-- cfg: { emoji, name, text, color, rainbow, time }
function UI.banner(cfg)
	table.insert(bannerQueue, cfg)
	if bannerBusy then
		return
	end
	bannerBusy = true
	task.spawn(function()
		while #bannerQueue > 0 do
			playBanner(table.remove(bannerQueue, 1))
		end
		bannerBusy = false
	end)
end

-- cfg: { player, userId, rarity = "Kosmisch" (Index 1-8 oder Name), bot, oneIn }
function UI.feed(cfg)
	local rar = RARITY[1]
	for i, r in ipairs(RARITY) do
		if r.name == cfg.rarity or i == cfg.rarity then
			rar = r
		end
	end
	feedCount += 1
	local slot = make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(360, 68), LayoutOrder = feedCount }, feedList)
	local plate = make("CanvasGroup", {
		Name = "Plate", BackgroundColor3 = C.white, Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(-400, 0),
	}, slot)
	round(plate, 10)
	outline(plate, 3)
	vgrad(plate, { Color3.fromRGB(78, 80, 94), Color3.fromRGB(32, 34, 44) })
	stripes(plate, 360, 68, C.white, 0.94, 22, 8, 35)

	local av = make("Frame", { BackgroundColor3 = rar.color, Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(52, 52), ZIndex = 3 }, plate)
	round(av, 999)
	outline(av, 3)
	if cfg.userId then
		make("ImageLabel", {
			BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 4,
			Image = "rbxthumb://type=AvatarHeadShot&id=" .. cfg.userId .. "&w=150&h=150",
		}, av)
		round(av, 999)
	else
		text(av, string.upper(string.sub(cfg.player or "?", 1, 1)), 28, { stroke = 3 })
	end

	text(plate, (cfg.player or "?") .. " hat", 14, { ax = AX.Left, sz = UDim2.new(1, -180, 0, 16), pos = UDim2.fromOffset(70, 6), stroke = 2, color = C.soft })
	local name = text(plate, rar.name .. " " .. (cfg.bot or ""), 22, { ax = AX.Left, sz = UDim2.new(1, -180, 0, 28), pos = UDim2.fromOffset(70, 24), stroke = 3, color = rar.rainbow and C.white or rar.color })
	fit(name, 22)
	if rar.rainbow then
		rainbow(name)
	end
	text(plate, "1 in", 14, { ax = AX.Right, sz = UDim2.fromOffset(100, 16), pos = UDim2.new(1, -10, 0, 6), anchor = Vector2.new(1, 0), stroke = 2, color = C.soft })
	local one = text(plate, fmt(cfg.oneIn or 1), 28, { ax = AX.Right, sz = UDim2.fromOffset(104, 34), pos = UDim2.new(1, -10, 0, 22), anchor = Vector2.new(1, 0), stroke = 3 })
	fit(one, 28)

	tween(plate, 0.4, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
	table.insert(feedSlots, slot)
	local function remove()
		local i = table.find(feedSlots, slot)
		if not i then
			return
		end
		table.remove(feedSlots, i)
		tween(plate, 0.3, { Position = UDim2.fromOffset(-400, 0), GroupTransparency = 1 })
		task.delay(0.35, function()
			slot:Destroy()
		end)
	end
	while #feedSlots > 3 do
		local oldest = feedSlots[1]
		table.remove(feedSlots, 1)
		oldest:Destroy()
	end
	task.delay(cfg.time or 7, remove)
end

shared.DropABotUI = UI
gui.Parent = playerGui

-- =====================================================================
--  DEMO (nur Optik ansehen; DEMO = false setzen, sobald das Spiel die API nutzt)
-- =====================================================================
if DEMO then
	local money, gears = 1250, 12
	local demoUp = {
		{ id = "kerne", name = "Mehr Kerne", emoji = "⚪", level = 2, valueText = "3 Kerne", cost = 210, state = "active" },
		{ id = "tempo", name = "Schnellerer Drop", emoji = "⚡", level = 5, max = 26, valueText = "0,63 s", cost = 2060, state = "active" },
		{ id = "glueck", name = "Kern-Glück", emoji = "🍀", level = 0, valueText = "+0 %", cost = 80, state = "active" },
		{ id = "reihen", name = "Mehr Reihen", emoji = "📌", level = 1, valueText = "10 Reihen", cost = 8000, state = "active" },
		{ id = "plaetze", name = "Werkstatt-Platz", emoji = "🏭", level = 1, valueText = "4 Plätze", cost = 180, state = "active" },
		{ id = "sockel", name = "Brett-Sockel", emoji = "🧱", level = 7, max = 7, valueText = "Stufe 7", cost = 0, state = "max" },
		{ state = "locked", lockedText = "4 weitere Upgrades" },
		{ state = "locked", lockedText = "9 weitere Upgrades" },
	}
	local function money_(n)
		money = n
		UI.setSchrauben(money, 37)
	end
	UI.setUpgrades(demoUp)
	money_(money)
	UI.setZahnraeder(gears, "Rebirth 1")
	UI.setLuck(12)
	UI.setAuto(false)
	UI.setBadge("aufgaben", 2)
	UI.setBadge("shop", true)
	UI.setBoosts({
		{ name = "Glückstrank", seconds = 214, color = P.green[1] },
		{ name = "Geld ×2", seconds = 96, color = P.gold[1] },
	})
	UI.showHint(true)

	UI.onDrop = function()
		UI.showHint(false)
		money_(money + math.random(20, 90))
		UI.setDropProgress(0)
		task.spawn(function()
			for i = 1, 10 do
				task.wait(0.06)
				UI.setDropProgress(i / 10)
			end
		end)
	end
	UI.onAutoToggle = function() end
	UI.onUpgradeBuy = function(id)
		for _, u in ipairs(demoUp) do
			if u.id == id and u.state == "active" then
				money_(money - u.cost)
				u.level += 1
				u.cost = math.floor(u.cost * 2.2)
				UI.setUpgrades(demoUp)
			end
		end
	end

	task.spawn(function()
		while gui.Parent do
			task.wait(1)
			money_(money + 37)
		end
	end)
	task.delay(1.5, function()
		UI.banner({ emoji = "🤖", name = player.DisplayName, text = "hat einen Samurai-Mech gebaut!", color = RARITY[6].color })
	end)
	task.delay(3, function()
		UI.feed({ player = "Nerd", rarity = "Kosmisch", bot = "Prototyp Null", oneIn = 100000 })
	end)
	task.delay(4.5, function()
		UI.feed({ player = "Taffy", rarity = "Göttlich", bot = "Satelliten-Bot", oneIn = 6500 })
	end)
end
