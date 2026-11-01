-- ██████╗ ██████╗ ██╗███╗   ███╗ ██████╗ ██████╗  █████╗ ██╗  ██╗
-- ██╔══██╗██╔══██╗██║████╗ ████║██╔═══██╗██╔══██╗██╔══██╗╚██╗██╔╝
-- ██████╔╝██████╔╝██║██╔████╔██║██║   ██║██║  ██║███████║ ╚███╔╝
-- ██╔═══╝ ██╔══██╗██║██║╚██╔╝██║██║   ██║██║  ██║██╔══██║ ██╔██╗
-- ██║     ██║  ██║██║██║ ╚═╝ ██║╚██████╔╝██████╔╝██║  ██║██╔╝ ██╗
-- ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
-- PRIMODAXVGRANT | Vagrant Survival
-- Version  : 4.1
-- Admin    : PRIMODAX
-- Game     : Vagrant Survival (Roblox)
-- Executor : Delta, Arceus X, Fluxus
--
-- CHANGES v4.0:
--   • Fly removed → Infinite Jump (no anticheat trip, no stuck-in-air bug)
--   • SpeedHack removed → Noclip / Walk-Through-Walls (no kick on speed event)
--   • Floating circle toggle button (bottom-center, always visible)
--   • Main menu hidden by default, shows/hides on circle button tap
--   • Aimbot FOV & Silent Aim FOV: live sliders in menu (adjustable)
--   • Config system: Save / Load / Export (clipboard base64) / Import
--   • Admin watermark: PRIMODAX on title bar

-- ══════════════════════════════════════════════════════
--  SERVICES
-- ══════════════════════════════════════════════════════
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")
local HttpService       = game:GetService("HttpService")

local LP  = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

-- ══════════════════════════════════════════════════════
--  CONFIG (defaults — overwritten by loaded config)
-- ══════════════════════════════════════════════════════
local CFG = {
    -- combat
    SilentAim        = true,
    SilentAimPart    = "Head",
    SilentAimFOV     = 120,   -- adjustable 10–500
    Aimbot           = true,
    AimbotSmoothing  = 0.15,
    AimbotPart       = "Head",
    AimbotFOV        = 150,   -- adjustable 10–500
    ShowFOV          = true,
    FOVColor         = Color3.fromRGB(255, 215, 0),
    -- utility
    UnlimitedAmmo    = true,
    AutoReload       = true,
    AutoPickup       = true,
    AutoPickupRange  = 30,
    AutoRespawn      = true,
    AutoRespawnLoot  = true,
    -- movement
    InfiniteJump     = false,
    Noclip           = false,
    -- visual
    ESPEnabled       = true,
    ESPColor         = Color3.fromRGB(255, 0, 0),
    -- bypass
    AntiKick         = true,
    HideExecutor     = true,
}

-- ══════════════════════════════════════════════════════
--  CONFIG SAVE / LOAD / EXPORT / IMPORT
--  Uses writefile/readfile when available (Delta/Fluxus)
--  Falls back to clipboard export otherwise.
-- ══════════════════════════════════════════════════════
local CONFIG_FILE = "primodax_cfg.json"

local function cfgToTable()
    return {
        SilentAim       = CFG.SilentAim,
        SilentAimFOV    = CFG.SilentAimFOV,
        Aimbot          = CFG.Aimbot,
        AimbotFOV       = CFG.AimbotFOV,
        AimbotSmoothing = CFG.AimbotSmoothing,
        ShowFOV         = CFG.ShowFOV,
        UnlimitedAmmo   = CFG.UnlimitedAmmo,
        AutoReload      = CFG.AutoReload,
        AutoPickup      = CFG.AutoPickup,
        AutoPickupRange = CFG.AutoPickupRange,
        AutoRespawn     = CFG.AutoRespawn,
        AutoRespawnLoot = CFG.AutoRespawnLoot,
        InfiniteJump    = CFG.InfiniteJump,
        Noclip          = CFG.Noclip,
        ESPEnabled      = CFG.ESPEnabled,
        AntiKick        = CFG.AntiKick,
        HideExecutor    = CFG.HideExecutor,
    }
end

local function applyTable(t)
    for k, v in pairs(t) do
        if CFG[k] ~= nil then CFG[k] = v end
    end
