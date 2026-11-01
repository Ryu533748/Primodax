-- ██████╗ ██████╗ ██╗███╗   ███╗ ██████╗ ██████╗  █████╗ ██╗  ██╗
-- ██╔══██╗██╔══██╗██║████╗ ████║██╔═══██╗██╔══██╗██╔══██╗╚██╗██╔╝
-- ██████╔╝██████╔╝██║██╔████╔██║██║   ██║██║  ██║███████║ ╚███╔╝
-- ██╔═══╝ ██╔══██╗██║██║╚██╔╝██║██║   ██║██║  ██║██╔══██║ ██╔██╗
-- ██║     ██║  ██║██║██║ ╚═╝ ██║╚██████╔╝██████╔╝██║  ██║██╔╝ ██╗
-- ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
-- PRIMODAX v6.0 | Vagrant Survival v10 — Team Stultus
-- Author  : BoboyTagaAquarius
-- Executor : Delta, Arceus X, Fluxus

-- ══════════════════════════════════════════════════════
--  SERVICES
-- ══════════════════════════════════════════════════════
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")
local Workspace         = game:GetService("Workspace")
local HttpService       = game:GetService("HttpService")

local LP  = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

-- ══════════════════════════════════════════════════════
--  CONFIG
-- ══════════════════════════════════════════════════════
local CFG = {
    SilentAim        = false,
    SilentAimPart    = "Head",
    SilentAimFOV     = 120,
    Aimbot           = false,
    AimbotSmoothing  = 0.08,
    AimbotPart       = "Head",
    AimbotFOV        = 180,
    ShowFOVCircle    = true,
    ShowAimbotFOV    = true,
    UnlimitedAmmo    = false,
    AutoReload       = false,
    AutoPickup       = false,
    AutoPickupRange  = 40,
    AutoRespawn      = false,
    AutoRespawnLoot  = true,
    AutoSprint       = false,
    SprintSpeed      = 28,
    FloatMode        = false,
    FloatPower       = 55,
    Noclip           = false,
    ESPEnabled       = false,
    ESPColor         = Color3.fromRGB(255, 50, 50),
    AntiKick         = true,
    HideExecutor     = true,
}

local CONFIG_FILE  = "primodax_v6_cfg.json"
local PERSIST_KEYS = {
    "SilentAim","SilentAimFOV","Aimbot","AimbotFOV","AimbotSmoothing",
    "ShowFOVCircle","ShowAimbotFOV",
    "UnlimitedAmmo","AutoReload","AutoPickup","AutoPickupRange",
    "AutoRespawn","AutoRespawnLoot","AutoSprint","SprintSpeed",
    "FloatMode","FloatPower","Noclip","ESPEnabled","AntiKick","HideExecutor",
}

local function cfgToTable()
    local t = {} for _,k in ipairs(PERSIST_KEYS) do t[k] = CFG[k] end return t
end
local function applyTable(t)
    for _,k in ipairs(PERSIST_KEYS) do if t[k] ~= nil then CFG[k] = t[k] end end
end
local function saveConfig()
    local ok, json = pcall(function() return HttpService:JSONEncode(cfgToTable()) end)
    if not ok then return false, "encode fail" end
    if writefile then local ok2 = pcall(writefile, CONFIG_FILE, json) if ok2 then return true end end
    if setclipboard then pcall(setclipboard, json) return true end
    return false, "no writefile/setclipboard"
end
local function loadConfig()
    if readfile then
        local ok, raw = pcall(readfile, CONFIG_FILE)
        if ok and raw and #raw > 2 then
            local ok2, t = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok2 and t then applyTable(t) return true end
        end
    end
    return false
end
pcall(loadConfig)

-- ══════════════════════════════════════════════════════
--  UTILITY
-- ══════════════════════════════════════════════════════
local function getChar(p)   return p and p.Character end
local function getHum(p)    local c = getChar(p) return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot(p)   local c = getChar(p) return c and c:FindFirstChild("HumanoidRootPart") end
local function getPart(p,n) local c = getChar(p) return c and c:FindFirstChild(n) end
local function isAlive(p)   local h = getHum(p) return h and h.Health > 0 end

local function toScreen(pos)
    local s, on = Cam:WorldToViewportPoint(pos) return Vector2.new(s.X, s.Y), on
end
local function screenCenter()
    return Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
end
local function dist2D(sp) return (sp - screenCenter()).Magnitude end

local function getNearestEnemy(fovR, part)
    local best, bDist, bPos = nil, fovR, nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isAlive(p) then
            local pt = getPart(p, part or "Head")
            if pt then
                local sp, on = toScreen(pt.Position)
                if on then
                    local d = dist2D(sp)
                    if d < bDist then best = p bDist = d bPos = pt.Position end
                end
            end
        end
    end
    return best, bPos
