-- ██████╗ ██████╗ ██╗███╗   ███╗ ██████╗ ██████╗  █████╗ ██╗  ██╗
-- ██╔══██╗██╔══██╗██║████╗ ████║██╔═══██╗██╔══██╗██╔══██╗╚██╗██╔╝
-- ██████╔╝██████╔╝██║██╔████╔██║██║   ██║██║  ██║███████║ ╚███╔╝
-- ██╔═══╝ ██╔══██╗██║██║╚██╔╝██║██║   ██║██║  ██║██╔══██║ ██╔██╗
-- ██║     ██║  ██║██║██║ ╚═╝ ██║╚██████╔╝██████╔╝██║  ██║██╔╝ ██╗
-- ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
-- VAGRANT SURVIVAL v11 | FULL COMPLETE VERSION

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

-- ============ CONFIG & DEFAULT ============
local CFG = {
    ESPEnabled = true, ESPBox = true, ESPName = true, ESPDistance = true, ESPSkeleton = true, 
    ESPLine = false, GunESPEnabled = false, NightVision = false,
    SilentAim = true, Aimbot = false, AimbotSmoothing = 15, FOVRange = 150,
    WallCheck = true, TargetPart = "Head", UseFOV = true, SkipFriends = true,
    NoRecoil = false, NoSpread = false,
    InfiniteJump = true, AutoSprint = true, SprintSpeed = 22, GodMode = false,
    AutoPickup = false, PickupPriority = "Random", 
    AntiKick = true
}

-- ============ UTILS ============
local function getChar(p) return p and p.Character end
local function getHum(p) local c = getChar(p) return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot(p) local c = getChar(p) return c and c:FindFirstChild("HumanoidRootPart") end
local function getPart(p, n) local c = getChar(p) return c and c:FindFirstChild(n) end
local function isAlive(p) local h = getHum(p) return h and h.Health > 0 end

local function isVisible(targetPart, camPos)
    if not CFG.WallCheck then return true end
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LP.Character, Cam}
    local result = Workspace:Raycast(camPos, targetPart.Position - camPos, rayParams)
    if result and result.Instance then
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end
    return true
end

-- ============ NIGHT VISION ============
local nightVisionColor = Instance.new("ColorCorrectionEffect")
local nightVisionBright = Instance.new("BloomEffect")
local function toggleNightVision()
    if CFG.NightVision then
        nightVisionColor.Brightness = 0.3
        nightVisionColor.Contrast = 0.1
        nightVisionColor.TintColor = Color3.fromRGB(200, 255, 200)
        nightVisionColor.Parent = Lighting
        nightVisionBright.Intensity = 0.5
        nightVisionBright.Size = 24
        nightVisionBright.Parent = Lighting
    else
        nightVisionColor.Parent = nil
        nightVisionBright.Parent = nil
    end
end

-- ============ ESP SYSTEM ============
local espObjects = {}
local function createESP(player)
    if espObjects[player] or player == LP then return end
    local objs = {
        Box = Drawing.new("Square"), Name = Drawing.new("Text"), Dist = Drawing.new("Text"), Line = Drawing.new("Line"),
        Skel = { Head = Drawing.new("Line"), Torso = Drawing.new("Line"), LArm = Drawing.new("Line"), RArm = Drawing.new("Line"), LLeg = Drawing.new("Line"), RLeg = Drawing.new("Line") }
    }
    objs.Box.Thickness = 1; objs.Box.Color = Color3.fromRGB(255, 50, 50); objs.Box.Filled = false
    objs.Name.Size = 14; objs.Name.Center = true; objs.Name.Outline = true; objs.Name.Color = Color3.fromRGB(255, 255, 255)
    objs.Dist.Size = 12; objs.Dist.Center = true; objs.Dist.Outline = true; objs.Dist.Color = Color3.fromRGB(255, 215, 0)
    objs.Line.Thickness = 1; objs.Line.Color = Color3.fromRGB(255, 255, 255)
    for k, v in pairs(objs.Skel) do v.Thickness = 1; v.Color = Color3.fromRGB(255, 255, 255) end
    espObjects[player] = objs
