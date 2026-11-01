-- ██████╗ ██████╗ ██╗███╗   ███╗ ██████╗ ██████╗  █████╗ ██╗  ██╗
-- ██╔══██╗██╔══██╗██║████╗ ████║██╔═══██╗██╔══██╗██╔══██╗╚██╗██╔╝
-- ██████╔╝██████╔╝██║██╔████╔██║██║   ██║██║  ██║███████║ ╚███╔╝
-- ██╔═══╝ ██╔══██╗██║██║╚██╔╝██║██║   ██║██║  ██║██╔══██║ ██╔██╗
-- ██║     ██║  ██║██║██║ ╚═╝ ██║╚██████╔╝██████╔╝██║  ██║██╔╝ ██╗
-- ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
-- PRIMODAXVGRANT | Vagrant Survival
-- Version  : 5.3 (fixed + bypass+)
-- Admin    : PRIMODAX
-- Game     : Vagrant Survival v10 (Roblox) — Team Stultus
-- Executor : Delta, Arceus X, Fluxus
--
-- FIXES v5.3:
--   • makeSection / makeToggle / makeSlider / toggleRefs defined BEFORE use
--   • Bypass: hookmetamethod namecall hook made more resilient
--   • Bypass: HideExecutor now also strips _G executor markers
--   • Bypass: AntiKick pattern list expanded
--   • Bypass: speed event swallowing covers "walkspeed" + "movespeed"
--   • Drawing API guarded — graceful skip if executor doesn't expose it

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
    SilentAim        = false,
    SilentAimPart    = "Head",
    SilentAimFOV     = 120,
    Aimbot           = false,
    AimbotSmoothing  = 0.12,
    AimbotPart       = "Head",
    AimbotFOV        = 180,
    ShowFOV          = true,
    FOVColor         = Color3.fromRGB(255, 215, 0),
    UnlimitedAmmo    = false,
    AutoReload       = false,
    AutoPickup       = false,
    AutoPickupRange  = 40,
    AutoRespawn      = false,
    AutoRespawnLoot  = false,
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
local function getChar(p)   return p and p.Character end
local function getHum(p)    local c=getChar(p) return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot(p)   local c=getChar(p) return c and c:FindFirstChild("HumanoidRootPart") end
local function getPart(p,n) local c=getChar(p) return c and c:FindFirstChild(n) end
local function isAlive(p)   local h=getHum(p) return h and h.Health>0 end

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
--  FOV CIRCLES — guarded: Drawing may not exist on all executors
-- ══════════════════════════════════════════════════════
local fovCircle, aimbotCircle
if Drawing then
    fovCircle           = Drawing.new("Circle")
    fovCircle.Thickness = 1.5
    fovCircle.Color     = CFG.FOVColor
    fovCircle.Filled    = false
    fovCircle.Visible   = CFG.ShowFOV
    fovCircle.Radius    = CFG.SilentAimFOV
    fovCircle.Position  = screenCenter()

    aimbotCircle           = Drawing.new("Circle")
    aimbotCircle.Thickness = 1
    aimbotCircle.Color     = Color3.fromRGB(200, 200, 200)
    aimbotCircle.Filled    = false
    aimbotCircle.Visible   = false
    aimbotCircle.Radius    = CFG.AimbotFOV
    aimbotCircle.Position  = screenCenter()
end

-- ══════════════════════════════════════════════════════
--  BYPASS v5.3: HIDE EXECUTOR GLOBALS
--  Also nukes _G executor markers that Vagrant Survival probes.
-- ══════════════════════════════════════════════════════
pcall(function()
    if not CFG.HideExecutor then return end
    -- nil out _G markers
    local EXEC_KEYS = {
        "syn","fluxus","DELTA","Delta","delta","getgenv","is_executor_closure",
        "rconsole","hookfunction","hookmetamethod","checkcaller","cloneref",
        "FLUXUS_KEY","DELTA_KEY","ARCEUS_KEY","KRNL_LOADED",
    }
    for _, k in ipairs(EXEC_KEYS) do
        pcall(function() _G[k] = nil end)
    end
    -- metatable hook to intercept game[key] probes
    local ok, mt = pcall(getrawmetatable, game)
    if not ok then return end
    pcall(setreadonly, mt, false)
    local _oi = mt.__index
    mt.__index = newcclosure(function(self, k)
        local lk = tostring(k):lower()
        if lk=="executor" or lk=="syn"   or lk=="fluxus"
        or lk=="delta"    or lk=="getgenv" or lk=="is_executor_closure"
        or lk=="krnl_loaded" or lk:find("executor") then
            return nil
        end
        return _oi(self, k)
    end)
    pcall(setreadonly, mt, true)
end)

-- ══════════════════════════════════════════════════════
--  BYPASS v5.3: ANTI-KICK + SILENT AIM (single __namecall hook)
--  Expanded pattern list covers more Vagrant Survival detection remotes.
-- ══════════════════════════════════════════════════════
local silentTarget = nil

