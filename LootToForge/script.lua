-- PrimoDax Hub | Loot To Forge
-- Created By: BoboyTagaAquarius

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")
local CoreGui          = game:GetService("CoreGui")
local VirtualUser      = game:GetService("VirtualUser")

local LP  = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

local CFG = {
    AutoClick       = false,
    ClickDelay      = 0.1,
    AutoFarm        = false,
    FarmRadius      = 30,
    AutoCollect     = false,
    AutoLootForge   = false,
    ForgeOnCollect  = false,
    TargetRarity    = "All",
    WalkSpeed       = 16,
    FlySpeed        = 60,
    IsFlying        = false,
    InfiniteJump    = false,
    NoClip          = false,
    InstantProx     = false,
    PlayerESP       = false,
    ItemESP         = false,
}

-- ============ UTILS ============
local function getChar()  return LP.Character end
local function getRoot()  local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()   local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end

local function isTargetLoot(obj)
    local name = obj.Name:lower()
    local isLoot = name:find("loot") or name:find("coin") or name:find("ore") or name:find("gem")
    if not isLoot then return false end
    if CFG.TargetRarity == "All" then return true end
    local r = CFG.TargetRarity:lower()
    if name:find(r) then return true end
    local attr = obj:GetAttribute("Rarity") or obj:GetAttribute("Type")
    if attr and tostring(attr):lower() == r then return true end
    return false
end

-- ============ ESP ============
local espHighlights = {}
local function createESP(obj, color)
    if espHighlights[obj] then return end
    local h = Instance.new("SelectionBox")
    h.Adornee             = obj
    h.Color3              = color or Color3.fromRGB(255,0,0)
    h.LineThickness       = 0.05
    h.SurfaceTransparency = 0.7
    h.SurfaceColor3       = color or Color3.fromRGB(255,0,0)
    h.Parent              = game:GetService("CoreGui")
    espHighlights[obj]    = h
    obj.AncestryChanged:Connect(function()
        if not obj:IsDescendantOf(game) then
            h:Destroy()
            espHighlights[obj] = nil
        end
    end)
end
local function clearESP()
    for obj, h in pairs(espHighlights) do h:Destroy(); espHighlights[obj] = nil end
end

-- ============ CORE FEATURES ============

-- Auto Clicker
task.spawn(function()
    while task.wait(CFG.ClickDelay) do
        if CFG.AutoClick then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2))
            end)
        end
    end
end)

-- Forge queue
local forgeQueue = {}

-- Heartbeat
RunService.Heartbeat:Connect(function()
    local root = getRoot()
    local hum  = getHum()
    local char = getChar()
    if not root or not hum or not char then return end

    hum.WalkSpeed = CFG.WalkSpeed

    if CFG.NoClip then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end

    if CFG.InstantProx then
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                v.HoldDuration          = 0
                v.MaxActivationDistance = 9999
            end
        end
    end

    if CFG.AutoCollect or CFG.AutoFarm then
        for _, obj in ipairs(Workspace:GetChildren()) do
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
            if part and (root.Position - part.Position).Magnitude < CFG.FarmRadius then
                if isTargetLoot(obj) then
                    pcall(function()
                        for _, v in ipairs(obj:GetDescendants()) do
                            if v:IsA("ProximityPrompt") then fireproximityprompt(v) end
                            if v:IsA("ClickDetector")   then fireclickdetector(v)   end
                        end
                    end)
                    if CFG.ForgeOnCollect then table.insert(forgeQueue, obj.Name) end
                end
            end
        end
    end

    if CFG.AutoFarm then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if isTargetLoot(obj) and obj:IsA("BasePart") then
                root.CFrame = CFrame.new(obj.Position + Vector3.new(0,3,0))
                break
            end
        end
    end

    if CFG.PlayerESP then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local r = p.Character:FindFirstChild("HumanoidRootPart")
                if r then createESP(r, Color3.fromRGB(255,50,50)) end
            end
        end
    end
    if CFG.ItemESP then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if isTargetLoot(obj) and obj:IsA("BasePart") then
                createESP(obj, Color3.fromRGB(50,255,50))
            end
        end
    end
    if not CFG.PlayerESP and not CFG.ItemESP then clearESP() end
end)

