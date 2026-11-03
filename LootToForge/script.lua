--[[
PRIMODAX HUB | LOOT TO FORGE
FULLY FUNCTIONAL BUILD (Now with RemoteSpy Arguments!)
Created By: BoboyTagaAquarius
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")

local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera

-- CONFIG
local CFG = {
    AutoTrain = false,
    AutoClaimOre = false,
    AutoSkill = false,
    AutoKill = false,
    AutoStageClear = false,
    WalkSpeedEnabled = false,
    WalkSpeed = 50,
    Fly = false,
    FlySpeed = 60,
    InfiniteJump = false,
    NoClip = false,
    AntiAFK = true,
}

-- REMOTE HELPER
local function getRE(folderName, remoteName)
    local root = ReplicatedStorage:FindFirstChild("Remote")
    if not root then return nil end
    local f = root:FindFirstChild(folderName)
    if not f then return nil end
    local remote = f:FindFirstChild(remoteName)
    if remote and (remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent")) then 
        return remote 
    end
    return nil
end

local function getRF(folderName, remoteName)
    local root = ReplicatedStorage:FindFirstChild("Remote")
    if not root then return nil end
    local f = root:FindFirstChild(folderName)
    if not f then return nil end
    local remote = f:FindFirstChild(remoteName)
    if remote and remote:IsA("RemoteFunction") then return remote end
    return nil
end

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 3 })
    end)
end

-- ANTI AFK
task.spawn(function()
    while true do
        task.wait(60)
        if CFG.AntiAFK then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0,0))
            end)
        end
    end
end)

-- MAIN LOOP (FARMING LOGIC)
task.spawn(function()
    while true do
        task.wait(0.2) -- Remote spam protection

        if CFG.AutoTrain then
            local re = getRE("Train_Server", "IntoAutoTrainRE")
            if re then pcall(function() re:FireServer(true) end) end
        end

        if CFG.AutoClaimOre then
            local re1 = getRE("Ore_Server", "ClaimedAIOre") or getRE("Ore_Server", "ClaimedAIOreRE")
            local rf1 = getRF("Ore_Server", "GetOreRF")
            if re1 then pcall(function() re1:FireServer() end) end
            if rf1 then pcall(function() rf1:InvokeServer() end) end
        end

        if CFG.AutoSkill then
            local re = getRE("Skill_Server", "UseAnySkillRE")
            if re then pcall(function() re:FireServer("1") end) end -- Assuming "1" is the skill slot
        end

        if CFG.AutoKill then
            local re = getRE("Combat_Server", "KillEnemyRE")
            if re then 
                -- Try passing common arguments seen in screenshot ("1-K" or "Stage-1")
                pcall(function() re:FireServer("1-K") end)
                task.wait(0.05)
                pcall(function() re:FireServer("1") end)
            end
        end
        
        if CFG.AutoStageClear then
            local rf = getRF("Stage_Server", "StageFinishedRF") or getRF("Combat_Server", "StageFinishedRF")
            local re = getRE("Stage_Server", "StageFinishedRE") or getRE("Combat_Server", "StageFinishedRE")
            
            -- Screenshot shows "Stage-1", "Stage-2", "Stage-3" in logs
            local args = {"Stage-1", "Stage-2", "Stage-3", "StageManager"}
            
            for _, arg in ipairs(args) do
                if rf then pcall(function() rf:InvokeServer(arg) end) end
                if re then pcall(function() re:FireServer(arg) end) end
                task.wait(0.1)
            end
        end
    end
end)

-- MOVEMENT LOGIC
local BodyVel, BodyGyr
local function startFly()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    BodyVel = Instance.new("BodyVelocity", root)
    BodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
    BodyVel.Velocity = Vector3.new(0,0,0)
    BodyGyr = Instance.new("BodyGyro", root)
    BodyGyr.MaxTorque = Vector3.new(1e5,1e5,1e5)
    BodyGyr.CFrame    = root.CFrame
end

local function stopFly()
    if BodyVel then BodyVel:Destroy(); BodyVel = nil end
    if BodyGyr then BodyGyr:Destroy(); BodyGyr = nil end
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

