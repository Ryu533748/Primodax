-- ██████╗ ██████╗ ██╗███╗   ███╗ ██████╗ ██████╗  █████╗ ██╗  ██╗
-- ██╔══██╗██╔══██╗██║████╗ ████║██╔═══██╗██╔══██╗██╔══██╗╚██╗██╔╝
-- ██████╔╝██████╔╝██║██╔████╔██║██║   ██║██║  ██║███████║ ╚███╔╝
-- ██╔═══╝ ██╔══██╗██║██║╚██╔╝██║██║   ██║██║  ██║██╔══██║ ██╔██╗
-- ██║     ██║  ██║██║██║ ╚═╝ ██║╚██████╔╝██████╔╝██║  ██║██╔╝ ██╗
-- ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
-- VAGRANT SURVIVAL v20 | FINAL RELEASE

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local Workspace        = game:GetService("Workspace")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")

local LP  = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

-- ============ CONFIG ============
local CFG = {
    ESPEnabled = true, ESPBox = true, ESPName = true, ESPDistance = true, ESPSkeleton = true,
    ESPLine = false, GunESPEnabled = true, NightVision = false,
    SilentAim = true, RageBot = false, Aimbot = false, AimbotSmoothing = 15, FOVRange = 250,
    WallCheck = true, TargetPart = "Head", UseFOV = true, SkipFriends = true,
    NoRecoil = true, NoSpread = true,
    InfiniteJump = false, AutoSprint = false, SprintSpeed = 22, GodMode = false,
    AutoPickup = false, PickupPriority = "Random",
    AntiKick = true,
}

-- ============ UTILS ============
local function getChar(p)   return p and p.Character end
local function getHum(p)    local c=getChar(p) return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot(p)   local c=getChar(p) return c and c:FindFirstChild("HumanoidRootPart") end
local function getPart(p,n) local c=getChar(p) return c and c:FindFirstChild(n) end
local function isAlive(p)   local h=getHum(p) return h and h.Health>0 end

-- ============ TARGET ENGINE ============
-- 100 Hz dedicated loop — always fresher than any FireServer call
local activeTarget = nil

local function refreshTarget()
    if not (CFG.SilentAim or CFG.Aimbot or CFG.RageBot) then
        activeTarget = nil return
    end
    local center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
    local bestP, bestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isAlive(p) then
            if not (CFG.SkipFriends and LP:IsFriendsWith(p.UserId)) then
                local tPart = getPart(p, CFG.TargetPart)
                if tPart then
                    local sPos, onS = Cam:WorldToViewportPoint(tPart.Position)
                    if onS then
                        local d2 = (Vector2.new(sPos.X, sPos.Y) - center).Magnitude
                        -- only lock targets inside the FOV circle
                        if d2 < CFG.FOVRange and d2 < bestDist then
                            bestP = p bestDist = d2
                        end
                    end
                end
            end
        end
    end
    activeTarget = bestP
end

task.spawn(function()
    while true do
        pcall(refreshTarget)
        task.wait(0.01)
    end
end)

-- ============ NIGHT VISION ============
local nightVisionColor  = Instance.new("ColorCorrectionEffect")
local nightVisionBright = Instance.new("BloomEffect")
local function toggleNightVision()
    if CFG.NightVision then
        nightVisionColor.Brightness = 0.3
        nightVisionColor.Contrast   = 0.1
        nightVisionColor.TintColor  = Color3.fromRGB(200,255,200)
        nightVisionColor.Parent     = Lighting
        nightVisionBright.Intensity = 0.5
        nightVisionBright.Size      = 24
        nightVisionBright.Parent    = Lighting
    else
        nightVisionColor.Parent  = nil
        nightVisionBright.Parent = nil
    end
end

-- ============ ESP ============
local espObjects = {}
local function createESP(player)
    if espObjects[player] or player == LP then return end
    local objs = {
        Box  = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Dist = Drawing.new("Text"),
        Line = Drawing.new("Line"),
        Skel = {
            Head  = Drawing.new("Line"), Torso = Drawing.new("Line"),
            LArm  = Drawing.new("Line"), RArm  = Drawing.new("Line"),
            LLeg  = Drawing.new("Line"), RLeg  = Drawing.new("Line"),
        },
    }
    objs.Box.Thickness=1.5 objs.Box.Color=Color3.fromRGB(255,50,50) objs.Box.Filled=false
    objs.Name.Size=14 objs.Name.Center=true objs.Name.Outline=true objs.Name.Color=Color3.fromRGB(255,255,255)
    objs.Dist.Size=12 objs.Dist.Center=true objs.Dist.Outline=true objs.Dist.Color=Color3.fromRGB(255,215,0)
    objs.Line.Thickness=1 objs.Line.Color=Color3.fromRGB(255,255,255)
    for _,v in pairs(objs.Skel) do v.Thickness=1 v.Color=Color3.fromRGB(255,255,255) end
    espObjects[player] = objs