end

-- ══════════════════════════════════════════════════════
--  FOV CIRCLES
-- ══════════════════════════════════════════════════════
local fovCircle, aimbotCircle
if Drawing then
    fovCircle            = Drawing.new("Circle")
    fovCircle.Thickness  = 1.5
    fovCircle.Color      = Color3.fromRGB(255, 215, 0)
    fovCircle.Filled     = false
    fovCircle.Visible    = false
    fovCircle.Radius     = CFG.SilentAimFOV
    fovCircle.Position   = screenCenter()

    aimbotCircle           = Drawing.new("Circle")
    aimbotCircle.Thickness = 1.2
    aimbotCircle.Color     = Color3.fromRGB(220, 220, 220)
    aimbotCircle.Filled    = false
    aimbotCircle.Visible   = false
    aimbotCircle.Radius    = CFG.AimbotFOV
    aimbotCircle.Position  = screenCenter()
end

-- ══════════════════════════════════════════════════════
--  BYPASS: HIDE EXECUTOR
-- ══════════════════════════════════════════════════════
pcall(function()
    if not CFG.HideExecutor then return end
    local EKEYS = {
        "syn","fluxus","DELTA","Delta","delta","getgenv","is_executor_closure",
        "rconsole","hookfunction","hookmetamethod","checkcaller","cloneref",
        "FLUXUS_KEY","DELTA_KEY","ARCEUS_KEY","KRNL_LOADED","KRNL_KEY",
        "Seliware","seliware","SELIWARE","Hydrogen","hydrogen","Xeno","xeno",
    }
    for _, k in ipairs(EKEYS) do pcall(function() _G[k] = nil end) end
    local ok, mt = pcall(getrawmetatable, game) if not ok then return end
    pcall(setreadonly, mt, false)
    local _oi = mt.__index
    mt.__index = newcclosure(function(self, k)
        local lk = tostring(k):lower()
        if lk == "executor" or lk == "syn" or lk == "fluxus" or lk == "delta"
        or lk == "getgenv" or lk == "is_executor_closure" or lk == "krnl_loaded"
        or lk == "hydrogen" or lk == "seliware" or lk == "xeno"
        or lk:find("executor") then return nil end
        return _oi(self, k)
    end)
    pcall(setreadonly, mt, true)
end)

-- ══════════════════════════════════════════════════════
--  BYPASS: __namecall — anti-kick + silent aim
--  checkcaller() guard prevents double-hook loops.
--  Args copied to fresh table before unpack.
-- ══════════════════════════════════════════════════════
local silentTarget = nil

local _nc
_nc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    if checkcaller and checkcaller() then return _nc(self, ...) end
    local method = getnamecallmethod()
    local args   = { ... }

    if method == "FireServer" or method == "InvokeServer" then
        -- ── anti-kick filter ──────────────────────────────────────────
        if CFG.AntiKick then
            local n = (typeof(self) == "Instance" and self.Name or ""):lower()
            local KICK_PATTERNS = {
                "kick","ban","cheat","detect","anticheat","report","flag",
                "speed","velocity","noclip","collide","walkspeed","movespeed",
                "exploit","hack","sanity","integrity","verify","position",
                "teleport","tphack","sprint","movement","physics","remote",
                "check","validation","playercheck","playervalidation",
                "abusecheck","suspicious","anomaly","watchdog","guardian",
            }
            for _, pat in ipairs(KICK_PATTERNS) do
                if n:find(pat) then return nil end
            end
        end

        -- ── silent aim redirect ───────────────────────────────────────
        if CFG.SilentAim and silentTarget and isAlive(silentTarget) then
            local part = getPart(silentTarget, CFG.SilentAimPart)
            if part then
                local newArgs = {}
                for i, v in ipairs(args) do
                    if typeof(v) == "Vector3" then
                        newArgs[i] = part.Position
                    elseif typeof(v) == "Instance" and v:IsA("BasePart") then
                        newArgs[i] = part
                    elseif typeof(v) == "Instance" and v:IsA("Model") then
                        newArgs[i] = getChar(silentTarget) or v
                    else
                        newArgs[i] = v
                    end
                end
                return _nc(self, table.unpack(newArgs))
            end
        end
    end

    return _nc(self, table.unpack(args))
end))

-- ══════════════════════════════════════════════════════
--  AIMBOT v6 — camera-safe, no CameraType override
--  Computes a CFrame nudge via viewport delta so the
--  default Roblox camera chain stays intact.
--  Q to hold on PC; mobile button wired in GUI.
-- ══════════════════════════════════════════════════════
local aimbotOn    = false
local aimbotConn  = nil