end

local function saveConfig()
    local ok, json = pcall(function()
        return HttpService:JSONEncode(cfgToTable())
    end)
    if not ok then return false, "encode fail" end
    if writefile then
        local ok2 = pcall(writefile, CONFIG_FILE, json)
        if ok2 then return true, "saved to "..CONFIG_FILE end
    end
    -- no writefile: export to clipboard
    if setclipboard then
        pcall(setclipboard, json)
        return true, "copied to clipboard"
    end
    return false, "no writefile or setclipboard"
end

local function loadConfig()
    if readfile then
        local ok, raw = pcall(readfile, CONFIG_FILE)
        if ok and raw and #raw > 2 then
            local ok2, t = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok2 and t then
                applyTable(t)
                return true, "loaded from "..CONFIG_FILE
            end
        end
    end
    return false, "no saved config"
end

local function exportConfig()
    -- export = json string to clipboard for sharing
    local ok, json = pcall(function()
        return HttpService:JSONEncode(cfgToTable())
    end)
    if not ok then return false, "encode fail" end
    if setclipboard then
        pcall(setclipboard, json)
        return true, "config copied to clipboard — paste to share"
    end
    return false, "setclipboard not available"
end

local function importConfig(jsonStr)
    local ok, t = pcall(function() return HttpService:JSONDecode(jsonStr) end)
    if ok and t then
        applyTable(t)
        return true, "config imported"
    end
    return false, "invalid JSON"
end

-- try auto-load on start
pcall(loadConfig)

-- ══════════════════════════════════════════════════════
--  UTILITY
-- ══════════════════════════════════════════════════════
local function getChar(p)  return p and p.Character end
local function getHum(p)
    local c = getChar(p); return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot(p)
    local c = getChar(p); return c and c:FindFirstChild("HumanoidRootPart")
end
local function getPart(p, name)
    local c = getChar(p); return c and c:FindFirstChild(name)
end
local function isAlive(p)
    local h = getHum(p); return h and h.Health > 0
end
local function toScreen(pos)
    local s, on = Cam:WorldToViewportPoint(pos)
    return Vector2.new(s.X, s.Y), on
end
local function dist2D(sp)
    return (sp - Vector2.new(
        Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2
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
                    if d < bDist then best=p bDist=d bPos=part.Position end
                end
            end
        end
    end
    return best, bPos
end

-- ══════════════════════════════════════════════════════
--  FOV CIRCLE (Drawing)
-- ══════════════════════════════════════════════════════
local fovCircle         = Drawing.new("Circle")
fovCircle.Thickness     = 1.5
fovCircle.Color         = CFG.FOVColor
fovCircle.Filled        = false
fovCircle.Visible       = CFG.ShowFOV
fovCircle.Radius        = CFG.AimbotFOV
fovCircle.Position      = Vector2.new(
    Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2
)

-- ══════════════════════════════════════════════════════
--  HOOK: Silent Aim + Anti-Kick (single __namecall hook)
-- ══════════════════════════════════════════════════════
local silentTarget = nil
local _nc
_nc = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args   = {...}
    if method == "FireServer" or method == "InvokeServer" then
        if CFG.AntiKick then
            local n = (self.Name or ""):lower()
            if n:find("kick") or n:find("ban")  or n:find("cheat")
            or n:find("detect") or n:find("anticheat")
            or n:find("report") or n:find("flag") then
                return nil
            end
        end
        if CFG.SilentAim and silentTarget and isAlive(silentTarget) then
            local part = getPart(silentTarget, CFG.SilentAimPart)
            if part then
                for i, v in ipairs(args) do
                    if typeof(v) == "Vector3"  then args[i] = part.Position end
                    if typeof(v) == "Instance" and v:IsA("BasePart") then
                        args[i] = part
                    end
                end
            end
        end
    end
    return _nc(self, table.unpack(args))
end)

-- ══════════════════════════════════════════════════════
--  HIDE EXECUTOR GLOBALS
-- ══════════════════════════════════════════════════════
pcall(function()
    if not CFG.HideExecutor then return end
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local _oi = mt.__index
    mt.__index = newcclosure(function(self, k)
        if k=="Executor" or k=="executor" or k=="syn"
        or k=="fluxus" or k=="DELTA" then return nil end
        return _oi(self, k)
    end)
    setreadonly(mt, true)
end)

-- ══════════════════════════════════════════════════════
--  AIMBOT (hold Q — desktop; toggle button on mobile)
-- ══════════════════════════════════════════════════════
local aimbotOn = false
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.Q then aimbotOn = true end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.KeyCode == Enum.KeyCode.Q then aimbotOn = false end
end)

