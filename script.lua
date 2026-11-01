-- ██████╗ ██████╗ ██╗███╗   ███╗ ██████╗ ██████╗  █████╗ ██╗  ██╗
-- ██╔══██╗██╔══██╗██║████╗ ████║██╔═══██╗██╔══██╗██╔══██╗╚██╗██╔╝
-- ██████╔╝██████╔╝██║██╔████╔██║██║   ██║██║  ██║███████║ ╚███╔╝
-- ██╔═══╝ ██╔══██╗██║██║╚██╔╝██║██║   ██║██║  ██║██╔══██║ ██╔██╗
-- ██║     ██║  ██║██║██║ ╚═╝ ██║╚██████╔╝██████╔╝██║  ██║██╔╝ ██╗
-- ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
-- PRIMODAXVGRANT | Vagrant Survival
-- Version  : 5.2
-- Admin    : PRIMODAX
-- Game     : Vagrant Survival v10 (Roblox) — Team Stultus
-- Executor : Delta, Arceus X, Fluxus
--
-- CHANGES v5.0:
--   • All features DEFAULT OFF except AntiKick + HideExecutor
--   • Noclip: server-safe — cancels collision client-side ONLY on non-root
--     parts, no BodyVelocity, no speed event, reconnect issue fixed
--   • Silent Aim: FOV circle IS the targeting zone — target inside circle
--     gets aim redirected. Separate FOV from Aimbot FOV.
--   • Aimbot: improved prediction, smoothing slider, correct CFrame lerp
--   • Auto Sprint: sets WalkSpeed high passively without firing speed remotes
--   • Infinite Jump → Float Mode: hold Space = continuous upward velocity,
--     release = stop. No BodyVelocity kick surface (uses Humanoid.Jump loop)
--   • Auto Pickup: improved range + ProximityPrompt + ClickDetector + Touch
--   • iPad/wide viewport support: UI scales relative to ViewportSize
--   • Floating circle toggle: bottom-center, draggable, always visible
--   • Config save/load/export/import
--   • BG image placeholder wired

-- ══════════════════════════════════════════════════════
--  SERVICES
-- ══════════════════════════════════════════════════════
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")
local Workspace         = game:GetService("Workspace")
local HttpService       = game:GetService("HttpService")

local LP  = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

-- ══════════════════════════════════════════════════════
--  CONFIG — ALL OFF BY DEFAULT except bypass
-- ══════════════════════════════════════════════════════
local CFG = {
    -- combat
    SilentAim        = false,
    SilentAimPart    = "Head",
    SilentAimFOV     = 120,    -- radius in pixels; circle = targeting zone
    Aimbot           = false,
    AimbotSmoothing  = 0.12,
    AimbotPart       = "Head",
    AimbotFOV        = 180,    -- separate from silent aim FOV
    ShowFOV          = true,
    FOVColor         = Color3.fromRGB(255, 215, 0),
    -- utility
    UnlimitedAmmo    = false,
    AutoReload       = false,
    AutoPickup       = false,
    AutoPickupRange  = 40,
    AutoRespawn      = false,
    AutoRespawnLoot  = false,
    AutoSprint       = false,
    SprintSpeed      = 28,     -- vanilla walk = 16; 28 feels natural, no kick
    -- movement
    FloatMode        = false,  -- hold Space = fly upward, release = stop
    FloatPower       = 55,     -- upward stud/s while Space held
    Noclip           = false,
    -- visual
    ESPEnabled       = false,
    ESPColor         = Color3.fromRGB(255, 50, 50),
    -- bypass (ON by default)
    AntiKick         = true,
    HideExecutor     = true,
}

-- ══════════════════════════════════════════════════════
--  CONFIG PERSISTENCE
-- ══════════════════════════════════════════════════════
local CONFIG_FILE = "primodax_v5_cfg.json"

local PERSIST_KEYS = {
    "SilentAim","SilentAimFOV","Aimbot","AimbotFOV","AimbotSmoothing",
    "ShowFOV","UnlimitedAmmo","AutoReload","AutoPickup","AutoPickupRange",
    "AutoRespawn","AutoRespawnLoot","AutoSprint","SprintSpeed",
    "FloatMode","FloatPower","Noclip","ESPEnabled","AntiKick","HideExecutor",
}

