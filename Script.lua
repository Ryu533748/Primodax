-- ██████╗ ██████╗ ██╗███╗   ███╗ ██████╗ ██████╗  █████╗ ██╗  ██╗
-- ██╔══██╗██╔══██╗██║████╗ ████║██╔═══██╗██╔══██╗██╔══██╗╚██╗██╔╝
-- ██████╔╝██████╔╝██║██╔████╔██║██║   ██║██║  ██║███████║ ╚███╔╝ 
-- ██╔═══╝ ██╔══██╗██║██║╚██╔╝██║██║   ██║██║  ██║██╔══██║ ██╔██╗ 
-- ██║     ██║  ██║██║██║ ╚═╝ ██║╚██████╔╝██████╔╝██║  ██║██╔╝ ██╗
-- ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
-- Primodaxvgrant | Vagrant Survival
-- Version  : 1.0
-- Author   : Primodaxvgrant
-- Discord  : N/A
-- Game     : Vagrant Survival

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

-- ── PRIMODAXVGRANT CONFIG ─────────────────────────────────────────────────────
local CFG = {
    -- Silent Aim
    SilentAim        = true,
    SilentAimPart    = "Head",
    SilentAimFOV     = 120,

    -- Aimbot
    Aimbot           = true,
    AimbotKey        = Enum.KeyCode.Q,
    AimbotSmoothing  = 0.15,
    AimbotPart       = "Head",
    AimbotFOV        = 150,

    -- Movement
    FlyHack          = false,
    FlySpeed         = 80,
    SpeedHack        = false,
    WalkSpeed        = 50,

    -- Combat
    UnlimitedAmmo    = true,
    AutoReload       = true,

    -- Utility
    AutoPickup       = true,
    AutoPickupRange  = 25,
    AutoRespawn      = true,
    AutoRespawnLoot  = true,

    -- FOV Circle
    ShowFOV          = true,
    FOVColor         = Color3.fromRGB(255, 215, 0),
}

-- ── UTILITY ───────────────────────────────────────────────────────────────────
local function getCharacter(player)
    return player and player.Character
end

local function getHumanoid(player)
    local char = getCharacter(player)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot(player)
    local char = getCharacter(player)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getPart(player, partName)
    local char = getCharacter(player)
    return char and char:FindFirstChild(partName)
end

local function isAlive(player)
    local hum = getHumanoid(player)
    return hum and hum.Health > 0
end

local function worldToViewport(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

local function getDistance2D(screenPos)
    return (screenPos - Vector2.new(
        Camera.ViewportSize.X / 2,
        Camera.ViewportSize.Y / 2
    )).Magnitude
end

local function getNearestPlayer(fov)
    local nearest, nearestDist, nearestPos = nil, fov, nil
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isAlive(player) then
            local part = getPart(player, CFG.AimbotPart)
            if part then
                local screenPos, onScreen = worldToViewport(part.Position)
                if onScreen then
                    local dist = getDistance2D(screenPos)
                    if dist < nearestDist then
                        nearest     = player
                        nearestDist = dist
                        nearestPos  = part.Position
                    end
                end
            end
        end
    end
    return nearest, nearestPos
end

-- ── FOV CIRCLE ────────────────────────────────────────────────────────────────
local fovCircle          = Drawing.new("Circle")
fovCircle.Thickness      = 1.5
fovCircle.Color          = CFG.FOVColor
fovCircle.Filled         = false
fovCircle.Visible        = CFG.ShowFOV
fovCircle.Radius         = CFG.AimbotFOV
fovCircle.Position       = Vector2.new(
    Camera.ViewportSize.X / 2,
    Camera.ViewportSize.Y / 2
)

-- ── SILENT AIM ────────────────────────────────────────────────────────────────
local silentAimTarget = nil

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args   = {...}
    if CFG.SilentAim and method == "FireServer" then
        if silentAimTarget then
            local part = getPart(silentAimTarget, CFG.SilentAimPart)
            if part then
                for i, v in ipairs(args) do
                    if typeof(v) == "Vector3" then
                        args[i] = part.Position
                    end
                    if typeof(v) == "Instance" and v:IsA("BasePart") then
                        args[i] = part
                    end
                end
            end
        end
    end
    return oldNamecall(self, table.unpack(args))
end)

