--[[
PRIMODAX HUB | UI FEATURE REPLICA
Created By: BoboyTagaAquarius
Features matched from screenshots (red-circled elements replaced with custom branding).
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer
if not LP then return end

-- Cleanup
local function getGui()
    local candidates = {}
    pcall(function() if typeof(gethui) == "function" then table.insert(candidates, gethui()) end end)
    table.insert(candidates, CoreGui)
    pcall(function() local pg = LP:FindFirstChild("PlayerGui") if pg then table.insert(candidates, pg) end end)
    for _, p in ipairs(candidates) do
        if p then local old = p:FindFirstChild("PrimoDaxUI") if old then old:Destroy() end end
    end
    local ok, hui = pcall(function() return typeof(gethui) == "function" and gethui() or nil end)
    if ok and hui then return hui end
    local okCore = pcall(function() local _ = CoreGui.Name end)
    if okCore then return CoreGui end
    return LP:WaitForChild("PlayerGui")
end

local parent = getGui()

-- Colors matching the dark/purple theme
local C_BG = Color3.fromRGB(20, 20, 25)
local C_SIDEBAR = Color3.fromRGB(28, 28, 34)
local C_CARD = Color3.fromRGB(35, 35, 42)
local C_TEXT = Color3.fromRGB(230, 230, 235)
local C_DIM = Color3.fromRGB(150, 150, 160)
local C_ACCENT = Color3.fromRGB(180, 150, 255) -- Purple accent

local Gui = Instance.new("ScreenGui")
Gui.Name = "PrimoDaxUI"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = parent

-- Helpers
local function corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = obj
end

local function stroke(obj, col, thick)
    local s = Instance.new("UIStroke")
    s.Color = col or C_CARD
    s.Thickness = thick or 1
    s.Parent = obj
end

local function makeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Floating Icon
local FloatIcon = Instance.new("TextButton")
FloatIcon.Name = "FloatIcon"
FloatIcon.Size = UDim2.fromOffset(50, 50)
FloatIcon.Position = UDim2.new(0, 20, 0.4, 0)
FloatIcon.BackgroundColor3 = C_SIDEBAR
FloatIcon.Text = "P"
FloatIcon.TextColor3 = C_ACCENT
FloatIcon.Font = Enum.Font.GothamBold
FloatIcon.TextSize = 24
FloatIcon.BorderSizePixel = 0
FloatIcon.Parent = Gui
corner(FloatIcon, 10)
stroke(FloatIcon, C_ACCENT, 1)

-- Main Window
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.Size = UDim2.fromOffset(500, 350)
Main.BackgroundColor3 = C_BG
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Visible = false
Main.Parent = Gui
corner(Main, 10)
stroke(Main, C_CARD, 1)

-- Topbar (Draggable)
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = C_SIDEBAR
TopBar.BorderSizePixel = 0
TopBar.Parent = Main
makeDraggable(Main, TopBar)

-- TITLE
local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromOffset(15, 0)
Title.Size = UDim2.new(0.5, 0, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "PrimoDax Hub" 
Title.TextColor3 = C_ACCENT
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- Tabs Container
local TabsContainer = Instance.new("Frame")
TabsContainer.BackgroundTransparency = 1
TabsContainer.AnchorPoint = Vector2.new(1, 0)
TabsContainer.Position = UDim2.new(1, -15, 0, 0)
TabsContainer.Size = UDim2.new(0.5, 0, 1, 0)
TabsContainer.Parent = TopBar

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.Padding = UDim.new(0, 10)
TabLayout.Parent = TabsContainer

local Pages = {}
local TabButtons = {}

local function CreateTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 0, 1, 0)
    btn.AutomaticSize = Enum.AutomaticSize.X
    btn.BackgroundTransparency = 1
    btn.Text = name
    btn.TextColor3 = C_DIM
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = TabsContainer
    
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 5)
    pad.PaddingRight = UDim.new(0, 5)
    pad.Parent = btn
    
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, 0, 1, -40)
    page.Position = UDim2.fromOffset(0, 40)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = C_ACCENT
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new()
    page.Visible = false
    page.Parent = Main
    
    local pad2 = Instance.new("UIPadding")
    pad2.PaddingTop = UDim.new(0, 10)
    pad2.PaddingBottom = UDim.new(0, 10)
    pad2.PaddingLeft = UDim.new(0, 10)
    pad2.PaddingRight = UDim.new(0, 10)
    pad2.Parent = page
    
    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.48, 0, 0, 200)
    grid.CellPadding = UDim2.new(0.04, 0, 0, 10)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = page
    
    Pages[name] = page
    TabButtons[name] = btn
    
    btn.Activated:Connect(function()
        for n, p in pairs(Pages) do p.Visible = (n == name) end
        for n, b in pairs(TabButtons) do
            b.TextColor3 = (n == name) and C_ACCENT or C_DIM
        end
    end)