local function cfgToTable()
    local t = {}
    for _, k in ipairs(PERSIST_KEYS) do t[k] = CFG[k] end
    return t
end
local function applyTable(t)
    for _, k in ipairs(PERSIST_KEYS) do
        if t[k] ~= nil then CFG[k] = t[k] end
    end
end
local function saveConfig()
    local ok, json = pcall(function() return HttpService:JSONEncode(cfgToTable()) end)
    if not ok then return false, "encode fail" end
    if writefile then
        local ok2 = pcall(writefile, CONFIG_FILE, json)
        if ok2 then return true, "saved → "..CONFIG_FILE end
    end
    if setclipboard then pcall(setclipboard, json) return true, "no writefile — copied to clipboard" end
    return false, "no writefile or setclipboard"
end
local function loadConfig()
    if readfile then
        local ok, raw = pcall(readfile, CONFIG_FILE)
        if ok and raw and #raw > 2 then
            local ok2, t = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok2 and t then applyTable(t) return true, "loaded ← "..CONFIG_FILE end
        end
    end
    return false, "no saved config"
end
local function exportConfig()
    local ok, json = pcall(function() return HttpService:JSONEncode(cfgToTable()) end)
    if not ok then return false, "encode fail" end
    if setclipboard then pcall(setclipboard, json) return true, "config copied to clipboard" end
    return false, "setclipboard unavailable"
end
local function importConfig(jsonStr)
    local ok, t = pcall(function() return HttpService:JSONDecode(jsonStr) end)
    if ok and t then applyTable(t) return true, "config imported" end
    return false, "invalid JSON"
end

pcall(loadConfig)

-- ══════════════════════════════════════════════════════
--  UTILITY
-- ══════════════════════════════════════════════════════
local function getChar(p)  return p and p.Character end
local function getHum(p)   local c=getChar(p) return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot(p)  local c=getChar(p) return c and c:FindFirstChild("HumanoidRootPart") end
local function getPart(p,n) local c=getChar(p) return c and c:FindFirstChild(n) end
local function isAlive(p)  local h=getHum(p) return h and h.Health>0 end

local function toScreen(pos)
    local s, on = Cam:WorldToViewportPoint(pos)
    return Vector2.new(s.X, s.Y), on
end
local function screenCenter()
    return Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
end
local function dist2D(sp)
    return (sp - screenCenter()).Magnitude
end

-- best enemy inside given pixel-radius FOV
local function getNearestEnemy(fovRadius, targetPart)
    local best, bDist, bPos = nil, fovRadius, nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isAlive(p) then
            local part = getPart(p, targetPart or "Head")
            if part then
                local sp, on = toScreen(part.Position)
                if on then
                    local d = dist2D(sp)
                    if d < bDist then
                        best=p bDist=d bPos=part.Position
                    end
                end
            end
        end
    end
    return best, bPos
end

-- ══════════════════════════════════════════════════════
--  FOV CIRCLE (Drawing) — silent aim zone indicator
-- ══════════════════════════════════════════════════════
local fovCircle         = Drawing.new("Circle")
fovCircle.Thickness     = 1.5
fovCircle.Color         = CFG.FOVColor
fovCircle.Filled        = false
fovCircle.Visible       = CFG.ShowFOV
fovCircle.Radius        = CFG.SilentAimFOV
fovCircle.Position      = screenCenter()

-- second circle for aimbot FOV (white, thinner)
local aimbotCircle      = Drawing.new("Circle")
aimbotCircle.Thickness  = 1
aimbotCircle.Color      = Color3.fromRGB(200, 200, 200)
aimbotCircle.Filled     = false
aimbotCircle.Visible    = false
aimbotCircle.Radius     = CFG.AimbotFOV
aimbotCircle.Position   = screenCenter()

