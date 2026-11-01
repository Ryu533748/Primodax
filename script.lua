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
    SilentAimSticky    = 0.18,
    Aimbot             = false,
    AimbotSmoothing    = 0.08,
    AimbotSticky       = 0.22,
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
    WideScreen         = false,
    WideScreenFOV      = 90,
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
    local t = {} for _,k in ipairs(PERSIST_KEYS) do t[k]=CFG[k] end return t
end
local function applyTable(t)
    for _,k in ipairs(PERSIST_KEYS) do if t[k]~=nil then CFG[k]=t[k] end end
end
local function saveConfig()
    local ok,json = pcall(function() return HttpService:JSONEncode(cfgToTable()) end)
    if not ok then return false end
    if writefile then pcall(writefile,CONFIG_FILE,json) return true end
    if setclipboard then pcall(setclipboard,json) return true end
    return false
end
local function loadConfig()
    if readfile then
        local ok,raw = pcall(readfile,CONFIG_FILE)
        if ok and raw and #raw>2 then
            local ok2,t = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok2 and t then applyTable(t) return true end
        end
    end
    return false
end
local function importFromString(str)
    local ok,t = pcall(function() return HttpService:JSONDecode(str) end)
    if ok and type(t)=="table" then applyTable(t) return true end
    return false
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
    local s,on = Cam:WorldToViewportPoint(pos) return Vector2.new(s.X,s.Y),on
end
local function screenCenter()
    return Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2)
end
local function dist2D(sp) return (sp-screenCenter()).Magnitude end

local targetVelCache = {}
local function getPredictedPos(player,partName,stickyBlend)
    local part = getPart(player,partName) if not part then return nil end
    local pos  = part.Position
    local prev = targetVelCache[player]
    local predicted = pos
    if prev then
        local vel = (pos-prev.pos)/math.max(prev.dt,0.001)
        predicted = pos + vel*0.05
    end
    targetVelCache[player] = {pos=pos,dt=1/60}
    return pos:Lerp(predicted,math.clamp(stickyBlend,0,1))
end

local function getNearestEnemy(fovR,part)
    local best,bDist,bPos = nil,fovR,nil
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and isAlive(p) then
            local pt = getPart(p,part or "Head")
            if pt then
                local sp,on = toScreen(pt.Position)
                if on then
                    local d = dist2D(sp)
                    if d<bDist then best=p bDist=d bPos=pt.Position end
                end
            end
        end
    end
    return best,bPos
end

-- ══════════════════════════════════════════════════════
--  WIDESCREEN
-- ══════════════════════════════════════════════════════
local defaultFOV = 70
RunService.RenderStepped:Connect(function()
    if CFG.WideScreen then Cam.FieldOfView=CFG.WideScreenFOV
    elseif Cam.FieldOfView~=defaultFOV then Cam.FieldOfView=defaultFOV end
end)

-- ══════════════════════════════════════════════════════
--  FOV CIRCLES
-- ══════════════════════════════════════════════════════
local fovCircle,aimbotCircle
if Drawing then
    fovCircle           = Drawing.new("Circle")
    fovCircle.Thickness = 1.5
    fovCircle.Color     = Color3.fromRGB(255,215,0)
    fovCircle.Filled    = false
    fovCircle.Visible   = false
    fovCircle.Radius    = CFG.SilentAimFOV
    fovCircle.Position  = screenCenter()

    aimbotCircle            = Drawing.new("Circle")
    aimbotCircle.Thickness  = 1.2
    aimbotCircle.Color      = Color3.fromRGB(220,220,220)
    aimbotCircle.Filled     = false
    aimbotCircle.Visible    = false
    aimbotCircle.Radius     = CFG.AimbotFOV
    aimbotCircle.Position   = screenCenter()
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
    for _,k in ipairs(EKEYS) do pcall(function() _G[k]=nil end) end
    local ok,mt = pcall(getrawmetatable,game) if not ok then return end
    pcall(setreadonly,mt,false)
    local _oi = mt.__index
    mt.__index = newcclosure(function(self,k)
        local lk = tostring(k):lower()
        if lk=="executor" or lk=="syn" or lk=="fluxus" or lk=="delta"
        or lk=="getgenv" or lk=="is_executor_closure" or lk=="krnl_loaded"
        or lk=="hydrogen" or lk=="seliware" or lk=="xeno"
        or lk:find("executor") then return nil end
        return _oi(self,k)
    end)
    pcall(setreadonly,mt,true)
end)

-- ══════════════════════════════════════════════════════
--  STRONG ANTI-CHEAT BYPASS
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

pcall(function()
    local ok,mt = pcall(getrawmetatable,game) if not ok then return end
    pcall(setreadonly,mt,false)
    local _oni = mt.__newindex
    if _oni then
        mt.__newindex = newcclosure(function(self,k,v)
            if typeof(self)=="Instance" and self:IsA("BasePart")
            and k=="CFrame" and self==getRoot(LP) then return end
            return _oni(self,k,v)
        end)
    end
    pcall(setreadonly,mt,true)
end)

pcall(function()
    local hum=getHum(LP) if not hum then return end
    local ok,mt=pcall(getrawmetatable,hum) if not ok then return end
    pcall(setreadonly,mt,false)
    local _oi2=mt.__index
    mt.__index=newcclosure(function(self,k)
        if k=="WalkSpeed" and CFG.AutoSprint then return 16 end
        return _oi2(self,k)
    end)
    pcall(setreadonly,mt,true)
end)

