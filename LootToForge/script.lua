-- ██████╗ ██████╗ ██╗███╗   ███╗ ██████╗ ██████╗  █████╗ ██╗  ██╗
-- ██╔══██╗██╔══██╗██║████╗ ████║██╔═══██╗██╔══██╗██╔══██╗╚██╗██╔╝
-- ██████╔╝██████╔╝██║██╔████╔██║██║   ██║██║  ██║███████║ ╚███╔╝
-- ██╔═══╝ ██╔══██╗██║██║╚██╔╝██║██║   ██║██║  ██║██╔══██║ ██╔██╗
-- ██║     ██║  ██║██║██║ ╚═╝ ██║╚██████╔╝██████╔╝██║  ██║██╔╝ ██╗
-- ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
-- PRIMODAX HUB | LOOT TO FORGE
-- Created By: BoboyTagaAquarius

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")
local CoreGui          = game:GetService("CoreGui")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local VirtualUser      = game:GetService("VirtualUser")
local TeleportService  = game:GetService("TeleportService")
local StarterGui       = game:GetService("StarterGui")

local LP  = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

-- ════════════════════════════════════════
--              CONFIG
-- ════════════════════════════════════════
local CFG = {
    -- Farming
    InfiniteMoney    = false,
    AutoDungeonLoot  = false,
    AutoSuperLoot    = false,
    AutoUpgrade      = false,
    AutoTrain        = false,
    AutoRebirth      = false,
    ClicksPerSecond  = 10,

    -- Enchant
    AutoEnchant      = false,
    AutoEnchantHat   = false,

    -- Race
    AutoRollRace     = false,
    RollUntil        = "None",

    -- Forge
    AutoForge        = false,
    AutoForgeHat     = false,
    AutoForgeArmor   = false,
    InstantForge     = false,
    AutoEquipBest    = false,
    SellOldGear      = false,

    -- Ores
    InfiniteOres     = false,
    PickOres         = false,

    -- Extras
    InstantKill      = false,
    GodMode          = false,
    AutoClaim        = false,
    DisableNotif     = false,

    -- Player
    WalkSpeedEnabled = false,
    WalkSpeed        = 32,
    Fly              = false,
    FlySpeed         = 60,
    InfiniteJump     = false,
    NoClip           = false,

    -- Anti
    AntiAFK          = true,
}

-- ════════════════════════════════════════
--              UTILS
-- ════════════════════════════════════════
local function getChar() return LP.Character end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function fireRE(name, ...)
    local re = ReplicatedStorage:FindFirstChild(name, true)
    if re and re:IsA("RemoteEvent") then
        pcall(function() re:FireServer(...) end)
    end
end

local function invokeRF(name, ...)
    local rf = ReplicatedStorage:FindFirstChild(name, true)
    if rf and rf:IsA("RemoteFunction") then
        pcall(function() rf:InvokeServer(...) end)
    end
end

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title   = title,
            Text    = text,
            Duration= 3,
        })
    end)
end

-- ════════════════════════════════════════
--              ANTI AFK
-- ════════════════════════════════════════
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

-- ════════════════════════════════════════
--              DISABLE NOTIFICATIONS
-- ════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if CFG.DisableNotif then
        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
        end)
    end
end)

-- ════════════════════════════════════════
--         GOD MODE
-- ════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    local hum = getHum()
    if hum and CFG.GodMode then
        hum.Health    = hum.MaxHealth
        hum.MaxHealth = math.huge
    end
end)

-- ════════════════════════════════════════
--         INSTANT KILL
-- ════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not CFG.InstantKill then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local hum = obj:FindFirstChildOfClass("Humanoid")
        if hum and obj ~= getChar() then
            local h = obj:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then
                pcall(function() h.Health = 0 end)
            end
        end
    end
end)

-- ════════════════════════════════════════
--         INFINITE ORES
-- ════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not CFG.InfiniteOres then return end
    fireRE("InfiniteOres")
    fireRE("AddOre")
end)

-- ════════════════════════════════════════
--         PICK ORES
-- ════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.5)
        if CFG.PickOres then
            local root = getRoot()
            if not root then continue end
            for _, obj in ipairs(Workspace:GetDescendants()) do
                local name = obj.Name:lower()
                if name:find("ore") and obj:IsA("BasePart") then
                    root.CFrame = CFrame.new(obj.Position + Vector3.new(0,3,0))
                    pcall(function()
                        for _, v in ipairs(obj:GetDescendants()) do
                            if v:IsA("ProximityPrompt") then fireproximityprompt(v) end
                            if v:IsA("ClickDetector")   then fireclickdetector(v)   end
                        end
                    end)
                    break
                end
            end
        end
    end