-- ══════════════════════════════════════════════════════
--  BYPASS: HIDE EXECUTOR GLOBALS
-- ══════════════════════════════════════════════════════
pcall(function()
    if not CFG.HideExecutor then return end
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local _oi = mt.__index
    mt.__index = newcclosure(function(self, k)
        if k=="Executor" or k=="executor" or k=="syn"
        or k=="fluxus" or k=="DELTA" or k=="getgenv" then return nil end
        return _oi(self, k)
    end)
    setreadonly(mt, true)
end)

-- ══════════════════════════════════════════════════════
--  BYPASS: ANTI-KICK + SILENT AIM (single __namecall hook)
--
--  Silent aim fix: Vagrant Survival fires shooting remotes with
--  a Vector3 hit position AND a BasePart hit instance.
--  We replace BOTH when a target is inside the silent aim FOV circle.
--  The hook only fires on FireServer/InvokeServer — safe.
-- ══════════════════════════════════════════════════════
local silentTarget = nil

local _nc
_nc = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args   = {...}

    if method == "FireServer" or method == "InvokeServer" then
        -- anti-kick: swallow detection remotes
        if CFG.AntiKick then
            local n = (self.Name or ""):lower()
            if n:find("kick")   or n:find("ban")      or n:find("cheat")
            or n:find("detect") or n:find("anticheat") or n:find("report")
            or n:find("flag")   or n:find("speed")    or n:find("velocity")
            or n:find("noclip") or n:find("collide") then
                return nil
            end
        end

        -- silent aim: redirect Vector3 + BasePart args toward target
        if CFG.SilentAim and silentTarget and isAlive(silentTarget) then
            local part = getPart(silentTarget, CFG.SilentAimPart)
            if part then
                for i, v in ipairs(args) do
                    if typeof(v) == "Vector3" then
                        args[i] = part.Position
                    elseif typeof(v) == "Instance" and v:IsA("BasePart") then
                        args[i] = part
                    elseif typeof(v) == "Instance" and v:IsA("Model") then
                        -- some games pass Character model — redirect to target char
                        local tc = getChar(silentTarget)
                        if tc then args[i] = tc end
                    end
                end
            end
        end
    end

    return _nc(self, table.unpack(args))
end)

-- ══════════════════════════════════════════════════════
--  AIMBOT (hold Q on desktop; toggle button on mobile)
--  Uses a separate AimbotFOV radius, independent of silent FOV.
--  Smoothing is lerp factor per frame — lower = smoother/slower.
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
--  FLOAT MODE (replaces old fly + infinite jump)
--  Space held → HRP gets an upward CFrame nudge each Stepped.
--  No BodyVelocity instance → no anticheat surface.
--  Release Space → stops immediately.
--  For true "fly around" feel: W/A/S/D still moves normally via Humanoid.
-- ══════════════════════════════════════════════════════
RunService.Stepped:Connect(function(_, dt)
    if not CFG.FloatMode then return end
    local root = getRoot(LP)
    if not root then return end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space)
    or UserInputService:IsKeyDown(Enum.KeyCode.ButtonA) then
        -- nudge upward — client-side CFrame move, no physics object created
        root.CFrame = root.CFrame + Vector3.new(0, CFG.FloatPower * dt, 0)
    end
end)