-- Forge Loop
task.spawn(function()
    while task.wait(1) do
        if CFG.AutoLootForge and #forgeQueue > 0 then
            local item = table.remove(forgeQueue, 1)
            local re = game:GetService("ReplicatedStorage"):FindFirstChild("ForgeItem") or game:GetService("ReplicatedStorage"):FindFirstChild("Forge")
            if re then pcall(function() re:FireServer(item) end) end
        end
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if CFG.InfiniteJump then
        local hum = getHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Fly
local BodyVel, BodyGyr
local function startFly()
    local root = getRoot(); if not root then return end
    BodyVel = Instance.new("BodyVelocity", root)
    BodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
    BodyGyr = Instance.new("BodyGyro", root)
    BodyGyr.MaxTorque = Vector3.new(1e5,1e5,1e5)
end
local function stopFly()
    if BodyVel then BodyVel:Destroy(); BodyVel = nil end
    if BodyGyr then BodyGyr:Destroy(); BodyGyr = nil end
    local hum = getHum(); if hum then hum.PlatformStand = false end
end

RunService.Heartbeat:Connect(function()
    if CFG.IsFlying then
        if not BodyVel then startFly() end
        local hum = getHum(); if hum then hum.PlatformStand = true end
        local dir = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
        if BodyVel then BodyVel.Velocity = dir.Magnitude > 0 and dir.Unit * CFG.FlySpeed or Vector3.new(0,0,0) end
        if BodyGyr then BodyGyr.CFrame = Cam.CFrame end
    else
        if BodyVel then stopFly() end
    end
end)

-- ============ GUI ============
local parentGui = gethui and gethui() or game:GetService("CoreGui")
if parentGui:FindFirstChild("PrimoDaxLTF") then parentGui:FindFirstChild("PrimoDaxLTF"):Destroy() end

local ACCENT  = Color3.fromRGB(255,105,180)
local BG_DARK = Color3.fromRGB(18,18,18)
local BG_CARD = Color3.fromRGB(28,28,28)
local BG_MID  = Color3.fromRGB(30,30,30)
local TXT     = Color3.fromRGB(220,220,220)
local TXT_DIM = Color3.fromRGB(130,130,130)

local Gui = Instance.new("ScreenGui")
Gui.Name           = "PrimoDaxLTF"
Gui.ResetOnSpawn   = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent         = parentGui
if protect_gui then pcall(protect_gui, Gui) end

-- Floating Toggle Button (Yung mismong circle)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size             = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position         = UDim2.new(0, 20, 0, 20)
ToggleBtn.BackgroundColor3 = BG_DARK
ToggleBtn.Text             = "P"
ToggleBtn.TextColor3       = ACCENT
ToggleBtn.Font             = Enum.Font.GothamBold
ToggleBtn.TextSize         = 24
ToggleBtn.BorderSizePixel  = 0
ToggleBtn.Parent           = Gui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)
local TStroke = Instance.new("UIStroke", ToggleBtn)
TStroke.Color = ACCENT
TStroke.Thickness = 2

local Main = Instance.new("Frame")
Main.Name             = "Main"
Main.Size             = UDim2.new(0, 550, 0, 320)
Main.Position         = UDim2.new(0.5,-275,0.5,-160)
Main.BackgroundColor3 = BG_DARK
Main.BorderSizePixel  = 0
Main.Active           = true
Main.Visible          = false -- Naka-tago sa umpisa
Main.Parent           = Gui
Instance.new("UICorner",Main).CornerRadius = UDim.new(0,8)

-- Toggle Logic
local draggingToggle, dragStartToggle, startPosToggle
ToggleBtn.InputBegan:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        draggingToggle = true; dragStartToggle = input.Position; startPosToggle = ToggleBtn.Position 
    end 
