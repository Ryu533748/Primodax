-- ██████╗ ██████╗ ██╗███╗   ███╗ ██████╗ ██████╗  █████╗ ██╗  ██╗
-- ██╔══██╗██╔══██╗██║████╗ ████║██╔═══██╗██╔══██╗██╔══██╗╚██╗██╔╝
-- ██████╔╝██████╔╝██║██╔████╔██║██║   ██║██║  ██║███████║ ╚███╔╝
-- ██╔═══╝ ██╔══██╗██║██║╚██╔╝██║██║   ██║██║  ██║██╔══██║ ██╔██╗
-- ██║     ██║  ██║██║██║ ╚═╝ ██║╚██████╔╝██████╔╝██║  ██║██╔╝ ██╗
-- ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
-- PRIMODAX SCRIPT | LOOT TO FORGE
-- AUTHOR: BOBOYTAGAAQUARIUS

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")
local CoreGui          = game:GetService("CoreGui")
local VirtualUser      = game:GetService("VirtualUser")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local LP  = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

local CFG = {
    -- Main
    AutoClick = false, ClickDelay = 0.1,
    AutoFarm = false, FarmRadius = 40,
    AutoCollect = false, TargetRarity = "All",
    -- Dungeon
    AutoDungeon = false, DungeonStage = "Stage 1", ForceKill = false,
    -- Tower
    AutoTower = false, TowerRound = "Round 1",
    -- Forge
    AutoForge = false, AutoEquipBest = false,
    -- Sell
    AutoSell = false, SellRarity = "All",
    -- Progression
    AutoRebirth = false, AutoBuyUpgrades = false,
    -- Training
    AutoTrain = false, ClicksPerSecond = 10,
    -- Player
    WalkSpeedEnabled = false, WalkSpeed = 32,
    Fly = false, FlySpeed = 60,
    InfiniteJump = false, NoClip = false
}

-- ============ UTILS ============
local function getChar() return LP.Character end
local function getRoot() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function isAlive(p) local h = p and p.Character and p.Character:FindFirstChildOfClass("Humanoid"); return h and h.Health > 0 end

local function isTargetLoot(obj)
    local name = obj.Name:lower()
    local isLoot = name:find("loot") or name:find("coin") or name:find("gold") or name:find("ore") or name:find("drop") or name:find("chest") or name:find("weapon") or name:find("sword")
    if not isLoot then return false end
    if CFG.TargetRarity == "All" then return true end
    local r = CFG.TargetRarity:lower()
    if name:find(r) then return true end
    local attr = obj:GetAttribute("Rarity") or obj:GetAttribute("Type")
    if attr and tostring(attr):lower() == r then return true end
    return false
end

-- ============ AUTO CLICKER (FIXED FOR PC/MOBILE) ============
task.spawn(function()
    while task.wait(CFG.ClickDelay) do
        if CFG.AutoClick or CFG.AutoTrain then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2), Cam.CFrame)
            end)
        end
    end
end)

-- ============ AUTO FARM / COLLECT ============
RunService.Heartbeat:Connect(function()
    if not (CFG.AutoCollect or CFG.AutoFarm) then return end
    local root = getRoot()
    if not root then return end

    for _, obj in ipairs(Workspace:GetChildren()) do
        local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
        if part and (root.Position - part.Position).Magnitude < CFG.FarmRadius then
            if isTargetLoot(obj) then
                pcall(function()
                    for _, v in ipairs(obj:GetDescendants()) do
                        if v:IsA("ProximityPrompt") then fireproximityprompt(v) end
                        if v:IsA("ClickDetector") then fireclickdetector(v) end
                    end
                end)
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
end)