-- also handle mobile jump button hold via Humanoid Jump loop
local floatConn = nil
local function startFloatLoop(hum)
    if floatConn then floatConn:Disconnect() end
    floatConn = RunService.Heartbeat:Connect(function()
        if CFG.FloatMode and hum and hum.Health > 0 then
            if UserInputService.JumpRequest then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end

-- ══════════════════════════════════════════════════════
--  NOCLIP (server-safe version)
--  Cancels CanCollide on character parts EXCEPT HumanoidRootPart.
--  HRP keeps collision so server doesn't flag position teleports.
--  Swallows "noclip"/"collide" detection remotes in the hook above.
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
--  AUTO SPRINT
--  Sets WalkSpeed passively each Heartbeat — no remote fired,
--  no speed event triggered. Resets on death via CharacterAdded.
-- ══════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not CFG.AutoSprint then return end
    local hum = getHum(LP)
    if hum and hum.WalkSpeed < CFG.SprintSpeed then
        hum.WalkSpeed = CFG.SprintSpeed
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
        if (v:IsA("IntValue") or v:IsA("NumberValue")) then
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

-- ══════════════════════════════════════════════════════
--  AUTO PICKUP (improved: ProximityPrompt + ClickDetector + TouchPart)
-- ══════════════════════════════════════════════════════
-- AUTO PICKUP v5.2
-- Scans ALL descendants of Workspace for any pickup-able object.
-- ProximityPrompt fired via fireproximityprompt (executor API).
-- ClickDetector fired via fireclickdetector.
-- Also fires any RemoteEvent/RemoteFunction named like a pickup.
-- Player's own dropped bag/loot is included via PlayerBag scan.

local PICKUP_FOLDERS = {
    "Loots","Items","Drops","Pickups","Collectibles",
    "Weapons","Loot","Spawns","WorldItems","GroundItems",
    "DroppedItems","Interactables","Resources","Ammo","Supplies",
}

-- try to fire all known pickup remote patterns on an object
local function tryPickup(obj, root)
    -- ProximityPrompt
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            pcall(fireproximityprompt, v)
        end
    end
    -- ClickDetector
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("ClickDetector") then
            pcall(fireclickdetector, v)
        end
    end
    -- RemoteEvent with pickup-like name
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("pick") or n:find("loot") or n:find("collect")
            or n:find("grab") or n:find("take") or n:find("item") then
                pcall(function() v:FireServer() end)
            end
        end
    end
end

-- scan a folder for nearby pickups
local function scanFolder(folder, root)
    if not folder then return end
    for _, obj in ipairs(folder:GetChildren()) do
        local part = obj:IsA("BasePart") and obj
                     or obj:FindFirstChildOfClass("BasePart")
        if part then
            local d = (root.Position - part.Position).Magnitude
            if d <= CFG.AutoPickupRange then
                tryPickup(obj, root)
            end
        end
    end
end

-- also scan ReplicatedStorage for dropped bag remotes
local function scanRSPickups(root)
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("loot") or n:find("bag") or n:find("drop")
            or n:find("pick") or n:find("collect") then
                pcall(function() v:FireServer(root.Position) end)
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if not CFG.AutoPickup then return end
    local root = getRoot(LP) if not root then return end
    -- named folders
    for _, fname in ipairs(PICKUP_FOLDERS) do
        scanFolder(Workspace:FindFirstChild(fname), root)
    end
    -- scan entire Workspace top-level children not in a named folder
    for _, obj in ipairs(Workspace:GetChildren()) do
        if not obj:IsA("Model") or obj == getChar(LP) then continue end
        local part = obj:FindFirstChildOfClass("BasePart")
        if part then
            local d = (root.Position - part.Position).Magnitude
            if d <= CFG.AutoPickupRange then
                tryPickup(obj, root)
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════
--  AUTO RESPAWN
-- ══════════════════════════════════════════════════════
-- AUTO RESPAWN v5.2
-- On death: fires respawn remote, then teleports to OWN dropped bag/loot
-- if AutoRespawnLoot is ON. Scans Workspace for a Model/Part whose
-- name contains the player's username (dropped bag pattern in Vagrant Survival).

local RESPAWN_FOLDERS = {"LootBoxes","LootZones","Crates","Chests","Lootboxes","Bags","DroppedBags","PlayerLoot"}

local function findOwnBag()
    -- look for any Workspace object named after LP or containing "bag"/"loot"+"LP.Name"
    local root = getRoot(LP) if not root then return nil end
    local best, bDist = nil, math.huge
    local lname = LP.Name:lower()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if (n:find(lname) or n:find("bag") or n:find("drop") or n:find("loot"))
        and (obj:IsA("BasePart") or obj:IsA("Model")) then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
            if part then
                local d = (root.Position - part.Position).Magnitude
                if d < bDist then best = part bDist = d end
            end
        end
    end
    return best
end

local function nearestLootbox()
    local root = getRoot(LP) if not root then return nil end
    local best, bDist = nil, math.huge
    -- check own bag first
    local ownBag = findOwnBag()
    if ownBag then return ownBag end
    -- fallback to world lootboxes
    for _, fname in ipairs(RESPAWN_FOLDERS) do
        local f = Workspace:FindFirstChild(fname)
        if f then
            for _, box in ipairs(f:GetChildren()) do
                local part = box:IsA("BasePart") and box or box:FindFirstChildOfClass("BasePart")
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
    startFloatLoop(hum)
    hum.Died:Connect(function()
        if not CFG.AutoRespawn then return end
        -- try respawn remotes
        task.wait(3)
        local remNames = {"Respawn","RespawnPlayer","PlayerRespawn","RevivePlayer","Revive"}
        for _, rname in ipairs(remNames) do
            local rem = ReplicatedStorage:FindFirstChild(rname)
                     or Workspace:FindFirstChild(rname)
            if rem and rem:IsA("RemoteEvent") then
                pcall(function() rem:FireServer() end)
                break
            end
        end
        task.wait(1)
        if not isAlive(LP) then pcall(function() LP:LoadCharacter() end) end
        -- after respawn: teleport to own bag/loot
        if CFG.AutoRespawnLoot then
            task.wait(1.5)  -- wait for character to load
            local newRoot = getRoot(LP)
            if newRoot then
                local lb = nearestLootbox()
                if lb then newRoot.CFrame = lb.CFrame + Vector3.new(0, 5, 0) end
            end
        end
    end)
end

LP.CharacterAdded:Connect(onCharAdded)
if LP.Character then task.spawn(function() onCharAdded(LP.Character) end) end

-- ══════════════════════════════════════════════════════
--  ESP
-- ══════════════════════════════════════════════════════
local espObjects = {}
local function makeESP(player)
    local box       = Drawing.new("Square")
    box.Visible=false box.Color=CFG.ESPColor box.Thickness=1 box.Filled=false
    local name      = Drawing.new("Text")
    name.Visible=false name.Color=Color3.fromRGB(255,255,255)
    name.Size=14 name.Center=true name.Outline=true
    local dist      = Drawing.new("Text")
    dist.Visible=false dist.Color=Color3.fromRGB(255,215,0)
    dist.Size=12 dist.Center=true dist.Outline=true
    espObjects[player] = {box=box,name=name,dist=dist}
end
local function removeESP(player)
    local e=espObjects[player]
    if e then e.box:Remove() e.name:Remove() e.dist:Remove() espObjects[player]=nil end
end
for _,p in ipairs(Players:GetPlayers()) do if p~=LP then makeESP(p) end end
Players.PlayerAdded:Connect(function(p) if p~=LP then makeESP(p) end end)
Players.PlayerRemoving:Connect(removeESP)

-- ══════════════════════════════════════════════════════
--  MAIN RENDER LOOP
-- ══════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    local center = screenCenter()

    -- FOV circles
    fovCircle.Position   = center
    fovCircle.Visible    = CFG.ShowFOV and CFG.SilentAim
    fovCircle.Radius     = CFG.SilentAimFOV
    aimbotCircle.Position = center
    aimbotCircle.Visible  = CFG.ShowFOV and CFG.Aimbot and aimbotOn
    aimbotCircle.Radius   = CFG.AimbotFOV

    -- silent aim: target = nearest enemy inside silent FOV circle
    local sTarget, _ = getNearestEnemy(CFG.SilentAimFOV, CFG.SilentAimPart)
    silentTarget = CFG.SilentAim and sTarget or nil

    -- aimbot: separate FOV, separate target
    if CFG.Aimbot and aimbotOn then
        local aTarget, aPos = getNearestEnemy(CFG.AimbotFOV, CFG.AimbotPart)
        if aTarget and aPos then
            local _, on = toScreen(aPos)
            if on then
                local targetCF = CFrame.new(
                    Cam.CFrame.Position,
                    Cam.CFrame.Position + (aPos - Cam.CFrame.Position).Unit
                )
                Cam.CFrame = Cam.CFrame:Lerp(targetCF, CFG.AimbotSmoothing)
            end
        end
    end

    -- ESP
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
        local height = math.abs(rootSP.Y-headSP.Y)*2.2
        local width  = height*0.5
        local myRoot = getRoot(LP)
        local d = myRoot and (myRoot.Position-root.Position).Magnitude or 0
        e.box.Size     = Vector2.new(width,height)
        e.box.Position = Vector2.new(rootSP.X-width/2, rootSP.Y-height/2)
        e.box.Color    = CFG.ESPColor
        e.box.Visible  = true
        e.name.Text    = player.Name
        e.name.Position= Vector2.new(rootSP.X, headSP.Y-16)
        e.name.Visible = true
        e.dist.Text    = string.format("[%.0fm]",d)
        e.dist.Position= Vector2.new(rootSP.X, rootSP.Y+height/2+2)
        e.dist.Visible = true
    end
end)