end
for _,p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(p)
    if not espObjects[p] then return end
    for _,v in pairs(espObjects[p]) do
        if typeof(v)=="table" then
            for _,l in pairs(v) do pcall(function() l:Remove() end) end
        else
            pcall(function() v:Remove() end)
        end
    end
    espObjects[p] = nil
end)

task.spawn(function()
    while task.wait(0.1) do
        for player,objs in pairs(espObjects) do
            local rendered = false
            if CFG.ESPEnabled and isAlive(player) then
                local char   = getChar(player)
                local root   = getRoot(player)
                local head   = getPart(player,"Head")
                local myRoot = getRoot(LP)
                if root and head and myRoot then
                    local headPos,onScreen = Cam:WorldToViewportPoint(head.Position)
                    local rootPos,_        = Cam:WorldToViewportPoint(root.Position)
                    if onScreen then
                        rendered = true
                        local h = math.abs(rootPos.Y-headPos.Y)*1.8
                        local w = h*0.6
                        objs.Box.Visible  = CFG.ESPBox
                        objs.Box.Size     = Vector2.new(w,h)
                        objs.Box.Position = Vector2.new(headPos.X-w/2, headPos.Y-h*0.2)
                        objs.Name.Visible  = CFG.ESPName
                        objs.Name.Text     = player.Name
                        objs.Name.Position = Vector2.new(headPos.X, headPos.Y-20)
                        objs.Dist.Visible  = CFG.ESPDistance
                        objs.Dist.Text     = string.format("[%d studs]",(myRoot.Position-root.Position).Magnitude)
                        objs.Dist.Position = Vector2.new(headPos.X, rootPos.Y+10)
                        objs.Line.Visible  = CFG.ESPLine
                        objs.Line.From     = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y)
                        objs.Line.To       = Vector2.new(headPos.X, headPos.Y)
                        if CFG.ESPSkeleton then
                            local function drawBone(p1,p2,line)
                                if p1 and p2 then
                                    local v1,on1 = Cam:WorldToViewportPoint(p1.Position)
                                    local v2,on2 = Cam:WorldToViewportPoint(p2.Position)
                                    line.Visible = on1 and on2
                                    line.From    = Vector2.new(v1.X,v1.Y)
                                    line.To      = Vector2.new(v2.X,v2.Y)
                                else line.Visible = false end
                            end
                            local ut = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
                            local lt = char:FindFirstChild("LowerTorso")  or char:FindFirstChild("Torso")
                            drawBone(head, ut, objs.Skel.Head)
                            drawBone(ut,   lt, objs.Skel.Torso)
                            drawBone(char:FindFirstChild("LeftUpperArm"),  char:FindFirstChild("LeftLowerArm"),  objs.Skel.LArm)
                            drawBone(char:FindFirstChild("RightUpperArm"), char:FindFirstChild("RightLowerArm"), objs.Skel.RArm)
                            drawBone(char:FindFirstChild("LeftUpperLeg"),  char:FindFirstChild("LeftLowerLeg"),  objs.Skel.LLeg)
                            drawBone(char:FindFirstChild("RightUpperLeg"), char:FindFirstChild("RightLowerLeg"), objs.Skel.RLeg)
                        else
                            for _,l in pairs(objs.Skel) do l.Visible=false end
                        end
                    end
                end
            end
            if not rendered then
                objs.Box.Visible=false objs.Name.Visible=false
                objs.Dist.Visible=false objs.Line.Visible=false
                for _,l in pairs(objs.Skel) do l.Visible=false end
            end
        end
    end
end)

