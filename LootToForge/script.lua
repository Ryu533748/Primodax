--[[
PRIMODAX HUB | LOOT TO FORGE
Exact UI Layout Replica (Airflow Style)
Created By: BoboyTagaAquarius
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

-- Colors
local C_BG = Color3.fromRGB(22, 22, 27)
local C_TOPBAR = Color3.fromRGB(30, 30, 36)
local C_SECTION = Color3.fromRGB(30, 30, 36)
local C_TEXT = Color3.fromRGB(240, 240, 245)
local C_DIM = Color3.fromRGB(150, 150, 160)
local C_ACCENT = Color3.fromRGB(200, 180, 255)

local Gui = Instance.new("ScreenGui")
Gui.Name = "PrimoDaxUI"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = parent

local function corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = obj
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
FloatIcon.BackgroundColor3 = C_BG
FloatIcon.Text = "P"
FloatIcon.TextColor3 = C_ACCENT
FloatIcon.Font = Enum.Font.GothamBold
FloatIcon.TextSize = 24
FloatIcon.BorderSizePixel = 0
FloatIcon.Parent = Gui
corner(FloatIcon, 8)

-- Main Window
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.Size = UDim2.fromOffset(550, 380)
Main.BackgroundColor3 = C_BG
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Visible = false
Main.Parent = Gui
corner(Main, 8)

-- Topbar (Draggable)
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = C_TOPBAR
TopBar.BorderSizePixel = 0
TopBar.Parent = Main
makeDraggable(Main, TopBar)

-- Tabs Container (Aligned Right like screenshots)
local TabsContainer = Instance.new("Frame")
TabsContainer.BackgroundTransparency = 1
TabsContainer.AnchorPoint = Vector2.new(1, 0)
TabsContainer.Position = UDim2.new(1, -15, 0, 0)
TabsContainer.Size = UDim2.new(0.6, 0, 1, 0)
TabsContainer.Parent = TopBar

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.Padding = UDim.new(0, 15)
TabLayout.Parent = TabsContainer

-- Left Title (Red circled area replaced)
local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromOffset(15, 0)
Title.Size = UDim2.new(0.3, 0, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "PrimoDax Hub" 
Title.TextColor3 = C_ACCENT
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local Pages = {}
local TabButtons = {}

local function CreateTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 0, 1, 0)
    btn.AutomaticSize = Enum.AutomaticSize.X
    btn.BackgroundTransparency = 1
    btn.Text = name
    btn.TextColor3 = C_DIM
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = TabsContainer
    
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
    
    -- Padding
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = page
    
    -- 2-Column Grid exactly like screenshots
    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.48, 0, 0, 180) -- Fixed height for sections
    grid.CellPadding = UDim2.new(0.04, 0, 0, 8)
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

-- Section Builder
local function CreateSection(parentPage, title, order)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = C_SECTION
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order
    frame.Parent = parentPage
    corner(frame, 6)
    
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

-- Toggle with working logic
local function CreateToggle(parent, label, order)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 22)
    container.BackgroundTransparency = 1
    container.LayoutOrder = order
    container.Parent = parent
    
    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.new(1, -30, 1, 0)
    text.Font = Enum.Font.Gotham
    text.Text = label
    text.TextColor3 = C_TEXT
    text.TextSize = 11
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = container
    
    local btn = Instance.new("TextButton")
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, 0, 0.5, 0)
    btn.Size = UDim2.fromOffset(28, 14)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = container
    corner(btn, 7)
    
    local circle = Instance.new("Frame")
    circle.Size = UDim2.fromOffset(10, 10)
    circle.Position = UDim2.fromOffset(2, 2)
    circle.BackgroundColor3 = Color3.new(1, 1, 1)
    circle.Parent = btn
    corner(circle, 5)
    
    local toggled = false
    btn.Activated:Connect(function()
        toggled = not toggled
        -- ACTUAL FUNCTIONALITY LOGIC HERE (Prints for now as we don't have game remotes)
        print("[PrimoDax] Toggle:", label, "is now", toggled)
        
        TweenService:Create(circle, TweenInfo.new(0.1), {
            Position = toggled and UDim2.new(1, -12, 0, 2) or UDim2.fromOffset(2, 2)
        }):Play()
        TweenService:Create(btn, TweenInfo.new(0.1), {
            BackgroundColor3 = toggled and C_ACCENT or Color3.fromRGB(50, 50, 60)
        }):Play()
    end)
end

local function CreateDropdown(parent, label, options, order)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 22)
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
    btn.Size = UDim2.fromOffset(50, 18)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    btn.Text = options[1] or "None"
    btn.TextColor3 = C_TEXT
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 10
    btn.Parent = container
    corner(btn, 4)
    
    -- Simple cycling dropdown logic
    local idx = 1
    btn.Activated:Connect(function()
        idx = idx + 1
        if idx > #options then idx = 1 end
        btn.Text = options[idx]
        print("[PrimoDax] Dropdown", label, "set to", btn.Text)
    end)
end