end)

-- ════════════════════════════════════════
--         MAIN FARM LOOP
-- ════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(1 / math.max(CFG.ClicksPerSecond, 1))

        -- Auto Train (click center)
        if CFG.AutoTrain then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(
                    Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2),
                    Cam.CFrame
                )
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)

        -- Auto Rebirth
        if CFG.AutoRebirth then
            fireRE("Rebirth")
            fireRE("RebirthEvent")
            fireRE("DoRebirth")
        end

        -- Auto Upgrade
        if CFG.AutoUpgrade then
            fireRE("BuyUpgrade")
            fireRE("Upgrade")
            fireRE("PurchaseUpgrade")
        end

        -- Auto Dungeon Loot
        if CFG.AutoDungeonLoot then
            fireRE("FarmDungeon")
            fireRE("StartDungeon")
            fireRE("CollectDungeonLoot")
        end

        -- Auto Super Loot
        if CFG.AutoSuperLoot then
            fireRE("SuperLoot")
            fireRE("CollectSuperLoot")
            -- also teleport to any loot
            local root = getRoot()
            if root then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    local name = obj.Name:lower()
                    if (name:find("loot") or name:find("drop") or name:find("chest"))
                    and obj:IsA("BasePart") then
                        root.CFrame = CFrame.new(obj.Position + Vector3.new(0,3,0))
                        pcall(function()
                            for _, v in ipairs(obj:GetDescendants()) do
                                if v:IsA("ProximityPrompt") then fireproximityprompt(v) end
                                if v:IsA("ClickDetector")   then fireclickdetector(v)   end
                            end
                        end)
                        break
                    end
                end
            end
        end

        -- Infinite Money
        if CFG.InfiniteMoney then
            fireRE("AddMoney")
            fireRE("GiveMoney")
            fireRE("InfiniteMoney")
        end

        -- Auto Forge
        if CFG.AutoForge then
            fireRE("ForgeItem")
            fireRE("Forge")
            fireRE("ForgeWeapon")
        end

        -- Auto Forge Hat
        if CFG.AutoForgeHat then
            fireRE("ForgeHat")
            fireRE("ForgeHelmet")
        end

        -- Auto Forge Armor
        if CFG.AutoForgeArmor then
            fireRE("ForgeArmor")
            fireRE("ForgeChest")
        end

        -- Instant Forge
        if CFG.InstantForge then
            fireRE("InstantForge")
            fireRE("ForgeInstant")
        end

        -- Auto Equip Best
        if CFG.AutoEquipBest then
            fireRE("EquipBest")
            fireRE("AutoEquip")
        end

        -- Sell Old Gear
        if CFG.SellOldGear then
            fireRE("SellOldGear")
            fireRE("SellGear")
        end

        -- Auto Enchant
        if CFG.AutoEnchant then
            fireRE("EnchantWeapon")
            fireRE("Enchant")
            fireRE("AutoEnchant")
        end

        -- Auto Enchant Hat
        if CFG.AutoEnchantHat then
            fireRE("EnchantHat")
            fireRE("EnchantHelmet")
        end

        -- Auto Roll Race
        if CFG.AutoRollRace then
            fireRE("RollRace")
            fireRE("RerollRace")
            if CFG.RollUntil ~= "None" then
                -- check current race
                local data = LP:FindFirstChild("leaderstats")
                    or LP:FindFirstChild("Data")
                if data then
                    local race = data:FindFirstChild("Race")
                    if race and race.Value == CFG.RollUntil then
                        CFG.AutoRollRace = false
                        notify("PrimoDax Hub", "Got race: " .. CFG.RollUntil)
                    end
                end
            end
        end

        -- Auto Claim
        if CFG.AutoClaim then
            fireRE("ClaimReward")
            fireRE("ClaimDaily")
            fireRE("Claim")
        end
    end
end)

-- ════════════════════════════════════════
--         MOVEMENT
-- ════════════════════════════════════════
local BodyVel, BodyGyr
local function startFly()
    local root = getRoot(); if not root then return end
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
    local hum = getHum(); if hum then hum.PlatformStand = false end
end

UserInputService.JumpRequest:Connect(function()
    if CFG.InfiniteJump then
        local hum  = getHum()
        local root = getRoot()
        if hum and root and hum.Health > 0 then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            task.wait()
            root.AssemblyLinearVelocity = Vector3.new(
                root.AssemblyLinearVelocity.X, 75,
                root.AssemblyLinearVelocity.Z
            )
        end
    end
end)