-- ============ AUTO FORGE / REBIRTH / UPGRADES ============
task.spawn(function()
    while task.wait(1) do
        if CFG.AutoForge then
            pcall(function()
                local re = ReplicatedStorage:FindFirstChild("ForgeItem") or ReplicatedStorage:FindFirstChild("Forge")
                if re and re:IsA("RemoteEvent") then re:FireServer() end
            end)
        end
        if CFG.AutoRebirth then
            pcall(function()
                local re = ReplicatedStorage:FindFirstChild("Rebirth") or ReplicatedStorage:FindFirstChild("RebirthEvent")
                if re and re:IsA("RemoteEvent") then re:FireServer() end
            end)
        end
        if CFG.AutoBuyUpgrades then
            pcall(function()
                local re = ReplicatedStorage:FindFirstChild("BuyUpgrade") or ReplicatedStorage:FindFirstChild("Upgrade")
                if re and re:IsA("RemoteEvent") then re:FireServer() end
            end)
        end
    end
end)

-- ============ MOVEMENT (FLY, NOCLIP, JUMP, WALKSPEED) ============
local BodyVel, BodyGyr
local function startFly()
    local root = getRoot(); if not root then return end
    BodyVel = Instance.new("BodyVelocity", root); BodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
    BodyGyr = Instance.new("BodyGyro", root); BodyGyr.MaxTorque = Vector3.new(1e5,1e5,1e5)
end
local function stopFly()
    if BodyVel then BodyVel:Destroy(); BodyVel = nil end
    if BodyGyr then BodyGyr:Destroy(); BodyGyr = nil end
    local hum = getHum(); if hum then hum.PlatformStand = false end
end

UserInputService.JumpRequest:Connect(function()
    if CFG.InfiniteJump then
        local hum = getHum(); local root = getRoot()
        if hum and root and hum.Health > 0 then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            task.wait()
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 75, root.AssemblyLinearVelocity.Z)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    local hum = getHum(); local char = getChar()
    if not hum or not char then return end
    
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
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Cam.CFrame.LookVector end
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

-- ============ UI SYSTEM ============
local parentGui = gethui and gethui() or CoreGui
if parentGui:FindFirstChild("PrimoDaxUI") then parentGui:FindFirstChild("PrimoDaxUI"):Destroy() end

local BG_MAIN   = Color3.fromRGB(14, 14, 16)
local BG_SIDE   = Color3.fromRGB(20, 20, 24)
local BG_CARD   = Color3.fromRGB(26, 26, 30)
local ACCENT    = Color3.fromRGB(255, 100, 180) -- Pink (from your screenshot)
local TXT_MAIN  = Color3.fromRGB(240, 240, 240)
local TXT_SUB   = Color3.fromRGB(150, 150, 160)

local Gui = Instance.new("ScreenGui")
Gui.Name           = "PrimoDaxUI"
Gui.ResetOnSpawn   = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent         = parentGui
if protect_gui then pcall(protect_gui, Gui) end

-- FLOATING ICON
local FloatBtn = Instance.new("TextButton")
FloatBtn.Size = UDim2.new(0, 45, 0, 45)
FloatBtn.Position = UDim2.new(0, 20, 0, 20)
FloatBtn.BackgroundColor3 = BG_MAIN
FloatBtn.Text = "P"
FloatBtn.TextColor3 = ACCENT
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.TextSize = 24
FloatBtn.Parent = Gui
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(1, 0)
local stroke = Instance.new("UIStroke", FloatBtn); stroke.Color = ACCENT; stroke.Thickness = 2

-- MAIN MENU
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 600, 0, 350)
Main.Position = UDim2.new(0.5, -300, 0.5, -175)
Main.BackgroundColor3 = BG_MAIN
Main.BorderSizePixel = 0
Main.Visible = false
Main.Active = true
Main.Parent = Gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 6)

-- Drag Logic for Float Button
local draggingBtn, dragStartBtn, startPosBtn
FloatBtn.InputBegan:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        draggingBtn = true; dragStartBtn = input.Position; startPosBtn = FloatBtn.Position 
    end 