-- ============ GUN ESP ============
local gunESPObjects = {}
task.spawn(function()
    while task.wait(1) do
        if not CFG.GunESPEnabled then
            for obj,d in pairs(gunESPObjects) do
                d.Text:Remove() d.Dist:Remove() gunESPObjects[obj]=nil
            end
        else
            for obj,d in pairs(gunESPObjects) do
                if not obj or not obj.Parent then
                    d.Text:Remove() d.Dist:Remove() gunESPObjects[obj]=nil
                end
            end
            for _,obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") or obj:IsA("Tool") or obj:IsA("BasePart") then
                    local n = obj.Name:lower()
                    if n:find("gun") or n:find("crossbow") or n:find("weapon")
                    or n:find("rifle") or n:find("pistol") or n:find("shotgun") or n:find("revolver") then
                        local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
                        if part and not gunESPObjects[obj] then
                            local text = Drawing.new("Text")
                            text.Size=14 text.Center=true text.Outline=true
                            text.Color=Color3.fromRGB(0,255,255)
                            local dist = Drawing.new("Text")
                            dist.Size=12 dist.Center=true dist.Outline=true
                            dist.Color=Color3.fromRGB(255,255,255)
                            gunESPObjects[obj] = {Text=text,Dist=dist}
                        end
                    end
                end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if not CFG.GunESPEnabled then return end
    for obj,d in pairs(gunESPObjects) do
        if obj and obj.Parent then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
            if part then
                local sp,on = Cam:WorldToViewportPoint(part.Position)
                if on then
                    local myRoot = getRoot(LP)
                    local distance = myRoot and math.floor((myRoot.Position-part.Position).Magnitude) or 0
                    d.Text.Text     = "["..obj.Name.."]"
                    d.Text.Position = Vector2.new(sp.X,sp.Y-20)
                    d.Text.Visible  = true
                    d.Dist.Text     = "["..tostring(distance).." studs]"
                    d.Dist.Position = Vector2.new(sp.X,sp.Y)
                    d.Dist.Visible  = true
                else
                    d.Text.Visible=false d.Dist.Visible=false
                end
            end
        end
    end
end)

-- ============ FOV CIRCLE + AIMBOT ============
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness=1.5
fovCircle.Color=Color3.fromRGB(255,255,255)
fovCircle.Filled=false

RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
    fovCircle.Radius   = CFG.FOVRange
    fovCircle.Visible  = CFG.UseFOV

    if CFG.Aimbot and activeTarget then
        local tPart = getPart(activeTarget, CFG.TargetPart)
        if tPart then
            local targetCF = CFrame.new(Cam.CFrame.Position, tPart.Position)
            local smooth   = math.clamp(1-(CFG.AimbotSmoothing/100), 0.05, 1)
            Cam.CFrame     = Cam.CFrame:Lerp(targetCF, smooth)
        end
    end
end)

-- ============ NAMECALL HOOK ============
-- FIX: no pcall wrapper — return value must reach Roblox directly.
-- FIX: activeTarget read from 100Hz loop above — never nil from frame lag.
local oldNamecall
oldNamecall = hookmetamethod(game,"__namecall",newcclosure(function(self,...)
    if checkcaller and checkcaller() then return oldNamecall(self,...) end

    local method = getnamecallmethod()
    local args   = {...}

    if method == "FireServer" or method == "InvokeServer" then

        -- anti kick
        if CFG.AntiKick then
            local name = (self.Name or ""):lower()
            if name:find("kick") or name:find("ban")
            or name:find("detect") or name:find("report") then
                return nil
            end
        end

        -- silent aim — redirect all Vector3/CFrame/BasePart args to target
        if CFG.SilentAim and activeTarget and isAlive(activeTarget) then
            local targetPart = getPart(activeTarget, CFG.TargetPart)
            if targetPart then
                local targetPos = targetPart.Position
                for i,v in ipairs(args) do
                    if typeof(v) == "Vector3" then
                        args[i] = targetPos
                    elseif typeof(v) == "CFrame" then
                        args[i] = CFrame.lookAt(Cam.CFrame.Position, targetPos)
                    elseif typeof(v) == "Instance" then
                        if v:IsA("BasePart") then
                            args[i] = targetPart
                        elseif v:IsA("Model") then
                            args[i] = getChar(activeTarget) or v
                        end
                    end
                end
            end
        end
    end

    -- FIX: direct return — not inside pcall, value reaches Roblox
    return oldNamecall(self, table.unpack(args))
end))