-- ══════════════════════════════════════════════════════
--  GUI SETUP
--  iPad/wide support: panel width scales to viewport width.
--  On narrow phone (~400px): panel = 270px wide
--  On iPad wide (~1024px): panel = 380px wide, font bumps up
-- ══════════════════════════════════════════════════════
if CoreGui:FindFirstChild("PrimodaxGUI") then
    CoreGui:FindFirstChild("PrimodaxGUI"):Destroy()
end

local SG = Instance.new("ScreenGui")
SG.Name           = "PrimodaxGUI"
SG.ResetOnSpawn   = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset = true
SG.Parent         = CoreGui

-- responsive sizing
local vp     = Cam.ViewportSize
local isWide = vp.X > 700
local PANEL_W   = isWide and 380 or 270
local PANEL_H   = isWide and 600 or 530
local BASE_FONT = isWide and 14  or 12
local TITLE_FONT= isWide and 16  or 14
local BTN_H     = isWide and 38  or 32

-- ── MAIN PANEL (declared FIRST so toggle can reference it) ──
local MF = Instance.new("Frame")
MF.Size             = UDim2.new(0, PANEL_W, 0, PANEL_H)
MF.Position         = UDim2.new(0.5, -PANEL_W/2, 0.5, -PANEL_H/2)
MF.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
MF.BorderSizePixel  = 0
MF.Active           = true
MF.Draggable        = true
MF.Visible          = false
MF.ZIndex           = 5
MF.Parent           = SG
Instance.new("UICorner", MF).CornerRadius = UDim.new(0, 12)