-- ── AIMBOT ────────────────────────────────────────────────────────────────────
local aimbotActive = false

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == CFG.AimbotKey then aimbotActive = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == CFG.AimbotKey then aimbotActive = false end
end)

-- ── FLY HACK ─────────────────────────────────────────────────────────────────
local flyConnection = nil
local bodyVelocity  = nil
local bodyGyro      = nil

local function enableFly()
    local root = getRoot(LocalPlayer)
    if not root then return end
    local hum = getHumanoid(LocalPlayer)
    if hum then hum.PlatformStand = true end

    bodyVelocity          = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bodyVelocity.Parent   = root

    bodyGyro           = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bodyGyro.CFrame    = root.CFrame
    bodyGyro.Parent    = root

    flyConnection = RunService.RenderStepped:Connect(function()
        if not CFG.FlyHack then return end
        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDir += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDir -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDir += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDir -= Vector3.new(0,1,0) end
        if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
        bodyVelocity.Velocity = moveDir * CFG.FlySpeed
        bodyGyro.CFrame       = Camera.CFrame
    end)
end

local function disableFly()
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    if bodyVelocity  then bodyVelocity:Destroy()    bodyVelocity  = nil end
    if bodyGyro      then bodyGyro:Destroy()         bodyGyro      = nil end
    local hum = getHumanoid(LocalPlayer)
    if hum then hum.PlatformStand = false end
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F then
        CFG.FlyHack = not CFG.FlyHack
        if CFG.FlyHack then enableFly() else disableFly() end
    end
    if input.KeyCode == Enum.KeyCode.G then
        CFG.SpeedHack = not CFG.SpeedHack
        local hum = getHumanoid(LocalPlayer)
        if hum then
            hum.WalkSpeed = CFG.SpeedHack and CFG.WalkSpeed or 16
        end
    end
end)

-- ── UNLIMITED AMMO + AUTO RELOAD ──────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not CFG.UnlimitedAmmo and not CFG.AutoReload then return end
    local char = getCharacter(LocalPlayer)
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    for _, v in ipairs(tool:GetDescendants()) do
        local name = v.Name:lower()
        if v:IsA("IntValue") or v:IsA("NumberValue") then
            if name:find("ammo") or name:find("bullet") or name:find("mag") then
                if CFG.UnlimitedAmmo and v.Value < 5 then
                    v.Value = 999
                end
            end
            if name:find("reload") or name:find("reloading") then
                if CFG.AutoReload and v.Value == 1 then
                    v.Value = 0
                end
            end
        end
        if v:IsA("BoolValue") then
            local n = v.Name:lower()
            if CFG.AutoReload and (n:find("reload") or n:find("reloading")) then
                v.Value = false
            end
        end
    end
end)

-- ── AUTO PICKUP ───────────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not CFG.AutoPickup then return end
    local root = getRoot(LocalPlayer)
    if not root then return end
    local lootFolder = Workspace:FindFirstChild("Loots")
                    or Workspace:FindFirstChild("Items")
                    or Workspace:FindFirstChild("Drops")
                    or Workspace
    for _, obj in ipairs(lootFolder:GetChildren()) do
        local prompt   = obj:FindFirstChildOfClass("ProximityPrompt")
        local clickDet = obj:FindFirstChildOfClass("ClickDetector")
        local part     = obj:IsA("BasePart") and obj
                      or obj:FindFirstChildOfClass("BasePart")
        if part then
            local dist = (root.Position - part.Position).Magnitude
            if dist <= CFG.AutoPickupRange then
                if prompt then fireproximityprompt(prompt) end
                if clickDet then fireclickdetector(clickDet) end
            end
        end
    end
end)