end

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(p)
    if espObjects[p] then
        for _, v in pairs(espObjects[p]) do
            if typeof(v) == "table" then for _, l in pairs(v) do pcall(function() l:Remove() end) end
            else pcall(function() v:Remove() end) end
        end
        espObjects[p] = nil
    end
end)

RunService.RenderStepped:Connect(function()
    for player, objs in pairs(espObjects) do
        local isRendered = false
        if CFG.ESPEnabled and isAlive(player) then
            local char = getChar(player); local root = getRoot(player); local head = getPart(player, "Head"); local myRoot = getRoot(LP)
            if root and head and myRoot then
                local headPos, onScreen = Cam:WorldToViewportPoint(head.Position)
                local rootPos, _ = Cam:WorldToViewportPoint(root.Position)
                if onScreen then
                    isRendered = true
                    local height = math.abs(rootPos.Y - headPos.Y) * 1.8; local width = height * 0.6
                    objs.Box.Visible = CFG.ESPBox; objs.Box.Size = Vector2.new(width, height); objs.Box.Position = Vector2.new(headPos.X - width/2, headPos.Y - height*0.2)
                    objs.Name.Visible = CFG.ESPName; objs.Name.Text = player.Name; objs.Name.Position = Vector2.new(headPos.X, headPos.Y - 20)
                    objs.Dist.Visible = CFG.ESPDistance; objs.Dist.Text = string.format("[%d studs]", (myRoot.Position - root.Position).Magnitude); objs.Dist.Position = Vector2.new(headPos.X, rootPos.Y + 10)
                    objs.Line.Visible = CFG.ESPLine; objs.Line.From = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y); objs.Line.To = Vector2.new(headPos.X, headPos.Y)
                    if CFG.ESPSkeleton then
                        local function drawBone(p1, p2, line)
                            if p1 and p2 then
                                local v1, on1 = Cam:WorldToViewportPoint(p1.Position); local v2, on2 = Cam:WorldToViewportPoint(p2.Position)
                                line.Visible = on1 and on2; line.From = Vector2.new(v1.X, v1.Y); line.To = Vector2.new(v2.X, v2.Y)
                            else line.Visible = false end
                        end
                        drawBone(head, char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), objs.Skel.Head)
                        drawBone(char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("LowerTorso") or char:FindFirstChild("Torso"), objs.Skel.Torso)
                        drawBone(char:FindFirstChild("LeftUpperArm"), char:FindFirstChild("LeftLowerArm"), objs.Skel.LArm)
                        drawBone(char:FindFirstChild("RightUpperArm"), char:FindFirstChild("RightLowerArm"), objs.Skel.RArm)
                        drawBone(char:FindFirstChild("LeftUpperLeg"), char:FindFirstChild("LeftLowerLeg"), objs.Skel.LLeg)
                        drawBone(char:FindFirstChild("RightUpperLeg"), char:FindFirstChild("RightLowerLeg"), objs.Skel.RLeg)
                    else
                        for _, l in pairs(objs.Skel) do l.Visible = false end
                    end
                end
            end
        end
        if not isRendered then
            objs.Box.Visible = false; objs.Name.Visible = false; objs.Dist.Visible = false; objs.Line.Visible = false
            for _, l in pairs(objs.Skel) do l.Visible = false end
        end
    end
end)

-- ============ TARGETING & AIMBOT ============
local activeTarget = nil
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5; fovCircle.Color = Color3.fromRGB(255, 255, 255); fovCircle.Filled = false

RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    fovCircle.Radius = CFG.FOVRange; fovCircle.Visible = CFG.UseFOV
    local center = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    local bestT, bDist = nil, CFG.FOVRange
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isAlive(p) then
            local isFriend = LP:IsFriendsWith(p.UserId)
            if not (CFG.SkipFriends and isFriend) then
                local tPart = getPart(p, CFG.TargetPart)
                if tPart then
                    local sPos, onS = Cam:WorldToViewportPoint(tPart.Position)
                    local dist2D = (Vector2.new(sPos.X, sPos.Y) - center).Magnitude
                    if onS and dist2D < bDist then
                        if isVisible(tPart, Cam.CFrame.Position) then
                            bestT = p; bDist = dist2D 
                        end
                    end
                end
            end
        end
    end
    activeTarget = bestT
    if CFG.Aimbot and activeTarget then
        local tPart = getPart(activeTarget, CFG.TargetPart)
        if tPart then
            local targetCF = CFrame.new(Cam.CFrame.Position, tPart.Position)
            local smooth = math.clamp(1 - (CFG.AimbotSmoothing / 100), 0.05, 1)
            Cam.CFrame = Cam.CFrame:Lerp(targetCF, smooth)
        end
    end
end)

-- ============ ANTI-CHEAT & SILENT AIM ============
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod(); local args = { ... }
    if CFG.AntiKick and (method == "FireServer" or method == "InvokeServer") then
        local name = (self.Name or ""):lower()
        if name:find("kick") or name:find("ban") or name:find("detect") or name:find("report") then return nil end
    end
    if CFG.SilentAim and (method == "FireServer" or method == "InvokeServer") and activeTarget and isAlive(activeTarget) then
        local targetPart = getPart(activeTarget, CFG.TargetPart)
        if targetPart and isVisible(targetPart, Cam.CFrame.Position) then
            for i, v in ipairs(args) do
                if typeof(v) == "Vector3" then args[i] = targetPart.Position
                elseif typeof(v) == "CFrame" then args[i] = CFrame.new(Cam.CFrame.Position, targetPart.Position) 
                elseif typeof(v) == "Instance" and v:IsA("BasePart") then args[i] = targetPart end
            end
        end
    end
    return oldNamecall(self, table.unpack(args))
end)

-- ============ MOVEMENT & RECOIL ============
UserInputService.JumpRequest:Connect(function()
    if CFG.InfiniteJump then
        local hum = getHum(LP); local root = getRoot(LP)
        if hum and root and hum.Health > 0 then
            hum:ChangeState(Enum.HumanoidStateType.Jumping); task.wait()
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 60, root.AssemblyLinearVelocity.Z)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    local hum = getHum(LP)
    if hum then
        if CFG.GodMode and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
        if CFG.AutoSprint and hum.WalkSpeed < CFG.SprintSpeed then hum.WalkSpeed = CFG.SprintSpeed elseif not CFG.AutoSprint and hum.WalkSpeed == CFG.SprintSpeed then hum.WalkSpeed = 16 end
    end
end)

local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if CFG.NoRecoil and (key == "Recoil" or key == "RecoilAmount") then return 0 end
    if CFG.NoSpread and (key == "Spread" or key == "SpreadAmount") then return 0 end
    return oldIndex(self, key)
end)

-- ============ TELEPORT TO BAG ============
local function doTeleportBag()
    local myRoot = getRoot(LP)
    if not myRoot then return end
    local bestBag, bestDist = nil, math.huge
    local myName, myId = LP.Name:lower(), tostring(LP.UserId)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local n = (obj.Name or ""):lower()
        if n:find("bag") or n:find("loot") or n:find("corpse") or n:find("drop") then
            local isMine = n:find(myName, 1, true) or n:find(myId, 1, true)
            if not isMine then
                local ok, attr = pcall(function() return obj:GetAttribute("Owner") or obj:GetAttribute("UserId") end)
                if ok and attr and tostring(attr):lower() == myName then isMine = true end
            end
            if isMine then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
                if part then
                    local dist = (myRoot.Position - part.Position).Magnitude
                    if dist < bestDist then bestBag = part; bestDist = dist end
                end
            end
        end
    end
    if bestBag then
        myRoot.CFrame = bestBag.CFrame * CFrame.new(0, 3, 0)
    else
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local n = (obj.Name or ""):lower()
            if n:find("bag") or n:find("loot") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
                if part then
                    local dist = (myRoot.Position - part.Position).Magnitude
                    if dist < bestDist then bestBag = part; bestDist = dist end
                end
            end
        end
        if bestBag then myRoot.CFrame = bestBag.CFrame * CFrame.new(0, 3, 0) end
    end
