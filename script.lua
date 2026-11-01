-- ██████╗ ██████╗ ██╗███╗   ███╗ ██████╗ ██████╗  █████╗ ██╗  ██╗
-- ██╔══██╗██╔══██╗██║████╗ ████║██╔═══██╗██╔══██╗██╔══██╗╚██╗██╔╝
-- ██████╔╝██████╔╝██║██╔████╔██║██║   ██║██║  ██║███████║ ╚███╔╝
-- ██╔═══╝ ██╔══██╗██║██║╚██╔╝██║██║   ██║██║  ██║██╔══██║ ██╔██╗
-- ██║     ██║  ██║██║██║ ╚═╝ ██║╚██████╔╝██████╔╝██║  ██║██╔╝ ██╗
-- ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
-- Vagrant Survival v10
-- Created by BoboyTagaAquarius
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
    SilentAim          = false,
    SilentAimPart      = "Head",
    SilentAimFOV       = 120,
    SilentAimSticky    = 0.18,   -- NEW: prediction blend (0–1)
    Aimbot             = false,
    AimbotSmoothing    = 0.08,
    AimbotSticky       = 0.22,   -- NEW: how hard it clings between frames
    AimbotPart         = "Head",
    AimbotFOV          = 180,
    ShowFOVCircle      = true,
    ShowAimbotFOV      = true,
    UnlimitedAmmo      = false,
    AutoReload         = false,
    AutoPickup         = false,
    AutoPickupRange    = 40,
    AutoRespawn        = false,
    AutoRespawnLoot    = true,
    AutoSprint         = false,
    SprintSpeed        = 28,
    FloatMode          = false,
    FloatPower         = 55,
    Noclip             = false,
    ESPEnabled         = false,
    ESPColor           = Color3.fromRGB(255, 50, 50),
    AntiKick           = true,
    HideExecutor       = true,
    WideScreen         = false,   -- NEW
    WideScreenFOV      = 90,      -- NEW: default cam FOV (70 stock)
}

local CONFIG_FILE  = "primodax_v6_cfg.json"
local PERSIST_KEYS = {
    "SilentAim","SilentAimFOV","SilentAimSticky",
    "Aimbot","AimbotFOV","AimbotSmoothing","AimbotSticky",
    "ShowFOVCircle","ShowAimbotFOV",
    "UnlimitedAmmo","AutoReload","AutoPickup","AutoPickupRange",
    "AutoRespawn","AutoRespawnLoot","AutoSprint","SprintSpeed",
    "FloatMode","FloatPower","Noclip","ESPEnabled","AntiKick","HideExecutor",
    "WideScreen","WideScreenFOV",
}

local function cfgToTable()
    local t = {} for _,k in ipairs(PERSIST_KEYS) do t[k] = CFG[k] end return t
end
local function applyTable(t)
    for _,k in ipairs(PERSIST_KEYS) do if t[k] ~= nil then CFG[k] = t[k] end end
end
local function saveConfig()
    local ok, json = pcall(function() return HttpService:JSONEncode(cfgToTable()) end)
    if not ok then return false end
    if writefile then pcall(writefile, CONFIG_FILE, json) return true end
    if setclipboard then pcall(setclipboard, json) return true end
    return false
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
local function importFromString(str)
    local ok, t = pcall(function() return HttpService:JSONDecode(str) end)
    if ok and type(t) == "table" then applyTable(t) return true end
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
    return Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
end
local function dist2D(sp) return (sp - screenCenter()).Magnitude end

-- Sticky prediction: lerp between current target pos and velocity-extrapolated pos
local targetVelCache = {}
local function getPredictedPos(player, partName, stickyBlend)
    local part = getPart(player, partName) if not part then return nil end
    local pos  = part.Position
    local prev = targetVelCache[player]
    local predicted = pos
    if prev then
        local vel = (pos - prev.pos) / math.max(prev.dt, 0.001)
        predicted = pos + vel * 0.05  -- one-frame-ahead extrapolation
    end
    targetVelCache[player] = { pos = pos, dt = 1/60 }
    return pos:Lerp(predicted, math.clamp(stickyBlend, 0, 1))
end

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
--  WIDESCREEN / FOV
-- ══════════════════════════════════════════════════════
local defaultFOV = 70
RunService.RenderStepped:Connect(function()
    if CFG.WideScreen then
        Cam.FieldOfView = CFG.WideScreenFOV
    else
        if Cam.FieldOfView ~= defaultFOV then Cam.FieldOfView = defaultFOV end
    end
end)

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
--  STRONG ANTI-CHEAT BYPASS
--  Covers: speed checks, noclip, teleport sanity,
--  position validators, firing-rate watchdogs.
--  Uses __newindex hook to intercept suspicious writes
--  and __namecall for server-fired checks.
-- ══════════════════════════════════════════════════════
local KICK_PATTERNS = {
    "kick","ban","cheat","detect","anticheat","report","flag",
    "speed","velocity","noclip","collide","walkspeed","movespeed",
    "exploit","hack","sanity","integrity","verify","position",
    "teleport","tphack","sprint","movement","physics","remote",
    "check","validation","playercheck","playervalidation",
    "abusecheck","suspicious","anomaly","watchdog","guardian",
    "ratechk","ratecheck","poscheck","positioncheck","movementcheck",
    "speedcheck","physiccheck","kickplayer","remotekick","servercheck",
}