end)
UserInputService.InputChanged:Connect(function(input) 
    if draggingToggle and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then 
        local delta = input.Position - dragStartToggle
        ToggleBtn.Position = UDim2.new(startPosToggle.X.Scale, startPosToggle.X.Offset + delta.X, startPosToggle.Y.Scale, startPosToggle.Y.Offset + delta.Y) 
    end 
end)
UserInputService.InputEnded:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        if draggingToggle then
            local delta = input.Position - dragStartToggle
            -- Kung hindi ginilid (click lang), i-toggle ang menu
            if math.abs(delta.X) < 5 and math.abs(delta.Y) < 5 then 
                Main.Visible = not Main.Visible 
            end
        end
        draggingToggle = false 
    end 
end)

-- Top Bar
local TBar = Instance.new("Frame")
TBar.Size             = UDim2.new(1,0,0,35)
TBar.BackgroundColor3 = BG_MID
TBar.BorderSizePixel  = 0
TBar.Parent           = Main
Instance.new("UICorner",TBar).CornerRadius = UDim.new(0,8)

local TLbl = Instance.new("TextLabel")
TLbl.Text           = "PrimoDax Hub"
TLbl.Font           = Enum.Font.GothamBold
TLbl.TextSize       = 14
TLbl.TextColor3     = Color3.fromRGB(255,255,255)
TLbl.Size           = UDim2.new(1,-80,0,20)
TLbl.Position       = UDim2.new(0,12,0,2)
TLbl.BackgroundTransparency = 1
TLbl.TextXAlignment = Enum.TextXAlignment.Left
TLbl.Parent         = TBar

local CLbl = Instance.new("TextLabel")
CLbl.Text           = "Created By: BoboyTagaAquarius"
CLbl.Font           = Enum.Font.Gotham
CLbl.TextSize       = 9
CLbl.TextColor3     = TXT_DIM
CLbl.Size           = UDim2.new(1,-80,0,12)
CLbl.Position       = UDim2.new(0,12,0,20)
CLbl.BackgroundTransparency = 1
CLbl.TextXAlignment = Enum.TextXAlignment.Left
CLbl.Parent         = TBar

local XBtn = Instance.new("TextButton")
XBtn.Text             = "✕"
XBtn.Font             = Enum.Font.GothamBold
XBtn.TextSize         = 13
XBtn.TextColor3       = Color3.fromRGB(255,80,80)
XBtn.Size             = UDim2.new(0,26,0,26)
XBtn.Position         = UDim2.new(1,-30,0,4)
XBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
XBtn.BorderSizePixel  = 0
XBtn.Parent           = TBar
Instance.new("UICorner",XBtn).CornerRadius = UDim.new(0,6)
XBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size             = UDim2.new(0,100,1,-35)
Sidebar.Position         = UDim2.new(0,0,0,35)
Sidebar.BackgroundColor3 = BG_MID
Sidebar.BorderSizePixel  = 0
Sidebar.Parent           = Main
Instance.new("UICorner",Sidebar).CornerRadius = UDim.new(0,8)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size                = UDim2.new(1,-105,1,-40)
Scroll.Position            = UDim2.new(0,100,0,35)
Scroll.BackgroundColor3    = BG_DARK
Scroll.BorderSizePixel     = 0
Scroll.ScrollBarThickness  = 2
Scroll.ScrollBarImageColor3 = ACCENT
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.CanvasSize          = UDim2.new(0,0,0,0)
Scroll.Parent              = Main
local SL = Instance.new("UIListLayout",Scroll)
SL.Padding = UDim.new(0,4)
local SP = Instance.new("UIPadding",Scroll)
SP.PaddingLeft   = UDim.new(0,8)
SP.PaddingRight  = UDim.new(0,8)
SP.PaddingTop    = UDim.new(0,6)
SP.PaddingBottom = UDim.new(0,6)

-- UI HELPERS
local tabFrames, tabBtns = {}, {}