-- ============ NO RECOIL / NO SPREAD ============
-- Value scan only — no __index/__newindex hook (those crash mobile)
RunService.RenderStepped:Connect(function()
    if not CFG.NoRecoil and not CFG.NoSpread then return end
    local char = getChar(LP) if not char then return end
    for _,tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            for _,v in ipairs(tool:GetDescendants()) do
                pcall(function()
                    local n = v.Name:lower()
                    if CFG.NoRecoil and (n:find("recoil") or n:find("camerarecoil")) then
                        if v:IsA("NumberValue") or v:IsA("IntValue") then v.Value=0 end
                        if v:IsA("Vector3Value") then v.Value=Vector3.zero end
                    end
                    if CFG.NoSpread and (n:find("spread") or n:find("bulletspread")) then
                        if v:IsA("NumberValue") or v:IsA("IntValue") then v.Value=0 end
                    end
                end)
            end
        end
    end
end)

-- ============ MOVEMENT ============
UserInputService.JumpRequest:Connect(function()
    pcall(function()
        if CFG.InfiniteJump then
            local hum  = getHum(LP)
            local root = getRoot(LP)
            if hum and root and hum.Health>0 then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                task.wait()
                root.AssemblyLinearVelocity = Vector3.new(
                    root.AssemblyLinearVelocity.X, 75, root.AssemblyLinearVelocity.Z)
            end
        end
    end)
end)

RunService.Heartbeat:Connect(function()
    pcall(function()
        local hum  = getHum(LP)
        local root = getRoot(LP)
        if hum and root then
            if CFG.GodMode and hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
            if CFG.InfiniteJump and root.AssemblyLinearVelocity.Y < -50 then
                root.AssemblyLinearVelocity = Vector3.new(
                    root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
            end
            if CFG.AutoSprint and hum.WalkSpeed < CFG.SprintSpeed then
                hum.WalkSpeed = CFG.SprintSpeed
            elseif not CFG.AutoSprint and hum.WalkSpeed == CFG.SprintSpeed then
                hum.WalkSpeed = 16
            end
        end
    end)
end)

-- ============ TELEPORT TO BAG ============
local function doTeleportBag()
    local myRoot = getRoot(LP) if not myRoot then return end
    local bestBag,bestDist = nil,math.huge
    local myName,myId = LP.Name:lower(),tostring(LP.UserId)
    for _,obj in ipairs(Workspace:GetDescendants()) do
        local n = (obj.Name or ""):lower()
        if n:find("bag") or n:find("loot") or n:find("corpse") or n:find("drop") then
            local isMine = n:find(myName,1,true) or n:find(myId,1,true)
            if not isMine then
                local ok,attr = pcall(function()
                    return obj:GetAttribute("Owner") or obj:GetAttribute("UserId")
                end)
                if ok and attr and tostring(attr):lower()==myName then isMine=true end
            end
            if isMine then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
                if part then
                    local dist = (myRoot.Position-part.Position).Magnitude
                    if dist < bestDist then bestBag=part bestDist=dist end
                end
            end
        end
    end
    if bestBag then myRoot.CFrame = bestBag.CFrame * CFrame.new(0,3,0) end
end

-- ============ UI ============
local parentGui = gethui and gethui() or CoreGui
pcall(function()
    local old = parentGui:FindFirstChild("VagrantSurvivalUI")
    if old then old:Destroy() end
end)

local SG = Instance.new("ScreenGui")
SG.Name="VagrantSurvivalUI" SG.ResetOnSpawn=false SG.IgnoreGuiInset=true
SG.DisplayOrder=999 SG.Parent=parentGui
if protect_gui then pcall(protect_gui,SG) end

-- floating gear button
local FloatBtn = Instance.new("TextButton")
FloatBtn.Size=UDim2.new(0,40,0,40)
FloatBtn.Position=UDim2.new(0,20,0,20)
FloatBtn.BackgroundColor3=Color3.fromRGB(20,20,20)
FloatBtn.Text="⚙️" FloatBtn.TextSize=20
FloatBtn.TextColor3=Color3.fromRGB(100,50,200)
FloatBtn.ZIndex=10 FloatBtn.Parent=SG
Instance.new("UICorner",FloatBtn).CornerRadius=UDim.new(1,0)
local fStroke=Instance.new("UIStroke",FloatBtn)
fStroke.Color=Color3.fromRGB(100,50,200) fStroke.Thickness=2

local MF = Instance.new("Frame")
MF.Size=UDim2.new(0,480,0,280)
MF.Position=UDim2.new(0.5,-240,0.5,-140)
MF.BackgroundColor3=Color3.fromRGB(12,12,12)
MF.BorderSizePixel=0 MF.Active=true MF.Visible=false
MF.ZIndex=5 MF.Parent=SG
Instance.new("UICorner",MF).CornerRadius=UDim.new(0,8)

-- float button: drag vs tap
local fbDragging=false local fbDragStart=nil
local fbPosStart=nil   local fbMoved=false

FloatBtn.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.Touch
    or inp.UserInputType==Enum.UserInputType.MouseButton1 then
        fbDragging=true fbMoved=false
        fbDragStart=inp.Position fbPosStart=FloatBtn.Position
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if not fbDragging then return end
    if inp.UserInputType==Enum.UserInputType.Touch
    or inp.UserInputType==Enum.UserInputType.MouseMovement then
        local delta=inp.Position-fbDragStart
        if delta.Magnitude>6 then
            fbMoved=true
            FloatBtn.Position=UDim2.new(
                fbPosStart.X.Scale,fbPosStart.X.Offset+delta.X,
                fbPosStart.Y.Scale,fbPosStart.Y.Offset+delta.Y)
        end
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if not fbDragging then return end
    if inp.UserInputType==Enum.UserInputType.Touch
    or inp.UserInputType==Enum.UserInputType.MouseButton1 then
        fbDragging=false
        if not fbMoved then MF.Visible=not MF.Visible end
        fbMoved=false
    end
end)