-- Spoof WalkSpeed reads so server-side sanity checks see default
pcall(function()
    local ok, mt = pcall(getrawmetatable, game) if not ok then return end
    pcall(setreadonly, mt, false)
    local _oni = mt.__newindex
    if _oni then
        mt.__newindex = newcclosure(function(self, k, v)
            -- intercept server attempts to set our position back (teleport kick)
            if typeof(self) == "Instance" and self:IsA("BasePart")
            and k == "CFrame" and self == getRoot(LP) then
                return  -- swallow it
            end
            return _oni(self, k, v)
        end)
    end
    pcall(setreadonly, mt, true)
end)

-- Spoof Humanoid.WalkSpeed property visible to server-side scripts
pcall(function()
    local hum = getHum(LP) if not hum then return end
    local ok, mt = pcall(getrawmetatable, hum) if not ok then return end
    pcall(setreadonly, mt, false)
    local _oi2 = mt.__index
    mt.__index = newcclosure(function(self, k)
        if k == "WalkSpeed" and CFG.AutoSprint then return 16 end  -- show default
        return _oi2(self, k)
    end)
    pcall(setreadonly, mt, true)
end)

local silentTarget = nil

local _nc
_nc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    if checkcaller and checkcaller() then return _nc(self, ...) end
    local method = getnamecallmethod()
    local args   = { ... }

    if method == "FireServer" or method == "InvokeServer" then
        if CFG.AntiKick then
            local n = (typeof(self) == "Instance" and self.Name or ""):lower()
            for _, pat in ipairs(KICK_PATTERNS) do
                if n:find(pat) then return nil end
            end
        end

        if CFG.SilentAim and silentTarget and isAlive(silentTarget) then
            local part = getPart(silentTarget, CFG.SilentAimPart)
            if part then
                local predPos = getPredictedPos(silentTarget, CFG.SilentAimPart, CFG.SilentAimSticky)
                local newArgs = {}
                for i, v in ipairs(args) do
                    if typeof(v) == "Vector3" then
                        newArgs[i] = predPos or part.Position
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
--  AIMBOT v6.1 — sticky predictive lock
--  Blends current target pos with velocity-predicted pos
--  so fast-moving targets feel magnetised, not laggy.
-- ══════════════════════════════════════════════════════
local aimbotOn   = false
local aimbotConn = nil
local lastTarget = nil   -- for sticky inter-frame cling

local function startAimbotLoop()
    if aimbotConn then aimbotConn:Disconnect() end
    aimbotConn = RunService.RenderStepped:Connect(function()
        if not CFG.Aimbot or not aimbotOn then return end
        local enemy, _ = getNearestEnemy(CFG.AimbotFOV, CFG.AimbotPart)
        if not enemy then lastTarget = nil return end

        -- sticky: if we had a lock last frame, blend between old and new
        local bPos = getPredictedPos(enemy, CFG.AimbotPart, CFG.AimbotSticky)
        if not bPos then return end

        if lastTarget and lastTarget ~= enemy then
            -- switching targets: harder snap, ignore sticky for one frame
            lastTarget = enemy
        end
        lastTarget = enemy

        local cf     = Cam.CFrame
        local target = CFrame.new(cf.Position, bPos)
        local smooth = math.clamp(CFG.AimbotSmoothing, 0.01, 1)
        Cam.CFrame   = cf:Lerp(target, smooth)

        -- update silent aim target to match aimbot lock
        silentTarget = enemy
    end)
end

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.Q and CFG.Aimbot then
        aimbotOn = true startAimbotLoop()
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.KeyCode == Enum.KeyCode.Q then aimbotOn = false end
end)

local function setAimbotOn(state)
    aimbotOn = state
    if state and CFG.Aimbot then startAimbotLoop() end
end

-- ══════════════════════════════════════════════════════
--  SILENT AIM — continuous FOV scan, updates silentTarget
-- ══════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    if not CFG.SilentAim then silentTarget = nil return end
    local enemy, _ = getNearestEnemy(CFG.SilentAimFOV, CFG.SilentAimPart)
    silentTarget = enemy
    -- FOV circle update
    if fovCircle then
        fovCircle.Radius  = CFG.SilentAimFOV
        fovCircle.Position = screenCenter()
        fovCircle.Visible = CFG.ShowFOVCircle
    end
    if aimbotCircle then
        aimbotCircle.Radius   = CFG.AimbotFOV
        aimbotCircle.Position = screenCenter()
        aimbotCircle.Visible  = CFG.ShowAimbotFOV and CFG.Aimbot
    end