local function startAimbotLoop()
    if aimbotConn then aimbotConn:Disconnect() end
    aimbotConn = RunService.RenderStepped:Connect(function()
        if not CFG.Aimbot or not aimbotOn then return end
        local _, bPos = getNearestEnemy(CFG.AimbotFOV, CFG.AimbotPart)
        if not bPos then return end

        local cf     = Cam.CFrame
        local target = CFrame.new(cf.Position, bPos)
        -- smooth lerp — does NOT set CameraType; works with default camera
        Cam.CFrame = cf:Lerp(target, math.clamp(CFG.AimbotSmoothing, 0.01, 1))
    end)
end

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.Q and CFG.Aimbot then
        aimbotOn = true
        startAimbotLoop()
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.KeyCode == Enum.KeyCode.Q then
        aimbotOn = false
    end
end)

local function setAimbotOn(state)
    aimbotOn = state
    if state and CFG.Aimbot then startAimbotLoop() end
end

-- ══════════════════════════════════════════════════════
--  FLOAT MODE
-- ══════════════════════════════════════════════════════
local mobileJumpHeld = false
local function bindFloatHook(char)
    local hum = char:FindFirstChildOfClass("Humanoid") if not hum then return end
    hum.StateChanged:Connect(function(_, new)
        if CFG.FloatMode and
        (new == Enum.HumanoidStateType.Jumping or new == Enum.HumanoidStateType.Freefall) then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)
end
UserInputService.JumpRequest:Connect(function()
    if CFG.FloatMode then
        mobileJumpHeld = true
        task.delay(0.15, function() mobileJumpHeld = false end)
    end
end)
RunService.Stepped:Connect(function(_, dt)
    if not CFG.FloatMode then return end
    local root = getRoot(LP) if not root then return end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) or mobileJumpHeld then
        root.CFrame = root.CFrame + Vector3.new(0, CFG.FloatPower * dt, 0)
    end
end)

-- ══════════════════════════════════════════════════════
--  NOCLIP — 100 ms throttle
-- ══════════════════════════════════════════════════════
local noclipTimer = 0
RunService.Stepped:Connect(function(_, dt)
    if not CFG.Noclip then return end
    noclipTimer = noclipTimer + dt
    if noclipTimer < 0.1 then return end
    noclipTimer = 0
    local char = getChar(LP) if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            v.CanCollide = false
        end
    end
end)

-- ══════════════════════════════════════════════════════
--  AUTO SPRINT — lerp ramp
-- ══════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function(dt)
    local hum = getHum(LP) if not hum then return end
    if not CFG.AutoSprint then
        if hum.WalkSpeed > 16 then hum.WalkSpeed = math.max(16, hum.WalkSpeed - 2 * dt * 20) end
        return
    end
    if hum.WalkSpeed < CFG.SprintSpeed then
        hum.WalkSpeed = math.min(CFG.SprintSpeed, hum.WalkSpeed + 1)
    end
end)

-- ══════════════════════════════════════════════════════
--  UNLIMITED AMMO + AUTO RELOAD
-- ══════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not CFG.UnlimitedAmmo and not CFG.AutoReload then return end
    local char = getChar(LP) if not char then return end
    local tool = char:FindFirstChildOfClass("Tool") if not tool then return end
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
            if CFG.AutoReload and (bn:find("reload") or bn:find("reloading")) then v.Value = false end
        end
    end
end)

-- ══════════════════════════════════════════════════════
--  AUTO PICKUP
-- ══════════════════════════════════════════════════════
local PICKUP_FOLDERS = {
    "Loots","Items","Drops","Pickups","Collectibles","Weapons","Loot",
    "Spawns","WorldItems","GroundItems","DroppedItems","Interactables",
    "Resources","Ammo","Supplies",
}
local function tryPickup(obj)
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("ProximityPrompt") then pcall(fireproximityprompt, v) end
        if v:IsA("ClickDetector")   then pcall(fireclickdetector, v) end
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("pick") or n:find("loot") or n:find("collect")
            or n:find("grab") or n:find("take") or n:find("item") then
                pcall(function() v:FireServer() end)
            end
        end
    end
end
local function scanFolder(folder, root)
    if not folder then return end
    for _, obj in ipairs(folder:GetChildren()) do
        local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
        if part and (root.Position - part.Position).Magnitude <= CFG.AutoPickupRange then
            tryPickup(obj)
        end
    end
end
RunService.Heartbeat:Connect(function()
    if not CFG.AutoPickup then return end
    local root = getRoot(LP) if not root then return end
    for _, fname in ipairs(PICKUP_FOLDERS) do scanFolder(Workspace:FindFirstChild(fname), root) end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if not obj:IsA("Model") or obj == getChar(LP) then continue end
        local part = obj:FindFirstChildOfClass("BasePart")
        if part and (root.Position - part.Position).Magnitude <= CFG.AutoPickupRange then
            tryPickup(obj)
        end
    end
end)