-- top bar
local TopBar=Instance.new("Frame")
TopBar.Size=UDim2.new(1,0,0,35)
TopBar.BackgroundColor3=Color3.fromRGB(20,20,20)
TopBar.ZIndex=6 TopBar.Parent=MF
Instance.new("UICorner",TopBar).CornerRadius=UDim.new(0,8)

local function mkLbl(pr)
    local l=Instance.new("TextLabel") for k,v in pairs(pr) do l[k]=v end return l
end
mkLbl({Size=UDim2.new(1,-10,0,20),Position=UDim2.new(0,10,0,2),
    BackgroundTransparency=1,Text="Vagrant Survival v20",
    TextColor3=Color3.fromRGB(200,200,200),Font=Enum.Font.GothamBold,
    TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=TopBar})
mkLbl({Size=UDim2.new(1,-10,0,10),Position=UDim2.new(0,10,0,18),
    BackgroundTransparency=1,Text="Created by: BoboyTagaAquarius",
    TextColor3=Color3.fromRGB(150,150,150),Font=Enum.Font.Gotham,
    TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7,Parent=TopBar})

-- menu drag
do
    local drag,ds,ps=false,nil,nil
    TopBar.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch
        or inp.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true ds=inp.Position ps=MF.Position end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not drag then return end
        if inp.UserInputType==Enum.UserInputType.Touch
        or inp.UserInputType==Enum.UserInputType.MouseMovement then
            local d=inp.Position-ds
            MF.Position=UDim2.new(ps.X.Scale,ps.X.Offset+d.X,ps.Y.Scale,ps.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch
        or inp.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

-- sidebar + pages
local Sidebar=Instance.new("Frame")
Sidebar.Size=UDim2.new(0,100,1,-35) Sidebar.Position=UDim2.new(0,0,0,35)
Sidebar.BackgroundColor3=Color3.fromRGB(15,15,15)
Sidebar.ZIndex=6 Sidebar.Parent=MF

local Content=Instance.new("Frame")
Content.Size=UDim2.new(1,-105,1,-40) Content.Position=UDim2.new(0,100,0,35)
Content.BackgroundTransparency=1 Content.ZIndex=6 Content.Parent=MF

local Pages={}
local function makePage(name)
    local f=Instance.new("ScrollingFrame")
    f.Size=UDim2.new(1,0,1,0) f.BackgroundTransparency=1
    f.ScrollBarThickness=2 f.ZIndex=7
    f.AutomaticCanvasSize=Enum.AutomaticSize.Y
    f.CanvasSize=UDim2.new(0,0,0,0)
    f.Visible=false f.Parent=Content
    local l=Instance.new("UIListLayout",f)
    l.Padding=UDim.new(0,4) l.SortOrder=Enum.SortOrder.LayoutOrder
    Pages[name]=f return f
end

local VisualPage   = makePage("Visual")
local CombatPage   = makePage("Combat")
local SettingsPage = makePage("Settings")

local function switchTab(name)
    for n,p in pairs(Pages) do p.Visible=(n==name) end
end

local function makeTabBtn(name,order)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,-10,0,30)
    btn.Position=UDim2.new(0,5,0,5+(order*35))
    btn.BackgroundColor3=Color3.fromRGB(25,25,25)
    btn.Text="  "..name
    btn.TextColor3=Color3.fromRGB(150,150,150)
    btn.Font=Enum.Font.GothamBold btn.TextSize=11
    btn.TextXAlignment=Enum.TextXAlignment.Left
    btn.ZIndex=7 btn.Parent=Sidebar
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,4)
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
end
makeTabBtn("Visual",0)
makeTabBtn("Combat",1)
makeTabBtn("Settings",2)