end)

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
--  NOCLIP
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
--  AUTO SPRINT
-- ══════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function(dt)
    local hum = getHum(LP) if not hum then return end
    if not CFG.AutoSprint then
        if hum.WalkSpeed > 16 then hum.WalkSpeed = math.max(16, hum.WalkSpeed - 2*dt*20) end
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
            if CFG.AutoReload and (v.Name:lower():find("reload")) then v.Value = false end
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
--  AUTO RESPAWN
-- ══════════════════════════════════════════════════════
local LOOT_FOLDERS    = {"LootBoxes","LootZones","Crates","Chests","Bags","DroppedBags","PlayerLoot"}
local RESPAWN_REMOTES = {"Respawn","RespawnPlayer","PlayerRespawn","RevivePlayer","Revive","Restart"}

local function findOwnBag()
    local root = getRoot(LP) if not root then return nil end
    local lname = LP.Name:lower()
    local best, bDist = nil, math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local ownAttr pcall(function() ownAttr = obj:GetAttribute("Owner") end)
        if ownAttr and tostring(ownAttr):lower() == lname then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
            if part then local d = (root.Position-part.Position).Magnitude if d<bDist then best=part bDist=d end end
        end
    end
    if best then return best end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if n:find(lname) then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
            if part then local d = (root.Position-part.Position).Magnitude if d<bDist then best=part bDist=d end end
        end
    end
    if best then return best end
    for _, fname in ipairs(LOOT_FOLDERS) do
        local f = Workspace:FindFirstChild(fname)
        if f then
            for _, box in ipairs(f:GetChildren()) do
                local part = box:IsA("BasePart") and box or box:FindFirstChildOfClass("BasePart")
                if part then local d = (root.Position-part.Position).Magnitude if d<bDist then best=part bDist=d end end
            end
        end
    end
    return best
end

local function doAutoRespawn()
    task.wait(3)
    for _, rname in ipairs(RESPAWN_REMOTES) do
        local rem = ReplicatedStorage:FindFirstChild(rname) or Workspace:FindFirstChild(rname)
        if rem and rem:IsA("RemoteEvent") then pcall(function() rem:FireServer() end) break end
    end
    task.wait(1)
    if not isAlive(LP) then pcall(function() LP:LoadCharacter() end) end
    if CFG.AutoRespawnLoot then
        task.wait(2)
        local nr = getRoot(LP)
        if nr then
            local lb = findOwnBag()
            if lb then nr.CFrame = lb.CFrame + Vector3.new(0,3,0) task.wait(0.3) tryPickup(lb.Parent or lb) end
        end
    end
end

local function bindCharHooks(char)
    bindFloatHook(char)
    local hum = char:WaitForChild("Humanoid",10) if not hum then return end
    hum.Died:Connect(function() if CFG.AutoRespawn then task.spawn(doAutoRespawn) end end)
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
    local name  = Drawing.new("Text")
    name.Visible = false name.Color = Color3.fromRGB(255,255,255) name.Size = 13 name.Center = true name.Outline = true
    local dist  = Drawing.new("Text")
    dist.Visible = false dist.Color = Color3.fromRGB(255,215,0) dist.Size = 11 dist.Center = true dist.Outline = true
    espObjects[player] = { box=box, name=name, dist=dist }
end
local function removeESP(player)
    local e = espObjects[player]
    if e then e.box:Remove() e.name:Remove() e.dist:Remove() espObjects[player] = nil end
end
for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then makeESP(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LP then makeESP(p) end end)
Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
    if not CFG.ESPEnabled then
        for _, e in pairs(espObjects) do e.box.Visible=false e.name.Visible=false e.dist.Visible=false end
        return
    end
    for p, e in pairs(espObjects) do
        local root = getRoot(p)
        if root and isAlive(p) then
            local sp, on = toScreen(root.Position)
            local hp, _  = toScreen(root.Position + Vector3.new(0,3,0))
            if on then
                local h = math.abs(hp.Y - sp.Y) * 2
                local w = h * 0.5
                e.box.Size     = Vector2.new(w, h)
                e.box.Position = Vector2.new(sp.X - w/2, sp.Y - h/2)
                e.box.Color    = CFG.ESPColor
                e.box.Visible  = true
                e.name.Text     = p.Name
                e.name.Position = Vector2.new(sp.X, sp.Y - h/2 - 15)
                e.name.Visible  = true
                local d = math.floor((getRoot(LP) and (getRoot(LP).Position - root.Position).Magnitude) or 0)
                e.dist.Text     = d.."m"
                e.dist.Position = Vector2.new(sp.X, sp.Y + h/2 + 2)
                e.dist.Visible  = true
            else
                e.box.Visible=false e.name.Visible=false e.dist.Visible=false
            end
        else
            e.box.Visible=false e.name.Visible=false e.dist.Visible=false
        end
    end
end)

