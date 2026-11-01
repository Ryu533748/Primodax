-- ██████╗ ██████╗ ██╗███╗   ███╗ ██████╗ ██████╗  █████╗ ██╗  ██╗
-- ██╔══██╗██╔══██╗██║████╗ ████║██╔═══██╗██╔══██╗██╔══██╗╚██╗██╔╝
-- ██████╔╝██████╔╝██║██╔████╔██║██║   ██║██║  ██║███████║ ╚███╔╝
-- ██╔═══╝ ██╔══██╗██║██║╚██╔╝██║██║   ██║██║  ██║██╔══██║ ██╔██╗
-- ██║     ██║  ██║██║██║ ╚═╝ ██║╚██████╔╝██████╔╝██║  ██║██╔╝ ██╗
-- ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
-- PRIMODAXVGRANT | Vagrant Survival
-- Version  : 3.0
-- Author   : Primodaxvgrant
-- Game     : Vagrant Survival (Roblox)
-- Executor : Delta, Arceus X, Fluxus

-- SERVICES
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")
local Workspace         = game:GetService("Workspace")

local LP                = Players.LocalPlayer
local Cam               = Workspace.CurrentCamera

-- CONFIG
local CFG = {
    SilentAim        = true,
    SilentAimPart    = "Head",
    SilentAimFOV     = 120,
    Aimbot           = true,
    AimbotKey        = Enum.KeyCode.Q,
    AimbotSmoothing  = 0.15,
    AimbotPart       = "Head",
    AimbotFOV        = 150,
    FlyHack          = false,
    FlySpeed         = 80,
    SpeedHack        = false,
    WalkSpeed        = 50,
    UnlimitedAmmo    = true,
    AutoReload       = true,
    AutoPickup       = true,
    AutoPickupRange  = 30,
    AutoRespawn      = true,
    AutoRespawnLoot  = true,
    AntiKick         = true,
    HideExecutor     = true,
    ShowFOV          = true,
    FOVColor         = Color3.fromRGB(255, 215, 0),
    ESPEnabled       = true,
    ESPColor         = Color3.fromRGB(255, 0, 0),
}

-- UTILITY
local function getChar(p) return p and p.Character end
local function getHum(p)
    local c = getChar(p)
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot(p)
    local c = getChar(p)
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getPart(p, name)
    local c = getChar(p)
    return c and c:FindFirstChild(name)
end
local function isAlive(p)
    local h = getHum(p)
    return h and h.Health > 0
end
local function toScreen(pos)
    local s, on = Cam:WorldToViewportPoint(pos)
    return Vector2.new(s.X, s.Y), on
end
local function dist2D(sp)
    return (sp - Vector2.new(
        Cam.ViewportSize.X / 2,
        Cam.ViewportSize.Y / 2
    )).Magnitude
end
local function getNearestEnemy(fov)
    local best, bDist, bPos = nil, fov, nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isAlive(p) then
            local part = getPart(p, CFG.AimbotPart)
            if part then
                local sp, on = toScreen(part.Position)
                if on then
                    local d = dist2D(sp)
                    if d < bDist then
                        best  = p
                        bDist = d
                        bPos  = part.Position
                    end
                end
            end
        end
    end
    return best, bPos
end

-- FOV CIRCLE
local fovCircle     = Drawing.new("Circle")
fovCircle.Thickness = 1.5
fovCircle.Color     = CFG.FOVColor
fovCircle.Filled    = false
fovCircle.Visible   = CFG.ShowFOV
fovCircle.Radius    = CFG.AimbotFOV
fovCircle.Position  = Vector2.new(
    Cam.ViewportSize.X / 2,
    Cam.ViewportSize.Y / 2
)

-- COMBINED HOOK: silent aim + antikick (ONE hook only)
local silentTarget = nil
local _nc
_nc = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args   = {...}
    if method == "FireServer" or method == "InvokeServer" then
        if CFG.AntiKick then
            local n = (self.Name or ""):lower()
            if n:find("kick") or n:find("ban") or n:find("cheat")
            or n:find("detect") or n:find("anticheat")
            or n:find("report") or n:find("flag") then
                return nil
            end
        end
        if CFG.SilentAim and silentTarget and isAlive(silentTarget) then
            local part = getPart(silentTarget, CFG.SilentAimPart)
            if part then
                for i, v in ipairs(args) do
                    if typeof(v) == "Vector3" then
                        args[i] = part.Position
                    elseif typeof(v) == "Instance" and v:IsA("BasePart") then
                        args[i] = part
                    end
                end
            end
        end
    end
    return _nc(self, table.unpack(args))
end)