end

-- ============ UI SYSTEM ============
local parentGui = gethui and gethui() or CoreGui
if parentGui:FindFirstChild("VagrantSurvivalUI") then parentGui:FindFirstChild("VagrantSurvivalUI"):Destroy() end

local SG = Instance.new("ScreenGui")
SG.Name = "VagrantSurvivalUI"; SG.ResetOnSpawn = false; SG.IgnoreGuiInset = true; SG.DisplayOrder = 999; SG.Parent = parentGui
if protect_gui then pcall(protect_gui, SG) end

local FloatBtn = Instance.new("TextButton")
FloatBtn.Size = UDim2.new(0, 40, 0, 40); FloatBtn.Position = UDim2.new(0, 20, 0, 20)
FloatBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); FloatBtn.Text = "⚙️"; FloatBtn.TextSize = 20; FloatBtn.TextColor3 = Color3.fromRGB(100, 50, 200); FloatBtn.Parent = SG
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(1, 0)
local stroke = Instance.new("UIStroke", FloatBtn); stroke.Color = Color3.fromRGB(100, 50, 200); stroke.Thickness = 2

local MF = Instance.new("Frame")
MF.Size = UDim2.new(0, 520, 0, 340); MF.Position = UDim2.new(0.5, -260, 0.5, -170)
MF.BackgroundColor3 = Color3.fromRGB(12, 12, 12); MF.BorderSizePixel = 0; MF.Active = true; MF.Visible = false; MF.Parent = SG
Instance.new("UICorner", MF).CornerRadius = UDim.new(0, 8)

local draggingBtn, dragStartBtn, startPosBtn
FloatBtn.InputBegan:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        draggingBtn = true; dragStartBtn = input.Position; startPosBtn = FloatBtn.Position 
    end 
end)
UserInputService.InputChanged:Connect(function(input) 
    if draggingBtn and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then 
        local delta = input.Position - dragStartBtn; FloatBtn.Position = UDim2.new(startPosBtn.X.Scale, startPosBtn.X.Offset + delta.X, startPosBtn.Y.Scale, startPosBtn.Y.Offset + delta.Y) 
    end 
end)
UserInputService.InputEnded:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        if draggingBtn then
            local delta = input.Position - dragStartBtn
            if math.abs(delta.X) < 5 and math.abs(delta.Y) < 5 then MF.Visible = not MF.Visible end
        end
        draggingBtn = false 
    end 
end)

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 35); TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20); TopBar.Parent = MF
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 0, 20); Title.Position = UDim2.new(0, 10, 0, 2); Title.BackgroundTransparency = 1
Title.Text = "Vagrant Survival v11"; Title.TextColor3 = Color3.fromRGB(200, 200, 200); Title.Font = Enum.Font.GothamBold; Title.TextSize = 13; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Parent = TopBar

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -10, 0, 10); SubTitle.Position = UDim2.new(0, 10, 0, 18); SubTitle.BackgroundTransparency = 1
SubTitle.Text = "Created by: BoboyTagaAquarius"; SubTitle.TextColor3 = Color3.fromRGB(150, 150, 150); SubTitle.Font = Enum.Font.Gotham; SubTitle.TextSize = 10; SubTitle.TextXAlignment = Enum.TextXAlignment.Left; SubTitle.Parent = TopBar

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 120, 1, -35); Sidebar.Position = UDim2.new(0, 0, 0, 35); Sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 15); Sidebar.Parent = MF

local function makeTab(name, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 30); btn.Position = UDim2.new(0, 5, 0, 5 + (order * 35)); btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25); btn.Text = "  " .. name; btn.TextColor3 = Color3.fromRGB(150, 150, 150); btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = Sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    return btn
end

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -125, 1, -40); Content.Position = UDim2.new(0, 120, 0, 35); Content.BackgroundTransparency = 1; Content.Parent = MF