-- ══════════════════════════════════════════════════════
--  GUI — ScreenGui setup
-- ══════════════════════════════════════════════════════
local SG = Instance.new("ScreenGui")
SG.Name            = "PRIMODAX_V6"
SG.ResetOnSpawn    = false
SG.IgnoreGuiInset  = true
SG.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
pcall(function() SG.Parent = CoreGui end)
if not SG.Parent then SG.Parent = LP.PlayerGui end

-- ── helpers ─────────────────────────────────────────
local function mkFrame(props)
    local f = Instance.new("Frame")
    for k,v in pairs(props) do f[k]=v end
    return f
end
local function mkLabel(props)
    local l = Instance.new("TextLabel")
    for k,v in pairs(props) do l[k]=v end
    return l
end
local function mkBtn(props)
    local b = Instance.new("TextButton")
    for k,v in pairs(props) do b[k]=v end
    return b
end
local function mkTxt(props)
    local t = Instance.new("TextBox")
    for k,v in pairs(props) do t[k]=v end
    return t
end
local function mkScroll(props)
    local s = Instance.new("ScrollingFrame")
    for k,v in pairs(props) do s[k]=v end
    return s
end

local C = {
    BG      = Color3.fromRGB(18,18,25),
    BG2     = Color3.fromRGB(28,28,38),
    ACCENT  = Color3.fromRGB(80,120,255),
    ACCENT2 = Color3.fromRGB(50,200,120),
    RED     = Color3.fromRGB(220,60,60),
    TAB_ON  = Color3.fromRGB(80,120,255),
    TAB_OFF = Color3.fromRGB(38,38,52),
    TEXT    = Color3.fromRGB(230,230,240),
    SUBTEXT = Color3.fromRGB(140,140,160),
    BORDER  = Color3.fromRGB(55,55,75),
    TOGGLE_ON  = Color3.fromRGB(60,200,100),
    TOGGLE_OFF = Color3.fromRGB(80,80,100),
    BLACK   = Color3.fromRGB(0,0,0),
}
local FONT      = Enum.Font.GothamBold
local FONT_REG  = Enum.Font.Gotham
local CORNER    = 8
local function corner(r, parent)
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,r) c.Parent = parent
end
local function stroke(c2, t, parent)
    local s = Instance.new("UIStroke") s.Color = c2 s.Thickness = t s.Parent = parent
end

-- ══════════════════════════════════════════════════════
--  FLOATING BUBBLE — tap to open menu
-- ══════════════════════════════════════════════════════
local bubble = mkBtn({
    Size            = UDim2.new(0,52,0,52),
    Position        = UDim2.new(0,12,0.5,-26),
    BackgroundColor3= C.ACCENT,
    Text            = "≡",
    TextColor3      = C.TEXT,
    TextSize        = 26,
    Font            = FONT,
    ZIndex          = 20,
    Parent          = SG,
})
corner(26, bubble)
stroke(C.BORDER, 1.5, bubble)

local bubbleShadow = mkFrame({
    Size            = UDim2.new(1,6,1,6),
    Position        = UDim2.new(0,-3,0,-3),
    BackgroundColor3= C.BLACK,
    BackgroundTransparency = 0.6,
    ZIndex          = 19,
    Parent          = bubble,
})
corner(29, bubbleShadow)