end)
UserInputService.InputChanged:Connect(function(input) 
    if draggingBtn and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then 
        local delta = input.Position - dragStartBtn
        FloatBtn.Position = UDim2.new(startPosBtn.X.Scale, startPosBtn.X.Offset + delta.X, startPosBtn.Y.Scale, startPosBtn.Y.Offset + delta.Y) 
    end 
end)
UserInputService.InputEnded:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        if draggingBtn then
            local delta = input.Position - dragStartBtn
            if math.abs(delta.X) < 5 and math.abs(delta.Y) < 5 then Main.Visible = not Main.Visible end
        end
        draggingBtn = false 
    end 
end)

-- SIDEBAR
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 120, 1, 0)
Sidebar.BackgroundColor3 = BG_SIDE
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 6)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 0, 40); Title.Position = UDim2.new(0, 10, 0, 5); Title.BackgroundTransparency = 1
Title.Text = "PRIMODAX"; Title.TextColor3 = ACCENT; Title.Font = Enum.Font.GothamBold; Title.TextSize = 16; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Parent = Sidebar

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -10, 0, 15); SubTitle.Position = UDim2.new(0, 10, 0, 22); SubTitle.BackgroundTransparency = 1
SubTitle.Text = "By: BoboyTagaAquarius"; SubTitle.TextColor3 = TXT_SUB; SubTitle.Font = Enum.Font.Gotham; SubTitle.TextSize = 10; SubTitle.TextXAlignment = Enum.TextXAlignment.Left; SubTitle.Parent = Sidebar

local function makeTab(text, icon, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35); btn.Position = UDim2.new(0, 5, 0, 45 + (order * 40))
    btn.BackgroundColor3 = BG_SIDE; btn.Text = "  " .. icon .. "  " .. text; btn.TextColor3 = TXT_SUB; btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = Sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    return btn
end

-- TOP BAR
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, -120, 0, 35); TopBar.Position = UDim2.new(0, 120, 0, 0); TopBar.BackgroundColor3 = BG_MAIN; TopBar.BorderSizePixel = 0; TopBar.Parent = Main
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 6)

local SearchBar = Instance.new("Frame")
SearchBar.Size = UDim2.new(0, 150, 0, 20); SearchBar.Position = UDim2.new(0, 10, 0, 8); SearchBar.BackgroundColor3 = BG_CARD; SearchBar.Parent = TopBar
Instance.new("UICorner", SearchBar).CornerRadius = UDim.new(1, 0)
local SearchTxt = Instance.new("TextLabel")
SearchTxt.Size = UDim2.new(1, -10, 1, 0); SearchTxt.Position = UDim2.new(0, 10, 0, 0); SearchTxt.BackgroundTransparency = 1
SearchTxt.Text = "Search..."; SearchTxt.TextColor3 = TXT_SUB; SearchTxt.Font = Enum.Font.Gotham; SearchTxt.TextSize = 10; SearchTxt.TextXAlignment = Enum.TextXAlignment.Left; SearchTxt.Parent = SearchBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 20); CloseBtn.Position = UDim2.new(1, -40, 0, 8); CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"; CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80); CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 12; CloseBtn.Parent = TopBar
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

-- CONTENT
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -125, 1, -40); Content.Position = UDim2.new(0, 120, 0, 35); Content.BackgroundTransparency = 1; Content.Parent = Main

local Pages = {}
local function makePage(name)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0); scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 2; scroll.ScrollBarImageColor3 = ACCENT; scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.CanvasSize = UDim2.new(0,0,0,0); scroll.Visible = false; scroll.Parent = Content
    local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 8); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = scroll
    Pages[name] = scroll
    return scroll
end

local PageDungeon = makePage("Dungeon")
local PageTower = makePage("Tower")
local PageForge = makePage("Forge")
local PageItems = makePage("Items")
local PageTraining = makePage("Training")
local PagePlayer = makePage("Player")

local function switchTab(name)
    for n, p in pairs(Pages) do p.Visible = (n == name) end
end