local Pages = {}
local function makePage(name)
    local frame = Instance.new("ScrollingFrame")
    frame.Size = UDim2.new(1, 0, 1, 0); frame.BackgroundTransparency = 1; frame.ScrollBarThickness = 2; frame.AutomaticCanvasSize = Enum.AutomaticSize.Y; frame.Visible = false; frame.Parent = Content
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = frame
    
    Pages[name] = frame
    return frame
end

local VisualPage = makePage("Visual")
local CombatPage = makePage("Combat")
local SettingsPage = makePage("Settings")

local function switchTab(name)
    for n, p in pairs(Pages) do p.Visible = (n == name) end
end

makeTab("Visual", 0).MouseButton1Click:Connect(function() switchTab("Visual") end)
makeTab("Combat", 1).MouseButton1Click:Connect(function() switchTab("Combat") end)
makeTab("Settings", 2).MouseButton1Click:Connect(function() switchTab("Settings") end)

local function makeToggle(name, key, parent, order, callback)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, -10, 0, 26); btn.BackgroundTransparency = 1; btn.Text = ""; btn.LayoutOrder = order; btn.Parent = parent
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -40, 1, 0); lbl.BackgroundTransparency = 1; lbl.Text = name; lbl.TextColor3 = Color3.fromRGB(200, 200, 200); lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = btn
    local ind = Instance.new("Frame"); ind.Size = UDim2.new(0, 24, 0, 12); ind.Position = UDim2.new(1, -30, 0.5, -6); ind.BackgroundColor3 = CFG[key] and Color3.fromRGB(100, 50, 200) or Color3.fromRGB(50, 50, 50); ind.Parent = btn
    Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)
    local dot = Instance.new("Frame"); dot.Size = UDim2.new(0, 8, 0, 8); dot.Position = CFG[key] and UDim2.new(1, -10, 0.5, -4) or UDim2.new(0, 2, 0.5, -4); dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255); dot.Parent = ind
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    btn.MouseButton1Click:Connect(function()
        CFG[key] = not CFG[key]
        ind.BackgroundColor3 = CFG[key] and Color3.fromRGB(100, 50, 200) or Color3.fromRGB(50, 50, 50)
        dot.Position = CFG[key] and UDim2.new(1, -10, 0.5, -4) or UDim2.new(0, 2, 0.5, -4)
        if callback then callback() end
    end)
end

local function makeSlider(name, key, min, max, parent, order)
    local frame = Instance.new("Frame"); frame.Size = UDim2.new(1, -10, 0, 35); frame.BackgroundTransparency = 1; frame.LayoutOrder = order; frame.Parent = parent
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, 0, 0, 15); lbl.BackgroundTransparency = 1; lbl.Text = name .. ": " .. CFG[key]; lbl.TextColor3 = Color3.fromRGB(200, 200, 200); lbl.Font = Enum.Font.Gotham; lbl.TextSize = 10; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = frame
    local bar = Instance.new("TextButton"); bar.Size = UDim2.new(1, 0, 0, 6); bar.Position = UDim2.new(0, 0, 0, 20); bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40); bar.Text = ""; bar.Parent = frame
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame"); fill.Size = UDim2.new((CFG[key] - min) / (max - min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(100, 50, 200); fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local drag = false
    bar.MouseButton1Down:Connect(function() drag = true end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end end)
    local function update(x)
        if not drag then return end
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + rel * (max - min))
        CFG[key] = val; lbl.Text = name .. ": " .. val; fill.Size = UDim2.new(rel, 0, 1, 0)
    end
    bar.MouseMoved:Connect(update)
    UserInputService.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then update(i.Position.X) end end)
end

