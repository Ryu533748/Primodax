-- ██████╗ ██████╗ ██╗███╗   ███╗ ██████╗ ██████╗  █████╗ ██╗  ██╗
-- ██╔══██╗██╔══██╗██║████╗ ████║██╔═══██╗██╔══██╗██╔══██╗╚██╗██╔╝
-- ██████╔╝██████╔╝██║██╔████╔██║██║   ██║██║  ██║███████║ ╚███╔╝
-- ██╔═══╝ ██╔══██╗██║██║╚██╔╝██║██║   ██║██║  ██║██╔══██║ ██╔██╗
-- ██║     ██║  ██║██║██║ ╚═╝ ██║╚██████╔╝██████╔╝██║  ██║██╔╝ ██╗
-- ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
-- PRIMODAXVGRANT | Vagrant Survival v10
-- Version  : 5.6
-- Created By: BoboyTagaAquarius
-- Game     : Vagrant Survival v10 (Roblox) — Team Stultus
-- Executor : Delta, Arceus X, Fluxus
--
-- FIXES v5.6:
--   • Two-column layout: left = category list, right = feature panel
--     Shape inspired by ROBScript Hub — does NOT copy features/content.
--   • Camera swipe: SF.Active=false, manual touch-scroll on canvas.
--     MF.Active toggled with visibility. No input eaten when menu hidden.
--   • Aimbot: CameraType set to Scriptable while Q held, restored on release.
--     CFrame set (not lerped) for snappy lock, lerp only for smoothing pass.
--   • Silent Aim: args rebuilt into new table before unpack.
--     Hook also covers InvokeServer with same redirect.
--   • Left/right camera swipe: SG.DisplayOrder low enough to not eat joystick.

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

local CONFIG_FILE   = "primodax_v5_cfg.json"
local PERSIST_KEYS  = {
    "SilentAim","SilentAimFOV","Aimbot","AimbotFOV","AimbotSmoothing",
    "ShowFOVCircle","ShowAimbotFOV",
    "UnlimitedAmmo","AutoReload","AutoPickup","AutoPickupRange",
    "AutoRespawn","AutoRespawnLoot","AutoSprint","SprintSpeed",
    "FloatMode","FloatPower","Noclip","ESPEnabled","AntiKick","HideExecutor",
}

local function cfgToTable()
    local t={} for _,k in ipairs(PERSIST_KEYS) do t[k]=CFG[k] end return t
end
local function applyTable(t)
    for _,k in ipairs(PERSIST_KEYS) do if t[k]~=nil then CFG[k]=t[k] end end
end
local function saveConfig()
    local ok,json=pcall(function() return HttpService:JSONEncode(cfgToTable()) end)
    if not ok then return false,"encode fail" end
    if writefile then local ok2=pcall(writefile,CONFIG_FILE,json) if ok2 then return true,"saved → "..CONFIG_FILE end end
    if setclipboard then pcall(setclipboard,json) return true,"copied to clipboard" end
    return false,"no writefile or setclipboard"
end
local function loadConfig()
    if readfile then
        local ok,raw=pcall(readfile,CONFIG_FILE)
        if ok and raw and #raw>2 then
            local ok2,t=pcall(function() return HttpService:JSONDecode(raw) end)
            if ok2 and t then applyTable(t) return true,"loaded ← "..CONFIG_FILE end
        end
    end
    return false,"no saved config"
end
local function exportConfig()
    local ok,json=pcall(function() return HttpService:JSONEncode(cfgToTable()) end)
    if not ok then return false,"encode fail" end
    if setclipboard then pcall(setclipboard,json) return true,"copied to clipboard" end
    return false,"setclipboard unavailable"
end
local function importConfig(s)
    local ok,t=pcall(function() return HttpService:JSONDecode(s) end)
    if ok and t then applyTable(t) return true,"config imported" end
    return false,"invalid JSON"
end
pcall(loadConfig)

-- ══════════════════════════════════════════════════════
--  UTILITY
-- ══════════════════════════════════════════════════════
local function getChar(p)    return p and p.Character end
local function getHum(p)     local c=getChar(p) return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot(p)    local c=getChar(p) return c and c:FindFirstChild("HumanoidRootPart") end
local function getPart(p,n)  local c=getChar(p) return c and c:FindFirstChild(n) end
local function isAlive(p)    local h=getHum(p) return h and h.Health>0 end

local function toScreen(pos)
    local s,on=Cam:WorldToViewportPoint(pos) return Vector2.new(s.X,s.Y),on
end
local function screenCenter()
    return Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2)
end
local function dist2D(sp) return (sp-screenCenter()).Magnitude end

local function getNearestEnemy(fovR,part)
    local best,bDist,bPos=nil,fovR,nil
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and isAlive(p) then
            local pt=getPart(p,part or "Head")
            if pt then
                local sp,on=toScreen(pt.Position)
                if on then
                    local d=dist2D(sp)
                    if d<bDist then best=p bDist=d bPos=pt.Position end
                end
            end
        end
    end
    return best,bPos
end

-- ══════════════════════════════════════════════════════
--  FOV CIRCLES  gold=silent aim  white=aimbot
-- ══════════════════════════════════════════════════════
local fovCircle,aimbotCircle
if Drawing then
    fovCircle=Drawing.new("Circle")
    fovCircle.Thickness=1.5 fovCircle.Color=Color3.fromRGB(255,215,0)
    fovCircle.Filled=false  fovCircle.Visible=false
    fovCircle.Radius=CFG.SilentAimFOV fovCircle.Position=screenCenter()

    aimbotCircle=Drawing.new("Circle")
    aimbotCircle.Thickness=1.2 aimbotCircle.Color=Color3.fromRGB(220,220,220)
    aimbotCircle.Filled=false  aimbotCircle.Visible=false
    aimbotCircle.Radius=CFG.AimbotFOV aimbotCircle.Position=screenCenter()
end