-- HIDE EXECUTOR
pcall(function()
    if not CFG.HideExecutor then return end
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local _oi = mt.__index
    mt.__index = newcclosure(function(self, k)
        if k == "Executor" or k == "executor"
        or k == "syn" or k == "fluxus" or k == "DELTA" then
            return nil
        end
        return _oi(self, k)
    end)
    setreadonly(mt, true)
end)

-- AIMBOT
local aimbotOn = false
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == CFG.AimbotKey then aimbotOn = true end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.KeyCode == CFG.AimbotKey then aimbotOn = false end
end)

-- FLY HACK
local flyConn, bVel, bGyro = nil, nil, nil
local function enableFly()
    local root = getRoot(LP)
    if not root then return end
    local hum = getHum(LP)
    if hum then hum.PlatformStand = true end
    bVel          = Instance.new("BodyVelocity")
    bVel.Velocity = Vector3.zero
    bVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bVel.Parent   = root
    bGyro           = Instance.new("BodyGyro")
    bGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bGyro.CFrame    = root.CFrame
    bGyro.Parent    = root
    flyConn = RunService.RenderStepped:Connect(function()
        if not CFG.FlyHack then return end
        local md  = Vector3.zero
        local UIS = UserInputService
        if UIS:IsKeyDown(Enum.KeyCode.W) then md = md + Cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then md = md - Cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then md = md - Cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then md = md + Cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space)     then md = md + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then md = md - Vector3.new(0,1,0) end
        if md.Magnitude > 0 then md = md.Unit end
        bVel.Velocity = md * CFG.FlySpeed
        bGyro.CFrame  = Cam.CFrame
    end)
end
local function disableFly()
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if bVel    then bVel:Destroy()       bVel    = nil end
    if bGyro   then bGyro:Destroy()      bGyro   = nil end
    local hum = getHum(LP)
    if hum then hum.PlatformStand = false end
end
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.F then
        CFG.FlyHack = not CFG.FlyHack
        if CFG.FlyHack then enableFly() else disableFly() end
    end
    if inp.KeyCode == Enum.KeyCode.G then
        CFG.SpeedHack = not CFG.SpeedHack
        local hum = getHum(LP)
        if hum then hum.WalkSpeed = CFG.SpeedHack and CFG.WalkSpeed or 16 end
    end
end)

-- UNLIMITED AMMO + AUTO RELOAD
RunService.Heartbeat:Connect(function()
    if not CFG.UnlimitedAmmo and not CFG.AutoReload then return end
    local char = getChar(LP)
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    for _, v in ipairs(tool:GetDescendants()) do
        local n = v.Name:lower()
        if v:IsA("IntValue") or v:IsA("NumberValue") then
            if CFG.UnlimitedAmmo and (n:find("ammo") or n:find("bullet") or n:find("mag")) then
                if v.Value < 5 then v.Value = 999 end
            end
            if CFG.AutoReload and (n:find("reload") or n:find("reloading")) then
                if v.Value == 1 then v.Value = 0 end
            end
        end
        if v:IsA("BoolValue") then
            local bn = v.Name:lower()
            if CFG.AutoReload and (bn:find("reload") or bn:find("reloading")) then
                v.Value = false
            end
        end
    end
end)

-- AUTO PICKUP
RunService.Heartbeat:Connect(function()
    if not CFG.AutoPickup then return end
    local root = getRoot(LP)
    if not root then return end
    local folders = {
        Workspace:FindFirstChild("Loots"),
        Workspace:FindFirstChild("Items"),
        Workspace:FindFirstChild("Drops"),
        Workspace:FindFirstChild("Pickups"),
        Workspace:FindFirstChild("Collectibles"),
    }
    for _, folder in ipairs(folders) do
        if folder then
            for _, obj in ipairs(folder:GetChildren()) do
                local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                local click  = obj:FindFirstChildOfClass("ClickDetector")
                local part   = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
                if part then
                    local d = (root.Position - part.Position).Magnitude
                    if d <= CFG.AutoPickupRange then
                        if prompt then pcall(fireproximityprompt, prompt) end
                        if click  then pcall(fireclickdetector,  click)  end
                    end
                end
            end
        end
    end
end)

-- AUTO RESPAWN
local function nearestLootbox()
    local root = getRoot(LP)
    if not root then return nil end
    local best, bDist = nil, math.huge
    local folders = {
        Workspace:FindFirstChild("LootBoxes"),
        Workspace:FindFirstChild("LootZones"),
        Workspace:FindFirstChild("Crates"),
        Workspace:FindFirstChild("Chests"),
    }
    for _, f in ipairs(folders) do
        if f then
            for _, box in ipairs(f:GetChildren()) do
                local part = box:IsA("BasePart") and box or box:FindFirstChildOfClass("BasePart")
                if part then
                    local d = (root.Position - part.Position).Magnitude
                    if d < bDist then best = part bDist = d end
                end
            end
        end
    end
    return best