local function makeDropdown(name, key, options, parent, order)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, -10, 0, 26); btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); btn.Text = ""; btn.LayoutOrder = order; btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -10, 1, 0); lbl.Position = UDim2.new(0, 5, 0, 0); lbl.BackgroundTransparency = 1; lbl.Text = name .. ": " .. CFG[key]; lbl.TextColor3 = Color3.fromRGB(200, 200, 200); lbl.Font = Enum.Font.Gotham; lbl.TextSize = 10; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = btn
    btn.MouseButton1Click:Connect(function()
        local curIdx = 1
        for i, v in ipairs(options) do if v == CFG[key] then curIdx = i; break end end
        CFG[key] = options[(curIdx % #options) + 1]
        lbl.Text = name .. ": " .. CFG[key]
    end)
end

makeToggle("Enable ESP", "ESPEnabled", VisualPage, 1)
makeToggle("Box ESP", "ESPBox", VisualPage, 2)
makeToggle("Name ESP", "ESPName", VisualPage, 3)
makeToggle("Distance ESP", "ESPDistance", VisualPage, 4)
makeToggle("Skeleton", "ESPSkeleton", VisualPage, 5)
makeToggle("Tracer Line", "ESPLine", VisualPage, 6)
makeToggle("Gun ESP (Loot)", "GunESPEnabled", VisualPage, 7)
makeToggle("Night Vision", "NightVision", VisualPage, 8, toggleNightVision)

makeToggle("Silent Aim", "SilentAim", CombatPage, 1)
makeToggle("Skip Friends", "SkipFriends", CombatPage, 2)
makeToggle("Aimbot (Smooth)", "Aimbot", CombatPage, 3)
makeSlider("Aimbot Smooth", "AimbotSmoothing", 0, 100, CombatPage, 4)
makeToggle("Wall Check", "WallCheck", CombatPage, 5)
makeDropdown("Target Part", "TargetPart", {"Head", "HumanoidRootPart", "Torso"}, CombatPage, 6)
makeDropdown("Priority", "Priority", {"Crosshair", "Distance"}, CombatPage, 7)
makeToggle("Use FOV", "UseFOV", CombatPage, 8)
makeSlider("FOV Radius", "FOVRange", 0, 800, CombatPage, 9)
makeToggle("No Recoil", "NoRecoil", CombatPage, 10)
makeToggle("No Spread", "NoSpread", CombatPage, 11)

makeToggle("Infinite Jump", "InfiniteJump", SettingsPage, 1)
makeToggle("Auto Sprint", "AutoSprint", SettingsPage, 2)
makeSlider("Sprint Speed", "SprintSpeed", 16, 100, SettingsPage, 3)
makeToggle("GodMode (Semi)", "GodMode", SettingsPage, 4)
makeToggle("Anti Kick/Ban", "AntiKick", SettingsPage, 5)

local teleBtn = Instance.new("TextButton"); teleBtn.Size = UDim2.new(1, -10, 0, 26); teleBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 200); teleBtn.Text = "Teleport to Bag/Loot"; teleBtn.TextColor3 = Color3.fromRGB(255, 255, 255); teleBtn.Font = Enum.Font.GothamBold; teleBtn.LayoutOrder = 6; teleBtn.Parent = SettingsPage
Instance.new("UICorner", teleBtn).CornerRadius = UDim.new(0, 4)
teleBtn.MouseButton1Click:Connect(doTeleportBag)

local function makeButton(name, color, parent, order, callback)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, -10, 0, 26); btn.BackgroundColor3 = color; btn.Text = name; btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.Font = Enum.Font.GothamBold; btn.LayoutOrder = order; btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseButton1Click:Connect(callback)
end

makeButton("Export Config", Color3.fromRGB(50, 150, 50), SettingsPage, 7, function()
    local encoded = HttpService:JSONEncode(CFG)
    if setclipboard then setclipboard(encoded) end
end)

makeButton("Import Config", Color3.fromRGB(150, 50, 50), SettingsPage, 8, function()
    local input = getclipboard and getclipboard() or ""
    if input ~= "" then
        local success, decoded = pcall(function() return HttpService:JSONDecode(input) end)
        if success and type(decoded) == "table" then
            for k, v in pairs(decoded) do if CFG[k] ~= nil then CFG[k] = v end end
        end
    end
end)

switchTab("Combat")

local dragging, dragStart, startPos
TopBar.InputBegan:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        dragging = true; dragStart = input.Position; startPos = MF.Position 
    end 
end)
UserInputService.InputChanged:Connect(function(input) 
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
                MF.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) 
    end 
end)
UserInputService.InputEnded:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        dragging = false 
    end 
end)