-- ══════════════════════════════════════════════════════
--  BYPASS: HIDE EXECUTOR
-- ══════════════════════════════════════════════════════
pcall(function()
    if not CFG.HideExecutor then return end
    local EKEYS={"syn","fluxus","DELTA","Delta","delta","getgenv","is_executor_closure",
        "rconsole","hookfunction","hookmetamethod","checkcaller","cloneref",
        "FLUXUS_KEY","DELTA_KEY","ARCEUS_KEY","KRNL_LOADED"}
    for _,k in ipairs(EKEYS) do pcall(function() _G[k]=nil end) end
    local ok,mt=pcall(getrawmetatable,game) if not ok then return end
    pcall(setreadonly,mt,false)
    local _oi=mt.__index
    mt.__index=newcclosure(function(self,k)
        local lk=tostring(k):lower()
        if lk=="executor" or lk=="syn" or lk=="fluxus" or lk=="delta"
        or lk=="getgenv" or lk=="is_executor_closure" or lk=="krnl_loaded"
        or lk:find("executor") then return nil end
        return _oi(self,k)
    end)
    pcall(setreadonly,mt,true)
end)

-- ══════════════════════════════════════════════════════
--  BYPASS: ANTI-KICK + SILENT AIM  (__namecall)
--  v5.6 fix: rebuild args into fresh table before unpack
--  so executor vararg copy doesn't lose the redirect
-- ══════════════════════════════════════════════════════
local silentTarget=nil

local _nc
_nc=hookmetamethod(game,"__namecall",function(self,...)
    local method=getnamecallmethod()
    local args={...}   -- copy into real table

    if method=="FireServer" or method=="InvokeServer" then
        -- anti-kick
        if CFG.AntiKick then
            local n=(typeof(self)=="Instance" and self.Name or ""):lower()
            if n:find("kick") or n:find("ban") or n:find("cheat")
            or n:find("detect") or n:find("anticheat") or n:find("report")
            or n:find("flag")  or n:find("speed")  or n:find("velocity")
            or n:find("noclip") or n:find("collide") or n:find("walkspeed")
            or n:find("movespeed") or n:find("exploit") or n:find("hack")
            or n:find("sanity") or n:find("integrity") or n:find("verify")
            or n:find("position") or n:find("teleport") or n:find("tphack")
            or n:find("sprint") or n:find("movement") or n:find("physics") then
                return nil
            end
        end

        -- silent aim: redirect Vector3 / BasePart / Model args
        if CFG.SilentAim and silentTarget and isAlive(silentTarget) then
            local part=getPart(silentTarget,CFG.SilentAimPart)
            if part then
                local newArgs={}
                for i,v in ipairs(args) do
                    if typeof(v)=="Vector3" then
                        newArgs[i]=part.Position          -- redirect hit pos
                    elseif typeof(v)=="Instance" and v:IsA("BasePart") then
                        newArgs[i]=part                   -- redirect hit part
                    elseif typeof(v)=="Instance" and v:IsA("Model") then
                        local tc=getChar(silentTarget)
                        newArgs[i]=tc or v                -- redirect character
                    else
                        newArgs[i]=v
                    end
                end
                return _nc(self,table.unpack(newArgs))   -- use redirected args
            end
        end
    end

    return _nc(self,table.unpack(args))
end)

-- ══════════════════════════════════════════════════════
--  AIMBOT v5.6
--  Fix: set CameraType=Scriptable while Q held so Roblox's
--  default camera doesn't override CFrame every frame.
--  Restore to Custom on release.
-- ══════════════════════════════════════════════════════
local aimbotOn=false
local _camTypeBackup=Enum.CameraType.Custom

UserInputService.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==Enum.KeyCode.Q and CFG.Aimbot then
        aimbotOn=true
        _camTypeBackup=Cam.CameraType
        Cam.CameraType=Enum.CameraType.Scriptable
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.KeyCode==Enum.KeyCode.Q then
        aimbotOn=false
        pcall(function() Cam.CameraType=_camTypeBackup end)
    end
end)

-- also toggle via mobile button (wired below in GUI)
local function setAimbotOn(state)
    aimbotOn=state
    if state and CFG.Aimbot then
        _camTypeBackup=Cam.CameraType
        Cam.CameraType=Enum.CameraType.Scriptable
    else
        pcall(function() Cam.CameraType=_camTypeBackup end)
    end
end

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
--  NOCLIP — 100ms throttle
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
--  AUTO SPRINT — lerp ramp
-- ══════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function(dt)
    local hum=getHum(LP) if not hum then return end
    if not CFG.AutoSprint then
        if hum.WalkSpeed>16 then hum.WalkSpeed=math.max(16,hum.WalkSpeed-2*dt*20) end
        return
    end
    if hum.WalkSpeed<CFG.SprintSpeed then
        hum.WalkSpeed=math.min(CFG.SprintSpeed,hum.WalkSpeed+1)
    end
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
        if v:IsA("BoolValue") then
            local bn=v.Name:lower()
            if CFG.AutoReload and (bn:find("reload") or bn:find("reloading")) then v.Value=false end
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
local RESPAWN_FOLDERS={"LootBoxes","LootZones","Crates","Chests","Bags","DroppedBags","PlayerLoot"}
local function findOwnBag()
    local root=getRoot(LP) if not root then return nil end
    local best,bDist=nil,math.huge local lname=LP.Name:lower()
    for _,obj in ipairs(Workspace:GetDescendants()) do
        local n=obj.Name:lower()
        if (n:find(lname) or n:find("bag") or n:find("drop") or n:find("loot"))
        and (obj:IsA("BasePart") or obj:IsA("Model")) then
            local part=obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
            if part then local d=(root.Position-part.Position).Magnitude
                if d<bDist then best=part bDist=d end end
        end
    end
    return best
end
local function nearestLootbox()
    local own=findOwnBag() if own then return own end
    local root=getRoot(LP) if not root then return nil end
    local best,bDist=nil,math.huge
    for _,fname in ipairs(RESPAWN_FOLDERS) do
        local f=Workspace:FindFirstChild(fname)
        if f then for _,box in ipairs(f:GetChildren()) do
            local part=box:IsA("BasePart") and box or box:FindFirstChildOfClass("BasePart")
            if part then local d=(root.Position-part.Position).Magnitude
                if d<bDist then best=part bDist=d end end
        end end
    end
    return best