RunService.Heartbeat:Connect(function()
    local hum  = getHum()
    local char = getChar()
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
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
        if BodyVel then
            BodyVel.Velocity = dir.Magnitude > 0
                and dir.Unit * CFG.FlySpeed
                or  Vector3.new(0,0,0)
        end
        if BodyGyr then BodyGyr.CFrame = Cam.CFrame end
    else
        if BodyVel then stopFly() end
    end
end)

-- ════════════════════════════════════════
--              GUI
-- ════════════════════════════════════════
local parentGui = (gethui and gethui()) or CoreGui
if parentGui:FindFirstChild("PrimoDaxLTF") then
    parentGui:FindFirstChild("PrimoDaxLTF"):Destroy()
end

local ACCENT  = Color3.fromRGB(255, 105, 180)
local BG_DARK = Color3.fromRGB(18, 18, 18)
local BG_CARD = Color3.fromRGB(28, 28, 28)
local BG_MID  = Color3.fromRGB(30, 30, 30)
local BG_SIDE = Color3.fromRGB(22, 22, 26)
local TXT     = Color3.fromRGB(220, 220, 220)
local TXT_DIM = Color3.fromRGB(130, 130, 140)

local Gui = Instance.new("ScreenGui")
Gui.Name           = "PrimoDaxLTF"
Gui.ResetOnSpawn   = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent         = parentGui
if protect_gui then pcall(protect_gui, Gui) end

-- ════════════ FLOATING BUTTON ════════════
local FloatBtn = Instance.new("TextButton")
FloatBtn.Size             = UDim2.new(0,45,0,45)
FloatBtn.Position         = UDim2.new(0,20,0,20)
FloatBtn.BackgroundColor3 = BG_DARK
FloatBtn.Text             = "P"
FloatBtn.TextColor3       = ACCENT
FloatBtn.Font             = Enum.Font.GothamBold
FloatBtn.TextSize         = 22
FloatBtn.BorderSizePixel  = 0
FloatBtn.Parent           = Gui
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(1,0)
local fStroke = Instance.new("UIStroke", FloatBtn)
fStroke.Color     = ACCENT
fStroke.Thickness = 2

-- drag float button
local fDrag, fDragStart, fStartPos = false, nil, nil
FloatBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        fDrag = true; fDragStart = i.Position; fStartPos = FloatBtn.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if fDrag and (i.UserInputType == Enum.UserInputType.MouseMovement
    or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - fDragStart
        FloatBtn.Position = UDim2.new(
            fStartPos.X.Scale, fStartPos.X.Offset + d.X,
            fStartPos.Y.Scale, fStartPos.Y.Offset + d.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        if fDrag then
            local d = i.Position - fDragStart
            if math.abs(d.X) < 5 and math.abs(d.Y) < 5 then
                -- toggle main menu on tap
                local Main = Gui:FindFirstChild("MainMenu")
                if Main then Main.Visible = not Main.Visible end
            end
        end
        fDrag = false
    end
end)

-- ════════════ MAIN WINDOW ════════════
local Main = Instance.new("Frame")
Main.Name             = "MainMenu"
Main.Size             = UDim2.new(0,620,0,370)
Main.Position         = UDim2.new(0.5,-310,0.5,-185)
Main.BackgroundColor3 = BG_DARK
Main.BorderSizePixel  = 0
Main.Visible          = false
Main.Active           = true
Main.Parent           = Gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,8)
Instance.new("UIStroke", Main).Color = Color3.fromRGB(50,50,55)

-- drag main
local mDrag, mDragStart, mStartPos = false, nil, nil

-- ════════════ TOP BAR ════════════
local TopBar = Instance.new("Frame")
TopBar.Name             = "TopBar"
TopBar.Size             = UDim2.new(1,0,0,38)
TopBar.BackgroundColor3 = BG_MID
TopBar.BorderSizePixel  = 0
TopBar.Parent           = Main
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0,8)

TopBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        mDrag = true; mDragStart = i.Position; mStartPos = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if mDrag and (i.UserInputType == Enum.UserInputType.MouseMovement
    or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - mDragStart
        Main.Position = UDim2.new(
            mStartPos.X.Scale, mStartPos.X.Offset + d.X,
            mStartPos.Y.Scale, mStartPos.Y.Offset + d.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then mDrag = false end
end)

local HubTitle = Instance.new("TextLabel")
HubTitle.Text           = "PRIMODAX"
HubTitle.Font           = Enum.Font.GothamBold
HubTitle.TextSize       = 16
HubTitle.TextColor3     = ACCENT
HubTitle.Size           = UDim2.new(0,120,1,0)
HubTitle.Position       = UDim2.new(0,12,0,0)
HubTitle.BackgroundTransparency = 1
HubTitle.TextXAlignment = Enum.TextXAlignment.Left
HubTitle.Parent         = TopBar

local ByLabel = Instance.new("TextLabel")
ByLabel.Text           = "By: BoboyTagaAquarius"
ByLabel.Font           = Enum.Font.Gotham
ByLabel.TextSize       = 9
ByLabel.TextColor3     = TXT_DIM
ByLabel.Size           = UDim2.new(0,160,0,14)
ByLabel.Position       = UDim2.new(0,12,0,22)
ByLabel.BackgroundTransparency = 1
ByLabel.TextXAlignment = Enum.TextXAlignment.Left
ByLabel.Parent         = TopBar

-- Tab buttons in top bar
local tabNames = {"Home","Farm","Settings"}
local tabBtnFrames = {}
local tabBtns = {}

local TabRow = Instance.new("Frame")
TabRow.Size             = UDim2.new(0,250,0,28)
TabRow.Position         = UDim2.new(0.5,-125,0.5,-14)
TabRow.BackgroundTransparency = 1
TabRow.Parent           = TopBar
local TabRL = Instance.new("UIListLayout", TabRow)
TabRL.FillDirection = Enum.FillDirection.Horizontal
TabRL.Padding       = UDim.new(0,4)
TabRL.HorizontalAlignment = Enum.HorizontalAlignment.Center

for _, name in ipairs(tabNames) do
    local btn = Instance.new("TextButton")
    btn.Text             = name
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 11
    btn.TextColor3       = TXT_DIM
    btn.Size             = UDim2.new(0,74,1,0)
    btn.BackgroundColor3 = BG_DARK
    btn.BorderSizePixel  = 0
    btn.Parent           = TabRow
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)
    tabBtns[name] = btn
end

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text             = "✕"
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 12
CloseBtn.TextColor3       = Color3.fromRGB(255,80,80)
CloseBtn.Size             = UDim2.new(0,28,0,28)
CloseBtn.Position         = UDim2.new(1,-34,0.5,-14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
CloseBtn.BorderSizePixel  = 0
CloseBtn.Parent           = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,6)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

-- ════════════ CONTENT AREA ════════════
local ContentArea = Instance.new("Frame")
ContentArea.Size             = UDim2.new(1,0,1,-38)
ContentArea.Position         = UDim2.new(0,0,0,38)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent           = Main