-- ══════════════════════════════════════════════════════
--  AUTO RESPAWN — improved own-bag detection
--  Priority: attribute "Owner" → name contains LP.Name
--            → folder scan → nearest generic bag
-- ══════════════════════════════════════════════════════
local LOOT_FOLDERS   = {"LootBoxes","LootZones","Crates","Chests","Bags","DroppedBags","PlayerLoot"}
local RESPAWN_REMOTES = {"Respawn","RespawnPlayer","PlayerRespawn","RevivePlayer","Revive","Restart"}

local function findOwnBag()
    local root = getRoot(LP) if not root then return nil end
    local lname = LP.Name:lower()
    local best, bDist = nil, math.huge

    -- pass 1: check Owner attribute (Vagrant-style bags often carry this)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local attr = pcall(function() return obj:GetAttribute("Owner") end)
        local ownAttr
        pcall(function() ownAttr = obj:GetAttribute("Owner") end)
        if ownAttr and tostring(ownAttr):lower() == lname then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
            if part then
                local d = (root.Position - part.Position).Magnitude
                if d < bDist then best = part bDist = d end
            end
        end
    end
    if best then return best end

    -- pass 2: name contains player name
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if n:find(lname) and (obj:IsA("BasePart") or obj:IsA("Model")) then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
            if part then
                local d = (root.Position - part.Position).Magnitude
                if d < bDist then best = part bDist = d end
            end
        end
    end
    if best then return best end

    -- pass 3: scan known loot folders, nearest bag
    for _, fname in ipairs(LOOT_FOLDERS) do
        local f = Workspace:FindFirstChild(fname)
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

local function doAutoRespawn()
    task.wait(3)
    -- try remote first
    for _, rname in ipairs(RESPAWN_REMOTES) do
        local rem = ReplicatedStorage:FindFirstChild(rname) or Workspace:FindFirstChild(rname)
        if rem and rem:IsA("RemoteEvent") then
            pcall(function() rem:FireServer() end)
            break
        end
    end
    task.wait(1)
    if not isAlive(LP) then pcall(function() LP:LoadCharacter() end) end

    if CFG.AutoRespawnLoot then
        task.wait(2)  -- wait for character to fully load
        local nr = getRoot(LP)
        if nr then
            local lb = findOwnBag()
            if lb then
                nr.CFrame = lb.CFrame + Vector3.new(0, 3, 0)
                task.wait(0.3)
                -- attempt to auto-loot the bag
                tryPickup(lb.Parent or lb)
            end
        end
    end
end

local function bindCharHooks(char)
    bindFloatHook(char)
    local hum = char:WaitForChild("Humanoid", 10) if not hum then return end
    hum.Died:Connect(function()
        if CFG.AutoRespawn then task.spawn(doAutoRespawn) end
    end)
end

LP.CharacterAdded:Connect(bindCharHooks)
if LP.Character then task.spawn(function() bindCharHooks(LP.Character) end) end

-- ══════════════════════════════════════════════════════
--  ESP
-- ══════════════════════════════════════════════════════
local espObjects = {}
local function makeESP(player)
    if not Drawing then return end
    local box   = Drawing.new("Square")
    box.Visible = false box.Color = CFG.ESPColor box.Thickness = 1 box.Filled = false

    local name = Drawing.new("Text")
    name.Visible = false name.Color = Color3.fromRGB(255,255,255)
    name.Size = 13 name.Center = true name.Outline = true

    local dist = Drawing.new("Text")
    dist.Visible = false dist.Color = Color3.fromRGB(255,215,0)
    dist.Size = 11 dist.Center = true dist.Outline = true

    espObjects[player] = { box = box, name = name, dist = dist }
end
local function removeESP(player)
    local e = espObjects[player]
    if e then e.box:Remove() e.name:Remove() e.dist:Remove() espObjects[player] = nil end
end
for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then makeESP(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LP then makeESP(p) end end)
Players.PlayerRemoving:Connect(removeESP)

-- ══════════════════════════════════════════════════════
--  GUI — iPad-aware, minimizable, two-column layout
--  DisplayOrder = -1 so it never eats joystick touches.
--  Menu drag via title bar only.
-- ══════════════════════════════════════════════════════
pcall(function() CoreGui:FindFirstChild("PRIMODAX_V6"):Destroy() end)

local SG = Instance.new("ScreenGui")
SG.Name            = "PRIMODAX_V6"
SG.ResetOnSpawn    = false
SG.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
SG.DisplayOrder    = -1   -- below joystick layer
SG.Parent          = CoreGui

-- ── Viewport-responsive sizing ────────────────────────
local VP        = Cam.ViewportSize
local IS_IPAD   = (VP.X >= 1000)   -- iPad / tablet threshold
local MENU_W    = IS_IPAD and 560 or 360
local MENU_H    = IS_IPAD and 520 or 420
local FONT_SZ   = IS_IPAD and 17  or 14
local BTN_H     = IS_IPAD and 44  or 34
local CAT_W     = IS_IPAD and 150 or 110