local silentTarget = nil
local _nc
_nc = hookmetamethod(game,"__namecall",newcclosure(function(self,...)
    if checkcaller and checkcaller() then return _nc(self,...) end
    local method = getnamecallmethod()
    local args   = {...}
    if method=="FireServer" or method=="InvokeServer" then
        if CFG.AntiKick then
            local n=(typeof(self)=="Instance" and self.Name or ""):lower()
            for _,pat in ipairs(KICK_PATTERNS) do
                if n:find(pat) then return nil end
            end
        end
        if CFG.SilentAim and silentTarget and isAlive(silentTarget) then
            local part=getPart(silentTarget,CFG.SilentAimPart)
            if part then
                local predPos=getPredictedPos(silentTarget,CFG.SilentAimPart,CFG.SilentAimSticky)
                local newArgs={}
                for i,v in ipairs(args) do
                    if typeof(v)=="Vector3" then newArgs[i]=predPos or part.Position
                    elseif typeof(v)=="Instance" and v:IsA("BasePart") then newArgs[i]=part
                    elseif typeof(v)=="Instance" and v:IsA("Model") then newArgs[i]=getChar(silentTarget) or v
                    else newArgs[i]=v end
                end
                return _nc(self,table.unpack(newArgs))
            end
        end
    end
    return _nc(self,table.unpack(args))
end))

-- ══════════════════════════════════════════════════════
--  AIMBOT
-- ══════════════════════════════════════════════════════
local aimbotOn=false
local aimbotConn=nil
local lastTarget=nil

local function startAimbotLoop()
    if aimbotConn then aimbotConn:Disconnect() end
    aimbotConn=RunService.RenderStepped:Connect(function()
        if not CFG.Aimbot or not aimbotOn then return end
        local enemy,_=getNearestEnemy(CFG.AimbotFOV,CFG.AimbotPart)
        if not enemy then lastTarget=nil return end
        local bPos=getPredictedPos(enemy,CFG.AimbotPart,CFG.AimbotSticky)
        if not bPos then return end
        lastTarget=enemy
        silentTarget=enemy
        local cf=Cam.CFrame
        local target=CFrame.new(cf.Position,bPos)
        Cam.CFrame=cf:Lerp(target,math.clamp(CFG.AimbotSmoothing,0.01,1))
    end)
end

UserInputService.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==Enum.KeyCode.Q and CFG.Aimbot then
        aimbotOn=true startAimbotLoop()
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.KeyCode==Enum.KeyCode.Q then aimbotOn=false end
end)

local function setAimbotOn(state)
    aimbotOn=state
    if state and CFG.Aimbot then startAimbotLoop() end
end

-- ══════════════════════════════════════════════════════
--  SILENT AIM scan
-- ══════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    if not CFG.SilentAim then silentTarget=nil return end
    local enemy,_=getNearestEnemy(CFG.SilentAimFOV,CFG.SilentAimPart)
    silentTarget=enemy
    if fovCircle then
        fovCircle.Radius=CFG.SilentAimFOV
        fovCircle.Position=screenCenter()
        fovCircle.Visible=CFG.ShowFOVCircle and CFG.SilentAim
    end
    if aimbotCircle then
        aimbotCircle.Radius=CFG.AimbotFOV
        aimbotCircle.Position=screenCenter()
        aimbotCircle.Visible=CFG.ShowAimbotFOV and CFG.Aimbot
    end
end)

-- ══════════════════════════════════════════════════════
--  FLOAT MODE
-- ══════════════════════════════════════════════════════
local mobileJumpHeld=false
local function bindFloatHook(char)
    local hum=char:FindFirstChildOfClass("Humanoid") if not hum then return end
    hum.StateChanged:Connect(function(_,new)
        if CFG.FloatMode and
        (new==Enum.HumanoidStateType.Jumping or new==Enum.HumanoidStateType.Freefall) then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)
end
UserInputService.JumpRequest:Connect(function()
    if CFG.FloatMode then mobileJumpHeld=true task.delay(0.15,function() mobileJumpHeld=false end) end
end)
RunService.Stepped:Connect(function(_,dt)
    if not CFG.FloatMode then return end
    local root=getRoot(LP) if not root then return end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) or mobileJumpHeld then
        root.CFrame=root.CFrame+Vector3.new(0,CFG.FloatPower*dt,0)
    end
end)

-- ══════════════════════════════════════════════════════
--  NOCLIP
-- ══════════════════════════════════════════════════════
local noclipTimer=0
RunService.Stepped:Connect(function(_,dt)
    if not CFG.Noclip then return end
    noclipTimer=noclipTimer+dt
    if noclipTimer<0.1 then return end
    noclipTimer=0
    local char=getChar(LP) if not char then return end
    for _,v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name~="HumanoidRootPart" then v.CanCollide=false end
    end
end)

-- ══════════════════════════════════════════════════════
--  AUTO SPRINT
-- ══════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function(dt)
    local hum=getHum(LP) if not hum then return end
    if not CFG.AutoSprint then
        if hum.WalkSpeed>16 then hum.WalkSpeed=math.max(16,hum.WalkSpeed-2*dt*20) end
        return
    end
    if hum.WalkSpeed<CFG.SprintSpeed then hum.WalkSpeed=math.min(CFG.SprintSpeed,hum.WalkSpeed+1) end