-- widget builders
local function makeToggle(name,key,parent,order,callback)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,-10,0,26) btn.BackgroundTransparency=1
    btn.Text="" btn.LayoutOrder=order btn.ZIndex=7 btn.Parent=parent
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-40,1,0) lbl.BackgroundTransparency=1
    lbl.Text=name lbl.TextColor3=Color3.fromRGB(200,200,200)
    lbl.Font=Enum.Font.Gotham lbl.TextSize=11
    lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.ZIndex=8 lbl.Parent=btn
    local ind=Instance.new("Frame")
    ind.Size=UDim2.new(0,24,0,12) ind.Position=UDim2.new(1,-30,0.5,-6)
    ind.BackgroundColor3=CFG[key] and Color3.fromRGB(100,50,200) or Color3.fromRGB(50,50,50)
    ind.ZIndex=8 ind.Parent=btn
    Instance.new("UICorner",ind).CornerRadius=UDim.new(1,0)
    local dot=Instance.new("Frame")
    dot.Size=UDim2.new(0,8,0,8)
    dot.Position=CFG[key] and UDim2.new(1,-10,0.5,-4) or UDim2.new(0,2,0.5,-4)
    dot.BackgroundColor3=Color3.fromRGB(255,255,255)
    dot.ZIndex=9 dot.Parent=ind
    Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
    btn.MouseButton1Click:Connect(function()
        CFG[key]=not CFG[key]
        ind.BackgroundColor3=CFG[key] and Color3.fromRGB(100,50,200) or Color3.fromRGB(50,50,50)
        dot.Position=CFG[key] and UDim2.new(1,-10,0.5,-4) or UDim2.new(0,2,0.5,-4)
        if callback then callback() end
    end)
end

local function makeSlider(name,key,min,max,parent,order)
    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(1,-10,0,35) frame.BackgroundTransparency=1
    frame.LayoutOrder=order frame.ZIndex=7 frame.Parent=parent
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,0,0,15) lbl.BackgroundTransparency=1
    lbl.Text=name..": "..CFG[key]
    lbl.TextColor3=Color3.fromRGB(200,200,200)
    lbl.Font=Enum.Font.Gotham lbl.TextSize=10
    lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.ZIndex=8 lbl.Parent=frame
    local bar=Instance.new("TextButton")
    bar.Size=UDim2.new(1,0,0,6) bar.Position=UDim2.new(0,0,0,20)
    bar.BackgroundColor3=Color3.fromRGB(40,40,40) bar.Text=""
    bar.ZIndex=8 bar.Parent=frame
    Instance.new("UICorner",bar).CornerRadius=UDim.new(1,0)
    local fill=Instance.new("Frame")
    fill.Size=UDim2.new((CFG[key]-min)/(max-min),0,1,0)
    fill.BackgroundColor3=Color3.fromRGB(100,50,200)
    fill.ZIndex=9 fill.Parent=bar
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local drag=false
    bar.MouseButton1Down:Connect(function() drag=true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
    local function update(x)
        if not drag then return end
        local rel=math.clamp((x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
        local val=math.floor(min+rel*(max-min))
        CFG[key]=val lbl.Text=name..": "..val fill.Size=UDim2.new(rel,0,1,0)
    end
    bar.MouseMoved:Connect(update)
    UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch then update(i.Position.X) end
    end)
end

local function makeDropdown(name,key,options,parent,order)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,-10,0,26) btn.BackgroundColor3=Color3.fromRGB(30,30,30)
    btn.Text="" btn.LayoutOrder=order btn.ZIndex=7 btn.Parent=parent
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,4)
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-10,1,0) lbl.Position=UDim2.new(0,5,0,0)
    lbl.BackgroundTransparency=1
    lbl.Text=name..": "..CFG[key]
    lbl.TextColor3=Color3.fromRGB(200,200,200)
    lbl.Font=Enum.Font.Gotham lbl.TextSize=10
    lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.ZIndex=8 lbl.Parent=btn
    btn.MouseButton1Click:Connect(function()
        local curIdx=1
        for i,v in ipairs(options) do if v==CFG[key] then curIdx=i break end end
        CFG[key]=options[(curIdx%#options)+1]
        lbl.Text=name..": "..CFG[key]
    end)
end

local function makeButton(name,color,parent,order,callback)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,-10,0,26) btn.BackgroundColor3=color
    btn.Text=name btn.TextColor3=Color3.fromRGB(255,255,255)
    btn.Font=Enum.Font.GothamBold btn.TextSize=11
    btn.LayoutOrder=order btn.ZIndex=7 btn.Parent=parent
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,4)
    btn.MouseButton1Click:Connect(callback)