end

local function CreateSection(parentPage, title, order)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = C_CARD
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order
    frame.Parent = parentPage
    corner(frame, 8)
    
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = frame
    
    local vList = Instance.new("UIListLayout")
    vList.Padding = UDim.new(0, 8)
    vList.SortOrder = Enum.SortOrder.LayoutOrder
    vList.Parent = frame
    
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 20)
    header.BackgroundTransparency = 1
    header.LayoutOrder = 0
    header.Parent = frame
    
    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size = UDim2.new(1, 0, 1, 0)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.Text = title
    titleLbl.TextColor3 = C_TEXT
    titleLbl.TextSize = 12
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = header
    
    return frame
end

local function CreateToggle(parent, label, order)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 24)
    container.BackgroundTransparency = 1
    container.LayoutOrder = order
    container.Parent = parent
    
    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.new(1, -40, 1, 0)
    text.Font = Enum.Font.Gotham
    text.Text = label
    text.TextColor3 = C_TEXT
    text.TextSize = 11
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = container
    
    local btn = Instance.new("TextButton")
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, 0, 0.5, 0)
    btn.Size = UDim2.fromOffset(30, 16)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = container
    corner(btn, 8)
    
    local circle = Instance.new("Frame")
    circle.Size = UDim2.fromOffset(12, 12)
    circle.Position = UDim2.fromOffset(2, 2)
    circle.BackgroundColor3 = Color3.new(1, 1, 1)
    circle.Parent = btn
    corner(circle, 6)
    
    local toggled = false
    btn.Activated:Connect(function()
        toggled = not toggled
        TweenService:Create(circle, TweenInfo.new(0.1), {
            Position = toggled and UDim2.new(1, -14, 0, 2) or UDim2.fromOffset(2, 2)
        }):Play()
        TweenService:Create(btn, TweenInfo.new(0.1), {
            BackgroundColor3 = toggled and C_ACCENT or Color3.fromRGB(50, 50, 60)
        }):Play()
    end)
end

local function CreateDropdown(parent, label, options, order)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 24)
    container.BackgroundTransparency = 1
    container.LayoutOrder = order
    container.Parent = parent
    
    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.new(1, -60, 1, 0)
    text.Font = Enum.Font.Gotham
    text.Text = label
    text.TextColor3 = C_TEXT
    text.TextSize = 11
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = container
    
    local btn = Instance.new("TextButton")
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, 0, 0.5, 0)
    btn.Size = UDim2.fromOffset(50, 20)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    btn.Text = options[1] or "None"
    btn.TextColor3 = C_TEXT
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 10
    btn.Parent = container
    corner(btn, 4)
end

local function CreateTextInput(parent, label, placeholder, order)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 24)
    container.BackgroundTransparency = 1
    container.LayoutOrder = order
    container.Parent = parent
    
    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.new(1, -120, 1, 0)
    text.Font = Enum.Font.Gotham
    text.Text = label
    text.TextColor3 = C_TEXT
    text.TextSize = 11
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = container
    
    local box = Instance.new("TextBox")
    box.AnchorPoint = Vector2.new(1, 0.5)
    box.Position = UDim2.new(1, 0, 0.5, 0)
    box.Size = UDim2.fromOffset(110, 20)
    box.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    box.PlaceholderText = placeholder
    box.Text = ""
    box.TextColor3 = C_TEXT
    box.PlaceholderColor3 = C_DIM
    box.Font = Enum.Font.Gotham
    box.TextSize = 10
    box.Parent = container
    corner(box, 4)
end

-- Setup Tabs
CreateTab("Home")
CreateTab("Farm")
CreateTab("Settings")

-- HOME PAGE FEATURES
local homePage = Pages["Home"]
local userSec = CreateSection(homePage, "USER INFO", 1)
CreateToggle(userSec, "Free", 1) 
CreateTextInput(userSec, "Name", "Display Name", 2)
local serverSec = CreateSection(homePage, "SERVER INFO", 2)
CreateTextInput(serverSec, "Job ID", "Job ID", 1)
local actionsSec = CreateSection(homePage, "ACTIONS", 3)
local rejoinBtn = Instance.new("TextButton")
rejoinBtn.Size = UDim2.new(1, 0, 0, 24)
rejoinBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
rejoinBtn.Text = "Rejoin Server"
rejoinBtn.TextColor3 = C_TEXT
rejoinBtn.Font = Enum.Font.Gotham
rejoinBtn.TextSize = 11
rejoinBtn.LayoutOrder = 1
rejoinBtn.Parent = actionsSec
corner(rejoinBtn, 4)