UserInputService.JumpRequest:Connect(function()
    if CFG.InfiniteJump then
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    hum.WalkSpeed = CFG.WalkSpeedEnabled and CFG.WalkSpeed or 16

    if CFG.NoClip then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end

    if CFG.Fly then
        if not BodyVel then startFly() end
        hum.PlatformStand = true
        local dir = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
        if BodyVel then BodyVel.Velocity = dir.Magnitude > 0 and dir.Unit * CFG.FlySpeed or Vector3.new(0,0,0) end
        if BodyGyr then BodyGyr.CFrame = Cam.CFrame end
    else
        if BodyVel then stopFly() end
    end
end)

-- ==================== UI ====================
local parentGui = (gethui and gethui()) or CoreGui
if parentGui:FindFirstChild("PrimoDaxFunctional") then parentGui:FindFirstChild("PrimoDaxFunctional"):Destroy() end

local ACCENT  = Color3.fromRGB(200, 170, 255)
local BG_DARK = Color3.fromRGB(22, 22, 27)
local BG_CARD = Color3.fromRGB(32, 32, 38)
local BG_MID  = Color3.fromRGB(28, 28, 34)
local TXT     = Color3.fromRGB(240, 240, 245)
local TXT_DIM = Color3.fromRGB(150, 150, 160)

local Gui = Instance.new("ScreenGui")
Gui.Name = "PrimoDaxFunctional"
Gui.ResetOnSpawn = false
Gui.Parent = parentGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0.85, 0, 0.6, 0)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = BG_DARK
Main.BorderSizePixel = 0
Main.Visible = false
Main.Parent = Gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,8)
local sizeConstraint = Instance.new("UISizeConstraint", Main)
sizeConstraint.MinSize = Vector2.new(320, 280)
sizeConstraint.MaxSize = Vector2.new(500, 380)

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1,0,0,38)
TopBar.BackgroundColor3 = BG_MID
TopBar.BorderSizePixel = 0
TopBar.Parent = Main
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0,8)

local Title = Instance.new("TextLabel")
Title.Text = "PrimoDax Hub"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextColor3 = ACCENT
Title.Size = UDim2.new(0,120,1,0)
Title.Position = UDim2.new(0,12,0,0)
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local TabRow = Instance.new("Frame")
TabRow.Size = UDim2.new(0,250,0,28)
TabRow.Position = UDim2.new(0.5,-125,0.5,-14)
TabRow.BackgroundTransparency = 1
TabRow.Parent = TopBar
local TabRL = Instance.new("UIListLayout", TabRow)
TabRL.FillDirection = Enum.FillDirection.Horizontal
TabRL.Padding = UDim.new(0,4)
TabRL.HorizontalAlignment = Enum.HorizontalAlignment.Center

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.TextColor3 = Color3.fromRGB(255,80,80)
CloseBtn.Size = UDim2.new(0,28,0,28)
CloseBtn.Position = UDim2.new(1,-34,0.5,-14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,6)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1,0,1,-38)
ContentArea.Position = UDim2.new(0,0,0,38)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = Main

local pages = {}
local function makePage(name)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1,0,1,0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 2
    scroll.ScrollBarImageColor3 = ACCENT
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.Visible = false
    scroll.Parent = ContentArea
    local pad = Instance.new("UIPadding", scroll)
    pad.PaddingLeft = UDim.new(0,8); pad.PaddingRight = UDim.new(0,8)
    pad.PaddingTop = UDim.new(0,8); pad.PaddingBottom = UDim.new(0,8)
    pages[name] = scroll
    return scroll
end

local pageHome = makePage("Home")
local pageFarm = makePage("Farm")
local pageSettings = makePage("Settings")

local tabBtns = {}
for _, name in ipairs({"Home","Farm","Settings"}) do
    local btn = Instance.new("TextButton")
    btn.Text = name
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 11
    btn.TextColor3 = TXT_DIM
    btn.Size = UDim2.new(0,74,1,0)
    btn.BackgroundColor3 = BG_DARK
    btn.BorderSizePixel = 0
    btn.Parent = TabRow
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)
    tabBtns[name] = btn
end

local function switchPage(name)
    for n, p in pairs(pages) do p.Visible = (n == name) end
    for n, b in pairs(tabBtns) do
        b.TextColor3 = TXT_DIM; b.BackgroundColor3 = BG_DARK
    end
    if tabBtns[name] then
        tabBtns[name].TextColor3 = Color3.fromRGB(255,255,255)
        tabBtns[name].BackgroundColor3 = ACCENT
    end
