--[[
	Drop a Bot – Welt-Look (Licht, Himmel, Farben, Deko)

	EINFÜGEN
	  Studio > ServerScriptService > neues **Script** (nicht LocalScript) > diesen Text hineinkopieren.
	  Play drücken. Das Skript stellt beim Start ein:
	    - warmes Tageslicht, blauer Dunst, Bloom-Glanz und kräftigere Farben
	    - Gras, Fels, Sand und Wasser in Cartoon-Farben (Terrain)
	    - die Baseplate in hellem Gras-Grün
	    - Deko rund um die Mitte (Bäume, Felsen, Pilze, Blumen), nur zum Testen (DEKO = true)

	Für die schönsten Schatten in Studio: Lighting > Technology auf "Future" stellen (nicht per Skript möglich).
]]

local DEKO = true            -- false = keine Deko bauen
local DEKO_ABSTAND = 34      -- so weit von der Mitte (0,0) fängt die Deko an (Studs)
local DEKO_ANZAHL = 90

local Lighting = game:GetService("Lighting")

-- ---------------------------------------------------------------- Licht
Lighting.ClockTime = 14.3
Lighting.GeographicLatitude = 25
Lighting.Brightness = 2.7
Lighting.ExposureCompensation = 0.1
Lighting.Ambient = Color3.fromRGB(104, 116, 158)
Lighting.OutdoorAmbient = Color3.fromRGB(138, 148, 182)
Lighting.ColorShift_Top = Color3.fromRGB(255, 240, 206)
Lighting.EnvironmentDiffuseScale = 0.7
Lighting.EnvironmentSpecularScale = 0.6
Lighting.GlobalShadows = true
Lighting.ShadowSoftness = 0.3

local function effect(class, name)
	local o = Lighting:FindFirstChild(name)
	if o and o.ClassName ~= class then
		o:Destroy()
		o = nil
	end
	if not o then
		o = Instance.new(class)
		o.Name = name
		o.Parent = Lighting
	end
	return o
end

local atmo = effect("Atmosphere", "DropABotAtmosphere")
atmo.Density = 0.27
atmo.Offset = 0.22
atmo.Color = Color3.fromRGB(190, 226, 255)
atmo.Decay = Color3.fromRGB(255, 214, 186)
atmo.Glare = 0.25
atmo.Haze = 1.1

local sky = effect("Sky", "DropABotSky")
sky.CelestialBodiesShown = true
sky.StarCount = 0

local bloom = effect("BloomEffect", "DropABotBloom")
bloom.Intensity = 0.45
bloom.Size = 26
bloom.Threshold = 0.9

local cc = effect("ColorCorrectionEffect", "DropABotColor")
cc.Saturation = 0.28
cc.Contrast = 0.08
cc.Brightness = 0.01
cc.TintColor = Color3.fromRGB(255, 250, 242)

local rays = effect("SunRaysEffect", "DropABotRays")
rays.Intensity = 0.05
rays.Spread = 0.6

-- ---------------------------------------------------------------- Terrain-Farben
local terrain = workspace.Terrain
terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(104, 214, 58))
terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(196, 132, 76))
terrain:SetMaterialColor(Enum.Material.Mud, Color3.fromRGB(150, 98, 64))
terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(98, 150, 236))
terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(255, 232, 170))
terrain:SetMaterialColor(Enum.Material.Sandstone, Color3.fromRGB(240, 170, 110))
terrain:SetMaterialColor(Enum.Material.Snow, Color3.fromRGB(240, 248, 255))
terrain.WaterColor = Color3.fromRGB(70, 205, 210)
terrain.WaterTransparency = 0.55
terrain.WaterReflectance = 0.25
terrain.WaterWaveSize = 0.15
terrain.WaterWaveSpeed = 8

local base = workspace:FindFirstChild("Baseplate")
if base and base:IsA("BasePart") then
	base.Material = Enum.Material.SmoothPlastic
	base.Color = Color3.fromRGB(112, 218, 62)
end

-- ---------------------------------------------------------------- Deko
if not DEKO then
	return
end

local old = workspace:FindFirstChild("DropABotDeko")
if old then
	old:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = "DropABotDeko"
folder.Parent = workspace