-- ── Container ────────────────────────────────────────
local Main = Instance.new("Frame")
Main.Name            = "Main"
Main.Size            = UDim2.new(0, MENU_W, 0, MENU_H + 36)
Main.Position        = UDim2.new(0.5, -MENU_W/2, 0.5, -(MENU_H+36)/2)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent          = SG
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

-- ── Title bar ─────────────────────────────────────────
local TitleBar = Instance.new("Frame")
TitleBar.Size              = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3  = Color3.fromRGB(30, 30, 40)
TitleBar.BorderSizePixel   = 0
TitleBar.Parent            = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size             = UDim2.new(1, -80, 1, 0)
TitleLabel.Position         = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text             = "PRIMODAX v6  ·  Vagrant Survival"
TitleLabel.TextColor3       = Color3.fromRGB(220, 180, 60)
TitleLabel.Font             = Enum.Font.GothamBold
TitleLabel.TextSize         = IS_IPAD and 16 or 13
TitleLabel.TextXAlignment   = Enum.TextXAlignment.Left
TitleLabel.Parent           = TitleBar

-- ── Minimize button ───────────────────────────────────
local MinBtn = Instance.new("TextButton")
MinBtn.Size                 = UDim2.new(0, 34, 0, 26)
MinBtn.Position             = UDim2.new(1, -74, 0, 5)
MinBtn.BackgroundColor3     = Color3.fromRGB(50, 50, 70)
MinBtn.Text                 = "—"
MinBtn.TextColor3           = Color3.fromRGB(200,200,200)
MinBtn.Font                 = Enum.Font.GothamBold
MinBtn.TextSize             = 16
MinBtn.Parent               = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- ── Close button ──────────────────────────────────────
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size               = UDim2.new(0, 30, 0, 26)
CloseBtn.Position           = UDim2.new(1, -36, 0, 5)
CloseBtn.BackgroundColor3   = Color3.fromRGB(180, 40, 40)
CloseBtn.Text               = "✕"
CloseBtn.TextColor3         = Color3.fromRGB(255,255,255)
CloseBtn.Font               = Enum.Font.GothamBold
CloseBtn.TextSize           = 16
CloseBtn.Parent             = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

-- ── Body (two-column: cat list | feature panel) ──────
local Body = Instance.new("Frame")
Body.Name                  = "Body"
Body.Size                  = UDim2.new(1, 0, 1, -36)
Body.Position              = UDim2.new(0, 0, 0, 36)
Body.BackgroundTransparency = 1
Body.Parent                = Main

-- Left: category list
local CatList = Instance.new("ScrollingFrame")
CatList.Size               = UDim2.new(0, CAT_W, 1, 0)
CatList.BackgroundColor3   = Color3.fromRGB(20, 20, 28)
CatList.BorderSizePixel    = 0
CatList.ScrollBarThickness = 3
CatList.CanvasSize         = UDim2.new(0, 0, 0, 0)
CatList.AutomaticCanvasSize = Enum.AutomaticSize.Y
CatList.Parent             = Body

-- Right: feature panel
local FeatPanel = Instance.new("ScrollingFrame")
FeatPanel.Size             = UDim2.new(1, -CAT_W, 1, 0)
FeatPanel.Position         = UDim2.new(0, CAT_W, 0, 0)
FeatPanel.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
FeatPanel.BorderSizePixel  = 0
FeatPanel.ScrollBarThickness = 4
FeatPanel.CanvasSize       = UDim2.new(0, 0, 0, 0)
FeatPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
FeatPanel.Active           = false   -- prevent eating swipe gestures
FeatPanel.Parent           = Body

local CatLayout = Instance.new("UIListLayout")
CatLayout.SortOrder        = Enum.SortOrder.LayoutOrder
CatLayout.Padding          = UDim.new(0, 2)
CatLayout.Parent           = CatList

local FeatLayout = Instance.new("UIListLayout")
FeatLayout.SortOrder       = Enum.SortOrder.LayoutOrder
FeatLayout.Padding         = UDim.new(0, 4)
FeatLayout.Parent          = FeatPanel
local FeatPadding = Instance.new("UIPadding")
FeatPadding.PaddingLeft    = UDim.new(0, 8)
FeatPadding.PaddingRight   = UDim.new(0, 8)
FeatPadding.PaddingTop     = UDim.new(0, 6)
FeatPadding.Parent         = FeatPanel