local function mkTab(name, order)
    local btn = Instance.new("TextButton")
    btn.Text             = name
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 11
    btn.TextColor3       = TXT_DIM
    btn.Size             = UDim2.new(1,-10,0,28)
    btn.Position         = UDim2.new(0,5,0,5 + (order * 32))
    btn.BackgroundColor3 = BG_MID
    btn.BorderSizePixel  = 0
    btn.Parent           = Sidebar
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,4)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,1,0); frame.BackgroundTransparency = 1; frame.Visible = false; frame.Parent = Scroll
    local fl = Instance.new("UIListLayout",frame); fl.Padding = UDim.new(0,4); fl.SortOrder = Enum.SortOrder.LayoutOrder

    tabFrames[name] = frame; tabBtns[name] = btn

    btn.MouseButton1Click:Connect(function()
        for k,f in pairs(tabFrames) do f.Visible = false; tabBtns[k].TextColor3 = TXT_DIM; tabBtns[k].BackgroundColor3 = BG_MID end
        frame.Visible = true; btn.TextColor3 = Color3.fromRGB(255,255,255); btn.BackgroundColor3 = ACCENT
    end)
    return frame
end

local function mkCard(parent, order)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,0); f.AutomaticSize = Enum.AutomaticSize.Y
    f.BackgroundColor3 = BG_CARD; f.BorderSizePixel = 0
    f.LayoutOrder = order or 0; f.Parent = parent
    Instance.new("UICorner",f).CornerRadius = UDim.new(0,6)
    local pad = Instance.new("UIPadding",f)
    pad.PaddingLeft = UDim.new(0,8); pad.PaddingRight  = UDim.new(0,8); pad.PaddingTop  = UDim.new(0,6); pad.PaddingBottom = UDim.new(0,6)
    local fl = Instance.new("UIListLayout",f); fl.SortOrder = Enum.SortOrder.LayoutOrder; fl.Padding = UDim.new(0,4)
    return f
end

local function mkLbl(parent, text, order)
    local l = Instance.new("TextLabel")
    l.Text = text; l.Font = Enum.Font.GothamBold; l.TextSize = 12; l.TextColor3 = TXT; l.Size = UDim2.new(1,0,0,18)
    l.BackgroundTransparency = 1; l.TextXAlignment = Enum.TextXAlignment.Left; l.LayoutOrder = order or 0; l.Parent = parent
    return l
end

local function mkToggle(parent, label, cfgKey, cb, order)
    local row = Instance.new("Frame"); row.Size = UDim2.new(1,0,0,26); row.BackgroundTransparency = 1; row.LayoutOrder = order or 0; row.Parent = parent
    local lbl = Instance.new("TextLabel"); lbl.Text = label; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11; lbl.TextColor3 = TXT; lbl.Size = UDim2.new(1,-44,1,0); lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
    
    local tog = Instance.new("TextButton"); tog.Size = UDim2.new(0,36,0,18); tog.Position = UDim2.new(1,-38,0.5,-9); tog.Text = ""; tog.BackgroundColor3 = Color3.fromRGB(60,60,60); tog.BorderSizePixel = 0; tog.Parent = row
    Instance.new("UICorner",tog).CornerRadius = UDim.new(1,0)
    
    local knob = Instance.new("Frame"); knob.Size = UDim2.new(0,14,0,14); knob.Position = UDim2.new(0,2,0.5,-7); knob.BackgroundColor3 = Color3.fromRGB(200,200,200); knob.BorderSizePixel = 0; knob.Parent = tog
    Instance.new("UICorner",knob).CornerRadius = UDim.new(1,0)

    local function refresh()
        local on = CFG[cfgKey]
        tog.BackgroundColor3 = on and ACCENT or Color3.fromRGB(60,60,60)
        TweenService:Create(knob, TweenInfo.new(0.12), { Position = on and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7) }):Play()
    end
    refresh()

    tog.MouseButton1Click:Connect(function()
        CFG[cfgKey] = not CFG[cfgKey]; refresh(); if cb then cb(CFG[cfgKey]) end
    end)
    return tog