local rng = Random.new(7)
local baseY = 0
if base and base:IsA("BasePart") then
	baseY = base.Position.Y + base.Size.Y / 2
end

local function part(shape, size, pos, color, mat)
	local p = Instance.new("Part")
	p.Shape = shape
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = folder
	return p
end

local BALL, CYL, BLOCK = Enum.PartType.Ball, Enum.PartType.Cylinder, Enum.PartType.Block
local GREENS = { Color3.fromRGB(84, 200, 64), Color3.fromRGB(58, 176, 84), Color3.fromRGB(122, 220, 70) }
local BLOSSOMS = { Color3.fromRGB(245, 120, 200), Color3.fromRGB(160, 110, 245), Color3.fromRGB(255, 190, 60), Color3.fromRGB(90, 190, 255) }
local ROCKS = { Color3.fromRGB(96, 148, 236), Color3.fromRGB(120, 168, 246), Color3.fromRGB(80, 122, 214) }

local function tree(x, z)
	local h = rng:NextNumber(9, 15)
	local crown = BLOSSOMS[rng:NextInteger(1, #BLOSSOMS)]
	local leaf = rng:NextNumber() < 0.35 and crown or GREENS[rng:NextInteger(1, #GREENS)]
	local trunk = part(CYL, Vector3.new(h, 2.2, 2.2), Vector3.new(x, baseY + h / 2, z), Color3.fromRGB(150, 98, 60))
	trunk.CFrame = CFrame.new(x, baseY + h / 2, z) * CFrame.Angles(0, 0, math.rad(90))
	local r = rng:NextNumber(7, 10)
	part(BALL, Vector3.new(r, r, r), Vector3.new(x, baseY + h + r * 0.3, z), leaf)
	part(BALL, Vector3.new(r * 0.7, r * 0.7, r * 0.7), Vector3.new(x + r * 0.35, baseY + h + r * 0.75, z + r * 0.2), leaf)
end

local function rock(x, z)
	local s = rng:NextNumber(3, 8)
	local p = part(BLOCK, Vector3.new(s, s * 0.8, s * 0.9), Vector3.new(x, baseY + s * 0.3, z), ROCKS[rng:NextInteger(1, #ROCKS)])
	p.CFrame = CFrame.new(x, baseY + s * 0.3, z) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6.28), rng:NextNumber(-0.3, 0.3))
end

local function mushroom(x, z)
	local s = rng:NextNumber(2.2, 4)
	local stem = part(CYL, Vector3.new(s, s * 0.5, s * 0.5), Vector3.new(x, baseY + s / 2, z), Color3.fromRGB(255, 244, 226))
	stem.CFrame = CFrame.new(x, baseY + s / 2, z) * CFrame.Angles(0, 0, math.rad(90))
	part(BALL, Vector3.new(s * 1.5, s * 0.9, s * 1.5), Vector3.new(x, baseY + s, z), BLOSSOMS[rng:NextInteger(1, #BLOSSOMS)])
end

local function flower(x, z)
	local c = BLOSSOMS[rng:NextInteger(1, #BLOSSOMS)]
	part(BALL, Vector3.new(1.4, 1.4, 1.4), Vector3.new(x, baseY + 1.6, z), c)
	part(BALL, Vector3.new(0.5, 0.5, 0.5), Vector3.new(x, baseY + 1.6, z + 0.55), Color3.fromRGB(255, 226, 90))
	local stem = part(CYL, Vector3.new(1.4, 0.3, 0.3), Vector3.new(x, baseY + 0.7, z), Color3.fromRGB(64, 170, 70))
	stem.CFrame = CFrame.new(x, baseY + 0.7, z) * CFrame.Angles(0, 0, math.rad(90))
end

for i = 1, DEKO_ANZAHL do
	local ang = rng:NextNumber(0, math.pi * 2)
	local dist = DEKO_ABSTAND + rng:NextNumber(0, 130)
	local x, z = math.cos(ang) * dist, math.sin(ang) * dist
	local roll = rng:NextNumber()
	if roll < 0.28 then
		tree(x, z)
	elseif roll < 0.5 then
		rock(x, z)
	elseif roll < 0.68 then
		mushroom(x, z)
	else
		flower(x, z)
	end
end