-- ══════════════════════════════════════════════════════
--  INFINITE JUMP
--  Fires Jump again when Humanoid lands while flag is on.
--  No BodyVelocity, no anticheat surface — just state flip.
-- ══════════════════════════════════════════════════════
local jumpConn = nil
local function hookInfiniteJump(char)
    if jumpConn then jumpConn:Disconnect() jumpConn = nil end
    local hum = char and char:WaitForChild("Humanoid", 10)
    if not hum then return end
    jumpConn = hum.StateChanged:Connect(function(_, new)
        if CFG.InfiniteJump
        and new == Enum.HumanoidStateType.Landed then
            task.wait()
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

-- ══════════════════════════════════════════════════════
--  NOCLIP (walk-through walls)
--  Cancels collision on character parts each physics step.
--  No speed change → no speed-event kick.
-- ══════════════════════════════════════════════════════
RunService.Stepped:Connect(function()
    if not CFG.Noclip then return end
    local char = getChar(LP)
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            v.CanCollide = false
        end
    end
end)

-- ══════════════════════════════════════════════════════
--  UNLIMITED AMMO + AUTO RELOAD
-- ══════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not CFG.UnlimitedAmmo and not CFG.AutoReload then return end
    local char = getChar(LP); if not char then return end
    local tool = char:FindFirstChildOfClass("Tool"); if not tool then return end
    for _, v in ipairs(tool:GetDescendants()) do
        local n = v.Name:lower()
        if v:IsA("IntValue") or v:IsA("NumberValue") then
            if CFG.UnlimitedAmmo
            and (n:find("ammo") or n:find("bullet") or n:find("mag")) then
                if v.Value < 5 then v.Value = 999 end
            end
            if CFG.AutoReload
            and (n:find("reload") or n:find("reloading")) then
                if v.Value == 1 then v.Value = 0 end
            end
        end
        if v:IsA("BoolValue") then
            local bn = v.Name:lower()
            if CFG.AutoReload
            and (bn:find("reload") or bn:find("reloading")) then
                v.Value = false
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════
--  AUTO PICKUP
-- ══════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not CFG.AutoPickup then return end
    local root = getRoot(LP); if not root then return end
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
                local part   = obj:IsA("BasePart") and obj
                               or obj:FindFirstChildOfClass("BasePart")
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

-- ══════════════════════════════════════════════════════
--  AUTO RESPAWN
-- ══════════════════════════════════════════════════════
local function nearestLootbox()
    local root = getRoot(LP); if not root then return nil end
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
                local part = box:IsA("BasePart") and box
                             or box:FindFirstChildOfClass("BasePart")
                if part then
                    local d = (root.Position - part.Position).Magnitude
                    if d < bDist then best=part bDist=d end
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
    hookInfiniteJump(char)
    if CFG.AutoRespawnLoot then
        task.wait(0.5)
        local lb = nearestLootbox()
        if lb then root.CFrame = lb.CFrame + Vector3.new(0,5,0) end
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
if LP.Character then
    task.spawn(function() onCharAdded(LP.Character) end)
end

-- ══════════════════════════════════════════════════════
--  ESP
-- ══════════════════════════════════════════════════════
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
        e.box:Remove() e.name:Remove() e.dist:Remove()
        espObjects[player] = nil
    end
end
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then makeESP(p) end
end
Players.PlayerAdded:Connect(function(p) if p~=LP then makeESP(p) end end)
Players.PlayerRemoving:Connect(removeESP)

-- ══════════════════════════════════════════════════════
--  MAIN RENDER LOOP
-- ══════════════════════════════════════════════════════
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

-- ══════════════════════════════════════════════════════
--  GUI — destroy old instance first
-- ══════════════════════════════════════════════════════
if CoreGui:FindFirstChild("PrimodaxGUI") then
    CoreGui:FindFirstChild("PrimodaxGUI"):Destroy()
end

local SG = Instance.new("ScreenGui")
SG.Name            = "PrimodaxGUI"
SG.ResetOnSpawn    = false
SG.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset  = true
SG.Parent          = CoreGui

-- ──────────────────────────────────────────────────────
--  FLOATING CIRCLE TOGGLE BUTTON (always visible, draggable)
-- ──────────────────────────────────────────────────────
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size              = UDim2.new(0, 56, 0, 56)
toggleBtn.Position          = UDim2.new(0.5, -28, 1, -90)   -- bottom-center
toggleBtn.BackgroundColor3  = Color3.fromRGB(255, 215, 0)
toggleBtn.TextColor3        = Color3.fromRGB(0, 0, 0)
toggleBtn.Text              = "⚡"
toggleBtn.TextSize          = 22
toggleBtn.Font              = Enum.Font.GothamBold
toggleBtn.ZIndex            = 10
toggleBtn.Active            = true
toggleBtn.Parent            = SG
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)