local mfStroke = Instance.new("UIStroke")
mfStroke.Color=Color3.fromRGB(255,215,0) mfStroke.Thickness=1.5 mfStroke.Parent=MF

-- viewport rotation handler
Cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    vp       = Cam.ViewportSize
    isWide   = vp.X > 700
    PANEL_W  = isWide and 380 or 270
    PANEL_H  = isWide and 600 or 530
    MF.Size  = UDim2.new(0, PANEL_W, 0, PANEL_H)
end)

-- BACKGROUND IMAGE
-- FILL: swap with your direct image URL (.png/.jpg) or rbxassetid://NUMBER
local BG_URL = "https://kommodo.ai/i/rEJQGF9mw7x6XTpPJChr"
local bgImg = Instance.new("ImageLabel")
bgImg.Size               = UDim2.new(1,0,1,0)
bgImg.Position           = UDim2.new(0,0,0,0)
bgImg.BackgroundTransparency = 1
bgImg.Image              = BG_URL
bgImg.ImageTransparency  = 0.3
bgImg.ScaleType          = Enum.ScaleType.Crop
bgImg.ZIndex             = 1
bgImg.Parent             = MF
Instance.new("UICorner", bgImg).CornerRadius = UDim.new(0,12)

-- TITLE BAR
local TB = Instance.new("Frame")
TB.Size=UDim2.new(1,0,0,50) TB.BackgroundColor3=Color3.fromRGB(255,215,0)
TB.BorderSizePixel=0 TB.ZIndex=6 TB.Parent=MF
Instance.new("UICorner", TB).CornerRadius = UDim.new(0,12)