-- ── AUTO RESPAWN ──────────────────────────────────────────────────────────────
local function findNearestLootbox()
    local root = getRoot(LocalPlayer)
    if not root then return nil end
    local nearest, nearestDist = nil, math.huge
    local lootBoxFolder = Workspace:FindFirstChild("LootBoxes")
                       or Workspace:FindFirstChild("LootZones")
                       or Workspace:FindFirstChild("Crates")
    if lootBoxFolder then
        for _, box in ipairs(lootBoxFolder:GetChildren()) do
            local part = box:IsA("BasePart") and box
                      or box:FindFirstChildOfClass("BasePart")
            if part then
                local dist = (root.Position - part.Position).Magnitude
                if dist < nearestDist then
                    nearest     = part
                    nearestDist = dist
                end
            end
        end
    end
    return nearest
end

local function onCharacterAdded(char)
    local hum  = char:WaitForChild("Humanoid")
    local root = char:WaitForChild("HumanoidRootPart")
    if CFG.SpeedHack then hum.WalkSpeed = CFG.WalkSpeed end
    if CFG.FlyHack then task.wait(0.5) enableFly() end
    if CFG.AutoRespawnLoot then
        task.wait(0.3)
        local lootbox = findNearestLootbox()
        if lootbox then
            root.CFrame = lootbox.CFrame + Vector3.new(0, 5, 0)
        end
    end
    hum.Died:Connect(function()
        if CFG.AutoRespawn then
            task.wait(3)
            local respawnRemote = ReplicatedStorage:FindFirstChild("Respawn")
                               or ReplicatedStorage:FindFirstChild("RespawnPlayer")
            if respawnRemote and respawnRemote:IsA("RemoteEvent") then
                respawnRemote:FireServer()
            end
            task.wait(1)
            if not isAlive(LocalPlayer) then
                LocalPlayer:LoadCharacter()
            end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then onCharacterAdded(LocalPlayer.Character) end

-- ── MAIN RENDER LOOP ──────────────────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(
        Camera.ViewportSize.X / 2,
        Camera.ViewportSize.Y / 2
    )
    fovCircle.Visible = CFG.ShowFOV
    fovCircle.Radius  = CFG.AimbotFOV

    local nearestPlayer, nearestPos = getNearestPlayer(CFG.SilentAimFOV)
    silentAimTarget = nearestPlayer

    if CFG.Aimbot and aimbotActive and nearestPlayer and nearestPos then
        local _, onScreen = worldToViewport(nearestPos)
        if onScreen then
            local targetCF = CFrame.new(
                Camera.CFrame.Position,
                Camera.CFrame.Position +
                (nearestPos - Camera.CFrame.Position).Unit
            )
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, CFG.AimbotSmoothing)
        end
    end
end)

-- ── PRIMODAXVGRANT GUI ────────────────────────────────────────────────────────
local ScreenGui              = Instance.new("ScreenGui")
ScreenGui.Name               = "Primodaxvgrant"
ScreenGui.ResetOnSpawn       = false
ScreenGui.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent             = game:GetService("CoreGui")