-- make toggle button draggable
do
    local drag, dragStart, startPos = false, nil, nil
    toggleBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch
        or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            drag      = true
            dragStart = inp.Position
            startPos  = toggleBtn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType == Enum.UserInputType.Touch
        or inp.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta  = inp.Position - dragStart
            toggleBtn.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch
        or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = false
        end
    end)
end

-- ──────────────────────────────────────────────────────
--  MAIN PANEL (hidden by default)
-- ──────────────────────────────────────────────────────
local MF = Instance.new("Frame")
MF.Size              = UDim2.new(0, 270, 0, 530)
MF.Position          = UDim2.new(0.5, -135, 0.5, -265)   -- center screen
MF.BackgroundColor3  = Color3.fromRGB(12, 12, 12)
MF.BorderSizePixel   = 0
MF.Active            = true
MF.Draggable         = true
MF.Visible           = false    -- hidden until toggle pressed
MF.ZIndex            = 5
MF.Parent            = SG
Instance.new("UICorner", MF).CornerRadius = UDim.new(0, 12)

-- ── BACKGROUND IMAGE ──────────────────────────────────
-- FILL: replace IMAGE_URL_HERE with your direct image link
-- e.g. "https://i.imgur.com/xxxxxxx.png"
-- or a Roblox asset: "rbxassetid://NUMBERHERE"
local BG_URL = "IMAGE_URL_HERE"  -- << FILL THIS

local bgImg = Instance.new("ImageLabel")
bgImg.Size               = UDim2.new(1, 0, 1, 0)
bgImg.Position           = UDim2.new(0, 0, 0, 0)
bgImg.BackgroundTransparency = 1
bgImg.Image              = BG_URL
bgImg.ImageTransparency  = 0.25   -- 0 = full opaque, 1 = invisible; tweak to taste
bgImg.ScaleType          = Enum.ScaleType.Crop   -- fills panel, crops edges
bgImg.ZIndex             = 1      -- sits behind everything else in MF
bgImg.Parent             = MF
Instance.new("UICorner", bgImg).CornerRadius = UDim.new(0, 12)
-- ─────────────────────────────────────────────────────

local stroke = Instance.new("UIStroke")
stroke.Color     = Color3.fromRGB(255, 215, 0)
stroke.Thickness = 1.5
stroke.Parent    = MF

-- title bar
local TB = Instance.new("Frame")
TB.Size             = UDim2.new(1, 0, 0, 50)
TB.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
TB.BorderSizePixel  = 0
TB.ZIndex           = 6
TB.Parent           = MF
Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 12)

local TL = Instance.new("TextLabel")
TL.Size               = UDim2.new(1, -60, 0, 26)
TL.Position           = UDim2.new(0, 8, 0, 2)
TL.BackgroundTransparency = 1
TL.Text               = "⚡ PRIMODAXVGRANT ⚡"
TL.TextColor3         = Color3.fromRGB(0, 0, 0)
TL.TextSize           = 14
TL.Font               = Enum.Font.GothamBold
TL.TextXAlignment     = Enum.TextXAlignment.Left
TL.ZIndex             = 7
TL.Parent             = TB