end
LP.CharacterAdded:Connect(function(char)
    bindFloatHook(char)
    local hum=char:WaitForChild("Humanoid",10) if not hum then return end
    hum.Died:Connect(function()
        if not CFG.AutoRespawn then return end
        task.wait(3)
        for _,rname in ipairs({"Respawn","RespawnPlayer","PlayerRespawn","RevivePlayer","Revive"}) do
            local rem=ReplicatedStorage:FindFirstChild(rname) or Workspace:FindFirstChild(rname)
            if rem and rem:IsA("RemoteEvent") then pcall(function() rem:FireServer() end) break end
        end
        task.wait(1)
        if not isAlive(LP) then pcall(function() LP:LoadCharacter() end) end
        if CFG.AutoRespawnLoot then task.wait(1.5)
            local nr=getRoot(LP) if nr then local lb=nearestLootbox()
                if lb then nr.CFrame=lb.CFrame+Vector3.new(0,5,0) end end
        end
    end)
end)
if LP.Character then task.spawn(function() bindFloatHook(LP.Character) end) end

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

-- ══════════════════════════════════════════════════════
--  RENDER LOOP
-- ══════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    local center=screenCenter()

    if fovCircle then
        fovCircle.Position=center
        fovCircle.Visible=CFG.ShowFOVCircle and CFG.SilentAim
        fovCircle.Radius=CFG.SilentAimFOV
    end
    if aimbotCircle then
        aimbotCircle.Position=center
        aimbotCircle.Visible=CFG.ShowAimbotFOV and CFG.Aimbot
        aimbotCircle.Radius=CFG.AimbotFOV
    end

    -- silent aim target update
    local sTarget=getNearestEnemy(CFG.SilentAimFOV,CFG.SilentAimPart)
    silentTarget=CFG.SilentAim and sTarget or nil

    -- aimbot: only when Q held (desktop) or mobile toggle on
    if CFG.Aimbot and aimbotOn then
        local _,aPos=getNearestEnemy(CFG.AimbotFOV,CFG.AimbotPart)
        if aPos then
            -- point camera directly at target, then lerp for smoothing
            local dir=(aPos-Cam.CFrame.Position).Unit
            local targetCF=CFrame.new(Cam.CFrame.Position,Cam.CFrame.Position+dir)
            -- hard-set first (Scriptable camera), then lerp for smoothness
            Cam.CFrame=targetCF:Lerp(Cam.CFrame,CFG.AimbotSmoothing)
        end
    end

    -- ESP
    for player,e in pairs(espObjects) do
        local function hide() e.box.Visible=false e.name.Visible=false e.dist.Visible=false end
        if not CFG.ESPEnabled or not isAlive(player) then hide() continue end
        local root=getRoot(player) local head=getPart(player,"Head")
        if not root or not head then hide() continue end
        local rootSP,rootOn=toScreen(root.Position)
        local headSP,headOn=toScreen(head.Position)
        if not rootOn or not headOn then hide() continue end
        local height=math.abs(rootSP.Y-headSP.Y)*2.2
        local width=height*0.5
        local myRoot=getRoot(LP)
        local d=myRoot and (myRoot.Position-root.Position).Magnitude or 0
        e.box.Size=Vector2.new(width,height)
        e.box.Position=Vector2.new(rootSP.X-width/2,rootSP.Y-height/2)
        e.box.Color=CFG.ESPColor e.box.Visible=true
        e.name.Text=player.Name e.name.Position=Vector2.new(rootSP.X,headSP.Y-16) e.name.Visible=true
        e.dist.Text=string.format("[%.0fm]",d)
        e.dist.Position=Vector2.new(rootSP.X,rootSP.Y+height/2+2) e.dist.Visible=true
    end
end)

-- ══════════════════════════════════════════════════════
--  GUI  — ROBScript-style two-column layout
--  Left  column : category tabs (dark sidebar)
--  Right column : feature list for selected category
--  Header: game name + creator
-- ══════════════════════════════════════════════════════
if CoreGui:FindFirstChild("PrimodaxGUI") then
    CoreGui:FindFirstChild("PrimodaxGUI"):Destroy()
end

local SG=Instance.new("ScreenGui")
SG.Name="PrimodaxGUI" SG.ResetOnSpawn=false
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset=true
SG.DisplayOrder=5   -- low enough not to eat joystick/camera swipes
SG.Parent=CoreGui

local vp=Cam.ViewportSize
local isWide=vp.X>700
-- panel dimensions
local PW  = isWide and 480 or 340   -- total width
local PH  = isWide and 620 or 560   -- total height
local LW  = isWide and 130 or 95    -- left sidebar width
local HDR = 52                       -- header height
local BF  = isWide and 13 or 11
local TF  = isWide and 15 or 13

-- colour palette matching screenshot vibe (dark navy/charcoal + gold accent)
local C_BG      = Color3.fromRGB(13,  14,  20)   -- main bg
local C_SIDEBAR = Color3.fromRGB(18,  19,  28)   -- left col
local C_PANEL   = Color3.fromRGB(20,  22,  32)   -- right col
local C_HDR     = Color3.fromRGB(15,  16,  24)   -- header
local C_ACCENT  = Color3.fromRGB(255, 200,  0)   -- gold
local C_ACCENT2 = Color3.fromRGB(255, 100,  0)   -- orange (active tab)
local C_TEXT    = Color3.fromRGB(220, 220, 230)
local C_DIM     = Color3.fromRGB(110, 110, 130)
local C_ROW     = Color3.fromRGB(26,  28,  40)
local C_ON      = Color3.fromRGB(70,  200,  80)
local C_OFF     = Color3.fromRGB(55,  55,   70)