end

local function onCharAdded(char)
    local hum  = char:WaitForChild("Humanoid", 10)
    local root = char:WaitForChild("HumanoidRootPart", 10)
    if not hum or not root then return end
    if CFG.SpeedHack then hum.WalkSpeed = CFG.WalkSpeed end
    if CFG.FlyHack   then task.wait(0.5) enableFly()    end
    if CFG.AutoRespawnLoot then
        task.wait(0.5)
        local lb = nearestLootbox()
        if lb then root.CFrame = lb.CFrame + Vector3.new(0, 5, 0) end
    end
    hum.Died:Connect(function()
        if not CFG.AutoRespawn then return end
        task.wait(3)
        local rem = ReplicatedStorage:FindFirstChild("Respawn")
                 or ReplicatedStorage:FindFirstChild("RespawnPlayer")
                 or ReplicatedStorage:FindFirstChild("PlayerRespawn")
        if rem and rem:IsA("RemoteEvent") then
            pcall(function() rem:FireServer() end)
        end
        task.wait(1)
        if not isAlive(LP) then
            pcall(function() LP:LoadCharacter() end)
        end
    end)
end

LP.CharacterAdded:Connect(onCharAdded)
if LP.Character then task.spawn(function() onCharAdded(LP.Character) end) end

-- ESP
local espObjects = {}
local function makeESP(player)
    local box       = Drawing.new("Square")
    box.Visible     = false
    box.Color       = CFG.ESPColor
    box.Thickness   = 1
    box.Filled      = false
    local name      = Drawing.new("Text")
    name.Visible    = false
    name.Color      = Color3.fromRGB(255,255,255)
    name.Size       = 14
    name.Center     = true
    name.Outline    = true
    local dist      = Drawing.new("Text")
    dist.Visible    = false
    dist.Color      = Color3.fromRGB(255,215,0)
    dist.Size       = 12
    dist.Center     = true
    dist.Outline    = true
    espObjects[player] = {box=box, name=name, dist=dist}
end
local function removeESP(player)
    local e = espObjects[player]
    if e then
        e.box:Remove()
        e.name:Remove()
        e.dist:Remove()
        espObjects[player] = nil
    end
end
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then makeESP(p) end
end
Players.PlayerAdded:Connect(function(p) if p ~= LP then makeESP(p) end end)
Players.PlayerRemoving:Connect(removeESP)

-- MAIN RENDER LOOP
RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
    fovCircle.Visible  = CFG.ShowFOV
    fovCircle.Radius   = CFG.AimbotFOV
    local np, npos = getNearestEnemy(CFG.SilentAimFOV)
    silentTarget = np
    if CFG.Aimbot and aimbotOn and np and npos then
        local _, on = toScreen(npos)
        if on then
            local cf = CFrame.new(
                Cam.CFrame.Position,
                Cam.CFrame.Position + (npos - Cam.CFrame.Position).Unit
            )
            Cam.CFrame = Cam.CFrame:Lerp(cf, CFG.AimbotSmoothing)
        end
    end
    for player, e in pairs(espObjects) do
        local function hide()
            e.box.Visible=false e.name.Visible=false e.dist.Visible=false
        end
        if not CFG.ESPEnabled or not isAlive(player) then hide() continue end
        local root = getRoot(player)
        local head = getPart(player, "Head")
        if not root or not head then hide() continue end
        local rootSP, rootOn = toScreen(root.Position)
        local headSP, headOn = toScreen(head.Position)
        if not rootOn or not headOn then hide() continue end
        local height = math.abs(rootSP.Y - headSP.Y) * 2.2
        local width  = height * 0.5
        local myRoot = getRoot(LP)
        local d = myRoot and (myRoot.Position - root.Position).Magnitude or 0
        e.box.Size     = Vector2.new(width, height)
        e.box.Position = Vector2.new(rootSP.X - width/2, rootSP.Y - height/2)
        e.box.Color    = CFG.ESPColor
        e.box.Visible  = true
        e.name.Text     = player.Name
        e.name.Position = Vector2.new(rootSP.X, headSP.Y - 16)
        e.name.Visible  = true
        e.dist.Text     = string.format("[%.0fm]", d)
        e.dist.Position = Vector2.new(rootSP.X, rootSP.Y + height/2 + 2)
        e.dist.Visible  = true
    end
end)

-- GUI
local SG = Instance.new("ScreenGui")
SG.Name = "Primodaxvgrant"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent = CoreGui

local MF = Instance.new("Frame")
MF.Size = UDim2.new(0, 235, 0, 430)
MF.Position = UDim2.new(0, 10, 0.2, 0)
MF.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
MF.BorderSizePixel = 0
MF.Active = true
MF.Draggable = true
MF.Parent = SG
Instance.new("UICorner", MF).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 215, 0)
stroke.Thickness = 1.5
stroke.Parent = MF