local SL = Instance.new("TextLabel")
SL.Size               = UDim2.new(1, -60, 0, 18)
SL.Position           = UDim2.new(0, 8, 0, 28)
SL.BackgroundTransparency = 1
SL.Text               = "Vagrant Survival | v4.1 | ADMIN: PRIMODAX"
SL.TextColor3         = Color3.fromRGB(30, 30, 30)
SL.TextSize           = 10
SL.Font               = Enum.Font.Gotham
SL.TextXAlignment     = Enum.TextXAlignment.Left
SL.ZIndex             = 7
SL.Parent             = TB

-- close X in title bar
local XBtn = Instance.new("TextButton")
XBtn.Size              = UDim2.new(0, 36, 0, 36)
XBtn.Position          = UDim2.new(1, -42, 0, 7)
XBtn.BackgroundColor3  = Color3.fromRGB(30, 30, 30)
XBtn.Text              = "✕"
XBtn.TextColor3        = Color3.fromRGB(255, 215, 0)
XBtn.TextSize          = 16
XBtn.Font              = Enum.Font.GothamBold
XBtn.ZIndex            = 8
XBtn.Parent            = TB
Instance.new("UICorner", XBtn).CornerRadius = UDim.new(1, 0)
XBtn.MouseButton1Click:Connect(function() MF.Visible = false end)

-- toggle logic
local menuOpen = false
toggleBtn.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    MF.Visible = menuOpen
end)

-- ──────────────────────────────────────────────────────
--  SCROLL CONTENT
-- ──────────────────────────────────────────────────────
local SF = Instance.new("ScrollingFrame")
SF.Size                  = UDim2.new(1, -10, 1, -58)
SF.Position              = UDim2.new(0, 5, 0, 54)
SF.BackgroundTransparency = 1
SF.ScrollBarThickness    = 3
SF.ScrollBarImageColor3  = Color3.fromRGB(255, 215, 0)
SF.CanvasSize            = UDim2.new(0,0,0,0)
SF.AutomaticCanvasSize   = Enum.AutomaticSize.Y
SF.ZIndex                = 6
SF.Parent                = MF

local Layout = Instance.new("UIListLayout")
Layout.Padding    = UDim.new(0, 5)
Layout.SortOrder  = Enum.SortOrder.LayoutOrder
Layout.Parent     = SF

local Pad = Instance.new("UIPadding")
Pad.PaddingTop   = UDim.new(0, 5)
Pad.PaddingLeft  = UDim.new(0, 5)
Pad.PaddingRight = UDim.new(0, 5)
Pad.Parent       = SF

-- ──────────────────────────────────────────────────────
--  UI HELPERS
-- ──────────────────────────────────────────────────────
local statusLabel = nil   -- assigned below after section builders

local function makeSection(text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size              = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundColor3  = Color3.fromRGB(30, 30, 30)
    lbl.Text              = text
    lbl.TextColor3        = Color3.fromRGB(255, 215, 0)
    lbl.TextSize          = 11
    lbl.Font              = Enum.Font.GothamBold
    lbl.LayoutOrder       = order
    lbl.ZIndex            = 6
    lbl.Parent            = SF
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 4)
end

local toggleRefs = {}   -- key → btn, for refresh after config load

local function makeToggle(label, key, order, onToggle)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = CFG[key] and Color3.fromRGB(255,215,0)
                                     or Color3.fromRGB(35,35,35)
    btn.Text         = label..": "..(CFG[key] and "ON" or "OFF")
    btn.TextColor3   = CFG[key] and Color3.fromRGB(0,0,0)
                                 or Color3.fromRGB(200,200,200)
    btn.TextSize     = 12
    btn.Font         = Enum.Font.GothamBold
    btn.LayoutOrder  = order
    btn.ZIndex       = 6
    btn.Parent       = SF
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(255,215,0) s.Thickness = 0.5 s.Parent = btn

    local function refresh()
        btn.BackgroundColor3 = CFG[key] and Color3.fromRGB(255,215,0)
                                         or Color3.fromRGB(35,35,35)
        btn.TextColor3 = CFG[key] and Color3.fromRGB(0,0,0)
                                    or Color3.fromRGB(200,200,200)
        btn.Text = label..": "..(CFG[key] and "ON" or "OFF")
    end
    toggleRefs[key] = refresh

    btn.MouseButton1Click:Connect(function()
        CFG[key] = not CFG[key]
        refresh()
        if onToggle then onToggle(CFG[key]) end
    end)