local tabD = makeTab("Dungeon", "⚔", 0); tabD.MouseButton1Click:Connect(function() switchTab("Dungeon") end)
local tabT = makeTab("Tower", "🏰", 1); tabT.MouseButton1Click:Connect(function() switchTab("Tower") end)
local tabF = makeTab("Forge", "🔨", 2); tabF.MouseButton1Click:Connect(function() switchTab("Forge") end)
local tabI = makeTab("Items", "🎒", 3); tabI.MouseButton1Click:Connect(function() switchTab("Items") end)
local tabTr = makeTab("Training", "🏋", 4); tabTr.MouseButton1Click:Connect(function() switchTab("Training") end)
local tabP = makeTab("Player", "🏃", 5); tabP.MouseButton1Click:Connect(function() switchTab("Player") end)

-- UI HELPERS
local function mkCard(parent, titleText, order)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -10, 0, 0); card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = BG_CARD; card.BorderSizePixel = 0; card.LayoutOrder = order; card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
    local pad = Instance.new("UIPadding", card); pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10); pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8)
    local layout = Instance.new("UIListLayout", card); layout.Padding = UDim.new(0, 8); layout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local header = Instance.new("Frame"); header.Size = UDim2.new(1, 0, 0, 20); header.BackgroundTransparency = 1; header.LayoutOrder = 0; header.Parent = card
    local hTxt = Instance.new("TextLabel"); hTxt.Size = UDim2.new(1, 0, 1, 0); hTxt.BackgroundTransparency = 1; hTxt.Text = titleText; hTxt.TextColor3 = ACCENT; hTxt.Font = Enum.Font.GothamBold; hTxt.TextSize = 12; hTxt.TextXAlignment = Enum.TextXAlignment.Left; hTxt.Parent = header
    return card
end

local function mkToggle(parent, name, key, order)
    local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 24); row.BackgroundTransparency = 1; row.LayoutOrder = order; row.Parent = parent
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -50, 1, 0); lbl.BackgroundTransparency = 1; lbl.Text = name; lbl.TextColor3 = TXT_MAIN; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
    
    local ind = Instance.new("Frame"); ind.Size = UDim2.new(0, 30, 0, 14); ind.Position = UDim2.new(1, -35, 0.5, -7); ind.BackgroundColor3 = CFG[key] and ACCENT or Color3.fromRGB(50, 50, 55); ind.Parent = row
    Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)
    local dot = Instance.new("Frame"); dot.Size = UDim2.new(0, 10, 0, 10); dot.Position = CFG[key] and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5); dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255); dot.Parent = ind
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    
    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            CFG[key] = not CFG[key]
            ind.BackgroundColor3 = CFG[key] and ACCENT or Color3.fromRGB(50, 50, 55)
            dot.Position = CFG[key] and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
        end
    end)
end

local function mkSlider(parent, name, key, min, max, order)
    local frame = Instance.new("Frame"); frame.Size = UDim2.new(1, 0, 0, 30); frame.BackgroundTransparency = 1; frame.LayoutOrder = order; frame.Parent = parent
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, 0, 0, 15); lbl.BackgroundTransparency = 1; lbl.Text = name .. ": " .. CFG[key]; lbl.TextColor3 = TXT_SUB; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = frame
    local bar = Instance.new("TextButton"); bar.Size = UDim2.new(1, 0, 0, 8); bar.Position = UDim2.new(0, 0, 0, 18); bar.BackgroundColor3 = Color3.fromRGB(50, 50, 55); bar.Text = ""; bar.Parent = frame
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame"); fill.Size = UDim2.new((CFG[key] - min) / (max - min), 0, 1, 0); fill.BackgroundColor3 = ACCENT; fill.Parent = bar
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