end

local function mkSlider(parent, label, min, max, cfgKey, order)
    local col = Instance.new("Frame"); col.Size = UDim2.new(1,0,0,0); col.AutomaticSize = Enum.AutomaticSize.Y; col.BackgroundTransparency = 1; col.LayoutOrder = order or 0; col.Parent = parent
    local cfl = Instance.new("UIListLayout",col); cfl.Padding = UDim.new(0,2)

    local top = Instance.new("Frame"); top.Size = UDim2.new(1,0,0,16); top.BackgroundTransparency = 1; top.Parent = col
    local lbl = Instance.new("TextLabel"); lbl.Text = label; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11; lbl.TextColor3 = TXT; lbl.Size = UDim2.new(0.7,0,1,0); lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = top
    local vLbl = Instance.new("TextLabel"); vLbl.Font = Enum.Font.GothamBold; vLbl.TextSize = 11; vLbl.TextColor3 = ACCENT; vLbl.Size = UDim2.new(0.3,0,1,0); vLbl.Position = UDim2.new(0.7,0,0,0); vLbl.BackgroundTransparency = 1; vLbl.TextXAlignment = Enum.TextXAlignment.Right; vLbl.Text = tostring(CFG[cfgKey]); vLbl.Parent = top

    local track = Instance.new("Frame"); track.Size = UDim2.new(1,0,0,4); track.BackgroundColor3 = Color3.fromRGB(50,50,50); track.BorderSizePixel = 0; track.Parent = col
    Instance.new("UICorner",track).CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame"); fill.Size = UDim2.new((CFG[cfgKey]-min)/(max-min),0,1,0); fill.BackgroundColor3 = ACCENT; fill.BorderSizePixel = 0; fill.Parent = track
    Instance.new("UICorner",fill).CornerRadius = UDim.new(1,0)

    local dragging = false
    track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + rel*(max-min))
            CFG[cfgKey] = val; fill.Size = UDim2.new(rel,0,1,0); vLbl.Text = tostring(val)
        end
    end)
    return col
end

local function mkDropdown(parent, label, options, cfgKey, order)
    local col = Instance.new("Frame"); col.Size = UDim2.new(1,0,0,0); col.AutomaticSize = Enum.AutomaticSize.Y; col.BackgroundTransparency = 1; col.LayoutOrder = order or 0; col.Parent = parent
    local cfl = Instance.new("UIListLayout",col); cfl.Padding = UDim.new(0,2)

    local lbl = mkLbl(col, label); lbl.TextSize = 11; lbl.Font = Enum.Font.Gotham

    local btn = Instance.new("TextButton"); btn.Text = CFG[cfgKey] or options[1]; btn.Font = Enum.Font.Gotham; btn.TextSize = 11; btn.TextColor3 = TXT; btn.Size = UDim2.new(1,0,0,24); btn.BackgroundColor3 = Color3.fromRGB(38,38,38); btn.BorderSizePixel = 0; btn.Parent = col
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,4)

    local list = Instance.new("Frame"); list.Size = UDim2.new(1,0,0,0); list.AutomaticSize = Enum.AutomaticSize.Y; list.BackgroundColor3 = Color3.fromRGB(38,38,38); list.BorderSizePixel = 0; list.Visible = false; list.ZIndex = 10; list.Parent = col
    Instance.new("UICorner",list).CornerRadius = UDim.new(0,4)
    local lfl = Instance.new("UIListLayout",list); lfl.SortOrder = Enum.SortOrder.LayoutOrder

    for i, opt in ipairs(options) do
        local ob = Instance.new("TextButton"); ob.Text = opt; ob.Font = Enum.Font.Gotham; ob.TextSize = 11; ob.TextColor3 = TXT; ob.Size = UDim2.new(1,0,0,22); ob.BackgroundTransparency = 1; ob.BorderSizePixel = 0; ob.LayoutOrder = i; ob.ZIndex = 11; ob.Parent = list
        ob.MouseButton1Click:Connect(function() CFG[cfgKey] = opt; btn.Text = opt; list.Visible = false end)
    end
    btn.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
    return col