local function CreateTextInput(parent, label, placeholder, order)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 22)
    container.BackgroundTransparency = 1
    container.LayoutOrder = order
    container.Parent = parent
    
    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.new(1, -110, 1, 0)
    text.Font = Enum.Font.Gotham
    text.Text = label
    text.TextColor3 = C_TEXT
    text.TextSize = 11
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = container
    
    local box = Instance.new("TextBox")
    box.AnchorPoint = Vector2.new(1, 0.5)
    box.Position = UDim2.new(1, 0, 0.5, 0)
    box.Size = UDim2.fromOffset(100, 18)
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

-- ==========================================
-- HOME PAGE (Features matched to Screenshot 6)
-- ==========================================
local homePage = Pages["Home"]
local homeSec1 = CreateSection(homePage, "User Info", 1)
CreateTextInput(homeSec1, "Name", "Not logged in", 1)
CreateToggle(homeSec1, "Lifetime (Free)", 2)

local homeSec2 = CreateSection(homePage, "Game Info", 2)
CreateTextInput(homeSec2, "Job ID", "...", 1)
CreateToggle(homeSec2, "Copy Job ID", 2)

local homeSec3 = CreateSection(homePage, "Actions", 3)
local rejoinBtn = Instance.new("TextButton")
rejoinBtn.Size = UDim2.new(1, 0, 0, 20)
rejoinBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
rejoinBtn.Text = "Rejoin Server"
rejoinBtn.TextColor3 = C_TEXT
rejoinBtn.Font = Enum.Font.Gotham
rejoinBtn.TextSize = 10
rejoinBtn.LayoutOrder = 1
rejoinBtn.Parent = homeSec3
corner(rejoinBtn, 4)

-- ==========================================
-- FARM PAGE (Features matched to Screenshot 2)
-- ==========================================
local farmPage = Pages["Farm"]

-- Column 1 equivalent
local farmSec1 = CreateSection(farmPage, "Farming", 1)
CreateToggle(farmSec1, "Infinite Money", 1)
CreateToggle(farmSec1, "Auto Dungeon Loot", 2)
CreateToggle(farmSec1, "Auto Super Loot", 3)
CreateToggle(farmSec1, "Auto Upgrade", 4)
CreateToggle(farmSec1, "Auto Train", 5)
CreateToggle(farmSec1, "Auto Rebirth", 6)

local farmSec2 = CreateSection(farmPage, "Enchant", 2)
CreateToggle(farmSec2, "Auto Enchant", 1)
CreateToggle(farmSec2, "Auto Enchant Hat", 2)
CreateToggle(farmSec2, "Auto Enchant Weapon", 3)

local farmSec3 = CreateSection(farmPage, "Race", 3)
CreateToggle(farmSec3, "Auto Roll Race", 1)
CreateDropdown(farmSec3, "Roll Until", {"None", "Human", "Goblin", "Skeleton", "Yeti", "Vampire"}, 2)

-- Column 2 equivalent
local farmSec4 = CreateSection(farmPage, "Forge", 4)
CreateToggle(farmSec4, "Auto Forge", 1)
CreateToggle(farmSec4, "Auto Forge Hat", 2)
CreateToggle(farmSec4, "Auto Forge Armor", 3)
CreateToggle(farmSec4, "Instant Forge", 4)
CreateToggle(farmSec4, "Auto Equip Best", 5)
CreateToggle(farmSec4, "Sell Old Gear", 6)

local farmSec5 = CreateSection(farmPage, "Ores", 5)
CreateToggle(farmSec5, "Infinite Ores", 1)
CreateDropdown(farmSec5, "Pick Ores", {"None", "Common", "Rare", "Legendary"}, 2)

local farmSec6 = CreateSection(farmPage, "Extras", 6)
CreateToggle(farmSec6, "Instant Kill", 1)
CreateToggle(farmSec6, "God Mode", 2)
CreateToggle(farmSec6, "Auto Claim", 3)
CreateToggle(farmSec6, "Disable Notifications", 4)

-- ==========================================
-- SETTINGS PAGE (Features matched to Screenshot 1)
-- ==========================================
local setPage = Pages["Settings"]

local setSec1 = CreateSection(setPage, "Menu", 1)
CreateTextInput(setSec1, "Menu Keybind", "RSHIFT", 1)
CreateDropdown(setSec1, "Menu Size", {"100%", "90%", "80%"}, 2)
CreateTextInput(setSec1, "Menu Color", "#FFFFFF", 3)

local setSec2 = CreateSection(setPage, "Themes", 2)
CreateDropdown(setSec2, "Preset", {"Airflow", "Dark", "Light"}, 1)
CreateTextInput(setSec2, "Theme Name", "None", 2)

local setSec3 = CreateSection(setPage, "Configs", 3)
CreateTextInput(setSec3, "Config Name", "no configs", 1)
CreateDropdown(setSec3, "AutoLoad", {"None", "Default", "Custom"}, 2)

local cBtnFrame = Instance.new("Frame")
cBtnFrame.Size = UDim2.new(1, 0, 0, 20)
cBtnFrame.BackgroundTransparency = 1
cBtnFrame.LayoutOrder = 3
cBtnFrame.Parent = setSec3
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
    b.Activated:Connect(function() print("[PrimoDax] Config Action:", text) end)
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

-- Keybind Toggle (RightShift / Insert)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.Insert then
        ToggleMenu()
    end
end)

print("[PrimoDax Hub] UI Replica Loaded — Created By: BoboyTagaAquarius. Join our discord server: https://discord.gg/wqAReaB3d")