end

-- Slider: returns the frame; live-updates CFG[key] (integer min..max)
local function makeSlider(label, key, minVal, maxVal, order)
    local container = Instance.new("Frame")
    container.Size             = UDim2.new(1, 0, 0, 52)
    container.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    container.LayoutOrder      = order
    container.ZIndex           = 6
    container.Parent           = SF
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1, -10, 0, 20)
    lbl.Position           = UDim2.new(0, 8, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text               = label..": "..tostring(CFG[key])
    lbl.TextColor3         = Color3.fromRGB(255, 215, 0)
    lbl.TextSize           = 11
    lbl.Font               = Enum.Font.Gotham
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.ZIndex             = 7
    lbl.Parent             = container

    local track = Instance.new("Frame")
    track.Size             = UDim2.new(1, -16, 0, 8)
    track.Position         = UDim2.new(0, 8, 0, 34)
    track.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    track.ZIndex           = 7
    track.Parent           = container
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    local startFrac = (CFG[key] - minVal) / (maxVal - minVal)
    fill.Size             = UDim2.new(startFrac, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    fill.ZIndex           = 8
    fill.Parent           = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("TextButton")
    knob.Size             = UDim2.new(0, 16, 0, 16)
    knob.AnchorPoint      = Vector2.new(0.5, 0.5)
    knob.Position         = UDim2.new(startFrac, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Text             = ""
    knob.ZIndex           = 9
    knob.Parent           = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local sliding = false
    local function updateSlider(inputPos)
        local absPos  = track.AbsolutePosition
        local absSize = track.AbsoluteSize
        local frac    = math.clamp((inputPos.X - absPos.X) / absSize.X, 0, 1)
        local value   = math.floor(minVal + frac * (maxVal - minVal) + 0.5)
        CFG[key]      = value
        fill.Size     = UDim2.new(frac, 0, 1, 0)
        knob.Position = UDim2.new(frac, 0, 0.5, 0)
        lbl.Text      = label..": "..tostring(value)
    end

    knob.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch
        or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
        end
    end)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch
        or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
            updateSlider(inp.Position)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if sliding and (inp.UserInputType == Enum.UserInputType.Touch
        or inp.UserInputType == Enum.UserInputType.MouseMovement) then
            updateSlider(inp.Position)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch
        or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end)
end

-- ──────────────────────────────────────────────────────
--  BUILD MENU ITEMS
-- ──────────────────────────────────────────────────────
makeSection("── COMBAT ──", 1)
makeToggle("🎯 Silent Aim",      "SilentAim",     2)
makeToggle("🔫 Aimbot [Hold Q]", "Aimbot",        3)
makeSlider("⭕ Aimbot FOV",      "AimbotFOV",     10, 500, 4)
makeSlider("🎯 Silent FOV",      "SilentAimFOV",  10, 500, 5)
makeToggle("🔋 Unlimited Ammo",  "UnlimitedAmmo", 6)
makeToggle("🔄 Auto Reload",     "AutoReload",    7)

makeSection("── MOVEMENT ──", 10)
makeToggle("🐇 Infinite Jump",   "InfiniteJump",  11)
makeToggle("👻 Noclip [Walls]",  "Noclip",        12)

makeSection("── UTILITY ──", 20)
makeToggle("🧲 Auto Pickup",     "AutoPickup",    21)
makeToggle("💀 Auto Respawn",    "AutoRespawn",   22)
makeToggle("📦 Respawn @ Loot",  "AutoRespawnLoot", 23)

makeSection("── VISUAL ──", 30)
makeToggle("🟥 ESP",             "ESPEnabled",    31)
makeToggle("⭕ Show FOV",        "ShowFOV",       32)

makeSection("── BYPASS ──", 40)
makeToggle("🛡️  Anti Kick",       "AntiKick",      41)
makeToggle("👁️  Hide Executor",    "HideExecutor",  42)

makeSection("── CONFIG ──", 50)

-- status line
local statLbl = Instance.new("TextLabel")
statLbl.Size               = UDim2.new(1, 0, 0, 20)
statLbl.BackgroundTransparency = 1
statLbl.Text               = ""
statLbl.TextColor3         = Color3.fromRGB(180, 255, 180)
statLbl.TextSize           = 10
statLbl.Font               = Enum.Font.Gotham
statLbl.LayoutOrder        = 51
statLbl.ZIndex             = 6
statLbl.Parent             = SF
statusLabel = statLbl

local function setStatus(msg)
    statLbl.Text = msg
    task.delay(3, function() if statLbl.Text == msg then statLbl.Text="" end end)
end

local function refreshAllToggles()
    for key, fn in pairs(toggleRefs) do fn() end
end

-- Save button
local saveBtn = Instance.new("TextButton")
saveBtn.Size             = UDim2.new(0.48, 0, 0, 30)
saveBtn.BackgroundColor3 = Color3.fromRGB(35, 120, 60)
saveBtn.Text             = "💾 Save"
saveBtn.TextColor3       = Color3.fromRGB(255,255,255)
saveBtn.TextSize         = 12
saveBtn.Font             = Enum.Font.GothamBold
saveBtn.LayoutOrder      = 52
saveBtn.ZIndex           = 6
saveBtn.Parent           = SF
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 6)
saveBtn.MouseButton1Click:Connect(function()
    local ok, msg = saveConfig()
    setStatus(ok and "✅ "..msg or "❌ "..msg)
end)