local TB = Instance.new("Frame")
TB.Size = UDim2.new(1, 0, 0, 45)
TB.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
TB.BorderSizePixel = 0
TB.Parent = MF
Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 10)

local TL = Instance.new("TextLabel")
TL.Size = UDim2.new(1, 0, 0, 25)
TL.Position = UDim2.new(0, 0, 0, 2)
TL.BackgroundTransparency = 1
TL.Text = "⚡ PRIMODAXVGRANT ⚡"
TL.TextColor3 = Color3.fromRGB(0, 0, 0)
TL.TextSize = 14
TL.Font = Enum.Font.GothamBold
TL.Parent = TB

local SL = Instance.new("TextLabel")
SL.Size = UDim2.new(1, 0, 0, 16)
SL.Position = UDim2.new(0, 0, 0, 26)
SL.BackgroundTransparency = 1
SL.Text = "Vagrant Survival | v3.0 | by Primodaxvgrant"
SL.TextColor3 = Color3.fromRGB(30, 30, 30)
SL.TextSize = 10
SL.Font = Enum.Font.Gotham
SL.Parent = TB

local SF = Instance.new("ScrollingFrame")
SF.Size = UDim2.new(1, -10, 1, -55)
SF.Position = UDim2.new(0, 5, 0, 50)
SF.BackgroundTransparency = 1
SF.ScrollBarThickness = 3
SF.ScrollBarImageColor3 = Color3.fromRGB(255,215,0)
SF.CanvasSize = UDim2.new(0,0,0,0)
SF.AutomaticCanvasSize = Enum.AutomaticSize.Y
SF.Parent = MF

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 5)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = SF

local Pad = Instance.new("UIPadding")
Pad.PaddingTop = UDim.new(0, 5)
Pad.PaddingLeft = UDim.new(0, 5)
Pad.PaddingRight = UDim.new(0, 5)
Pad.Parent = SF

local function makeSection(text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold
    lbl.LayoutOrder = order
    lbl.Parent = SF
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 4)
end

local function makeToggle(label, key, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = CFG[key] and Color3.fromRGB(255,215,0) or Color3.fromRGB(35,35,35)
    btn.Text = label..": "..(CFG[key] and "ON" or "OFF")
    btn.TextColor3 = CFG[key] and Color3.fromRGB(0,0,0) or Color3.fromRGB(200,200,200)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.LayoutOrder = order
    btn.Parent = SF
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(255,215,0)
    s.Thickness = 0.5
    s.Parent = btn
    btn.MouseButton1Click:Connect(function()
        CFG[key] = not CFG[key]
        btn.BackgroundColor3 = CFG[key] and Color3.fromRGB(255,215,0) or Color3.fromRGB(35,35,35)
        btn.TextColor3 = CFG[key] and Color3.fromRGB(0,0,0) or Color3.fromRGB(200,200,200)
        btn.Text = label..": "..(CFG[key] and "ON" or "OFF")
        if key == "FlyHack" then
            if CFG.FlyHack then enableFly() else disableFly() end
        end
        if key == "SpeedHack" then
            local hum = getHum(LP)
            if hum then hum.WalkSpeed = CFG.SpeedHack and CFG.WalkSpeed or 16 end
        end
    end)
end

makeSection("── COMBAT ──",      1)
makeToggle("🎯 Silent Aim",      "SilentAim",       2)
makeToggle("🔫 Aimbot [Hold Q]", "Aimbot",          3)
makeToggle("🔋 Unlimited Ammo",  "UnlimitedAmmo",   4)
makeToggle("🔄 Auto Reload",     "AutoReload",      5)
makeSection("── MOVEMENT ──",    6)
makeToggle("✈️  Fly [F]",         "FlyHack",         7)
makeToggle("⚡ Speed [G]",       "SpeedHack",       8)
makeSection("── UTILITY ──",     9)
makeToggle("🧲 Auto Pickup",     "AutoPickup",      10)
makeToggle("💀 Auto Respawn",    "AutoRespawn",     11)
makeToggle("📦 Respawn @ Loot",  "AutoRespawnLoot", 12)
makeSection("── VISUAL ──",      13)
makeToggle("🟥 ESP",             "ESPEnabled",      14)
makeToggle("⭕ Show FOV",        "ShowFOV",         15)
makeSection("── BYPASS ──",      16)
makeToggle("🛡️  Anti Kick",       "AntiKick",        17)
makeToggle("👁️  Hide Executor",    "HideExecutor",    18)

print("✅ PRIMODAXVGRANT v3.0 loaded — Vagrant Survival")