end)

-- ══════════════════════════════════════════════════════
--  UNLIMITED AMMO + AUTO RELOAD
-- ══════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not CFG.UnlimitedAmmo and not CFG.AutoReload then return end
    local char=getChar(LP) if not char then return end
    local tool=char:FindFirstChildOfClass("Tool") if not tool then return end
    for _,v in ipairs(tool:GetDescendants()) do
        local n=v.Name:lower()
        if v:IsA("IntValue") or v:IsA("NumberValue") then
            if CFG.UnlimitedAmmo and (n:find("ammo") or n:find("bullet") or n:find("mag")) then
                if v.Value<5 then v.Value=999 end
            end
            if CFG.AutoReload and (n:find("reload") or n:find("reloading")) then
                if v.Value==1 then v.Value=0 end
            end
        end
        if v:IsA("BoolValue") and CFG.AutoReload and v.Name:lower():find("reload") then
            v.Value=false
        end
    end
end)

-- ══════════════════════════════════════════════════════
--  AUTO PICKUP
-- ══════════════════════════════════════════════════════
local PICKUP_FOLDERS={"Loots","Items","Drops","Pickups","Collectibles","Weapons","Loot",
    "Spawns","WorldItems","GroundItems","DroppedItems","Interactables","Resources","Ammo","Supplies"}
local function tryPickup(obj)
    for _,v in ipairs(obj:GetDescendants()) do
        if v:IsA("ProximityPrompt") then pcall(fireproximityprompt,v) end
        if v:IsA("ClickDetector")   then pcall(fireclickdetector,v) end
        if v:IsA("RemoteEvent") then
            local n=v.Name:lower()
            if n:find("pick") or n:find("loot") or n:find("collect")
            or n:find("grab") or n:find("take") or n:find("item") then
                pcall(function() v:FireServer() end)
            end
        end
    end
end
local function scanFolder(folder,root)
    if not folder then return end
    for _,obj in ipairs(folder:GetChildren()) do
        local part=obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
        if part and (root.Position-part.Position).Magnitude<=CFG.AutoPickupRange then tryPickup(obj) end
    end
end
RunService.Heartbeat:Connect(function()
    if not CFG.AutoPickup then return end
    local root=getRoot(LP) if not root then return end
    for _,fname in ipairs(PICKUP_FOLDERS) do scanFolder(Workspace:FindFirstChild(fname),root) end
    for _,obj in ipairs(Workspace:GetChildren()) do
        if not obj:IsA("Model") or obj==getChar(LP) then continue end
        local part=obj:FindFirstChildOfClass("BasePart")
        if part and (root.Position-part.Position).Magnitude<=CFG.AutoPickupRange then tryPickup(obj) end
    end
end)

-- ══════════════════════════════════════════════════════
--  AUTO RESPAWN
-- ══════════════════════════════════════════════════════
local LOOT_FOLDERS={"LootBoxes","LootZones","Crates","Chests","Bags","DroppedBags","PlayerLoot"}
local RESPAWN_REMOTES={"Respawn","RespawnPlayer","PlayerRespawn","RevivePlayer","Revive","Restart"}

local function findOwnBag()
    local root=getRoot(LP) if not root then return nil end
    local lname=LP.Name:lower()
    local best,bDist=nil,math.huge
    for _,obj in ipairs(Workspace:GetDescendants()) do
        local ownAttr pcall(function() ownAttr=obj:GetAttribute("Owner") end)
        if ownAttr and tostring(ownAttr):lower()==lname then
            local part=obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
            if part then local d=(root.Position-part.Position).Magnitude if d<bDist then best=part bDist=d end end
        end
    end
    if best then return best end
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name:lower():find(lname) then
            local part=obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
            if part then local d=(root.Position-part.Position).Magnitude if d<bDist then best=part bDist=d end end
        end
    end
    if best then return best end
    for _,fname in ipairs(LOOT_FOLDERS) do
        local f=Workspace:FindFirstChild(fname)
        if f then
            for _,box in ipairs(f:GetChildren()) do
                local part=box:IsA("BasePart") and box or box:FindFirstChildOfClass("BasePart")
                if part then local d=(root.Position-part.Position).Magnitude if d<bDist then best=part bDist=d end end
            end
        end
    end
    return best
end

local function doAutoRespawn()
    task.wait(3)
    for _,rname in ipairs(RESPAWN_REMOTES) do
        local rem=ReplicatedStorage:FindFirstChild(rname) or Workspace:FindFirstChild(rname)
        if rem and rem:IsA("RemoteEvent") then pcall(function() rem:FireServer() end) break end
    end
    task.wait(1)
    if not isAlive(LP) then pcall(function() LP:LoadCharacter() end) end
    if CFG.AutoRespawnLoot then
        task.wait(2)
        local nr=getRoot(LP)
        if nr then
            local lb=findOwnBag()
            if lb then nr.CFrame=lb.CFrame+Vector3.new(0,3,0) task.wait(0.3) tryPickup(lb.Parent or lb) end
        end
    end
end

local function bindCharHooks(char)
    bindFloatHook(char)
    local hum=char:WaitForChild("Humanoid",10) if not hum then return end
    hum.Died:Connect(function() if CFG.AutoRespawn then task.spawn(doAutoRespawn) end end)