local _nc
_nc = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args   = {...}

    if method == "FireServer" or method == "InvokeServer" then
        if CFG.AntiKick then
            local n = (typeof(self) == "Instance" and self.Name or ""):lower()
            -- expanded detection keyword list v5.3
            if n:find("kick")       or n:find("ban")        or n:find("cheat")
            or n:find("detect")     or n:find("anticheat")  or n:find("report")
            or n:find("flag")       or n:find("speed")      or n:find("velocity")
            or n:find("noclip")     or n:find("collide")    or n:find("walkspeed")
            or n:find("movespeed")  or n:find("exploit")    or n:find("hack")
            or n:find("sanity")     or n:find("integrity")  or n:find("verify")
            or n:find("position")   or n:find("teleport")   or n:find("tphack") then
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
                    elseif typeof(v) == "Instance" and v:IsA("Model") then
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
--  AIMBOT
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
--  FLOAT MODE
-- ══════════════════════════════════════════════════════
RunService.Stepped:Connect(function(_, dt)
    if not CFG.FloatMode then return end
    local root = getRoot(LP)
    if not root then return end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space)
    or UserInputService:IsKeyDown(Enum.KeyCode.ButtonA) then
        root.CFrame = root.CFrame + Vector3.new(0, CFG.FloatPower * dt, 0)
    end
end)

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
--  NOCLIP
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
--  AUTO PICKUP
-- ══════════════════════════════════════════════════════
local PICKUP_FOLDERS = {
    "Loots","Items","Drops","Pickups","Collectibles",
    "Weapons","Loot","Spawns","WorldItems","GroundItems",
    "DroppedItems","Interactables","Resources","Ammo","Supplies",
}

local function tryPickup(obj, root)
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            pcall(fireproximityprompt, v)
        end
    end
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("ClickDetector") then
            pcall(fireclickdetector, v)
        end
    end
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

RunService.Heartbeat:Connect(function()
    if not CFG.AutoPickup then return end
    local root = getRoot(LP) if not root then return end
    for _, fname in ipairs(PICKUP_FOLDERS) do
        scanFolder(Workspace:FindFirstChild(fname), root)
    end
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
local RESPAWN_FOLDERS = {"LootBoxes","LootZones","Crates","Chests","Lootboxes","Bags","DroppedBags","PlayerLoot"}

local function findOwnBag()
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
    local ownBag = findOwnBag()
    if ownBag then return ownBag end
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
        if CFG.AutoRespawnLoot then
            task.wait(1.5)
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
    if not Drawing then return end
    local box  = Drawing.new("Square")
    box.Visible=false box.Color=CFG.ESPColor box.Thickness=1 box.Filled=false
    local name = Drawing.new("Text")
    name.Visible=false name.Color=Color3.fromRGB(255,255,255)
    name.Size=14 name.Center=true name.Outline=true
    local dist = Drawing.new("Text")
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

    if fovCircle then
        fovCircle.Position  = center
        fovCircle.Visible   = CFG.ShowFOV and CFG.SilentAim
        fovCircle.Radius    = CFG.SilentAimFOV
    end
    if aimbotCircle then
        aimbotCircle.Position = center
        aimbotCircle.Visible  = CFG.ShowFOV and CFG.Aimbot and aimbotOn
        aimbotCircle.Radius   = CFG.AimbotFOV
    end

    local sTarget = getNearestEnemy(CFG.SilentAimFOV, CFG.SilentAimPart)
    silentTarget  = CFG.SilentAim and sTarget or nil

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

local vp     = Cam.ViewportSize
local isWide = vp.X > 700
local PANEL_W   = isWide and 380 or 270
local PANEL_H   = isWide and 600 or 530
local BASE_FONT = isWide and 14  or 12
local TITLE_FONT= isWide and 16  or 14
local BTN_H     = isWide and 38  or 32

-- MAIN PANEL
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

Cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    vp      = Cam.ViewportSize
    isWide  = vp.X > 700
    PANEL_W = isWide and 380 or 270
    PANEL_H = isWide and 600 or 530
    MF.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
end)

-- BACKGROUND IMAGE
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
SL.Text="Vagrant Survival | v5.3 | ADMIN: PRIMODAX"
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

-- ══════════════════════════════════════════════════════
--  MENU BUILDER FUNCTIONS  ← THE FIX: defined before use
-- ══════════════════════════════════════════════════════
local toggleRefs = {}

local function makeSection(label, order)
    local f = Instance.new("Frame")
    f.Size=UDim2.new(1,0,0,22) f.BackgroundColor3=Color3.fromRGB(255,215,0)
    f.BackgroundTransparency=0.7 f.BorderSizePixel=0
    f.LayoutOrder=order f.ZIndex=6 f.Parent=SF
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,4)
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,0,1,0) lbl.BackgroundTransparency=1
    lbl.Text=label lbl.TextColor3=Color3.fromRGB(255,215,0)
    lbl.TextSize=BASE_FONT lbl.Font=Enum.Font.GothamBold
    lbl.ZIndex=7 lbl.Parent=f
end