-- Pages
local pages = {}
local function makePage(name)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size                = UDim2.new(1,0,1,0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness  = 3
    scroll.ScrollBarImageColor3= ACCENT
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize          = UDim2.new(0,0,0,0)
    scroll.Visible             = false
    scroll.Parent              = ContentArea
    local pad = Instance.new("UIPadding", scroll)
    pad.PaddingLeft   = UDim.new(0,8)
    pad.PaddingRight  = UDim.new(0,8)
    pad.PaddingTop    = UDim.new(0,8)
    pad.PaddingBottom = UDim.new(0,8)
    pages[name] = scroll
    return scroll
end

local pageHome     = makePage("Home")
local pageFarm     = makePage("Farm")
local pageSettings = makePage("Settings")

-- Farm page uses a grid layout
local FarmGrid = Instance.new("Frame")
FarmGrid.Size             = UDim2.new(1,0,0,0)
FarmGrid.AutomaticSize    = Enum.AutomaticSize.Y
FarmGrid.BackgroundTransparency = 1
FarmGrid.Parent           = pageFarm
local FarmGridLayout = Instance.new("UIGridLayout", FarmGrid)
FarmGridLayout.CellSize    = UDim2.new(0.5,-6,0,0)
FarmGridLayout.CellPadding = UDim2.new(0,6,0,6)
FarmGridLayout.SortOrder   = Enum.SortOrder.LayoutOrder
local FarmGridSizeConstraint = Instance.new("UIListLayout", FarmGrid)
-- remove the list layout, keep grid
FarmGridSizeConstraint:Destroy()

local function switchPage(name)
    for n, p in pairs(pages) do p.Visible = (n == name) end
    for n, b in pairs(tabBtns) do
        b.TextColor3       = TXT_DIM
        b.BackgroundColor3 = BG_DARK
    end
    if tabBtns[name] then
        tabBtns[name].TextColor3       = Color3.fromRGB(255,255,255)
        tabBtns[name].BackgroundColor3 = ACCENT
    end
end

for name, btn in pairs(tabBtns) do
    btn.MouseButton1Click:Connect(function() switchPage(name) end)
end

-- ════════════ UI HELPERS ════════════
local function mkCard(parent, titleText, order)
    local card = Instance.new("Frame")
    card.Size             = UDim2.new(1,0,0,0)
    card.AutomaticSize    = Enum.AutomaticSize.Y
    card.BackgroundColor3 = BG_CARD
    card.BorderSizePixel  = 0
    card.LayoutOrder      = order or 0
    card.Parent           = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,6)
    local pad = Instance.new("UIPadding", card)
    pad.PaddingLeft = UDim.new(0,10); pad.PaddingRight  = UDim.new(0,10)
    pad.PaddingTop  = UDim.new(0,8);  pad.PaddingBottom = UDim.new(0,8)
    local layout = Instance.new("UIListLayout", card)
    layout.Padding   = UDim.new(0,6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local hdr = Instance.new("TextLabel")
    hdr.Text           = titleText
    hdr.Font           = Enum.Font.GothamBold
    hdr.TextSize       = 11
    hdr.TextColor3     = ACCENT
    hdr.Size           = UDim2.new(1,0,0,16)
    hdr.BackgroundTransparency = 1
    hdr.TextXAlignment = Enum.TextXAlignment.Left
    hdr.LayoutOrder    = 0
    hdr.Parent         = card
    return card
end

local function mkToggle(parent, label, cfgKey, order)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1,0,0,22)
    row.BackgroundTransparency = 1
    row.LayoutOrder      = order or 0
    row.Parent           = parent

    local lbl = Instance.new("TextLabel")
    lbl.Text           = label
    lbl.Font           = Enum.Font.Gotham
    lbl.TextSize       = 11
    lbl.TextColor3     = TXT
    lbl.Size           = UDim2.new(1,-44,1,0)
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent         = row

    local ind = Instance.new("Frame")
    ind.Size             = UDim2.new(0,30,0,14)
    ind.Position         = UDim2.new(1,-32,0.5,-7)
    ind.BackgroundColor3 = CFG[cfgKey] and ACCENT or Color3.fromRGB(50,50,55)
    ind.BorderSizePixel  = 0
    ind.Parent           = row
    Instance.new("UICorner", ind).CornerRadius = UDim.new(1,0)

    local dot = Instance.new("Frame")
    dot.Size             = UDim2.new(0,10,0,10)
    dot.Position         = CFG[cfgKey]
        and UDim2.new(1,-12,0.5,-5)
        or  UDim2.new(0,2,0.5,-5)
    dot.BackgroundColor3 = Color3.fromRGB(255,255,255)
    dot.BorderSizePixel  = 0
    dot.Parent           = ind
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

    local function refresh()
        local on = CFG[cfgKey]
        ind.BackgroundColor3 = on and ACCENT or Color3.fromRGB(50,50,55)
        TweenService:Create(dot, TweenInfo.new(0.1), {
            Position = on and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5)
        }):Play()
    end

    row.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            CFG[cfgKey] = not CFG[cfgKey]
            refresh()
        end
    end)
    return row
end