local function mkDropdown(parent, name, key, options, order)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, 0, 0, 24); btn.BackgroundColor3 = Color3.fromRGB(50, 50, 55); btn.Text = ""; btn.LayoutOrder = order; btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -10, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0); lbl.BackgroundTransparency = 1; lbl.Text = name .. ": " .. CFG[key]; lbl.TextColor3 = TXT_MAIN; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = btn
    btn.MouseButton1Click:Connect(function()
        local curIdx = 1
        for i, v in ipairs(options) do if v == CFG[key] then curIdx = i; break end end
        CFG[key] = options[(curIdx % #options) + 1]
        lbl.Text = name .. ": " .. CFG[key]
    end)
end

-- POPULATE DUNGEON
local cD1 = mkCard(PageDungeon, "Auto Dungeon", 1)
mkToggle(cD1, "Auto Farm Dungeon", "AutoDungeon", 1)
mkDropdown(cD1, "Stage", "DungeonStage", {"Stage 1","Stage 2","Stage 3","Stage 4","Stage 5"}, 2)

-- POPULATE TOWER
local cT1 = mkCard(PageTower, "Auto Tower", 1)
mkToggle(cT1, "Auto Farm Tower", "AutoTower", 1)
mkDropdown(cT1, "Round", "TowerRound", {"Round 1","Round 2","Round 3"}, 2)

-- POPULATE FORGE
local cF1 = mkCard(PageForge, "Auto Forge", 1)
mkToggle(cF1, "Auto Forge", "AutoForge", 1)
mkToggle(cF1, "Auto Equip Best", "AutoEquipBest", 2)

-- POPULATE ITEMS
local cI1 = mkCard(PageItems, "Auto Collect", 1)
mkToggle(cI1, "Auto Collect", "AutoCollect", 1)
mkDropdown(cI1, "Target Rarity", "TargetRarity", {"All","Common","Rare","Epic","Legendary","Mythic"}, 2)

local cI2 = mkCard(PageItems, "Auto Sell", 2)
mkToggle(cI2, "Auto Sell", "AutoSell", 1)
mkDropdown(cI2, "Sell Rarity", "SellRarity", {"All","Common","Rare","Epic"}, 2)

-- POPULATE TRAINING
local cTr1 = mkCard(PageTraining, "Auto Train", 1)
mkToggle(cTr1, "Auto Train (Click)", "AutoTrain", 1)
mkSlider(cTr1, "Clicks Per Second", "ClicksPerSecond", 1, 20, 2)

local cTr2 = mkCard(PageTraining, "Progression", 2)
mkToggle(cTr2, "Auto Rebirth", "AutoRebirth", 1)
mkToggle(cTr2, "Auto Buy Upgrades", "AutoBuyUpgrades", 2)

-- POPULATE PLAYER
local cP1 = mkCard(PagePlayer, "Movement", 1)
mkToggle(cP1, "WalkSpeed", "WalkSpeedEnabled", 1)
mkSlider(cP1, "Speed Amount", "WalkSpeed", 16, 250, 2)
mkToggle(cP1, "Fly", "Fly", 3)
mkSlider(cP1, "Fly Speed", "FlySpeed", 10, 400, 4)
mkToggle(cP1, "Infinite Jump", "InfiniteJump", 5)
mkToggle(cP1, "No Clip", "NoClip", 6)

-- Initial Tab
tabD.TextColor3 = TXT_MAIN
tabD.BackgroundColor3 = BG_CARD
switchTab("Dungeon")

-- Footer
local Footer = Instance.new("TextLabel")
Footer.Size = UDim2.new(1, -120, 0, 20); Footer.Position = UDim2.new(0, 120, 1, -20); Footer.BackgroundTransparency = 1
Footer.Text = "Loot To Forge v0.5"; Footer.TextColor3 = TXT_SUB; Footer.Font = Enum.Font.Gotham; Footer.TextSize = 9; Footer.TextXAlignment = Enum.TextXAlignment.Right; Footer.Parent = Main

-- Drag Main Menu
local dragging, dragStart, startPos
TopBar.InputBegan:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = Main.Position end 
end)
UserInputService.InputChanged:Connect(function(input) 
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then 
        local delta = input.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) 
    end 
end)
UserInputService.InputEnded:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end 
end)

print("[PrimoDax Hub] Loaded! Created By: BoboyTagaAquarius")