end
LP.CharacterAdded:Connect(bindCharHooks)
if LP.Character then task.spawn(function() bindCharHooks(LP.Character) end) end

-- ══════════════════════════════════════════════════════
--  ESP
-- ══════════════════════════════════════════════════════
local espObjects={}
local function makeESP(player)
    if not Drawing then return end
    local box=Drawing.new("Square")
    box.Visible=false box.Color=CFG.ESPColor box.Thickness=1 box.Filled=false
    local name=Drawing.new("Text")
    name.Visible=false name.Color=Color3.fromRGB(255,255,255) name.Size=13 name.Center=true name.Outline=true
    local dist=Drawing.new("Text")
    dist.Visible=false dist.Color=Color3.fromRGB(255,215,0) dist.Size=11 dist.Center=true dist.Outline=true
    espObjects[player]={box=box,name=name,dist=dist}
end
local function removeESP(player)
    local e=espObjects[player]
    if e then e.box:Remove() e.name:Remove() e.dist:Remove() espObjects[player]=nil end
end
for _,p in ipairs(Players:GetPlayers()) do if p~=LP then makeESP(p) end end
Players.PlayerAdded:Connect(function(p) if p~=LP then makeESP(p) end end)
Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
    if not CFG.ESPEnabled then
        for _,e in pairs(espObjects) do e.box.Visible=false e.name.Visible=false e.dist.Visible=false end
        return
    end
    for p,e in pairs(espObjects) do
        local root=getRoot(p)
        if root and isAlive(p) then
            local sp,on=toScreen(root.Position)
            local hp,_=toScreen(root.Position+Vector3.new(0,3,0))
            if on then
                local h=math.abs(hp.Y-sp.Y)*2
                local w=h*0.5
                e.box.Size=Vector2.new(w,h)
                e.box.Position=Vector2.new(sp.X-w/2,sp.Y-h/2)
                e.box.Color=CFG.ESPColor
                e.box.Visible=true
                e.name.Text=p.Name
                e.name.Position=Vector2.new(sp.X,sp.Y-h/2-15)
                e.name.Visible=true
                local myRoot=getRoot(LP)
                local d=myRoot and math.floor((myRoot.Position-root.Position).Magnitude) or 0
                e.dist.Text=d.."m"
                e.dist.Position=Vector2.new(sp.X,sp.Y+h/2+2)
                e.dist.Visible=true
            else
                e.box.Visible=false e.name.Visible=false e.dist.Visible=false
            end
        else
            e.box.Visible=false e.name.Visible=false e.dist.Visible=false
        end
    end
end)

-- ══════════════════════════════════════════════════════
--  GUI SETUP
-- ══════════════════════════════════════════════════════
-- destroy old instance if re-running
pcall(function()
    local old=CoreGui:FindFirstChild("PRIMODAX_V6")
    if old then old:Destroy() end
end)

local SG=Instance.new("ScreenGui")
SG.Name="PRIMODAX_V6"
SG.ResetOnSpawn=false
SG.IgnoreGuiInset=true
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
pcall(function() SG.Parent=CoreGui end)
if not SG.Parent then SG.Parent=LP.PlayerGui end

-- ── colours / font ──────────────────────────────────
local C={
    BG      =Color3.fromRGB(18,18,25),
    BG2     =Color3.fromRGB(28,28,38),
    ACCENT  =Color3.fromRGB(80,120,255),
    ACCENT2 =Color3.fromRGB(50,200,120),
    RED     =Color3.fromRGB(220,60,60),
    TAB_ON  =Color3.fromRGB(80,120,255),
    TAB_OFF =Color3.fromRGB(38,38,52),
    TEXT    =Color3.fromRGB(230,230,240),
    SUBTEXT =Color3.fromRGB(140,140,160),
    BORDER  =Color3.fromRGB(55,55,75),
    TOG_ON  =Color3.fromRGB(60,200,100),
    TOG_OFF =Color3.fromRGB(80,80,100),
    BLACK   =Color3.fromRGB(0,0,0),
}
local FONT    =Enum.Font.GothamBold
local FONT_R  =Enum.Font.Gotham

local function corner(r,p)
    local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r) c.Parent=p
end
local function stroke(col,t,p)
    local s=Instance.new("UIStroke") s.Color=col s.Thickness=t s.Parent=p
end
local function mkFrame(pr)
    local f=Instance.new("Frame") for k,v in pairs(pr) do f[k]=v end return f
end
local function mkLabel(pr)
    local l=Instance.new("TextLabel") for k,v in pairs(pr) do l[k]=v end return l
end
local function mkBtn(pr)
    local b=Instance.new("TextButton") for k,v in pairs(pr) do b[k]=v end return b
end
local function mkTxt(pr)
    local t=Instance.new("TextBox") for k,v in pairs(pr) do t[k]=v end return t
end
local function mkScroll(pr)
    local s=Instance.new("ScrollingFrame") for k,v in pairs(pr) do s[k]=v end return s
end

-- ══════════════════════════════════════════════════════
--  FLOATING CIRCLE BUBBLE  (always on top, draggable)
--  Visible only when menu is closed.
-- ══════════════════════════════════════════════════════
local bubble=mkBtn({
    Size            =UDim2.new(0,54,0,54),
    Position        =UDim2.new(0,10,0.5,-27),   -- left-centre
    BackgroundColor3=C.ACCENT,
    Text            ="≡",
    TextColor3      =C.TEXT,
    TextSize        =26,
    Font            =FONT,
    ZIndex          =100,    -- always on top
    Visible         =false,  -- hidden while menu open
    Parent          =SG,
})
corner(27,bubble)
stroke(C.BORDER,2,bubble)