end
for name, btn in pairs(tabBtns) do
    btn.MouseButton1Click:Connect(function() switchPage(name) end)
end

local function mkCard(parent, titleText, order)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1,0,0,0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = BG_CARD
    card.BorderSizePixel = 0
    card.LayoutOrder = order or 0
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,6)
    local pad = Instance.new("UIPadding", card)
    pad.PaddingLeft = UDim.new(0,10); pad.PaddingRight = UDim.new(0,10)
    pad.PaddingTop = UDim.new(0,8); pad.PaddingBottom = UDim.new(0,8)
    local layout = Instance.new("UIListLayout", card)
    layout.Padding = UDim.new(0,6); layout.SortOrder = Enum.SortOrder.LayoutOrder
    local hdr = Instance.new("TextLabel")
    hdr.Text = titleText; hdr.Font = Enum.Font.GothamBold; hdr.TextSize = 11; hdr.TextColor3 = ACCENT
    hdr.Size = UDim2.new(1,0,0,16); hdr.BackgroundTransparency = 1
    hdr.TextXAlignment = Enum.TextXAlignment.Left; hdr.LayoutOrder = 0; hdr.Parent = card
    return card
end

local function mkToggle(parent, label, cfgKey, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,22); row.BackgroundTransparency = 1
    row.LayoutOrder = order or 0; row.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Text = label; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11; lbl.TextColor3 = TXT
    lbl.Size = UDim2.new(1,-44,1,0); lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
    local ind = Instance.new("Frame")
    ind.Size = UDim2.new(0,30,0,14); ind.Position = UDim2.new(1,-32,0.5,-7)
    ind.BackgroundColor3 = CFG[cfgKey] and ACCENT or Color3.fromRGB(50,50,55)
    ind.BorderSizePixel = 0; ind.Parent = row
    Instance.new("UICorner", ind).CornerRadius = UDim.new(1,0)
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0,10,0,10)
    dot.Position = CFG[cfgKey] and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5)
    dot.BackgroundColor3 = Color3.fromRGB(255,255,255); dot.BorderSizePixel = 0; dot.Parent = ind
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
    local function refresh()
        local on = CFG[cfgKey]
        ind.BackgroundColor3 = on and ACCENT or Color3.fromRGB(50,50,55)
        TweenService:Create(dot, TweenInfo.new(0.1), { Position = on and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5) }):Play()
    end
    row.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            CFG[cfgKey] = not CFG[cfgKey]; refresh()
        end
    end)
    return row
end

local function mkSlider(parent, label, cfgKey, min, max, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,0,34); frame.BackgroundTransparency = 1
    frame.LayoutOrder = order or 0; frame.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Text = label .. ": " .. tostring(CFG[cfgKey]); lbl.Font = Enum.Font.Gotham; lbl.TextSize = 10
    lbl.TextColor3 = TXT_DIM; lbl.Size = UDim2.new(1,0,0,14); lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = frame
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1,0,0,8); bar.Position = UDim2.new(0,0,0,18)
    bar.BackgroundColor3 = Color3.fromRGB(45,45,50); bar.BorderSizePixel = 0; bar.Parent = frame
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((CFG[cfgKey]-min)/(max-min),0,1,0); fill.BackgroundColor3 = ACCENT
    fill.BorderSizePixel = 0; fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
    local dragging = false
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + rel*(max-min))
            CFG[cfgKey] = val; fill.Size = UDim2.new(rel,0,1,0); lbl.Text = label .. ": " .. tostring(val)
        end
    end)
    return frame
end

local function mkButton(parent, text, cb, order)
    local btn = Instance.new("TextButton")
    btn.Text = text; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 11
    btn.TextColor3 = Color3.fromRGB(255,255,255); btn.Size = UDim2.new(1,0,0,24)
    btn.BackgroundColor3 = ACCENT; btn.BorderSizePixel = 0; btn.LayoutOrder = order or 0; btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
    btn.MouseButton1Click:Connect(function() if cb then cb() end end)
    return btn
end

local farmList = Instance.new("UIListLayout", pageFarm)
farmList.Padding = UDim.new(0,6); farmList.SortOrder = Enum.SortOrder.LayoutOrder