local MainFrame              = Instance.new("Frame")
MainFrame.Size               = UDim2.new(0, 230, 0, 340)
MainFrame.Position           = UDim2.new(0, 10, 0.3, 0)
MainFrame.BackgroundColor3   = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel    = 0
MainFrame.Active             = true
MainFrame.Draggable          = true
MainFrame.Parent             = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Title bar
local TitleBar               = Instance.new("Frame")
TitleBar.Size                = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3    = Color3.fromRGB(255, 215, 0)
TitleBar.BorderSizePixel     = 0
TitleBar.Parent              = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleLabel             = Instance.new("TextLabel")
TitleLabel.Size              = UDim2.new(1, 0, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text              = "⚡ PRIMODAXVGRANT ⚡"
TitleLabel.TextColor3        = Color3.fromRGB(0, 0, 0)
TitleLabel.TextSize          = 13
TitleLabel.Font              = Enum.Font.GothamBold
TitleLabel.Parent            = TitleBar

local SubLabel               = Instance.new("TextLabel")
SubLabel.Size                = UDim2.new(1, 0, 0, 18)
SubLabel.Position            = UDim2.new(0, 0, 0, 40)
SubLabel.BackgroundTransparency = 1
SubLabel.Text                = "Vagrant Survival | v1.0"
SubLabel.TextColor3          = Color3.fromRGB(255, 215, 0)
SubLabel.TextSize            = 11
SubLabel.Font                = Enum.Font.Gotham
SubLabel.Parent              = MainFrame

local Layout                 = Instance.new("UIListLayout")
Layout.Padding               = UDim.new(0, 4)
Layout.SortOrder             = Enum.SortOrder.LayoutOrder
Layout.Parent                = MainFrame

local Padding                = Instance.new("UIPadding")
Padding.PaddingTop           = UDim.new(0, 62)
Padding.PaddingLeft          = UDim.new(0, 8)
Padding.PaddingRight         = UDim.new(0, 8)
Padding.Parent               = MainFrame

local function makeToggle(labelText, cfgKey, order)
    local btn                = Instance.new("TextButton")
    btn.Size                 = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3     = CFG[cfgKey]
                               and Color3.fromRGB(255, 215, 0)
                               or  Color3.fromRGB(40, 40, 40)
    btn.Text                 = labelText .. ": " .. (CFG[cfgKey] and "ON" or "OFF")
    btn.TextColor3           = CFG[cfgKey]
                               and Color3.fromRGB(0, 0, 0)
                               or  Color3.fromRGB(255, 255, 255)
    btn.TextSize             = 12
    btn.Font                 = Enum.Font.GothamBold
    btn.LayoutOrder          = order
    btn.Parent               = MainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        CFG[cfgKey] = not CFG[cfgKey]
        btn.BackgroundColor3 = CFG[cfgKey]
                               and Color3.fromRGB(255, 215, 0)
                               or  Color3.fromRGB(40, 40, 40)
        btn.TextColor3       = CFG[cfgKey]
                               and Color3.fromRGB(0, 0, 0)
                               or  Color3.fromRGB(255, 255, 255)
        btn.Text = labelText .. ": " .. (CFG[cfgKey] and "ON" or "OFF")

        if cfgKey == "FlyHack" then
            if CFG.FlyHack then enableFly() else disableFly() end
        end
        if cfgKey == "SpeedHack" then
            local hum = getHumanoid(LocalPlayer)
            if hum then
                hum.WalkSpeed = CFG.SpeedHack and CFG.WalkSpeed or 16
            end
        end
    end)
end

makeToggle("🎯 Silent Aim",      "SilentAim",       1)
makeToggle("🔫 Aimbot [Q]",      "Aimbot",          2)
makeToggle("✈️  Fly [F]",         "FlyHack",         3)
makeToggle("⚡ Speed [G]",       "SpeedHack",       4)
makeToggle("🔋 Unlimited Ammo",  "UnlimitedAmmo",   5)
makeToggle("🔄 Auto Reload",     "AutoReload",      6)
makeToggle("🧲 Auto Pickup",     "AutoPickup",      7)
makeToggle("💀 Auto Respawn",    "AutoRespawn",     8)
makeToggle("📦 Respawn @ Loot",  "AutoRespawnLoot", 9)
makeToggle("⭕ Show FOV",        "ShowFOV",         10)

print("✅ PRIMODAXVGRANT loaded — Vagrant Survival | v1.0")

-- ══════════════════════════════════════════
-- PRIMODAXVGRANT BYPASS v1.0
-- ══════════════════════════════════════════

pcall(function()

    -- Block kick/ban/anticheat remotes
    local oldBypass
    oldBypass = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" or method == "InvokeServer" then
            local name = self.Name:lower()
            if name:find("kick")
            or name:find("ban")
            or name:find("anticheat")
            or name:find("detect")
            or name:find("report") then
                return nil
            end
        end
        return oldBypass(self, table.unpack({...}))
    end)

    -- Hide executor globals
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local oldIndex = mt.__index
    mt.__index = newcclosure(function(self, key)
        if key == "Executor" or key == "executor" then
            return nil
        end
        return oldIndex(self, key)
    end)
    setreadonly(mt, true)

    print("[Primodaxvgrant] Bypass active ✅")
end)