-- main floating panel
local MF=Instance.new("Frame")
MF.Size=UDim2.new(0,PW,0,PH)
MF.Position=UDim2.new(0.5,-PW/2,0.5,-PH/2)
MF.BackgroundColor3=C_BG
MF.BorderSizePixel=0
MF.Active=false   -- toggled with visibility
MF.Draggable=false
MF.Visible=false
MF.ZIndex=5
MF.Parent=SG
Instance.new("UICorner",MF).CornerRadius=UDim.new(0,14)
local mfStr=Instance.new("UIStroke",MF)
mfStr.Color=Color3.fromRGB(40,42,60) mfStr.Thickness=1.2

-- viewport resize
Cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    vp=Cam.ViewportSize isWide=vp.X>700
    PW=isWide and 480 or 340 PH=isWide and 620 or 560
    MF.Size=UDim2.new(0,PW,0,PH)
end)

-- ── HEADER ──────────────────────────────────────────
local HDRf=Instance.new("Frame",MF)
HDRf.Size=UDim2.new(1,0,0,HDR) HDRf.Position=UDim2.new(0,0,0,0)
HDRf.BackgroundColor3=C_HDR HDRf.BorderSizePixel=0 HDRf.ZIndex=6
Instance.new("UICorner",HDRf).CornerRadius=UDim.new(0,14)
-- bottom square corners on header
local HDRsq=Instance.new("Frame",HDRf)
HDRsq.Size=UDim2.new(1,0,0,14) HDRsq.Position=UDim2.new(0,0,1,-14)
HDRsq.BackgroundColor3=C_HDR HDRsq.BorderSizePixel=0 HDRsq.ZIndex=6

-- lightning bolt icon
local bolt=Instance.new("TextLabel",HDRf)
bolt.Size=UDim2.new(0,30,1,0) bolt.Position=UDim2.new(0,10,0,0)
bolt.BackgroundTransparency=1 bolt.Text="⚡"
bolt.TextColor3=C_ACCENT bolt.TextSize=TF+4
bolt.Font=Enum.Font.GothamBold bolt.ZIndex=7

-- title
local HTITLE=Instance.new("TextLabel",HDRf)
HTITLE.Size=UDim2.new(1,-100,0,28) HTITLE.Position=UDim2.new(0,42,0,4)
HTITLE.BackgroundTransparency=1
HTITLE.Text="Vagrant Survival v10"
HTITLE.TextColor3=C_TEXT HTITLE.TextSize=TF
HTITLE.Font=Enum.Font.GothamBold HTITLE.TextXAlignment=Enum.TextXAlignment.Left
HTITLE.ZIndex=7

-- subtitle / creator
local HSUB=Instance.new("TextLabel",HDRf)
HSUB.Size=UDim2.new(1,-100,0,18) HSUB.Position=UDim2.new(0,42,0,28)
HSUB.BackgroundTransparency=1
HSUB.Text="Created By BoboyTagaAquarius"
HSUB.TextColor3=C_DIM HSUB.TextSize=9
HSUB.Font=Enum.Font.Gotham HSUB.TextXAlignment=Enum.TextXAlignment.Left
HSUB.ZIndex=7

-- close button
local XB=Instance.new("TextButton",HDRf)
XB.Size=UDim2.new(0,30,0,30) XB.Position=UDim2.new(1,-38,0,11)
XB.BackgroundColor3=Color3.fromRGB(180,40,40)
XB.Text="✕" XB.TextColor3=Color3.fromRGB(255,255,255)
XB.TextSize=14 XB.Font=Enum.Font.GothamBold XB.ZIndex=8
Instance.new("UICorner",XB).CornerRadius=UDim.new(1,0)
XB.MouseButton1Click:Connect(function()
    MF.Visible=false MF.Active=false
end)

-- drag via header
do
    local drag,ds,dp=false,nil,nil
    HDRf.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then
            drag=true ds=inp.Position dp=MF.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not drag then return end
        if inp.UserInputType==Enum.UserInputType.MouseMovement
        or inp.UserInputType==Enum.UserInputType.Touch then
            local d=inp.Position-ds
            MF.Position=UDim2.new(dp.X.Scale,dp.X.Offset+d.X,dp.Y.Scale,dp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
end

-- ── LEFT SIDEBAR ─────────────────────────────────────
local SIDE=Instance.new("Frame",MF)
SIDE.Size=UDim2.new(0,LW,1,-HDR) SIDE.Position=UDim2.new(0,0,0,HDR)
SIDE.BackgroundColor3=C_SIDEBAR SIDE.BorderSizePixel=0 SIDE.ZIndex=6
local SIDEbr=Instance.new("Frame",SIDE)  -- bottom-left rounded corner patch
SIDEbr.Size=UDim2.new(0,LW,0,14) SIDEbr.Position=UDim2.new(0,0,1,-14)
SIDEbr.BackgroundColor3=C_SIDEBAR SIDEbr.BorderSizePixel=0 SIDEbr.ZIndex=6
Instance.new("UICorner",SIDEbr).CornerRadius=UDim.new(0,14)
-- divider line between sidebar and content
local DIV=Instance.new("Frame",MF)
DIV.Size=UDim2.new(0,1,1,-HDR) DIV.Position=UDim2.new(0,LW,0,HDR)
DIV.BackgroundColor3=Color3.fromRGB(35,37,55) DIV.BorderSizePixel=0 DIV.ZIndex=6

-- left tab layout
local TABL=Instance.new("UIListLayout",SIDE)
TABL.Padding=UDim.new(0,2) TABL.SortOrder=Enum.SortOrder.LayoutOrder
local TABP=Instance.new("UIPadding",SIDE)
TABP.PaddingTop=UDim.new(0,8) TABP.PaddingLeft=UDim.new(0,6) TABP.PaddingRight=UDim.new(0,6)

-- ── RIGHT CONTENT AREA ───────────────────────────────
local CONT=Instance.new("Frame",MF)
CONT.Size=UDim2.new(1,-LW-1,1,-HDR) CONT.Position=UDim2.new(0,LW+1,0,HDR)
CONT.BackgroundColor3=C_PANEL CONT.BorderSizePixel=0 CONT.ZIndex=6
-- bottom-right corner
local CONTbr=Instance.new("Frame",CONT)
CONTbr.Size=UDim2.new(1,0,0,14) CONTbr.Position=UDim2.new(0,0,1,-14)
CONTbr.BackgroundColor3=C_PANEL CONTbr.BorderSizePixel=0 CONTbr.ZIndex=6
Instance.new("UICorner",CONTbr).CornerRadius=UDim.new(0,14)

-- scrolling frame for right panel
-- v5.6 camera fix: Active=false, manual touch scroll
local SF=Instance.new("ScrollingFrame",CONT)
SF.Size=UDim2.new(1,0,1,0)
SF.Position=UDim2.new(0,0,0,0)
SF.BackgroundTransparency=1
SF.ScrollBarThickness=3
SF.ScrollBarImageColor3=C_ACCENT
SF.CanvasSize=UDim2.new(0,0,0,0)
SF.AutomaticCanvasSize=Enum.AutomaticSize.Y
SF.ScrollingDirection=Enum.ScrollingDirection.Y
SF.Active=false      -- KEY: don't eat camera touch input
SF.ZIndex=6
SF.ElasticBehavior=Enum.ElasticBehavior.Never

-- manual touch scroll on content panel (not SF) so camera still gets input
do
    local scrolling=false local scrollStart=nil local scrollOrigin=0
    CONT.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch then
            scrolling=true scrollStart=inp.Position scrollOrigin=SF.CanvasPosition.Y
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not scrolling then return end
        if inp.UserInputType==Enum.UserInputType.Touch then
            local delta=inp.Position.Y-scrollStart.Y
            local maxY=math.max(0,SF.AbsoluteCanvasSize.Y-SF.AbsoluteSize.Y)
            SF.CanvasPosition=Vector2.new(0,math.clamp(scrollOrigin-delta,0,maxY))
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch then scrolling=false end
    end)