local function mkGridRow(parent, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,0); row.AutomaticSize = Enum.AutomaticSize.Y
    row.BackgroundTransparency = 1; row.LayoutOrder = order or 0; row.Parent = parent
    local gl = Instance.new("UIListLayout", row)
    gl.FillDirection = Enum.FillDirection.Horizontal; gl.Padding = UDim.new(0,6)
    gl.SortOrder = Enum.SortOrder.LayoutOrder
    return row
end

local function mkGridCard(parent, titleText, order)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0.5,-3,0,0); card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = BG_CARD; card.BorderSizePixel = 0; card.LayoutOrder = order or 0; card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,6)
    local pad = Instance.new("UIPadding", card)
    pad.PaddingLeft = UDim.new(0,8); pad.PaddingRight = UDim.new(0,8)
    pad.PaddingTop = UDim.new(0,6); pad.PaddingBottom = UDim.new(0,6)
    local layout = Instance.new("UIListLayout", card)
    layout.Padding = UDim.new(0,5); layout.SortOrder = Enum.SortOrder.LayoutOrder
    local hdr = Instance.new("TextLabel")
    hdr.Text = titleText; hdr.Font = Enum.Font.GothamBold; hdr.TextSize = 11; hdr.TextColor3 = ACCENT
    hdr.Size = UDim2.new(1,0,0,14); hdr.BackgroundTransparency = 1
    hdr.TextXAlignment = Enum.TextXAlignment.Left; hdr.LayoutOrder = 0; hdr.Parent = card
    return card
end

local row1 = mkGridRow(pageFarm, 1)
local cCombat = mkGridCard(row1, "Combat", 1)
mkToggle(cCombat, "Auto Kill", "AutoKill", 1)
mkToggle(cCombat, "Auto Skill", "AutoSkill", 2)
mkToggle(cCombat, "Auto Stage Clear", "AutoStageClear", 3)

local cFarm = mkGridCard(row1, "Farming", 2)
mkToggle(cFarm, "Auto Train", "AutoTrain", 1)
mkToggle(cFarm, "Auto Claim Ore", "AutoClaimOre", 2)

local row2 = mkGridRow(pageFarm, 2)
local cPlayer = mkGridCard(row2, "Player", 1)
mkToggle(cPlayer, "Walk Speed", "WalkSpeedEnabled", 1)
mkSlider(cPlayer, "Speed", "WalkSpeed", 16, 250, 2)
mkToggle(cPlayer, "Fly", "Fly", 3)
mkToggle(cPlayer, "Infinite Jump", "InfiniteJump", 4)
mkToggle(cPlayer, "No Clip", "NoClip", 5)

local homeLayout = Instance.new("UIListLayout", pageHome)
homeLayout.Padding = UDim.new(0,8); homeLayout.SortOrder = Enum.SortOrder.LayoutOrder

do
    local c = mkCard(pageHome, "Server", 1)
    mkButton(c, "Rejoin", function() game:GetService("TeleportService"):Teleport(game.PlaceId, LP) end, 1)
end

local settingsLayout = Instance.new("UIListLayout", pageSettings)
settingsLayout.Padding = UDim.new(0,8); settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder

do
    local c = mkCard(pageSettings, "Info", 1)
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1,0,0,20); info.BackgroundTransparency = 1
    info.Text = "Created By: BoboyTagaAquarius"; info.TextColor3 = TXT; info.Font = Enum.Font.Gotham
    info.TextSize = 11; info.TextXAlignment = Enum.TextXAlignment.Left; info.Parent = c
end

local FloatBtn = Instance.new("TextButton")
FloatBtn.Size = UDim2.new(0,45,0,45)
FloatBtn.Position = UDim2.new(0,20,0.4,0)
FloatBtn.BackgroundColor3 = BG_DARK
FloatBtn.Text = "P"
FloatBtn.TextColor3 = ACCENT
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.TextSize = 22
FloatBtn.BorderSizePixel = 0
FloatBtn.Parent = Gui
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(1,0)

FloatBtn.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
end)

switchPage("Home")

notify("PrimoDax Hub", "Loot To Forge loaded! Created By: BoboyTagaAquarius")
print("[PrimoDax Functional] Loaded. Join our discord server: https://discord.gg/wqAReaB3d")