-- ── Minimize / drag state ────────────────────────────
local minimized   = false
local fullHeight  = MENU_H + 36

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    local tw = TweenService:Create(Main,
        TweenInfo.new(0.25, Enum.EasingStyle.Quad),
        { Size = minimized
            and UDim2.new(0, MENU_W, 0, 36)
            or  UDim2.new(0, MENU_W, 0, fullHeight) })
    tw:Play()
    MinBtn.Text = minimized and "□" or "—"
    Body.Visible = not minimized
end)

CloseBtn.MouseButton1Click:Connect(function()
    SG:Destroy()
end)

-- Drag on title bar only (safe for mobile; does not eat joystick)
do
    local dragging, dragStart, startPos = false, nil, nil
    TitleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch
        or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = inp.Position
            startPos  = Main.Position
        end
    end)
    TitleBar.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.Touch
        or inp.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = inp.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    TitleBar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch
        or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ── Helper: build UI elements ────────────────────────
local activeCategory  = nil
local categoryButtons = {}
local categoryPanels  = {}

local function makeToggle(parent, label, getVal, setVal, order)
    local row = Instance.new("Frame")
    row.Size               = UDim2.new(1, 0, 0, BTN_H)
    row.BackgroundColor3   = Color3.fromRGB(22, 22, 32)
    row.BorderSizePixel    = 0
    row.LayoutOrder        = order or 0
    row.Parent             = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1, -70, 1, 0)
    lbl.Position           = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = label
    lbl.TextColor3         = Color3.fromRGB(210, 210, 210)
    lbl.Font               = Enum.Font.Gotham
    lbl.TextSize           = FONT_SZ
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Parent             = row

    local btn = Instance.new("TextButton")
    btn.Size               = UDim2.new(0, 56, 0, BTN_H - 10)
    btn.Position           = UDim2.new(1, -64, 0.5, -(BTN_H-10)/2)
    btn.Font               = Enum.Font.GothamBold
    btn.TextSize           = FONT_SZ - 1
    btn.Parent             = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local function refresh()
        local v = getVal()
        btn.Text              = v and "ON" or "OFF"
        btn.BackgroundColor3  = v and Color3.fromRGB(50,180,80) or Color3.fromRGB(160,50,50)
        btn.TextColor3        = Color3.fromRGB(255,255,255)
    end
    refresh()

    btn.MouseButton1Click:Connect(function()
        setVal(not getVal())
        refresh()
    end)
    return row, refresh
end

local function makeSlider(parent, label, min_, max_, getVal, setVal, order)
    local row = Instance.new("Frame")
    row.Size               = UDim2.new(1, 0, 0, BTN_H + 16)
    row.BackgroundColor3   = Color3.fromRGB(22, 22, 32)
    row.BorderSizePixel    = 0
    row.LayoutOrder        = order or 0
    row.Parent             = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1, -10, 0, FONT_SZ + 4)
    lbl.Position           = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3         = Color3.fromRGB(210,210,210)
    lbl.Font               = Enum.Font.Gotham
    lbl.TextSize           = FONT_SZ
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Parent             = row

    local track = Instance.new("Frame")
    track.Size             = UDim2.new(1, -20, 0, 8)
    track.Position         = UDim2.new(0, 10, 1, -16)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    track.BorderSizePixel  = 0
    track.Parent           = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(0, 4)

    local fill = Instance.new("Frame")
    fill.Size              = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3  = Color3.fromRGB(80, 150, 255)
    fill.BorderSizePixel   = 0
    fill.Parent            = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

    local function updateSlider(val)
        val = math.clamp(val, min_, max_)
        setVal(val)
        local pct = (val - min_) / (max_ - min_)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        lbl.Text  = label .. ": " .. tostring(math.round(val))
    end
    updateSlider(getVal())

    local sliding = false
    local function onInput(inp)
        local relX = inp.Position.X - track.AbsolutePosition.X
        local pct  = math.clamp(relX / track.AbsoluteSize.X, 0, 1)
        updateSlider(min_ + pct * (max_ - min_))
    end
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch
        or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true onInput(inp)
        end
    end)
    track.InputChanged:Connect(function(inp)
        if sliding and (inp.UserInputType == Enum.UserInputType.Touch
        or inp.UserInputType == Enum.UserInputType.MouseMovement) then onInput(inp) end
    end)
    track.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch
        or inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
    return row
end

local function makeAction(parent, label, fn, order)
    local btn = Instance.new("TextButton")
    btn.Size               = UDim2.new(1, 0, 0, BTN_H)
    btn.BackgroundColor3   = Color3.fromRGB(40, 80, 160)
    btn.Text               = label
    btn.TextColor3         = Color3.fromRGB(255,255,255)
    btn.Font               = Enum.Font.GothamBold
    btn.TextSize           = FONT_SZ
    btn.LayoutOrder        = order or 0
    btn.Parent             = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(fn)
    return btn
end