end

local SFL=Instance.new("UIListLayout",SF)
SFL.Padding=UDim.new(0,4) SFL.SortOrder=Enum.SortOrder.LayoutOrder
local SFP=Instance.new("UIPadding",SF)
SFP.PaddingTop=UDim.new(0,8) SFP.PaddingLeft=UDim.new(0,8)
SFP.PaddingRight=UDim.new(0,10) SFP.PaddingBottom=UDim.new(0,12)

-- ── STATUS LABEL ─────────────────────────────────────
local statLbl=Instance.new("TextLabel",SF)
statLbl.Size=UDim2.new(1,0,0,18) statLbl.BackgroundTransparency=1
statLbl.Text="" statLbl.TextColor3=Color3.fromRGB(120,255,150)
statLbl.TextSize=9 statLbl.Font=Enum.Font.Gotham
statLbl.LayoutOrder=0 statLbl.ZIndex=7

local function setStatus(msg)
    statLbl.Text=msg
    task.delay(3,function() if statLbl.Text==msg then statLbl.Text="" end end)
end

-- ══════════════════════════════════════════════════════
--  WIDGET BUILDERS  (all go into SF, right panel)
-- ══════════════════════════════════════════════════════
local toggleRefs={}
local categoryPanels={}   -- panel frame per category name
local currentCategory=nil

-- section heading inside right panel
local function makeHeading(label,order)
    local f=Instance.new("TextLabel",SF)
    f.Size=UDim2.new(1,0,0,22) f.BackgroundTransparency=1
    f.Text=label f.TextColor3=C_ACCENT
    f.TextSize=BF f.Font=Enum.Font.GothamBold
    f.TextXAlignment=Enum.TextXAlignment.Left
    f.LayoutOrder=order f.ZIndex=7
    return f
end

local BTN_H=isWide and 36 or 30

local function makeToggle(label,cfgKey,order)
    local row=Instance.new("Frame",SF)
    row.Size=UDim2.new(1,0,0,BTN_H) row.BackgroundColor3=C_ROW
    row.BorderSizePixel=0 row.LayoutOrder=order row.ZIndex=7
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)

    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-58,1,0) lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1 lbl.Text=label
    lbl.TextColor3=C_TEXT lbl.TextSize=BF
    lbl.Font=Enum.Font.Gotham lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.ZIndex=8

    local pill=Instance.new("Frame",row)
    pill.Size=UDim2.new(0,42,0,22) pill.Position=UDim2.new(1,-50,0.5,-11)
    pill.BorderSizePixel=0 pill.ZIndex=8
    Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)

    local knob=Instance.new("Frame",pill)
    knob.Size=UDim2.new(0,18,0,18) knob.Position=UDim2.new(0,2,0.5,-9)
    knob.BackgroundColor3=Color3.fromRGB(255,255,255) knob.BorderSizePixel=0 knob.ZIndex=9
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local function refresh()
        local on=CFG[cfgKey]
        pill.BackgroundColor3=on and C_ON or C_OFF
        knob.Position=on and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
    end
    refresh() table.insert(toggleRefs,refresh)

    local btn=Instance.new("TextButton",row)
    btn.Size=UDim2.new(1,0,1,0) btn.BackgroundTransparency=1
    btn.Text="" btn.ZIndex=10
    btn.MouseButton1Click:Connect(function() CFG[cfgKey]=not CFG[cfgKey] refresh() end)
end