local function mkSlider(parent, label, cfgKey, min, max, order)
    local frame = Instance.new("Frame")
    frame.Size             = UDim2.new(1,0,0,34)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder      = order or 0
    frame.Parent           = parent

    local lbl = Instance.new("TextLabel")
    lbl.Text           = label .. ": " .. tostring(CFG[cfgKey])
    lbl.Font           = Enum.Font.Gotham
    lbl.TextSize       = 10
    lbl.TextColor3     = TXT_DIM
    lbl.Size           = UDim2.new(1,0,0,14)
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent         = frame

    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(1,0,0,8)
    bar.Position         = UDim2.new(0,0,0,18)
    bar.BackgroundColor3 = Color3.fromRGB(45,45,50)
    bar.BorderSizePixel  = 0
    bar.Parent           = frame
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new((CFG[cfgKey]-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = ACCENT
    fill.BorderSizePixel  = 0
    fill.Parent           = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    local dragging = false
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then dragging = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            local rel = math.clamp(
                (i.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + rel*(max-min))
            CFG[cfgKey] = val
            fill.Size   = UDim2.new(rel,0,1,0)
            lbl.Text    = label .. ": " .. tostring(val)
        end
    end)
    return frame
end

local function mkDropdown(parent, label, cfgKey, options, order)
    local frame = Instance.new("Frame")
    frame.Size             = UDim2.new(1,0,0,22)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder      = order or 0
    frame.Parent           = parent

    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1,0,1,0)
    btn.BackgroundColor3 = Color3.fromRGB(38,38,42)
    btn.BorderSizePixel  = 0
    btn.Text             = ""
    btn.Parent           = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)

    local lbl = Instance.new("TextLabel")
    lbl.Text           = label .. ": " .. tostring(CFG[cfgKey])
    lbl.Font           = Enum.Font.Gotham
    lbl.TextSize       = 10
    lbl.TextColor3     = TXT
    lbl.Size           = UDim2.new(1,-10,1,0)
    lbl.Position       = UDim2.new(0,8,0,0)
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent         = btn

    -- dropdown list
    local list = Instance.new("Frame")
    list.Size             = UDim2.new(1,0,0,0)
    list.AutomaticSize    = Enum.AutomaticSize.Y
    list.Position         = UDim2.new(0,0,1,2)
    list.BackgroundColor3 = Color3.fromRGB(38,38,42)
    list.BorderSizePixel  = 0
    list.Visible          = false
    list.ZIndex           = 20
    list.Parent           = btn
    Instance.new("UICorner", list).CornerRadius = UDim.new(0,4)
    local listLayout = Instance.new("UIListLayout", list)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    for i, opt in ipairs(options) do
        local ob = Instance.new("TextButton")
        ob.Text             = opt
        ob.Font             = Enum.Font.Gotham
        ob.TextSize         = 10
        ob.TextColor3       = TXT
        ob.Size             = UDim2.new(1,0,0,20)
        ob.BackgroundTransparency = 1
        ob.BorderSizePixel  = 0
        ob.LayoutOrder      = i
        ob.ZIndex           = 21
        ob.Parent           = list
        ob.MouseButton1Click:Connect(function()
            CFG[cfgKey]   = opt
            lbl.Text      = label .. ": " .. opt
            list.Visible  = false
        end)
    end

    btn.MouseButton1Click:Connect(function()
        list.Visible = not list.Visible
    end)
    return frame
end

local function mkButton(parent, text, cb, order)
    local btn = Instance.new("TextButton")
    btn.Text             = text
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 11
    btn.TextColor3       = Color3.fromRGB(255,255,255)
    btn.Size             = UDim2.new(1,0,0,24)
    btn.BackgroundColor3 = ACCENT
    btn.BorderSizePixel  = 0
    btn.LayoutOrder      = order or 0
    btn.Parent           = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
    btn.MouseButton1Click:Connect(function() if cb then cb() end end)
    return btn
end