local function makeToggle(label, cfgKey, order)
    local row = Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,BTN_H) row.BackgroundColor3=Color3.fromRGB(22,22,22)
    row.BorderSizePixel=0 row.LayoutOrder=order row.ZIndex=6 row.Parent=SF
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-56,1,0) lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1 lbl.Text=label
    lbl.TextColor3=Color3.fromRGB(220,220,220) lbl.TextSize=BASE_FONT
    lbl.Font=Enum.Font.Gotham lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.ZIndex=7 lbl.Parent=row

    local pill=Instance.new("Frame")
    pill.Size=UDim2.new(0,40,0,22) pill.Position=UDim2.new(1,-48,0.5,-11)
    pill.BorderSizePixel=0 pill.ZIndex=7 pill.Parent=row
    Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)

    local knob=Instance.new("Frame")
    knob.Size=UDim2.new(0,18,0,18) knob.Position=UDim2.new(0,2,0.5,-9)
    knob.BackgroundColor3=Color3.fromRGB(255,255,255) knob.BorderSizePixel=0
    knob.ZIndex=8 knob.Parent=pill
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local function refresh()
        local on = CFG[cfgKey]
        pill.BackgroundColor3 = on and Color3.fromRGB(80,200,80) or Color3.fromRGB(60,60,60)
        knob.Position = on and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
    end
    refresh()
    table.insert(toggleRefs, refresh)

    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,1,0) btn.BackgroundTransparency=1
    btn.Text="" btn.ZIndex=9 btn.Parent=row
    btn.MouseButton1Click:Connect(function()
        CFG[cfgKey] = not CFG[cfgKey]
        refresh()
    end)
end

local function makeSlider(label, cfgKey, minV, maxV, order)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,BTN_H+12) row.BackgroundColor3=Color3.fromRGB(22,22,22)
    row.BorderSizePixel=0 row.LayoutOrder=order row.ZIndex=6 row.Parent=SF
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-60,0,18) lbl.Position=UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency=1 lbl.Text=label
    lbl.TextColor3=Color3.fromRGB(220,220,220) lbl.TextSize=BASE_FONT-1
    lbl.Font=Enum.Font.Gotham lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.ZIndex=7 lbl.Parent=row

    local valLbl=Instance.new("TextLabel")
    valLbl.Size=UDim2.new(0,50,0,18) valLbl.Position=UDim2.new(1,-58,0,4)
    valLbl.BackgroundTransparency=1 valLbl.Text=tostring(CFG[cfgKey])
    valLbl.TextColor3=Color3.fromRGB(255,215,0) valLbl.TextSize=BASE_FONT-1
    valLbl.Font=Enum.Font.GothamBold valLbl.TextXAlignment=Enum.TextXAlignment.Right
    valLbl.ZIndex=7 valLbl.Parent=row

    local track=Instance.new("Frame")
    track.Size=UDim2.new(1,-20,0,6) track.Position=UDim2.new(0,10,1,-16)
    track.BackgroundColor3=Color3.fromRGB(50,50,50) track.BorderSizePixel=0
    track.ZIndex=7 track.Parent=row
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)

    local fill=Instance.new("Frame")
    fill.Size=UDim2.new((CFG[cfgKey]-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3=Color3.fromRGB(255,215,0) fill.BorderSizePixel=0
    fill.ZIndex=8 fill.Parent=track
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)

    local thumb=Instance.new("TextButton")
    thumb.Size=UDim2.new(0,16,0,16) thumb.BackgroundColor3=Color3.fromRGB(255,255,255)
    thumb.Text="" thumb.BorderSizePixel=0 thumb.ZIndex=9
    thumb.Position=UDim2.new((CFG[cfgKey]-minV)/(maxV-minV),0,0.5,-8)
    thumb.Parent=track
    Instance.new("UICorner",thumb).CornerRadius=UDim.new(1,0)

    local dragging=false
    local function updateVal(inputPos)
        local trackAbs = track.AbsolutePosition
        local trackSz  = track.AbsoluteSize
        local rel = math.clamp((inputPos.X - trackAbs.X) / trackSz.X, 0, 1)
        local val = math.floor(minV + rel*(maxV-minV) + 0.5)
        CFG[cfgKey] = val
        valLbl.Text  = tostring(val)
        fill.Size    = UDim2.new(rel,0,1,0)
        thumb.Position=UDim2.new(rel,0,0.5,-8)
    end

    thumb.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType==Enum.UserInputType.MouseMovement
        or inp.UserInputType==Enum.UserInputType.Touch then
            updateVal(inp.Position)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=false
        end
    end)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then
            updateVal(inp.Position)
        end
    end)
end

-- ══════════════════════════════════════════════════════
--  FLOATING CIRCLE TOGGLE
-- ══════════════════════════════════════════════════════
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
                MF.Visible = not MF.Visible
            end
        end
    end)
end

-- ══════════════════════════════════════════════════════
--  MENU ITEMS — called AFTER builder functions exist
-- ══════════════════════════════════════════════════════
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

print("✅ PRIMODAXVGRANT v5.3 loaded — Vagrant Survival | ADMIN: PRIMODAX")