local function makeSlider(label,cfgKey,minV,maxV,order)
    local rH=BTN_H+16
    local row=Instance.new("Frame",SF)
    row.Size=UDim2.new(1,0,0,rH) row.BackgroundColor3=C_ROW
    row.BorderSizePixel=0 row.LayoutOrder=order row.ZIndex=7
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)

    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-62,0,18) lbl.Position=UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency=1 lbl.Text=label
    lbl.TextColor3=C_TEXT lbl.TextSize=BF-1
    lbl.Font=Enum.Font.Gotham lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.ZIndex=8

    local valL=Instance.new("TextLabel",row)
    valL.Size=UDim2.new(0,52,0,18) valL.Position=UDim2.new(1,-60,0,4)
    valL.BackgroundTransparency=1 valL.Text=tostring(CFG[cfgKey])
    valL.TextColor3=C_ACCENT valL.TextSize=BF-1
    valL.Font=Enum.Font.GothamBold valL.TextXAlignment=Enum.TextXAlignment.Right valL.ZIndex=8

    local track=Instance.new("Frame",row)
    track.Size=UDim2.new(1,-20,0,6) track.Position=UDim2.new(0,10,1,-16)
    track.BackgroundColor3=Color3.fromRGB(40,42,60) track.BorderSizePixel=0 track.ZIndex=8
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)

    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new((CFG[cfgKey]-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3=C_ACCENT fill.BorderSizePixel=0 fill.ZIndex=9
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)

    local thumb=Instance.new("TextButton",track)
    thumb.Size=UDim2.new(0,18,0,18) thumb.BackgroundColor3=Color3.fromRGB(255,255,255)
    thumb.Text="" thumb.BorderSizePixel=0 thumb.ZIndex=10
    thumb.Position=UDim2.new((CFG[cfgKey]-minV)/(maxV-minV),0,0.5,-9)
    Instance.new("UICorner",thumb).CornerRadius=UDim.new(1,0)

    local dragging=false
    local function upd(pos)
        local ta=track.AbsolutePosition ts=track.AbsoluteSize
        local rel=math.clamp((pos.X-ta.X)/ts.X,0,1)
        local val=math.floor(minV+rel*(maxV-minV)+0.5)
        CFG[cfgKey]=val valL.Text=tostring(val)
        fill.Size=UDim2.new(rel,0,1,0) thumb.Position=UDim2.new(rel,0,0.5,-9)
    end
    thumb.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then dragging=true end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType==Enum.UserInputType.MouseMovement
        or inp.UserInputType==Enum.UserInputType.Touch then upd(inp.Position) end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then upd(inp.Position) end
    end)
end

-- cfg button (half width)
local _cfgOrder=200
local function cfgBtn(label,color,fn)
    _cfgOrder=_cfgOrder+1
    local b=Instance.new("TextButton",SF)
    b.Size=UDim2.new(0.48,0,0,BTN_H) b.BackgroundColor3=color
    b.Text=label b.TextColor3=Color3.fromRGB(255,255,255)
    b.TextSize=BF b.Font=Enum.Font.GothamBold
    b.LayoutOrder=_cfgOrder b.ZIndex=7
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    b.MouseButton1Click:Connect(fn)
end

local function refreshAllToggles() for _,fn in pairs(toggleRefs) do fn() end end

-- ── LEFT TAB BUTTONS ──────────────────────────────────
-- Each tab shows/hides groups of rows in the right SF by layoutOrder range.
-- We do it simpler: each tab stores a list of widget frames to show/hide.

-- We'll collect frames per category using a wrapper approach:
-- makeToggle/makeSlider returns the frame, we group them.

-- Rebuild with category-aware show/hide:
-- categoryWidgets[catName] = {frame, frame, ...}
local categoryWidgets={}
local currentCat=nil

local function startCategory(name)
    categoryWidgets[name]={}
    currentCat=name
end
local function _regWidget(f)
    if currentCat then
        table.insert(categoryWidgets[currentCat],f)
        f.Visible=false  -- hidden until tab selected
    end
end

-- override builders to register and return frame
local function makeHeadingC(label,order)
    local f=makeHeading(label,order) _regWidget(f) return f
end
local function makeToggleC(label,cfgKey,order)
    -- we need the row frame — rebuild inline to capture it
    local BTH=isWide and 36 or 30
    local row=Instance.new("Frame",SF)
    row.Size=UDim2.new(1,0,0,BTH) row.BackgroundColor3=C_ROW
    row.BorderSizePixel=0 row.LayoutOrder=order row.ZIndex=7
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-58,1,0) lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1 lbl.Text=label
    lbl.TextColor3=C_TEXT lbl.TextSize=BF lbl.Font=Enum.Font.Gotham
    lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.ZIndex=8
    local pill=Instance.new("Frame",row)
    pill.Size=UDim2.new(0,42,0,22) pill.Position=UDim2.new(1,-50,0.5,-11)
    pill.BorderSizePixel=0 pill.ZIndex=8
    Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("Frame",pill)
    knob.Size=UDim2.new(0,18,0,18) knob.Position=UDim2.new(0,2,0.5,-9)
    knob.BackgroundColor3=Color3.fromRGB(255,255,255) knob.BorderSizePixel=0 knob.ZIndex=9
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local function refresh()
        local on=CFG[cfgKey]
        pill.BackgroundColor3=on and C_ON or C_OFF
        knob.Position=on and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
    end
    refresh() table.insert(toggleRefs,refresh)
    local btn=Instance.new("TextButton",row)
    btn.Size=UDim2.new(1,0,1,0) btn.BackgroundTransparency=1 btn.Text="" btn.ZIndex=10
    btn.MouseButton1Click:Connect(function() CFG[cfgKey]=not CFG[cfgKey] refresh() end)
    _regWidget(row)
end