local TL = Instance.new("TextLabel")
TL.Size=UDim2.new(1,-50,0,28) TL.Position=UDim2.new(0,10,0,2)
TL.BackgroundTransparency=1 TL.Text="⚡ PRIMODAXVGRANT ⚡"
TL.TextColor3=Color3.fromRGB(0,0,0) TL.TextSize=TITLE_FONT
TL.Font=Enum.Font.GothamBold TL.TextXAlignment=Enum.TextXAlignment.Left
TL.ZIndex=7 TL.Parent=TB

local SL = Instance.new("TextLabel")
SL.Size=UDim2.new(1,-50,0,18) SL.Position=UDim2.new(0,10,0,30)
SL.BackgroundTransparency=1
SL.Text="Vagrant Survival | v5.2 | ADMIN: PRIMODAX"
SL.TextColor3=Color3.fromRGB(30,30,30) SL.TextSize=10
SL.Font=Enum.Font.Gotham SL.TextXAlignment=Enum.TextXAlignment.Left
SL.ZIndex=7 SL.Parent=TB

local XBtn = Instance.new("TextButton")
XBtn.Size=UDim2.new(0,36,0,36) XBtn.Position=UDim2.new(1,-42,0,7)
XBtn.BackgroundColor3=Color3.fromRGB(30,30,30)
XBtn.Text="✕" XBtn.TextColor3=Color3.fromRGB(255,215,0)
XBtn.TextSize=16 XBtn.Font=Enum.Font.GothamBold XBtn.ZIndex=8 XBtn.Parent=TB
Instance.new("UICorner",XBtn).CornerRadius=UDim.new(1,0)
XBtn.MouseButton1Click:Connect(function() MF.Visible=false end)

-- SCROLL FRAME
local SF = Instance.new("ScrollingFrame")
SF.Size=UDim2.new(1,-10,1,-58) SF.Position=UDim2.new(0,5,0,54)
SF.BackgroundTransparency=1 SF.ScrollBarThickness=3
SF.ScrollBarImageColor3=Color3.fromRGB(255,215,0)
SF.CanvasSize=UDim2.new(0,0,0,0) SF.AutomaticCanvasSize=Enum.AutomaticSize.Y
SF.ZIndex=6 SF.Parent=MF

local Layout=Instance.new("UIListLayout")
Layout.Padding=UDim.new(0,5) Layout.SortOrder=Enum.SortOrder.LayoutOrder
Layout.Parent=SF

local Pad=Instance.new("UIPadding")
Pad.PaddingTop=UDim.new(0,5) Pad.PaddingLeft=UDim.new(0,5)
Pad.PaddingRight=UDim.new(0,5) Pad.Parent=SF

-- ── FLOATING CIRCLE TOGGLE (declared AFTER MF so it can reference it) ──
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size             = UDim2.new(0, 60, 0, 60)
toggleBtn.Position         = UDim2.new(0.5, -30, 1, -95)
toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
toggleBtn.TextColor3       = Color3.fromRGB(0, 0, 0)
toggleBtn.Text             = "⚡"
toggleBtn.TextSize         = 24
toggleBtn.Font             = Enum.Font.GothamBold
toggleBtn.ZIndex           = 10
toggleBtn.Active           = true
toggleBtn.Parent           = SG
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)

local tShadow = Instance.new("UIStroke")
tShadow.Color=Color3.fromRGB(0,0,0) tShadow.Thickness=2 tShadow.Parent=toggleBtn

-- draggable + tap to toggle (MF now exists above, no nil reference)
do
    local drag, dragStart, startPos, moved = false, nil, nil, false
    toggleBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch
        or inp.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true moved=false
            dragStart=inp.Position startPos=toggleBtn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType==Enum.UserInputType.Touch
        or inp.UserInputType==Enum.UserInputType.MouseMovement) then
            local delta = inp.Position - dragStart
            if delta.Magnitude > 6 then moved=true end
            toggleBtn.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset+delta.X,
                startPos.Y.Scale, startPos.Y.Offset+delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch
        or inp.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=false
            if not moved then
                MF.Visible = not MF.Visible  -- MF exists here, no nil
            end
        end
    end)
end