-- ── Category system ───────────────────────────────────
local function showCategory(name)
    for n, panel in pairs(categoryPanels) do
        panel.Visible = (n == name)
    end
    for n, catBtn in pairs(categoryButtons) do
        catBtn.BackgroundColor3 = (n == name)
            and Color3.fromRGB(60, 100, 200)
            or  Color3.fromRGB(28, 28, 40)
    end
    activeCategory = name
end

local function addCategory(name, icon, order)
    local btn = Instance.new("TextButton")
    btn.Size               = UDim2.new(1, 0, 0, BTN_H)
    btn.BackgroundColor3   = Color3.fromRGB(28, 28, 40)
    btn.Text               = icon .. " " .. name
    btn.TextColor3         = Color3.fromRGB(200,200,200)
    btn.Font               = Enum.Font.Gotham
    btn.TextSize           = IS_IPAD and 15 or 12
    btn.TextXAlignment     = Enum.TextXAlignment.Left
    btn.LayoutOrder        = order
    btn.Parent             = CatList
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 0)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.Parent = btn

    -- panel in FeatPanel
    local panel = Instance.new("Frame")
    panel.Size             = UDim2.new(1, 0, 0, 0)
    panel.BackgroundTransparency = 1
    panel.AutomaticSize   = Enum.AutomaticSize.Y
    panel.Visible         = false
    panel.Parent          = FeatPanel

    local pLayout = Instance.new("UIListLayout")
    pLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    pLayout.Padding       = UDim.new(0, 4)
    pLayout.Parent        = panel

    categoryButtons[name] = btn
    categoryPanels[name]  = panel

    btn.MouseButton1Click:Connect(function() showCategory(name) end)
    return panel
end

-- ══════════════════════════════════════════════════════
--  CATEGORIES & FEATURES
-- ══════════════════════════════════════════════════════

-- ── Combat ───────────────────────────────────────────
local pCombat = addCategory("Combat", "⚔", 1)
makeToggle(pCombat, "Silent Aim",
    function() return CFG.SilentAim end,
    function(v) CFG.SilentAim = v end, 1)
makeSlider(pCombat, "Silent FOV", 30, 300,
    function() return CFG.SilentAimFOV end,
    function(v) CFG.SilentAimFOV = v end, 2)
makeToggle(pCombat, "Show Silent FOV Circle",
    function() return CFG.ShowFOVCircle end,
    function(v) CFG.ShowFOVCircle = v end, 3)
makeToggle(pCombat, "Aimbot (hold Q)",
    function() return CFG.Aimbot end,
    function(v)
        CFG.Aimbot = v
        if v then startAimbotLoop() end
    end, 4)
makeSlider(pCombat, "Aimbot FOV", 30, 500,
    function() return CFG.AimbotFOV end,
    function(v) CFG.AimbotFOV = v end, 5)
makeSlider(pCombat, "Aimbot Smooth", 1, 20,
    function() return CFG.AimbotSmoothing * 100 end,
    function(v) CFG.AimbotSmoothing = v / 100 end, 6)
makeToggle(pCombat, "Show Aimbot FOV Circle",
    function() return CFG.ShowAimbotFOV end,
    function(v) CFG.ShowAimbotFOV = v end, 7)

-- Mobile aimbot hold button
local aimbotHoldBtn = Instance.new("TextButton")
aimbotHoldBtn.Size             = UDim2.new(1, 0, 0, BTN_H)
aimbotHoldBtn.BackgroundColor3 = Color3.fromRGB(60,40,100)
aimbotHoldBtn.Text             = "🎯  Hold: Aimbot (Mobile)"
aimbotHoldBtn.TextColor3       = Color3.fromRGB(255,255,255)
aimbotHoldBtn.Font             = Enum.Font.GothamBold
aimbotHoldBtn.TextSize         = FONT_SZ
aimbotHoldBtn.LayoutOrder      = 8
aimbotHoldBtn.Parent           = pCombat
Instance.new("UICorner", aimbotHoldBtn).CornerRadius = UDim.new(0, 6)
aimbotHoldBtn.MouseButton1Down:Connect(function()  setAimbotOn(true)  end)
aimbotHoldBtn.MouseButton1Up:Connect(function()    setAimbotOn(false) end)
aimbotHoldBtn.TouchLongPress:Connect(function()    setAimbotOn(true)  end)

-- ── Weapons ───────────────────────────────────────────
local pWeapons = addCategory("Weapons", "🔫", 2)
makeToggle(pWeapons, "Unlimited Ammo",
    function() return CFG.UnlimitedAmmo end,
    function(v) CFG.UnlimitedAmmo = v end, 1)
makeToggle(pWeapons, "Auto Reload",
    function() return CFG.AutoReload end,
    function(v) CFG.AutoReload = v end, 2)