-- drag the bubble
do
    local drag,ds,ps=false,nil,nil
    bubble.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch
        or inp.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true ds=inp.Position ps=bubble.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not drag then return end
        if inp.UserInputType==Enum.UserInputType.Touch
        or inp.UserInputType==Enum.UserInputType.MouseMovement then
            local d=inp.Position-ds
            bubble.Position=UDim2.new(ps.X.Scale,ps.X.Offset+d.X,ps.Y.Scale,ps.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch
        or inp.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

-- ══════════════════════════════════════════════════════
--  MAIN MENU  — portrait layout
--  Left rail: vertical tab buttons (width 90)
--  Right panel: content (fills rest)
--  Title bar across full top
-- ══════════════════════════════════════════════════════
local MENU_W,MENU_H = 320,480
local menuOpen      = true
local menuMinimised = false
local TITLE_H       = 42
local TAB_W         = 90
local MIN_H         = TITLE_H  -- height when minimised

local menuFrame=mkFrame({
    Size            =UDim2.new(0,MENU_W,0,MENU_H),
    Position        =UDim2.new(0.5,-MENU_W/2,0.5,-MENU_H/2),
    BackgroundColor3=C.BG,
    BorderSizePixel =0,
    ZIndex          =10,
    ClipsDescendants=true,
    Parent          =SG,
})
corner(10,menuFrame)
stroke(C.BORDER,1.5,menuFrame)

local function setMenuVisible(v)
    menuOpen=v
    menuFrame.Visible=v
    bubble.Visible=not v
end
setMenuVisible(true)
bubble.MouseButton1Click:Connect(function() setMenuVisible(true) end)

-- ── title bar ───────────────────────────────────────
local titleBar=mkFrame({
    Size            =UDim2.new(1,0,0,TITLE_H),
    Position        =UDim2.new(0,0,0,0),
    BackgroundColor3=C.BG2,
    BorderSizePixel =0,
    ZIndex          =11,
    Parent          =menuFrame,
})
-- square bottom corners on titleBar
mkFrame({Size=UDim2.new(1,0,0.5,0),Position=UDim2.new(0,0,0.5,0),
    BackgroundColor3=C.BG2,BorderSizePixel=0,ZIndex=10,Parent=titleBar})
corner(10,titleBar)

mkLabel({
    Size=UDim2.new(1,-80,0,20),Position=UDim2.new(0,10,0,3),
    BackgroundTransparency=1,
    Text="PRIMODAX v6  ·  Vagrant Survival v10",
    TextColor3=C.TEXT,TextSize=11,Font=FONT,
    TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12,Parent=titleBar,
})
mkLabel({
    Size=UDim2.new(1,-80,0,16),Position=UDim2.new(0,10,0,22),
    BackgroundTransparency=1,
    Text="by BoboyTagaAquarius",
    TextColor3=C.SUBTEXT,TextSize=10,Font=FONT_R,
    TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12,Parent=titleBar,
})

-- close → bubble
local closeBtn=mkBtn({
    Size=UDim2.new(0,28,0,28),Position=UDim2.new(1,-34,0.5,-14),
    BackgroundColor3=C.RED,Text="✕",TextColor3=C.TEXT,TextSize=13,Font=FONT,
    ZIndex=13,Parent=titleBar,
})
corner(6,closeBtn)
closeBtn.MouseButton1Click:Connect(function() setMenuVisible(false) end)

-- minimise
local minBtn=mkBtn({
    Size=UDim2.new(0,28,0,28),Position=UDim2.new(1,-68,0.5,-14),
    BackgroundColor3=C.BG,Text="–",TextColor3=C.TEXT,TextSize=18,Font=FONT,
    ZIndex=13,Parent=titleBar,
})
corner(6,minBtn)
minBtn.MouseButton1Click:Connect(function()
    menuMinimised=not menuMinimised
    local targetH=menuMinimised and MIN_H or MENU_H
    TweenService:Create(menuFrame,TweenInfo.new(0.2),{Size=UDim2.new(0,MENU_W,0,targetH)}):Play()
    minBtn.Text=menuMinimised and "□" or "–"
end)

-- drag via title bar
do
    local drag,ds,ps=false,nil,nil
    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch
        or inp.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true ds=inp.Position ps=menuFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not drag then return end
        if inp.UserInputType==Enum.UserInputType.Touch
        or inp.UserInputType==Enum.UserInputType.MouseMovement then
            local d=inp.Position-ds
            menuFrame.Position=UDim2.new(ps.X.Scale,ps.X.Offset+d.X,ps.Y.Scale,ps.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch
        or inp.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

-- ── left tab rail ───────────────────────────────────
local tabRail=mkScroll({
    Size                =UDim2.new(0,TAB_W,1,-TITLE_H),
    Position            =UDim2.new(0,0,0,TITLE_H),
    BackgroundColor3    =C.BG2,
    BorderSizePixel     =0,
    ScrollBarThickness  =0,
    ZIndex              =11,
    Parent              =menuFrame,
    CanvasSize          =UDim2.new(0,0,0,0),
    AutomaticCanvasSize =Enum.AutomaticSize.Y,
})
local tabLayout=Instance.new("UIListLayout",tabRail)
tabLayout.Padding=UDim.new(0,4)
tabLayout.SortOrder=Enum.SortOrder.LayoutOrder
Instance.new("UIPadding",tabRail).PaddingTop=UDim.new(0,6)

-- square top-right corner on rail
mkFrame({Size=UDim2.new(0,10,1,0),Position=UDim2.new(1,-10,0,0),
    BackgroundColor3=C.BG2,BorderSizePixel=0,ZIndex=10,Parent=tabRail})

-- ── content panel ───────────────────────────────────
local contentPanel=mkScroll({
    Size                =UDim2.new(1,-TAB_W,1,-TITLE_H),
    Position            =UDim2.new(0,TAB_W,0,TITLE_H),
    BackgroundColor3    =C.BG,
    BorderSizePixel     =0,
    ScrollBarThickness  =4,
    ScrollBarImageColor3=C.ACCENT,
    ZIndex              =11,
    Parent              =menuFrame,
    CanvasSize          =UDim2.new(0,0,0,0),
    AutomaticCanvasSize =Enum.AutomaticSize.Y,
})

-- ── tab definitions ─────────────────────────────────
local TABS={
    {name="Config",     icon="⚙"},
    {name="Bypass",     icon="🛡"},
    {name="Visuals",    icon="👁"},
    {name="Combat",     icon="🎯"},
    {name="Survival",   icon="🏃"},
    {name="Weapons",    icon="🔫"},
    {name="MdKyamamoto",icon="⚡"},
}

local tabBtns  = {}
local tabPages = {}
local activeTab= ""

local function switchTab(name)
    activeTab=name
    for n,btn in pairs(tabBtns) do
        btn.BackgroundColor3=(n==name) and C.TAB_ON or C.TAB_OFF
        btn.TextColor3      =(n==name) and C.TEXT   or C.SUBTEXT
    end
    for n,page in pairs(tabPages) do page.Visible=(n==name) end
end

for i,tab in ipairs(TABS) do
    -- tab button in left rail
    local btn=mkBtn({
        Size            =UDim2.new(1,-8,0,52),
        BackgroundColor3=C.TAB_OFF,
        Text            =tab.icon.."\n"..tab.name,
        TextColor3      =C.SUBTEXT,
        TextSize        =10,
        Font            =FONT,
        TextWrapped     =true,
        BorderSizePixel =0,
        ZIndex          =12,
        LayoutOrder     =i,
        Parent          =tabRail,
    })
    corner(6,btn)
    tabBtns[tab.name]=btn

    -- content page inside contentPanel
    local page=mkFrame({
        Size            =UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        ZIndex          =12,
        Visible         =false,
        Parent          =contentPanel,
    })
    local layout=Instance.new("UIListLayout",page)
    layout.Padding=UDim.new(0,5)
    layout.SortOrder=Enum.SortOrder.LayoutOrder
    local pad=Instance.new("UIPadding",page)
    pad.PaddingTop=UDim.new(0,8) pad.PaddingLeft=UDim.new(0,8) pad.PaddingRight=UDim.new(0,8)
    tabPages[tab.name]=page

    btn.MouseButton1Click:Connect(function() switchTab(tab.name) end)
end

-- ══════════════════════════════════════════════════════
--  WIDGET BUILDERS  (content panel width = MENU_W-TAB_W-16)
-- ══════════════════════════════════════════════════════
local function addSectionHeader(page,txt,order)
    local l=mkLabel({
        Size=UDim2.new(1,0,0,26),BackgroundColor3=C.BG2,
        Text="  "..txt,TextColor3=C.ACCENT,TextSize=11,Font=FONT,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13,
        LayoutOrder=order,Parent=page,
    })
    corner(4,l) return l
end

local function addLabel(page,txt,order)
    return mkLabel({
        Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,
        Text=txt,TextColor3=C.SUBTEXT,TextSize=10,Font=FONT_R,
        TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,
        ZIndex=13,LayoutOrder=order,Parent=page,
    })
end

local function addToggle(page,labelTxt,cfgKey,order,onChange)
    local row=mkFrame({
        Size=UDim2.new(1,0,0,38),BackgroundColor3=C.BG2,
        BorderSizePixel=0,ZIndex=13,LayoutOrder=order,Parent=page,
    })
    corner(6,row)
    mkLabel({
        Size=UDim2.new(1,-52,1,0),Position=UDim2.new(0,10,0,0),
        BackgroundTransparency=1,Text=labelTxt,
        TextColor3=C.TEXT,TextSize=11,Font=FONT_R,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=14,Parent=row,
    })
    local pill=mkBtn({
        Size=UDim2.new(0,40,0,22),Position=UDim2.new(1,-46,0.5,-11),
        BackgroundColor3=CFG[cfgKey] and C.TOG_ON or C.TOG_OFF,
        Text="",BorderSizePixel=0,ZIndex=14,Parent=row,
    })
    corner(11,pill)
    local knob=mkFrame({
        Size=UDim2.new(0,16,0,16),
        Position=UDim2.new(CFG[cfgKey] and 1 or 0, CFG[cfgKey] and -19 or 3, 0.5,-8),
        BackgroundColor3=C.TEXT,BorderSizePixel=0,ZIndex=15,Parent=pill,
    })
    corner(8,knob)
    pill.MouseButton1Click:Connect(function()
        CFG[cfgKey]=not CFG[cfgKey]
        local on=CFG[cfgKey]
        TweenService:Create(pill,TweenInfo.new(0.15),{BackgroundColor3=on and C.TOG_ON or C.TOG_OFF}):Play()
        TweenService:Create(knob,TweenInfo.new(0.15),{Position=UDim2.new(on and 1 or 0,on and -19 or 3,0.5,-8)}):Play()
        if onChange then onChange(on) end
    end)
    return row
end

local function addSlider(page,labelTxt,cfgKey,minV,maxV,order,fmt,onChange)
    local row=mkFrame({
        Size=UDim2.new(1,0,0,52),BackgroundColor3=C.BG2,
        BorderSizePixel=0,ZIndex=13,LayoutOrder=order,Parent=page,
    })
    corner(6,row)
    local valLbl=mkLabel({
        Size=UDim2.new(0,50,0,18),Position=UDim2.new(1,-54,0,5),
        BackgroundTransparency=1,Text=tostring(CFG[cfgKey])..(fmt or ""),
        TextColor3=C.ACCENT,TextSize=11,Font=FONT,
        TextXAlignment=Enum.TextXAlignment.Right,ZIndex=14,Parent=row,
    })
    mkLabel({
        Size=UDim2.new(1,-60,0,18),Position=UDim2.new(0,10,0,5),
        BackgroundTransparency=1,Text=labelTxt,
        TextColor3=C.TEXT,TextSize=11,Font=FONT_R,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=14,Parent=row,
    })
    local track=mkFrame({
        Size=UDim2.new(1,-20,0,5),Position=UDim2.new(0,10,0,32),
        BackgroundColor3=C.BG,BorderSizePixel=0,ZIndex=14,Parent=row,
    })
    corner(3,track)
    local pct=(CFG[cfgKey]-minV)/(maxV-minV)
    local fill=mkFrame({Size=UDim2.new(pct,0,1,0),BackgroundColor3=C.ACCENT,BorderSizePixel=0,ZIndex=15,Parent=track})
    corner(3,fill)
    local thumb=mkBtn({
        Size=UDim2.new(0,14,0,14),Position=UDim2.new(pct,-7,0.5,-7),
        BackgroundColor3=C.TEXT,Text="",BorderSizePixel=0,ZIndex=16,Parent=track,
    })
    corner(7,thumb)
    local dragging=false
    local function update(x)
        local abs=track.AbsolutePosition.X
        local wid=track.AbsoluteSize.X
        local t=math.clamp((x-abs)/wid,0,1)
        local val=math.floor(minV+t*(maxV-minV))
        CFG[cfgKey]=val
        fill.Size=UDim2.new(t,0,1,0)
        thumb.Position=UDim2.new(t,-7,0.5,-7)
        valLbl.Text=tostring(val)..(fmt or "")
        if onChange then onChange(val) end
    end
    thumb.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch
        or inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType==Enum.UserInputType.Touch
        or inp.UserInputType==Enum.UserInputType.MouseMovement then update(inp.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch
        or inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    return row
end

local function addButton(page,txt,col,order,cb)
    local b=mkBtn({
        Size=UDim2.new(1,0,0,36),BackgroundColor3=col or C.ACCENT,
        Text=txt,TextColor3=C.TEXT,TextSize=11,Font=FONT,
        BorderSizePixel=0,ZIndex=13,LayoutOrder=order,Parent=page,
    })
    corner(6,b)
    b.MouseButton1Click:Connect(cb)
    return b
end

local function addTextBox(page,placeholder,order,cb)
    local t=mkTxt({
        Size=UDim2.new(1,0,0,36),BackgroundColor3=C.BG2,
        PlaceholderText=placeholder,Text="",
        TextColor3=C.TEXT,PlaceholderColor3=C.SUBTEXT,
        TextSize=10,Font=FONT_R,
        BorderSizePixel=0,ZIndex=13,LayoutOrder=order,
        ClearTextOnFocus=false,TextWrapped=false,Parent=page,
    })
    corner(6,t) stroke(C.BORDER,1,t)
    if cb then t.FocusLost:Connect(function() cb(t.Text) end) end
    return t
end

-- ══════════════════════════════════════════════════════
--  CONFIG TAB
-- ══════════════════════════════════════════════════════
local pg=tabPages["Config"]
local ord=0
local function o() ord=ord+1 return ord end

addSectionHeader(pg,"▸ SAVE / LOAD",o())
addButton(pg,"💾 Save Config",C.ACCENT2,o(),function() saveConfig() end)
addButton(pg,"📂 Load Config",C.ACCENT, o(),function() loadConfig() end)

addSectionHeader(pg,"▸ IMPORT CONFIG",o())
addLabel(pg,"Paste JSON then tap Import:",o())
local importBox=addTextBox(pg,'{"SilentAim":false,...}',o())
addButton(pg,"⬇ Import",C.ACCENT,o(),function()
    local txt=importBox.Text
    if txt and #txt>2 then
        local ok=importFromString(txt)
        importBox.Text=ok and "✔ Applied!" or "✘ Bad JSON"
    end
end)

addSectionHeader(pg,"▸ EXECUTOR BYPASS",o())
addToggle(pg,"Hide Executor",  "HideExecutor",o())
addToggle(pg,"Anti-Kick",      "AntiKick",     o())

-- ══════════════════════════════════════════════════════
--  BYPASS TAB
-- ══════════════════════════════════════════════════════
pg=tabPages["Bypass"] ord=0
addSectionHeader(pg,"▸ BYPASS",o())
addToggle(pg,"Anti-Kick",       "AntiKick",     o())
addToggle(pg,"Hide Executor",   "HideExecutor", o())
addLabel(pg,"WalkSpeed spoof + CFrame block active.",o())

-- ══════════════════════════════════════════════════════
--  VISUALS TAB
-- ══════════════════════════════════════════════════════
pg=tabPages["Visuals"] ord=0
addSectionHeader(pg,"▸ ESP",o())
addToggle(pg,"ESP Boxes + Names","ESPEnabled",o())
addSectionHeader(pg,"▸ FOV CIRCLES",o())
addToggle(pg,"Silent Aim Circle","ShowFOVCircle",o())
addToggle(pg,"Aimbot Circle",   "ShowAimbotFOV",o())
addSlider(pg,"Silent FOV",      "SilentAimFOV",30,400,o()," px")
addSlider(pg,"Aimbot FOV",      "AimbotFOV",   30,600,o()," px")
addSectionHeader(pg,"▸ WIDESCREEN",o())
addToggle(pg,"Widescreen","WideScreen",o())
addSlider(pg,"Camera FOV","WideScreenFOV",70,120,o(),"°")

-- ══════════════════════════════════════════════════════
--  COMBAT TAB
-- ══════════════════════════════════════════════════════
pg=tabPages["Combat"] ord=0
addSectionHeader(pg,"▸ SILENT AIM",o())
addToggle(pg,"Silent Aim",      "SilentAim",       o())
addSlider(pg,"SA FOV",          "SilentAimFOV",30,400,o()," px")
addSlider(pg,"SA Sticky",       "SilentAimSticky",0,100,o(),"%",
    function(v) CFG.SilentAimSticky=v/100 end)

addSectionHeader(pg,"▸ AIMBOT",o())
addToggle(pg,"Aimbot (hold Q)","Aimbot",o(),function(on) if on then startAimbotLoop() end end)
addSlider(pg,"AB FOV",         "AimbotFOV",   30,600,o()," px")
addSlider(pg,"Smoothing",      "AimbotSmoothing",1,100,o(),"%",
    function(v) CFG.AimbotSmoothing=v/100 end)
addSlider(pg,"AB Sticky",      "AimbotSticky",0,100,o(),"%",
    function(v) CFG.AimbotSticky=v/100 end)

-- mobile aim hold button (floating)
local aimHoldBtn=mkBtn({
    Size=UDim2.new(0,60,0,60),Position=UDim2.new(1,-72,1,-74),
    BackgroundColor3=Color3.fromRGB(220,60,60),
    Text="AIM",TextColor3=C.TEXT,TextSize=12,Font=FONT,
    ZIndex=100,Visible=false,Parent=SG,
})
corner(30,aimHoldBtn)
addToggle(pg,"Mobile AIM Button","Aimbot",o(),function(on) aimHoldBtn.Visible=on end)
aimHoldBtn.InputBegan:Connect(function() setAimbotOn(true) end)
aimHoldBtn.InputEnded:Connect(function()  setAimbotOn(false) end)

-- ══════════════════════════════════════════════════════
--  SURVIVAL TAB
-- ══════════════════════════════════════════════════════
pg=tabPages["Survival"] ord=0
addSectionHeader(pg,"▸ MOVEMENT",o())
addToggle(pg,"Auto Sprint",     "AutoSprint",       o())
addSlider(pg,"Sprint Speed",    "SprintSpeed",16,60,o())
addToggle(pg,"Float Mode",      "FloatMode",        o())
addSlider(pg,"Float Power",     "FloatPower",10,200,o())
addToggle(pg,"Noclip",          "Noclip",           o())
addSectionHeader(pg,"▸ LOOT",o())
addToggle(pg,"Auto Pickup",     "AutoPickup",       o())
addSlider(pg,"Pickup Range",    "AutoPickupRange",5,150,o()," st")
addSectionHeader(pg,"▸ RESPAWN",o())
addToggle(pg,"Auto Respawn",    "AutoRespawn",      o())
addToggle(pg,"Respawn → Bag",   "AutoRespawnLoot",  o())

-- ══════════════════════════════════════════════════════
--  WEAPONS TAB
-- ══════════════════════════════════════════════════════
pg=tabPages["Weapons"] ord=0
addSectionHeader(pg,"▸ AMMO",o())
addToggle(pg,"Unlimited Ammo","UnlimitedAmmo",o())
addToggle(pg,"Auto Reload",   "AutoReload",   o())

-- ══════════════════════════════════════════════════════
--  MdKyamamoto TAB
-- ══════════════════════════════════════════════════════
pg=tabPages["MdKyamamoto"] ord=0
addSectionHeader(pg,"▸ MdKyamamoto",o())
addLabel(pg,"Custom remote hooks go here.",o())

-- ── boot ────────────────────────────────────────────
switchTab("Config")
print("[PRIMODAX v6.1] Vagrant Survival v10 — BoboyTagaAquarius — loaded.")