local function makeSliderC(label,cfgKey,minV,maxV,order)
    local BTH=isWide and 36 or 30
    local rH=BTH+16
    local row=Instance.new("Frame",SF)
    row.Size=UDim2.new(1,0,0,rH) row.BackgroundColor3=C_ROW
    row.BorderSizePixel=0 row.LayoutOrder=order row.ZIndex=7
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-62,0,18) lbl.Position=UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency=1 lbl.Text=label
    lbl.TextColor3=C_TEXT lbl.TextSize=BF-1 lbl.Font=Enum.Font.Gotham
    lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.ZIndex=8
    local valL=Instance.new("TextLabel",row)
    valL.Size=UDim2.new(0,52,0,18) valL.Position=UDim2.new(1,-60,0,4)
    valL.BackgroundTransparency=1 valL.Text=tostring(CFG[cfgKey])
    valL.TextColor3=C_ACCENT valL.TextSize=BF-1 valL.Font=Enum.Font.GothamBold
    valL.TextXAlignment=Enum.TextXAlignment.Right valL.ZIndex=8
    local track=Instance.new("Frame",row)
    track.Size=UDim2.new(1,-20,0,6) track.Position=UDim2.new(0,10,1,-16)
    track.BackgroundColor3=Color3.fromRGB(40,42,60) track.BorderSizePixel=0 track.ZIndex=8
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new((CFG[cfgKey]-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3=C_ACCENT fill.BorderSizePixel=0 fill.ZIndex=9
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local thumb=Instance.new("TextButton",track)
    thumb.Size=UDim2.new(0,18,0,18) thumb.BackgroundColor3=Color3.fromRGB(255,255,255)
    thumb.Text="" thumb.BorderSizePixel=0 thumb.ZIndex=10
    thumb.Position=UDim2.new((CFG[cfgKey]-minV)/(maxV-minV),0,0.5,-9)
    Instance.new("UICorner",thumb).CornerRadius=UDim.new(1,0)
    local dragging=false
    local function upd(pos)
        local ta=track.AbsolutePosition ts=track.AbsoluteSize
        local rel=math.clamp((pos.X-ta.X)/ts.X,0,1)
        local val=math.floor(minV+rel*(maxV-minV)+0.5)
        CFG[cfgKey]=val valL.Text=tostring(val)
        fill.Size=UDim2.new(rel,0,1,0) thumb.Position=UDim2.new(rel,0,0.5,-9)
    end
    thumb.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then dragging=true end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType==Enum.UserInputType.MouseMovement
        or inp.UserInputType==Enum.UserInputType.Touch then upd(inp.Position) end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then upd(inp.Position) end
    end)
    _regWidget(row)
end

-- ── POPULATE CATEGORIES ───────────────────────────────
local CATS={
    {name="🎯 Combat",   icon="🎯"},
    {name="🏃 Movement", icon="🏃"},
    {name="🔧 Utility",  icon="🔧"},
    {name="👁️ Visual",   icon="👁️"},
    {name="🛡️ Bypass",   icon="🛡️"},
    {name="💾 Config",   icon="💾"},
}

startCategory("🎯 Combat")
makeToggleC("Silent Aim",               "SilentAim",       10)
makeSliderC("FOV Circle (Silent Aim)",  "SilentAimFOV",    10,500, 11)
makeToggleC("Show FOV Circle",          "ShowFOVCircle",   12)
makeToggleC("Aimbot  [Hold Q]",         "Aimbot",          13)
makeSliderC("Aimbot FOV",               "AimbotFOV",       10,500, 14)
makeToggleC("Show Aimbot FOV",          "ShowAimbotFOV",   15)
makeToggleC("Unlimited Ammo",           "UnlimitedAmmo",   16)
makeToggleC("Auto Reload",              "AutoReload",      17)

startCategory("🏃 Movement")
makeToggleC("Float Mode  [Space/Jump]", "FloatMode",       20)
makeSliderC("Float Power",              "FloatPower",      10,200, 21)
makeToggleC("Noclip",                  "Noclip",           22)
makeToggleC("Auto Sprint",             "AutoSprint",       23)
makeSliderC("Sprint Speed",            "SprintSpeed",      16,60,  24)

startCategory("🔧 Utility")
makeToggleC("Auto Pickup",             "AutoPickup",       30)
makeSliderC("Pickup Range",            "AutoPickupRange",  5,100,  31)
makeToggleC("Auto Respawn",            "AutoRespawn",      32)
makeToggleC("Respawn @ Loot",          "AutoRespawnLoot",  33)

startCategory("👁️ Visual")
makeToggleC("ESP",                     "ESPEnabled",       40)

startCategory("🛡️ Bypass")
makeToggleC("Anti Kick",               "AntiKick",         50)
makeToggleC("Hide Executor",           "HideExecutor",     51)

-- config category — special: has buttons + import box
startCategory("💾 Config")
do
    -- save button
    local b1=Instance.new("TextButton",SF)
    b1.Size=UDim2.new(0.48,0,0,BTN_H) b1.BackgroundColor3=Color3.fromRGB(35,120,60)
    b1.Text="💾 Save" b1.TextColor3=Color3.fromRGB(255,255,255)
    b1.TextSize=BF b1.Font=Enum.Font.GothamBold b1.LayoutOrder=60 b1.ZIndex=7
    Instance.new("UICorner",b1).CornerRadius=UDim.new(0,6)
    b1.MouseButton1Click:Connect(function() local ok,msg=saveConfig() setStatus(ok and "✅ "..msg or "❌ "..msg) end)
    _regWidget(b1)

    local b2=Instance.new("TextButton",SF)
    b2.Size=UDim2.new(0.48,0,0,BTN_H) b2.BackgroundColor3=Color3.fromRGB(40,80,160)
    b2.Text="📂 Load" b2.TextColor3=Color3.fromRGB(255,255,255)
    b2.TextSize=BF b2.Font=Enum.Font.GothamBold b2.LayoutOrder=61 b2.ZIndex=7
    Instance.new("UICorner",b2).CornerRadius=UDim.new(0,6)
    b2.MouseButton1Click:Connect(function()
        local ok,msg=loadConfig() if ok then refreshAllToggles() end
        setStatus(ok and "✅ "..msg or "❌ "..msg)
    end)
    _regWidget(b2)

    local b3=Instance.new("TextButton",SF)
    b3.Size=UDim2.new(0.48,0,0,BTN_H) b3.BackgroundColor3=Color3.fromRGB(120,60,35)
    b3.Text="📋 Export" b3.TextColor3=Color3.fromRGB(255,255,255)
    b3.TextSize=BF b3.Font=Enum.Font.GothamBold b3.LayoutOrder=62 b3.ZIndex=7
    Instance.new("UICorner",b3).CornerRadius=UDim.new(0,6)
    b3.MouseButton1Click:Connect(function() local ok,msg=exportConfig() setStatus(ok and "✅ "..msg or "❌ "..msg) end)
    _regWidget(b3)

    -- import label
    local iLbl=Instance.new("TextLabel",SF)
    iLbl.Size=UDim2.new(1,0,0,16) iLbl.BackgroundTransparency=1
    iLbl.Text="Paste config JSON — then tap Import:"
    iLbl.TextColor3=C_DIM iLbl.TextSize=9 iLbl.Font=Enum.Font.Gotham
    iLbl.TextXAlignment=Enum.TextXAlignment.Left iLbl.LayoutOrder=63 iLbl.ZIndex=7
    _regWidget(iLbl)

    -- import textbox
    local iBox=Instance.new("TextBox",SF)
    iBox.Size=UDim2.new(1,0,0,50) iBox.BackgroundColor3=Color3.fromRGB(25,26,38)
    iBox.BorderSizePixel=0 iBox.Text="" iBox.PlaceholderText="{\"SilentAim\":false,...}"
    iBox.TextColor3=Color3.fromRGB(180,255,180) iBox.PlaceholderColor3=C_DIM
    iBox.TextSize=9 iBox.Font=Enum.Font.Code
    iBox.TextWrapped=true iBox.MultiLine=true iBox.ClearTextOnFocus=false
    iBox.TextXAlignment=Enum.TextXAlignment.Left iBox.TextYAlignment=Enum.TextYAlignment.Top
    iBox.LayoutOrder=64 iBox.ZIndex=7
    Instance.new("UICorner",iBox).CornerRadius=UDim.new(0,6)
    local ibp=Instance.new("UIPadding",iBox)
    ibp.PaddingLeft=UDim.new(0,5) ibp.PaddingTop=UDim.new(0,4)
    _regWidget(iBox)

    local b4=Instance.new("TextButton",SF)
    b4.Size=UDim2.new(0.48,0,0,BTN_H) b4.BackgroundColor3=Color3.fromRGB(80,40,120)
    b4.Text="📥 Import" b4.TextColor3=Color3.fromRGB(255,255,255)
    b4.TextSize=BF b4.Font=Enum.Font.GothamBold b4.LayoutOrder=65 b4.ZIndex=7
    Instance.new("UICorner",b4).CornerRadius=UDim.new(0,6)
    b4.MouseButton1Click:Connect(function()
        local json=iBox.Text
        if json=="" and getclipboard then local ok,s=pcall(getclipboard) if ok then json=s end end
        if json=="" then setStatus("❌ paste JSON in the box") return end
        local ok,msg=importConfig(json)
        if ok then refreshAllToggles() iBox.Text="" end
        setStatus(ok and "✅ "..msg or "❌ "..msg)
    end)
    _regWidget(b4)
end

-- ── TAB SELECTOR FUNCTION ─────────────────────────────
local tabButtons={}

local function selectCategory(name)
    -- hide all widgets
    for catName,widgets in pairs(categoryWidgets) do
        local visible=(catName==name)
        for _,w in ipairs(widgets) do w.Visible=visible end
    end
    -- update tab button colors
    for catName,btn in pairs(tabButtons) do
        if catName==name then
            btn.BackgroundColor3=C_ACCENT2
            btn.TextColor3=Color3.fromRGB(255,255,255)
        else
            btn.BackgroundColor3=Color3.fromRGB(25,26,38)
            btn.TextColor3=C_DIM
        end
    end
    SF.CanvasPosition=Vector2.new(0,0)   -- scroll back to top on tab switch
    currentCat=name
end

-- ── BUILD LEFT TAB BUTTONS ────────────────────────────
for i,cat in ipairs(CATS) do
    local btn=Instance.new("TextButton",SIDE)
    btn.Size=UDim2.new(1,0,0,isWide and 40 or 34)
    btn.BackgroundColor3=Color3.fromRGB(25,26,38)
    btn.BorderSizePixel=0
    btn.Text=cat.name
    btn.TextColor3=C_DIM
    btn.TextSize=BF-1
    btn.Font=Enum.Font.GothamBold
    btn.TextWrapped=true
    btn.LayoutOrder=i
    btn.ZIndex=7
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)
    tabButtons[cat.name]=btn
    btn.MouseButton1Click:Connect(function() selectCategory(cat.name) end)