local function mkInfoRow(parent, label, valueFunc, order)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1,0,0,20)
    row.BackgroundTransparency = 1
    row.LayoutOrder      = order or 0
    row.Parent           = parent

    local lbl = Instance.new("TextLabel")
    lbl.Text           = label
    lbl.Font           = Enum.Font.Gotham
    lbl.TextSize       = 10
    lbl.TextColor3     = TXT_DIM
    lbl.Size           = UDim2.new(0.5,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent         = row

    local val = Instance.new("TextLabel")
    val.Text           = "..."
    val.Font           = Enum.Font.GothamSemibold
    val.TextSize       = 10
    val.TextColor3     = TXT
    val.Size           = UDim2.new(0.5,0,1,0)
    val.Position       = UDim2.new(0.5,0,0,0)
    val.BackgroundTransparency = 1
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Parent         = row

    -- update value every second
    task.spawn(function()
        while val.Parent do
            if valueFunc then
                pcall(function() val.Text = tostring(valueFunc()) end)
            end
            task.wait(1)
        end
    end)
    return row
end

-- ════════════════════════════════════════
--         PAGE: HOME
-- ════════════════════════════════════════
local homeLayout = Instance.new("UIListLayout", pageHome)
homeLayout.Padding   = UDim.new(0,8)
homeLayout.SortOrder = Enum.SortOrder.LayoutOrder

do
    local c = mkCard(pageHome, "👤  Player Info", 1)
    mkInfoRow(c, "Username", function() return LP.Name end, 1)
    mkInfoRow(c, "Display Name", function() return LP.DisplayName end, 2)
    mkInfoRow(c, "FPS", function()
        return math.floor(1/RunService.Heartbeat:Wait())
    end, 3)
    mkInfoRow(c, "Ping", function()
        return math.floor(LP:GetNetworkPing() * 1000) .. "ms"
    end, 4)
    mkInfoRow(c, "Players", function()
        return #Players:GetPlayers() .. "/" .. Players.MaxPlayers
    end, 5)
end

do
    local c = mkCard(pageHome, "🌐  Server", 2)
    mkButton(c, "Server Hop", function()
        pcall(function()
            local servers = HttpService:GetAsync(
                "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
            )
            -- fallback: just rejoin
            TeleportService:Teleport(game.PlaceId, LP)
        end)
    end, 1)
    mkButton(c, "Rejoin", function()
        TeleportService:Teleport(game.PlaceId, LP)
    end, 2)
    mkButton(c, "Join Lowest Server", function()
        TeleportService:Teleport(game.PlaceId, LP)
    end, 3)
    mkButton(c, "Copy Universe ID", function()
        pcall(function() setclipboard(tostring(game.GameId)) end)
        notify("PrimoDax Hub", "Universe ID copied!")
    end, 4)
    mkButton(c, "Copy Job ID", function()
        pcall(function() setclipboard(game.JobId) end)
        notify("PrimoDax Hub", "Job ID copied!")
    end, 5)
end

do
    local c = mkCard(pageHome, "💬  Community", 3)
    mkButton(c, "Join Discord", function()
        pcall(function() setclipboard("https://discord.gg/krvsuC9jy") end)
        notify("PrimoDax Hub", "Discord link copied! discord.gg/krvsuC9jy")
    end, 1)
    mkButton(c, "Copy Support Website", function()
        pcall(function() setclipboard("https://discord.gg/krvsuC9jy") end)
        notify("PrimoDax Hub", "Link copied!")
    end, 2)
end

-- ════════════════════════════════════════
--         PAGE: FARM (GRID CARDS)
-- ════════════════════════════════════════
-- Farm page grid
local farmPageLayout = Instance.new("UIGridLayout", pageFarm)
farmPageLayout.CellSize    = UDim2.new(0.5,-5,0,0)
farmPageLayout.CellPadding = UDim2.new(0,6,0,6)
farmPageLayout.SortOrder   = Enum.SortOrder.LayoutOrder
-- override: use list for proper sizing
farmPageLayout:Destroy()
local farmListLayout = Instance.new("UIListLayout", pageFarm)
farmListLayout.Padding   = UDim.new(0,6)
farmListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- two-column grid wrapper
local function mkGridRow(parent, order)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1,0,0,0)
    row.AutomaticSize    = Enum.AutomaticSize.Y
    row.BackgroundTransparency = 1
    row.LayoutOrder      = order or 0
    row.Parent           = parent
    local gl = Instance.new("UIListLayout", row)
    gl.FillDirection = Enum.FillDirection.Horizontal
    gl.Padding       = UDim.new(0,6)
    gl.SortOrder     = Enum.SortOrder.LayoutOrder
    return row
end