-- ──────────────────────────────────────────────────────
--  MENU ITEMS
-- ──────────────────────────────────────────────────────
makeSection("── COMBAT ──", 1)
makeToggle("🎯 Silent Aim",        "SilentAim",      2)
makeSlider("⭕ Silent Aim FOV",    "SilentAimFOV",   10, 500, 3)
makeToggle("🔫 Aimbot [Hold Q]",   "Aimbot",         4)
makeSlider("🔵 Aimbot FOV",        "AimbotFOV",      10, 500, 5)
makeToggle("🔋 Unlimited Ammo",    "UnlimitedAmmo",  6)
makeToggle("🔄 Auto Reload",       "AutoReload",     7)

makeSection("── MOVEMENT ──", 10)
makeToggle("🌊 Float Mode [Space]","FloatMode",      11)
makeSlider("🔼 Float Power",       "FloatPower",     10, 200, 12)
makeToggle("👻 Noclip",            "Noclip",         13)
makeToggle("💨 Auto Sprint",       "AutoSprint",     14)
makeSlider("🏃 Sprint Speed",      "SprintSpeed",    16, 60,  15)

makeSection("── UTILITY ──", 20)
makeToggle("🧲 Auto Pickup",       "AutoPickup",     21)
makeToggle("💀 Auto Respawn",      "AutoRespawn",    22)
makeToggle("📦 Respawn @ Loot",    "AutoRespawnLoot",23)

makeSection("── VISUAL ──", 30)
makeToggle("🟥 ESP",               "ESPEnabled",     31)
makeToggle("⭕ Show FOV Circles",  "ShowFOV",        32)

makeSection("── BYPASS ──", 40)
makeToggle("🛡️  Anti Kick",         "AntiKick",       41)
makeToggle("👁️  Hide Executor",      "HideExecutor",   42)

makeSection("── CONFIG ──", 50)

local statLbl=Instance.new("TextLabel")
statLbl.Size=UDim2.new(1,0,0,20) statLbl.BackgroundTransparency=1
statLbl.Text="" statLbl.TextColor3=Color3.fromRGB(180,255,180)
statLbl.TextSize=10 statLbl.Font=Enum.Font.Gotham
statLbl.LayoutOrder=51 statLbl.ZIndex=6 statLbl.Parent=SF

local function setStatus(msg)
    statLbl.Text=msg
    task.delay(3,function() if statLbl.Text==msg then statLbl.Text="" end end)
end
local function refreshAllToggles()
    for _,fn in pairs(toggleRefs) do fn() end
end

local function cfgBtn(label, color, order, fn)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0.48,0,0,BTN_H) b.BackgroundColor3=color
    b.Text=label b.TextColor3=Color3.fromRGB(255,255,255)
    b.TextSize=BASE_FONT b.Font=Enum.Font.GothamBold
    b.LayoutOrder=order b.ZIndex=6 b.Parent=SF
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    b.MouseButton1Click:Connect(fn)
end

cfgBtn("💾 Save",    Color3.fromRGB(35,120,60),  52, function()
    local ok,msg=saveConfig() setStatus(ok and "✅ "..msg or "❌ "..msg)
end)
cfgBtn("📂 Load",    Color3.fromRGB(40,80,160),  53, function()
    local ok,msg=loadConfig()
    if ok then refreshAllToggles() end
    setStatus(ok and "✅ "..msg or "❌ "..msg)
end)
cfgBtn("📋 Export",  Color3.fromRGB(120,60,35),  54, function()
    local ok,msg=exportConfig() setStatus(ok and "✅ "..msg or "❌ "..msg)
end)
cfgBtn("📥 Import",  Color3.fromRGB(80,40,120),  55, function()
    local json=""
    if getclipboard then local ok,s=pcall(getclipboard) if ok then json=s end end
    if json=="" then setStatus("❌ paste JSON in console: importConfig(str)") return end
    local ok,msg=importConfig(json)
    if ok then refreshAllToggles() end
    setStatus(ok and "✅ "..msg or "❌ "..msg)
end)

print("✅ PRIMODAXVGRANT v5.2 loaded — Vagrant Survival | ADMIN: PRIMODAX")