local welcomeSec = CreateSection(homePage, "INFO", 4)
local welcomeLbl = Instance.new("TextLabel")
welcomeLbl.Size = UDim2.new(1, 0, 0, 30)
welcomeLbl.BackgroundTransparency = 1
welcomeLbl.Font = Enum.Font.GothamBold
welcomeLbl.Text = "Welcome to PrimoDax Hub\nCreated By: BoboyTagaAquarius"
welcomeLbl.TextColor3 = C_ACCENT
welcomeLbl.TextSize = 12
welcomeLbl.TextWrapped = true
welcomeLbl.LayoutOrder = 1
welcomeLbl.Parent = welcomeSec

-- FARM PAGE FEATURES
local farmPage = Pages["Farm"]
local farmSec = CreateSection(farmPage, "FARMING", 1)
CreateToggle(farmSec, "Infinite Money", 1)
CreateToggle(farmSec, "Auto Dungeon Loot", 2)
CreateToggle(farmSec, "Auto Super Loot", 3)
CreateToggle(farmSec, "Auto Upgrade", 4)
CreateToggle(farmSec, "Auto Train", 5)
CreateToggle(farmSec, "Auto Rebirth", 6)

local forgeSec = CreateSection(farmPage, "FORGE", 2)
CreateToggle(forgeSec, "Auto Forge", 1)
CreateToggle(forgeSec, "Auto Forge Hat", 2)
CreateToggle(forgeSec, "Auto Forge Armor", 3)
CreateToggle(forgeSec, "Instant Forge", 4)
CreateToggle(forgeSec, "Auto Equip Best", 5)
CreateToggle(forgeSec, "Sell Old Gear", 6)

local enchSec = CreateSection(farmPage, "ENCHANT", 3)
CreateToggle(enchSec, "Auto Enchant", 1)
CreateToggle(enchSec, "Auto Enchant Hat", 2)

local oresSec = CreateSection(farmPage, "ORES", 4)
CreateToggle(oresSec, "Infinite Ores", 1)
CreateDropdown(oresSec, "Pick Ores", {"None", "Common", "Rare", "Legendary"}, 2)

local raceSec = CreateSection(farmPage, "RACE", 5)
CreateToggle(raceSec, "Auto Roll Race", 1)
CreateDropdown(raceSec, "Roll Until", {"None", "Human", "Goblin", "Skeleton", "Yeti", "Vampire"}, 2)

local extrasSec = CreateSection(farmPage, "EXTRAS", 6)
CreateToggle(extrasSec, "Instant Kill", 1)
CreateToggle(extrasSec, "God Mode", 2)
CreateToggle(extrasSec, "Auto Claim", 3)
CreateToggle(extrasSec, "Disable Notifications", 4)

-- SETTINGS PAGE FEATURES
local setPage = Pages["Settings"]
local menuSetSec = CreateSection(setPage, "MENU", 1)
CreateTextInput(menuSetSec, "Menu Keybind", "RSHIFT", 1)
CreateDropdown(menuSetSec, "Menu Size", {"100%", "90%", "80%", "70%"}, 2)

local themeSec = CreateSection(setPage, "THEME", 2)
CreateDropdown(themeSec, "Preset", {"Airflow", "Dark", "Light"}, 1)
CreateToggle(themeSec, "Smoke", 2)
CreateToggle(themeSec, "Muted Text", 3)
CreateToggle(themeSec, "Text Outline", 4)

local configSec = CreateSection(setPage, "CONFIGS", 3)
CreateTextInput(configSec, "Config Name", "no configs", 1)
local cBtnFrame = Instance.new("Frame")
cBtnFrame.Size = UDim2.new(1, 0, 0, 24)
cBtnFrame.BackgroundTransparency = 1
cBtnFrame.LayoutOrder = 2
cBtnFrame.Parent = configSec
local cBtnLayout = Instance.new("UIListLayout")
cBtnLayout.FillDirection = Enum.FillDirection.Horizontal
cBtnLayout.Padding = UDim.new(0, 5)
cBtnLayout.Parent = cBtnFrame

local function makeSmallBtn(text, p)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.33, -4, 1, 0)
    b.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    b.Text = text
    b.TextColor3 = C_TEXT
    b.Font = Enum.Font.Gotham
    b.TextSize = 10
    b.Parent = p
    corner(b, 4)
end
makeSmallBtn("Create", cBtnFrame)
makeSmallBtn("Save", cBtnFrame)
makeSmallBtn("Load", cBtnFrame)

-- Default Tab
Pages["Home"].Visible = true
TabButtons["Home"].TextColor3 = C_ACCENT

-- Toggle logic
local function ToggleMenu()
    Main.Visible = not Main.Visible
end
FloatIcon.Activated:Connect(ToggleMenu)

print("[PrimoDax Hub] UI Replica Loaded — Created By: BoboyTagaAquarius. Join our discord server: https://discord.gg/wqAReaB3d")