end

local function mkBtn(parent, text, cb, order)
    local btn = Instance.new("TextButton"); btn.Text = text; btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.TextColor3 = Color3.fromRGB(255,255,255); btn.Size = UDim2.new(1,0,0,26); btn.BackgroundColor3 = ACCENT; btn.BorderSizePixel = 0; btn.LayoutOrder = order or 0; btn.Parent = parent
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,5)
    btn.MouseButton1Click:Connect(function() if cb then cb() end end)
    return btn
end

-- TABS
local tMain   = mkTab("Main",   0)
local tFarm   = mkTab("Farm",   1)
local tForge  = mkTab("Forge",  2)
local tESP    = mkTab("ESP",    3)
local tPlayer = mkTab("Player", 4)

tabBtns["Main"].TextColor3      = Color3.fromRGB(255,255,255)
tabBtns["Main"].BackgroundColor3= ACCENT
tabFrames["Main"].Visible       = true

local c1 = mkCard(tMain, 1)
mkLbl(c1, "⚡  Auto Clicker", 1)
mkToggle(c1, "Auto Click", "AutoClick", nil, 2)
mkSlider(c1, "Click Delay", 1, 100, "ClickDelay", 3)

local c2 = mkCard(tMain, 2)
mkLbl(c2, "🎯  Rarity Filter", 1)
mkDropdown(c2, "Target Rarity", {"All","Common","Uncommon","Rare","Epic","Legendary"}, "TargetRarity", 2)

local c3 = mkCard(tFarm, 1)
mkLbl(c3, "🌾  Auto Farm", 1)
mkToggle(c3, "Auto Farm",    "AutoFarm",    nil, 2)
mkToggle(c3, "Auto Collect", "AutoCollect", nil, 3)
mkSlider(c3, "Farm Radius", 5, 200, "FarmRadius", 4)

local c4 = mkCard(tForge, 1)
mkLbl(c4, "🔨  Loot To Forge", 1)
mkToggle(c4, "Auto Loot Forge",  "AutoLootForge",  nil, 2)
mkToggle(c4, "Forge On Collect", "ForgeOnCollect", nil, 3)
mkBtn(c4, "Forge Now", function()
    local re = game:GetService("ReplicatedStorage"):FindFirstChild("ForgeItem") or game:GetService("ReplicatedStorage"):FindFirstChild("Forge")
    if re then pcall(function() re:FireServer() end) end
end, 4)

local c5 = mkCard(tESP, 1)
mkLbl(c5, "👁️  ESP", 1)
mkToggle(c5, "Player ESP", "PlayerESP", nil, 2)
mkToggle(c5, "Item ESP",   "ItemESP",   nil, 3)

local c6 = mkCard(tPlayer, 1)
mkLbl(c6, "🏃  Movement", 1)
mkSlider(c6, "Walk Speed", 16, 250, "WalkSpeed", 2)
mkSlider(c6, "Fly Speed",  10, 400, "FlySpeed",  3)
mkToggle(c6, "Fly",             "IsFlying",    nil, 4)
mkToggle(c6, "Infinite Jump",   "InfiniteJump",nil, 5)
mkToggle(c6, "No Clip",         "NoClip",      nil, 6)
mkToggle(c6, "Instant Proximity","InstantProx", nil, 7)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightBracket then
        Main.Visible = not Main.Visible
    end
end)

local dragging, dragStart, startPos
TBar.InputBegan:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        dragging = true; dragStart = input.Position; startPos = Main.Position 
    end 
end)
UserInputService.InputChanged:Connect(function(input) 
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then 
        local delta = input.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) 
    end 
end)
UserInputService.InputEnded:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end 
end)

print("[PrimoDax Hub | Loot To Forge] Loaded!")