-- ── Movement ──────────────────────────────────────────
local pMove = addCategory("Movement", "🏃", 3)
makeToggle(pMove, "Auto Sprint",
    function() return CFG.AutoSprint end,
    function(v) CFG.AutoSprint = v end, 1)
makeSlider(pMove, "Sprint Speed", 16, 80,
    function() return CFG.SprintSpeed end,
    function(v) CFG.SprintSpeed = v end, 2)
makeToggle(pMove, "Float Mode",
    function() return CFG.FloatMode end,
    function(v) CFG.FloatMode = v end, 3)
makeSlider(pMove, "Float Power", 10, 200,
    function() return CFG.FloatPower end,
    function(v) CFG.FloatPower = v end, 4)
makeToggle(pMove, "Noclip",
    function() return CFG.Noclip end,
    function(v) CFG.Noclip = v end, 5)

-- ── Survival ──────────────────────────────────────────
local pSurv = addCategory("Survival", "💊", 4)
makeToggle(pSurv, "Auto Pickup",
    function() return CFG.AutoPickup end,
    function(v) CFG.AutoPickup = v end, 1)
makeSlider(pSurv, "Pickup Range", 10, 150,
    function() return CFG.AutoPickupRange end,
    function(v) CFG.AutoPickupRange = v end, 2)
makeToggle(pSurv, "Auto Respawn",
    function() return CFG.AutoRespawn end,
    function(v) CFG.AutoRespawn = v end, 3)
makeToggle(pSurv, "Respawn → Own Lootbox",
    function() return CFG.AutoRespawnLoot end,
    function(v) CFG.AutoRespawnLoot = v end, 4)

-- ── Visuals ───────────────────────────────────────────
local pVis = addCategory("Visuals", "👁", 5)
makeToggle(pVis, "ESP",
    function() return CFG.ESPEnabled end,
    function(v) CFG.ESPEnabled = v end, 1)

-- ── Bypass ────────────────────────────────────────────
local pBypass = addCategory("Bypass", "🛡", 6)
makeToggle(pBypass, "Anti-Kick",
    function() return CFG.AntiKick end,
    function(v) CFG.AntiKick = v end, 1)
makeToggle(pBypass, "Hide Executor",
    function() return CFG.HideExecutor end,
    function(v) CFG.HideExecutor = v end, 2)

-- ── Config ────────────────────────────────────────────
local pConfig = addCategory("Config", "💾", 7)
makeAction(pConfig, "💾  Save Config",  function() saveConfig()   end, 1)
makeAction(pConfig, "📋  Export Config", function() exportConfig() end, 2)
makeAction(pConfig, "📥  Load Config",  function() loadConfig()   end, 3)

showCategory("Combat")

-- ══════════════════════════════════════════════════════
--  RENDER LOOP
-- ══════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    local center = screenCenter()

    if fovCircle then
        fovCircle.Position = center
        fovCircle.Visible  = CFG.ShowFOVCircle and CFG.SilentAim
        fovCircle.Radius   = CFG.SilentAimFOV
    end
    if aimbotCircle then
        aimbotCircle.Position = center
        aimbotCircle.Visible  = CFG.ShowAimbotFOV and CFG.Aimbot
        aimbotCircle.Radius   = CFG.AimbotFOV
    end

    -- silent aim target lock
    local sTarget = getNearestEnemy(CFG.SilentAimFOV, CFG.SilentAimPart)
    silentTarget   = CFG.SilentAim and sTarget or nil

    -- ESP update
    if CFG.ESPEnabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP then continue end
            local e = espObjects[p] if not e then continue end
            local root = getRoot(p)
            if not root or not isAlive(p) then
                e.box.Visible = false e.name.Visible = false e.dist.Visible = false
                continue
            end
            local pos = root.Position
            local sp, on = toScreen(pos)
            if not on then
                e.box.Visible = false e.name.Visible = false e.dist.Visible = false
                continue
            end
            local myRoot = getRoot(LP)
            local d      = myRoot and math.floor((myRoot.Position - pos).Magnitude) or 0
            local szY    = math.clamp(1000 / (Cam.CFrame.Position - pos).Magnitude, 20, 200)
            local szX    = szY * 0.6

            e.box.Visible   = true
            e.box.Size      = Vector2.new(szX, szY)
            e.box.Position  = Vector2.new(sp.X - szX/2, sp.Y - szY/2)
            e.box.Color     = CFG.ESPColor

            e.name.Visible  = true
            e.name.Text     = p.Name
            e.name.Position = Vector2.new(sp.X, sp.Y - szY/2 - 16)

            e.dist.Visible  = true
            e.dist.Text     = d .. "m"
            e.dist.Position = Vector2.new(sp.X, sp.Y + szY/2 + 2)
        end
    else
        for _, e in pairs(espObjects) do
            e.box.Visible = false e.name.Visible = false e.dist.Visible = false
        end
    end
end)