end

-- select first tab by default
selectCategory("🎯 Combat")

-- ══════════════════════════════════════════════════════
--  FLOATING TOGGLE BUTTON
-- ══════════════════════════════════════════════════════
local toggleBtn=Instance.new("TextButton",SG)
toggleBtn.Size=UDim2.new(0,62,0,62)
toggleBtn.Position=UDim2.new(0.5,-31,1,-100)
toggleBtn.BackgroundColor3=C_ACCENT
toggleBtn.TextColor3=Color3.fromRGB(0,0,0)
toggleBtn.Text="⚡" toggleBtn.TextSize=26
toggleBtn.Font=Enum.Font.GothamBold
toggleBtn.ZIndex=10 toggleBtn.Active=true
Instance.new("UICorner",toggleBtn).CornerRadius=UDim.new(1,0)
local tStr=Instance.new("UIStroke",toggleBtn)
tStr.Color=Color3.fromRGB(0,0,0) tStr.Thickness=2

do
    local drag,ds,sp,moved,onBtn=false,nil,nil,false,false
    toggleBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch
        or inp.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true moved=false onBtn=true ds=inp.Position sp=toggleBtn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType==Enum.UserInputType.Touch
        or inp.UserInputType==Enum.UserInputType.MouseMovement) then
            local d=inp.Position-ds
            if d.Magnitude>6 then moved=true end
            toggleBtn.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch
        or inp.UserInputType==Enum.UserInputType.MouseButton1 then
            if drag and onBtn and not moved then
                local nv=not MF.Visible
                MF.Visible=nv MF.Active=nv
            end
            drag=false onBtn=false
        end
    end)
end

print("✅ PRIMODAXVGRANT v5.6 loaded — Vagrant Survival v10 | Created By BoboyTagaAquarius")