-- Load button
local loadBtn = Instance.new("TextButton")
loadBtn.Size             = UDim2.new(0.48, 0, 0, 30)
loadBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 160)
loadBtn.Text             = "📂 Load"
loadBtn.TextColor3       = Color3.fromRGB(255,255,255)
loadBtn.TextSize         = 12
loadBtn.Font             = Enum.Font.GothamBold
loadBtn.LayoutOrder      = 53
loadBtn.ZIndex           = 6
loadBtn.Parent           = SF
Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 6)
loadBtn.MouseButton1Click:Connect(function()
    local ok, msg = loadConfig()
    if ok then refreshAllToggles() end
    setStatus(ok and "✅ "..msg or "❌ "..msg)
end)

-- Export to clipboard
local expBtn = Instance.new("TextButton")
expBtn.Size             = UDim2.new(0.48, 0, 0, 30)
expBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 35)
expBtn.Text             = "📋 Export"
expBtn.TextColor3       = Color3.fromRGB(255,255,255)
expBtn.TextSize         = 12
expBtn.Font             = Enum.Font.GothamBold
expBtn.LayoutOrder      = 54
expBtn.ZIndex           = 6
expBtn.Parent           = SF
Instance.new("UICorner", expBtn).CornerRadius = UDim.new(0, 6)
expBtn.MouseButton1Click:Connect(function()
    local ok, msg = exportConfig()
    setStatus(ok and "✅ "..msg or "❌ "..msg)
end)

-- Import from clipboard
local impBtn = Instance.new("TextButton")
impBtn.Size             = UDim2.new(0.48, 0, 0, 30)
impBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 120)
impBtn.Text             = "📥 Import"
impBtn.TextColor3       = Color3.fromRGB(255,255,255)
impBtn.TextSize         = 12
impBtn.Font             = Enum.Font.GothamBold
impBtn.LayoutOrder      = 55
impBtn.ZIndex           = 6
impBtn.Parent           = SF
Instance.new("UICorner", impBtn).CornerRadius = UDim.new(0, 6)
impBtn.MouseButton1Click:Connect(function()
    -- try getclipboard (Fluxus/Delta)
    local json = ""
    if getclipboard then
        local ok, s = pcall(getclipboard)
        if ok then json = s end
    end
    if json == "" then
        setStatus("❌ paste JSON into executor console: importConfig(str)")
        return
    end
    local ok, msg = importConfig(json)
    if ok then refreshAllToggles() end
    setStatus(ok and "✅ "..msg or "❌ "..msg)
end)

print("✅ PRIMODAXVGRANT v4.1 loaded — Vagrant Survival | ADMIN: PRIMODAX")