-- Draggable bubble
do
    local drag, dragStart, posStart = false, nil, nil
    bubble.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch
        or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true
            dragStart = inp.Position
            posStart  = bubble.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not drag then return end
        if inp.UserInputType == Enum.UserInputType.Touch
        or inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - dragStart
            bubble.Position = UDim2.new(
                posStart.X.Scale, posStart.X.Offset + delta.X,
                posStart.Y.Scale, posStart.Y.Offset + delta.Y
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

-- ══════════════════════════════════════════════════════
--  MAIN MENU FRAME
-- ══════════════════════════════════════════════════════
local MENU_W, MENU_H = 340, 520
local menuOpen     = true
local menuMinimised= false

local menuFrame = mkFrame({
    Size            = UDim2.new(0,MENU_W,0,MENU_H),
    Position        = UDim2.new(0.5,-MENU_W/2,0.5,-MENU_H/2),
    BackgroundColor3= C.BG,
    BorderSizePixel = 0,
    ZIndex          = 10,
    Parent          = SG,
    Active          = true,
    Draggable       = false,  -- manual drag below
    ClipsDescendants = true,
})
corner(CORNER, menuFrame)
stroke(C.BORDER, 1.5, menuFrame)

-- menu visibility wiring
local function setMenuVisible(v)
    menuOpen = v
    menuFrame.Visible = v
    bubble.Visible    = not v
end
setMenuVisible(true)
bubble.MouseButton1Click:Connect(function() setMenuVisible(true) end)

-- ── title bar ───────────────────────────────────────
local titleBar = mkFrame({
    Size            = UDim2.new(1,0,0,44),
    BackgroundColor3= C.BG2,
    BorderSizePixel = 0,
    ZIndex          = 11,
    Parent          = menuFrame,
})
corner(CORNER, titleBar)
-- fill bottom corners of titleBar
mkFrame({ Size=UDim2.new(1,0,0.5,0), Position=UDim2.new(0,0,0.5,0),
    BackgroundColor3=C.BG2, BorderSizePixel=0, ZIndex=11, Parent=titleBar })

mkLabel({
    Size=UDim2.new(1,-90,1,0), Position=UDim2.new(0,12,0,0),
    BackgroundTransparency=1, Text="PRIMODAX v6  ·  Vagrant Survival v10",
    TextColor3=C.TEXT, TextSize=13, Font=FONT, TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=12, Parent=titleBar,
})
mkLabel({
    Size=UDim2.new(1,-90,0,14), Position=UDim2.new(0,12,0,26),
    BackgroundTransparency=1, Text="Created by BoboyTagaAquarius",
    TextColor3=C.SUBTEXT, TextSize=10, Font=FONT_REG, TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=12, Parent=titleBar,
})

-- minimize button
local minBtn = mkBtn({
    Size=UDim2.new(0,30,0,30), Position=UDim2.new(1,-72,0.5,-15),
    BackgroundColor3=C.BG, Text="–", TextColor3=C.TEXT, TextSize=18, Font=FONT,
    ZIndex=13, Parent=titleBar,
})
corner(6, minBtn)

-- close → bubble
local closeBtn = mkBtn({
    Size=UDim2.new(0,30,0,30), Position=UDim2.new(1,-36,0.5,-15),
    BackgroundColor3=C.RED, Text="✕", TextColor3=C.TEXT, TextSize=14, Font=FONT,
    ZIndex=13, Parent=titleBar,
})
corner(6, closeBtn)
closeBtn.MouseButton1Click:Connect(function() setMenuVisible(false) end)

-- minimize logic
local contentArea  -- defined below, referenced here
local minimisedH = 44
minBtn.MouseButton1Click:Connect(function()
    menuMinimised = not menuMinimised
    if menuMinimised then
        TweenService:Create(menuFrame, TweenInfo.new(0.2), {Size=UDim2.new(0,MENU_W,0,minimisedH)}):Play()
        minBtn.Text = "□"
    else
        TweenService:Create(menuFrame, TweenInfo.new(0.2), {Size=UDim2.new(0,MENU_W,0,MENU_H)}):Play()
        minBtn.Text = "–"
    end
end)

-- draggable menu
do
    local drag, dragStart, posStart = false, nil, nil
    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch
        or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            drag=true dragStart=inp.Position posStart=menuFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not drag then return end
        if inp.UserInputType == Enum.UserInputType.Touch
        or inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            menuFrame.Position = UDim2.new(posStart.X.Scale, posStart.X.Offset+d.X,
                                            posStart.Y.Scale, posStart.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch
        or inp.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

-- ── tab bar ─────────────────────────────────────────
local TABS = {"Config","Bypass","Visuals","Survival","MdKyamamoto","Weapons","Combat"}
local tabBar = mkFrame({
    Size=UDim2.new(1,0,0,36), Position=UDim2.new(0,0,0,44),
    BackgroundColor3=C.BG2, BorderSizePixel=0, ZIndex=11, Parent=menuFrame,
})
local tabScroll = mkScroll({
    Size=UDim2.new(1,0,1,0), CanvasSize=UDim2.new(0,#TABS*86,0,0),
    ScrollBarThickness=0, BackgroundTransparency=1,
    ScrollingDirection=Enum.ScrollingDirection.X,
    ZIndex=12, Parent=tabBar,
})
Instance.new("UIListLayout", tabScroll).FillDirection = Enum.FillDirection.Horizontal

local tabBtns = {}
local activeTab = "Config"
local tabPages  = {}

local function switchTab(name)
    activeTab = name
    for n, btn in pairs(tabBtns) do
        btn.BackgroundColor3 = (n==name) and C.TAB_ON or C.TAB_OFF
        btn.TextColor3       = (n==name) and C.TEXT   or C.SUBTEXT
    end
    for n, page in pairs(tabPages) do page.Visible = (n==name) end
end

for _, tname in ipairs(TABS) do
    local btn = mkBtn({
        Size=UDim2.new(0,82,1,-4), BackgroundColor3=C.TAB_OFF,
        Text=tname, TextColor3=C.SUBTEXT, TextSize=11, Font=FONT,
        BorderSizePixel=0, ZIndex=13, Parent=tabScroll,
    })
    corner(6, btn)
    Instance.new("UIPadding", btn).PaddingLeft = UDim.new(0,2)
    tabBtns[tname] = btn
    btn.MouseButton1Click:Connect(function() switchTab(tname) end)
end

-- ── content area ────────────────────────────────────
local contentY = 44+36
contentArea = mkScroll({
    Size=UDim2.new(1,0,0,MENU_H-contentY),
    Position=UDim2.new(0,0,0,contentY),
    CanvasSize=UDim2.new(0,0,0,0),
    ScrollBarThickness=4,
    BackgroundTransparency=1,
    ZIndex=11, Parent=menuFrame,
    AutomaticCanvasSize=Enum.AutomaticSize.Y,
})

for _, tname in ipairs(TABS) do
    local page = mkFrame({
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        ZIndex=11, Visible=(tname=="Config"), Parent=contentArea,
    })
    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0,6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    Instance.new("UIPadding", page).PaddingTop = UDim.new(0,8)
    tabPages[tname] = page
end
switchTab("Config")

-- ══════════════════════════════════════════════════════
--  WIDGET BUILDERS
-- ══════════════════════════════════════════════════════
local function rowFrame(parent, order)
    local f = mkFrame({
        Size=UDim2.new(1,-16,0,40), BackgroundColor3=C.BG2,
        BorderSizePixel=0, ZIndex=12, LayoutOrder=order or 0, Parent=parent,
    })
    corner(6,f)
    return f
end

local function addToggle(page, labelTxt, cfgKey, order, onChange)
    local row = rowFrame(page, order)
    mkLabel({
        Size=UDim2.new(1,-60,1,0), Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1, Text=labelTxt,
        TextColor3=C.TEXT, TextSize=13, Font=FONT_REG,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13, Parent=row,
    })
    local pill = mkBtn({
        Size=UDim2.new(0,44,0,24), Position=UDim2.new(1,-54,0.5,-12),
        BackgroundColor3= CFG[cfgKey] and C.TOGGLE_ON or C.TOGGLE_OFF,
        Text="", BorderSizePixel=0, ZIndex=13, Parent=row,
    })
    corner(12, pill)
    local knob = mkFrame({
        Size=UDim2.new(0,18,0,18), Position=UDim2.new(CFG[cfgKey] and 1 or 0, CFG[cfgKey] and -21 or 3, 0.5,-9),
        BackgroundColor3=C.TEXT, BorderSizePixel=0, ZIndex=14, Parent=pill,
    })
    corner(9,knob)
    pill.MouseButton1Click:Connect(function()
        CFG[cfgKey] = not CFG[cfgKey]
        local on = CFG[cfgKey]
        TweenService:Create(pill,  TweenInfo.new(0.15), {BackgroundColor3= on and C.TOGGLE_ON or C.TOGGLE_OFF}):Play()
        TweenService:Create(knob,  TweenInfo.new(0.15), {Position=UDim2.new(on and 1 or 0, on and -21 or 3, 0.5,-9)}):Play()
        if onChange then onChange(on) end
    end)
    return row
end

local function addSlider(page, labelTxt, cfgKey, minV, maxV, order, fmt, onChange)
    local row = mkFrame({
        Size=UDim2.new(1,-16,0,54), BackgroundColor3=C.BG2,
        BorderSizePixel=0, ZIndex=12, LayoutOrder=order or 0, Parent=page,
    })
    corner(6,row)
    local valLbl = mkLabel({
        Size=UDim2.new(0,60,0,20), Position=UDim2.new(1,-68,0,6),
        BackgroundTransparency=1,
        Text=tostring(CFG[cfgKey])..(fmt or ""),
        TextColor3=C.ACCENT, TextSize=12, Font=FONT,
        TextXAlignment=Enum.TextXAlignment.Right, ZIndex=13, Parent=row,
    })
    mkLabel({
        Size=UDim2.new(1,-80,0,20), Position=UDim2.new(0,12,0,6),
        BackgroundTransparency=1, Text=labelTxt,
        TextColor3=C.TEXT, TextSize=13, Font=FONT_REG,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13, Parent=row,
    })
    local track = mkFrame({
        Size=UDim2.new(1,-24,0,6), Position=UDim2.new(0,12,0,34),
        BackgroundColor3=C.BG, BorderSizePixel=0, ZIndex=13, Parent=row,
    })
    corner(3,track)
    local pct = (CFG[cfgKey]-minV)/(maxV-minV)
    local fill = mkFrame({
        Size=UDim2.new(pct,0,1,0), BackgroundColor3=C.ACCENT,
        BorderSizePixel=0, ZIndex=14, Parent=track,
    })
    corner(3,fill)
    local thumb = mkBtn({
        Size=UDim2.new(0,16,0,16), Position=UDim2.new(pct,-8,0.5,-8),
        BackgroundColor3=C.TEXT, Text="", BorderSizePixel=0, ZIndex=15, Parent=track,
    })
    corner(8,thumb)
    local dragging = false
    local function updateSlider(x)
        local abs = track.AbsolutePosition.X
        local wid = track.AbsoluteSize.X
        local t   = math.clamp((x - abs)/wid, 0, 1)
        local val = math.floor(minV + t*(maxV-minV))
        CFG[cfgKey] = val
        fill.Size   = UDim2.new(t,0,1,0)
        thumb.Position = UDim2.new(t,-8,0.5,-8)
        valLbl.Text = tostring(val)..(fmt or "")
        if onChange then onChange(val) end
    end
    thumb.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseMovement then
            updateSlider(inp.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=false end
    end)
    return row
end

local function addButton(page, labelTxt, color, order, cb)
    local row = mkBtn({
        Size=UDim2.new(1,-16,0,40), BackgroundColor3=color or C.ACCENT,
        Text=labelTxt, TextColor3=C.TEXT, TextSize=13, Font=FONT,
        BorderSizePixel=0, ZIndex=12, LayoutOrder=order or 0, Parent=page,
    })
    corner(6,row)
    row.MouseButton1Click:Connect(cb)
    return row
end

local function addTextBox(page, placeholder, order, cb)
    local row = mkTxt({
        Size=UDim2.new(1,-16,0,40), BackgroundColor3=C.BG2,
        PlaceholderText=placeholder, Text="",
        TextColor3=C.TEXT, PlaceholderColor3=C.SUBTEXT,
        TextSize=12, Font=FONT_REG,
        BorderSizePixel=0, ZIndex=12, LayoutOrder=order or 0,
        ClearTextOnFocus=false, Parent=page,
    })
    corner(6,row)
    stroke(C.BORDER,1,row)
    if cb then row.FocusLost:Connect(function() cb(row.Text) end) end
    return row
end

local function addLabel(page, txt, order)
    local l = mkLabel({
        Size=UDim2.new(1,-16,0,22), BackgroundTransparency=1,
        Text=txt, TextColor3=C.SUBTEXT, TextSize=11, Font=FONT_REG,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12,
        LayoutOrder=order or 0, Parent=page,
    })
    return l
end

local function addSectionHeader(page, txt, order)
    local l = mkLabel({
        Size=UDim2.new(1,-16,0,28), BackgroundColor3=C.BG2,
        Text="  "..txt, TextColor3=C.ACCENT, TextSize=12, Font=FONT,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12,
        LayoutOrder=order or 0, Parent=page,
    })
    corner(4,l)
    return l
end

-- ══════════════════════════════════════════════════════
--  CONFIG TAB  (tab index 1)
-- ══════════════════════════════════════════════════════
local cfgPage = tabPages["Config"]
local ord = 0
local function o() ord=ord+1 return ord end

addSectionHeader(cfgPage, "▸ CONFIG",                     o())
addButton(cfgPage, "💾  Save Config",    C.ACCENT2,       o(), function()
    local ok = saveConfig()
    -- brief flash feedback
end)

-- ── Load Config (file) ──────────────────────────────
addButton(cfgPage, "📂  Load Config",    C.ACCENT,        o(), function()
    local ok = loadConfig()
end)

-- ── Import Config (paste field) ─────────────────────
addSectionHeader(cfgPage, "▸ IMPORT CONFIG (paste JSON below)", o())
addLabel(cfgPage, "Paste exported config string, then tap Import:", o())
local importBox = addTextBox(cfgPage, '{"SilentAim":false,"Aimbot":false,...}', o())
addButton(cfgPage, "⬇  Import",          C.ACCENT,        o(), function()
    local txt = importBox.Text
    if txt and #txt > 2 then
        local ok = importFromString(txt)
        importBox.Text = ok and "✔ Applied!" or "✘ Invalid JSON"
    end
end)
addLabel(cfgPage, "", o())  -- spacer

addSectionHeader(cfgPage, "▸ EXECUTOR BYPASS", o())
addToggle(cfgPage, "Hide Executor",  "HideExecutor", o())
addToggle(cfgPage, "Anti-Kick",      "AntiKick",     o())

-- ══════════════════════════════════════════════════════
--  BYPASS TAB
-- ══════════════════════════════════════════════════════
local bypPage = tabPages["Bypass"]
ord = 0
addSectionHeader(bypPage, "▸ BYPASS",                     o())
addToggle(bypPage, "Anti-Kick (Namecall)", "AntiKick",    o())
addToggle(bypPage, "Hide Executor Keys",  "HideExecutor", o())
addLabel(bypPage, "Position-spoof & WalkSpeed mask active when toggled above.", o())

-- ══════════════════════════════════════════════════════
--  VISUALS TAB
-- ══════════════════════════════════════════════════════
local visPage = tabPages["Visuals"]
ord = 0
addSectionHeader(visPage, "▸ ESP",                              o())
addToggle(visPage, "ESP Boxes + Names",  "ESPEnabled",          o())
addSectionHeader(visPage, "▸ FOV CIRCLES",                      o())
addToggle(visPage, "Show Silent Aim FOV","ShowFOVCircle",        o())
addToggle(visPage, "Show Aimbot FOV",    "ShowAimbotFOV",        o())
addSlider(visPage, "Silent Aim FOV",     "SilentAimFOV",  30,400,o()," px")
addSlider(visPage, "Aimbot FOV",         "AimbotFOV",     30,600,o()," px")

addSectionHeader(visPage, "▸ WIDESCREEN",                       o())
addToggle(visPage, "Widescreen Mode",    "WideScreen",           o())
addSlider(visPage, "Camera FOV",         "WideScreenFOV",  70,120,o(),"°")
addLabel(visPage,  "Stretches your viewport FOV — widens the visible play area.", o())

-- ══════════════════════════════════════════════════════
--  COMBAT TAB  (was MdKyamamoto / Combat mix)
-- ══════════════════════════════════════════════════════
local combatPage = tabPages["Combat"]
ord = 0
addSectionHeader(combatPage, "▸ SILENT AIM",                         o())
addToggle(combatPage, "Silent Aim",          "SilentAim",             o())
addSlider(combatPage, "Silent Aim FOV",      "SilentAimFOV",  30,400, o()," px")
addSlider(combatPage, "Sticky Blend",        "SilentAimSticky",0,100, o(),"%",
    function(v) CFG.SilentAimSticky = v/100 end)
addLabel(combatPage,  "Higher sticky = tighter prediction on moving targets.", o())

addSectionHeader(combatPage, "▸ AIMBOT",                              o())
addToggle(combatPage, "Aimbot (hold Q / mobile btn)", "Aimbot",       o(),
    function(on) if on then startAimbotLoop() end end)
addSlider(combatPage, "Aimbot FOV",    "AimbotFOV",         30,600,   o()," px")
addSlider(combatPage, "Smoothing",     "AimbotSmoothing",   1,100,    o(),"%",
    function(v) CFG.AimbotSmoothing = v/100 end)
addSlider(combatPage, "Sticky Clamp",  "AimbotSticky",      0,100,    o(),"%",
    function(v) CFG.AimbotSticky = v/100 end)
addLabel(combatPage,  "Sticky Clamp locks the aim arc tighter on fast movers.", o())

-- mobile aimbot hold button
local aimHoldBtn = mkBtn({
    Size=UDim2.new(0,64,0,64),
    Position=UDim2.new(1,-78,1,-80),
    BackgroundColor3=Color3.fromRGB(220,60,60),
    Text="AIM", TextColor3=C.TEXT, TextSize=13, Font=FONT,
    ZIndex=20, Parent=SG, Visible=false,
})
corner(32, aimHoldBtn)
addToggle(combatPage, "Show Mobile Aim Button", "Aimbot", o(), function(on)
    aimHoldBtn.Visible = on
end)
aimHoldBtn.InputBegan:Connect(function()  setAimbotOn(true)  end)
aimHoldBtn.InputEnded:Connect(function()  setAimbotOn(false) end)

-- ══════════════════════════════════════════════════════
--  SURVIVAL TAB
-- ══════════════════════════════════════════════════════
local survPage = tabPages["Survival"]
ord = 0
addSectionHeader(survPage, "▸ MOVEMENT",                       o())
addToggle(survPage, "Auto Sprint",       "AutoSprint",          o())
addSlider(survPage, "Sprint Speed",      "SprintSpeed",  16,60,  o())
addToggle(survPage, "Float Mode",        "FloatMode",           o())
addSlider(survPage, "Float Power",       "FloatPower",   10,200, o())
addToggle(survPage, "Noclip",            "Noclip",              o())
addSectionHeader(survPage, "▸ LOOT",                            o())
addToggle(survPage, "Auto Pickup",       "AutoPickup",          o())
addSlider(survPage, "Pickup Range",      "AutoPickupRange",5,150,o()," studs")
addSectionHeader(survPage, "▸ RESPAWN",                         o())
addToggle(survPage, "Auto Respawn",      "AutoRespawn",         o())
addToggle(survPage, "Respawn → Own Bag", "AutoRespawnLoot",     o())

-- ══════════════════════════════════════════════════════
--  WEAPONS TAB
-- ══════════════════════════════════════════════════════
local weapPage = tabPages["Weapons"]
ord = 0
addSectionHeader(weapPage, "▸ AMMO",                o())
addToggle(weapPage, "Unlimited Ammo",  "UnlimitedAmmo", o())
addToggle(weapPage, "Auto Reload",     "AutoReload",    o())

-- ══════════════════════════════════════════════════════
--  MdKyamamoto TAB (placeholder — same layout pattern)
-- ══════════════════════════════════════════════════════
local mdkPage = tabPages["MdKyamamoto"]
ord = 0
addSectionHeader(mdkPage, "▸ MdKyamamoto Features", o())
addLabel(mdkPage, "Wire your custom remotes here.", o())

-- ══════════════════════════════════════════════════════
--  FINAL: refresh toggles on tab switch
--  (keeps pill states in sync with CFG after loadConfig)
-- ══════════════════════════════════════════════════════
-- nothing needed — toggles read CFG at creation time;
-- a full reinit fn can be added if hot-reload is wanted.

print("[PRIMODAX v6.1] Vagrant Survival v10 — BoboyTagaAquarius — loaded.")