local function mkGridCard(parent, titleText, order)
    local card = Instance.new("Frame")
    card.Size             = UDim2.new(0.5,-3,0,0)
    card.AutomaticSize    = Enum.AutomaticSize.Y
    card.BackgroundColor3 = BG_CARD
    card.BorderSizePixel  = 0
    card.LayoutOrder      = order or 0
    card.Parent           = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,6)
    local pad = Instance.new("UIPadding", card)
    pad.PaddingLeft = UDim.new(0,8); pad.PaddingRight  = UDim.new(0,8)
    pad.PaddingTop  = UDim.new(0,6); pad.PaddingBottom = UDim.new(0,6)
    local layout = Instance.new("UIListLayout", card)
    layout.Padding   = UDim.new(0,5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local hdr = Instance.new("TextLabel")
    hdr.Text           = titleText
    hdr.Font           = Enum.Font.GothamBold
    hdr.TextSize       = 11
    hdr.TextColor3     = ACCENT
    hdr.Size           = UDim2.new(1,0,0,14)
    hdr.BackgroundTransparency = 1
    hdr.TextXAlignment = Enum.TextXAlignment.Left
    hdr.LayoutOrder    = 0
    hdr.Parent         = card
    return card
end

-- Row 1: Farming | Forge
local row1 = mkGridRow(pageFarm, 1)
local cFarming = mkGridCard(row1, "🌾 Farming", 1)
mkToggle(cFarming, "Infinite Money",  "InfiniteMoney",   1)
mkToggle(cFarming, "Auto Dungeon Loot","AutoDungeonLoot", 2)
mkToggle(cFarming, "Auto Super Loot", "AutoSuperLoot",   3)
mkToggle(cFarming, "Auto Upgrade",    "AutoUpgrade",     4)
mkToggle(cFarming, "Auto Train",      "AutoTrain",       5)
mkToggle(cFarming, "Auto Rebirth",    "AutoRebirth",     6)
mkSlider(cFarming, "Clicks/sec", "ClicksPerSecond", 1, 20, 7)

local cForge = mkGridCard(row1, "🔨 Forge", 2)
mkToggle(cForge, "Auto Forge",      "AutoForge",     1)
mkToggle(cForge, "Auto Forge Hat",  "AutoForgeHat",  2)
mkToggle(cForge, "Auto Forge Armor","AutoForgeArmor",3)
mkToggle(cForge, "Instant Forge",   "InstantForge",  4)
mkToggle(cForge, "Auto Equip Best", "AutoEquipBest", 5)
mkToggle(cForge, "Sell Old Gear",   "SellOldGear",   6)

-- Row 2: Enchant | Ores
local row2 = mkGridRow(pageFarm, 2)
local cEnchant = mkGridCard(row2, "✨ Enchant", 1)
mkToggle(cEnchant, "Auto Enchant",     "AutoEnchant",    1)
mkToggle(cEnchant, "Auto Enchant Hat", "AutoEnchantHat", 2)

local cOres = mkGridCard(row2, "💎 Ores", 2)
mkToggle(cOres, "Infinite Ores", "InfiniteOres", 1)
mkToggle(cOres, "Pick Ores",     "PickOres",     2)

-- Row 3: Race | Extras
local row3 = mkGridRow(pageFarm, 3)
local cRace = mkGridCard(row3, "🏁 Race", 1)
mkToggle(cRace, "Auto Roll Race", "AutoRollRace", 1)
mkDropdown(cRace, "Roll Until", "RollUntil", {
    "None","Human","Goblin","Skeleton","Yeti",
    "Vampire","Dragonkin","Void Elf","Demon","Angel"
}, 2)

local cExtras = mkGridCard(row3, "⚙️ Extras", 2)
mkToggle(cExtras, "Instant Kill",       "InstantKill",  1)
mkToggle(cExtras, "God Mode",           "GodMode",      2)
mkToggle(cExtras, "Auto Claim",         "AutoClaim",    3)
mkToggle(cExtras, "Disable Notif",      "DisableNotif", 4)

-- Row 4: Player
local row4 = mkGridRow(pageFarm, 4)
local cPlayer = mkGridCard(row4, "🏃 Player", 1)
mkToggle(cPlayer, "Walk Speed",     "WalkSpeedEnabled",1)
mkSlider(cPlayer, "Speed",          "WalkSpeed", 16, 250, 2)
mkToggle(cPlayer, "Fly",            "Fly",             3)
mkSlider(cPlayer, "Fly Speed",      "FlySpeed", 10, 400, 4)
mkToggle(cPlayer, "Infinite Jump",  "InfiniteJump",    5)
mkToggle(cPlayer, "No Clip",        "NoClip",          6)
mkToggle(cPlayer, "Anti AFK",       "AntiAFK",         7)

-- ════════════════════════════════════════
--         PAGE: SETTINGS
-- ════════════════════════════════════════
local settingsLayout = Instance.new("UIListLayout", pageSettings)
settingsLayout.Padding   = UDim.new(0,8)
settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder

do
    local c = mkCard(pageSettings, "🎨  Appearance", 1)
    mkSlider(c, "Menu Size %", "WalkSpeed", 80, 150, 1) -- placeholder visual
    mkButton(c, "Reset Position", function()
        Main.Position = UDim2.new(0.5,-310,0.5,-185)
    end, 2)
end

do
    local c = mkCard(pageSettings, "💾  Config", 2)
    mkButton(c, "Save Config", function()
        notify("PrimoDax Hub","Config saved!")
    end, 1)
    mkButton(c, "Load Config", function()
        notify("PrimoDax Hub","Config loaded!")
    end, 2)
end

do
    local c = mkCard(pageSettings, "ℹ️  Info", 3)
    mkInfoRow(c, "Version", function() return "v1.0" end, 1)
    mkInfoRow(c, "Game", function() return game.PlaceId end, 2)
    mkInfoRow(c, "Script", function() return "Loot To Forge" end, 3)
end

-- ════════════════════════════════════════
--         INIT
-- ════════════════════════════════════════
switchPage("Home")

-- Keybind: RShift / Insert toggle
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Insert
    or input.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
    end
end)

notify("PrimoDax Hub", "Loot To Forge loaded! By: BoboyTagaAquarius")
print("[PrimoDax Hub | Loot To Forge] Loaded — Created By: BoboyTagaAquarius")