end

-- Visual tab
makeToggle("Enable ESP",     "ESPEnabled",    VisualPage,1)
makeToggle("Box ESP",        "ESPBox",        VisualPage,2)
makeToggle("Name ESP",       "ESPName",       VisualPage,3)
makeToggle("Distance ESP",   "ESPDistance",   VisualPage,4)
makeToggle("Skeleton",       "ESPSkeleton",   VisualPage,5)
makeToggle("Tracer Line",    "ESPLine",       VisualPage,6)
makeToggle("Gun ESP (Loot)", "GunESPEnabled", VisualPage,7)
makeToggle("Night Vision",   "NightVision",   VisualPage,8,toggleNightVision)

-- Combat tab
makeToggle("Silent Aim",      "SilentAim",      CombatPage,1)
makeToggle("Rage Bot",        "RageBot",         CombatPage,2)
makeToggle("Aimbot (Smooth)", "Aimbot",          CombatPage,3)
makeSlider("Aimbot Smooth",   "AimbotSmoothing", 0,100,CombatPage,4)
makeToggle("Skip Friends",    "SkipFriends",     CombatPage,5)
makeToggle("Wall Check",      "WallCheck",       CombatPage,6)
makeDropdown("Target Part",   "TargetPart",{"Head","HumanoidRootPart","Torso"},CombatPage,7)
makeToggle("Use FOV",         "UseFOV",          CombatPage,8)
makeSlider("FOV Radius",      "FOVRange",0,800,  CombatPage,9)
makeToggle("No Recoil",       "NoRecoil",        CombatPage,10)
makeToggle("No Spread",       "NoSpread",        CombatPage,11)

-- Settings tab
makeToggle("Infinite Jump",   "InfiniteJump",    SettingsPage,1)
makeToggle("Auto Sprint",     "AutoSprint",       SettingsPage,2)
makeSlider("Sprint Speed",    "SprintSpeed",16,100,SettingsPage,3)
makeToggle("GodMode (Semi)",  "GodMode",          SettingsPage,4)
makeToggle("Anti Kick/Ban",   "AntiKick",         SettingsPage,5)
makeButton("Teleport to Bag/Loot",
    Color3.fromRGB(100,50,200),SettingsPage,6,doTeleportBag)
makeButton("Export Config",
    Color3.fromRGB(50,150,50),SettingsPage,7,function()
        local encoded=HttpService:JSONEncode(CFG)
        if setclipboard then setclipboard(encoded) end
    end)
makeButton("Import Config",
    Color3.fromRGB(150,50,50),SettingsPage,8,function()
        local input=getclipboard and getclipboard() or ""
        if input~="" then
            local ok,decoded=pcall(function() return HttpService:JSONDecode(input) end)
            if ok and type(decoded)=="table" then
                for k,v in pairs(decoded) do if CFG[k]~=nil then CFG[k]=v end end
            end
        end
    end)

switchTab("Combat")
print("[Vagrant Survival v20] BoboyTagaAquarius — loaded.")
