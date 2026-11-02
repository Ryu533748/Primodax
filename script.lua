-- ██████╗ ██████╗ ██╗███╗   ███╗ ██████╗ ██████╗  █████╗ ██╗  ██╗
-- ██╔══██╗██╔══██╗██║████╗ ████║██╔═══██╗██╔══██╗██╔══██╗╚██╗██╔╝
-- ██████╔╝██████╔╝██║██╔████╔██║██║   ██║██║  ██║███████║ ╚███╔╝
-- ██╔═══╝ ██╔══██╗██║██║╚██╔╝██║██║   ██║██║  ██║██╔══██║ ██╔██╗
-- ██║     ██║  ██║██║██║ ╚═╝ ██║╚██████╔╝██████╔╝██║  ██║██╔╝ ██╗
-- ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
-- PRIMODAX VGRANT v8.0 | TABBED UI | MOBILE OPTIMIZED

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

-- ============ CONFIG ============
local CFG = {
    SilentAim = false, WallCheck = false, TargetPart = "HumanoidRootPart", Priority = "Crosshair",
    UseFOV = true, FOVMode = "Dynamic", FOVRadius = 150, FOVThickness = 2, MaxDistance = 500, SnapLine = false, SnapThickness = 2,
    RageBot = false, AutoFire = false, RageTarget = "Head",
    NoRecoil = false, NoSpread = false, GodMode = false, 
    InfiniteJump = false, AutoSprint = false, SprintSpeed = 20,
    ESPEnabled = false, GunESPEnabled = false, AutoPickup = false, PickupPriority = "Random"
}

-- ============ UTILS ============
local function getChar(p) return p and p.Character end
local function getHum(p) local c = getChar(p) return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot(p) local c = getChar(p) return c and c:FindFirstChild("HumanoidRootPart") end
local function getPart(p, n) local c = getChar(p) return c and c:FindFirstChild(n) end
local function isAlive(p) local h = getHum(p) return h and h.Health > 0 end

-- ============ FEATURES (LOGIC) ============
RunService.Heartbeat:Connect(function()
    if not CFG.GodMode then return end
    local hum = getHum(LP)
    if hum and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
end)

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = CFG.FOVThickness; fovCircle.Color = Color3.fromRGB(255, 255, 255); fovCircle.Filled = false; fovCircle.Visible = true; fovCircle.Radius = CFG.FOVRadius

local activeTarget = nil
local function getTarget()
    local center = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    local bestTarget, bDist = nil, CFG.FOVRadius
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isAlive(p) then
            local part = getPart(p, CFG.TargetPart)
            if part then
                local screenPos, onScreen = Cam:WorldToViewportPoint(part.Position)
                local dist = (getRoot(LP).Position - part.Position).Magnitude
                if onScreen and dist <= CFG.MaxDistance then
                    local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist2D < bDist then bestTarget = p; bDist = dist2D end
                end
            end
        end
    end
    return bestTarget
end

RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    fovCircle.Radius = CFG.FOVRadius
    fovCircle.Thickness = CFG.FOVThickness
    fovCircle.Visible = CFG.UseFOV
    activeTarget = getTarget()
end)

-- ============ TELEPORT TO BAG ============
local function findMyBag()
    local myName = LP.Name:lower(); local myId = tostring(LP.UserId)
    local bestBag, bestDist = nil, math.huge; local myRoot = getRoot(LP)
    if not myRoot then return nil end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local n = (obj.Name or ""):lower()
        if n:find("bag") or n:find("loot") or n:find("drop") or n:find("corpse") then
            local ownerMatch = false
            if n:find(myName, 1, true) or n:find(myId, 1, true) then ownerMatch = true end
            if not ownerMatch then
                local ok, attr = pcall(function() return obj:GetAttribute("Owner") or obj:GetAttribute("UserId") end)
                if ok and attr and tostring(attr):lower() == myName then ownerMatch = true end
            end
            if ownerMatch then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
                if part then
                    local dist = (myRoot.Position - part.Position).Magnitude
                    if dist < bestDist then bestBag = part; bestDist = dist end
                end
            end
        end
    end
    return bestBag
end

local function doTeleportBag()
    local root = getRoot(LP)
    if root then
        local bag = findMyBag()
        if bag then root.CFrame = bag.CFrame + Vector3.new(0, 3, 0) end
    end
end

-- ============ UI SYSTEM (POTYZIUM STYLE) ============
if CoreGui:FindFirstChild("PrimodaxUI") then CoreGui:FindFirstChild("PrimodaxUI"):Destroy() end
local SG = Instance.new("ScreenGui")
SG.Name = "PrimodaxUI"; SG.ResetOnSpawn = false; SG.IgnoreGuiInset = true; SG.Parent = CoreGui

local MF = Instance.new("Frame")
MF.Size = UDim2.new(0, 500, 0, 300); MF.Position = UDim2.new(0.5, -250, 0.5, -150)
MF.BackgroundColor3 = Color3.fromRGB(15, 15, 15); MF.BorderSizePixel = 0; MF.Active = true; MF.Parent = SG
Instance.new("UICorner", MF).CornerRadius = UDim.new(0, 8)

-- Top Bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 30); TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20); TopBar.Parent = MF
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 1, 0); Title.Position = UDim2.new(0, 10, 0, 0); Title.BackgroundTransparency = 1
Title.Text = "Potyzium Hack | Primodax"; Title.TextColor3 = Color3.fromRGB(200, 200, 200); Title.Font = Enum.Font.GothamBold; Title.TextSize = 12; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Parent = TopBar

-- Sidebar (Tabs)
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 110, 1, -30); Sidebar.Position = UDim2.new(0, 0, 0, 30); Sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 15); Sidebar.Parent = MF

local function makeTab(name, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 30); btn.Position = UDim2.new(0, 5, 0, 5 + (order * 35)); btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25); btn.Text = "  " .. name; btn.TextColor3 = Color3.fromRGB(150, 150, 150); btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.Parent = Sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    return btn
end

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -115, 1, -35); Content.Position = UDim2.new(0, 110, 0, 30); Content.BackgroundTransparency = 1; Content.Parent = MF

-- Content Pages
local Pages = {}
local function makePage(name)
    local frame = Instance.new("ScrollingFrame")
    frame.Size = UDim2.new(1, 0, 1, 0); frame.BackgroundTransparency = 1; frame.ScrollBarThickness = 2; frame.AutomaticCanvasSize = Enum.AutomaticSize.Y; frame.Visible = false; frame.Parent = Content
    Pages[name] = frame
    return frame
end

local VisualPage = makePage("Visual")
local CombatPage = makePage("Combat")
local SettingsPage = makePage("UI Settings")

local function switchTab(name)
    for n, p in pairs(Pages) do p.Visible = (n == name) end
end

local tabVis = makeTab("Visual", 0); tabVis.MouseButton1Click:Connect(function() switchTab("Visual") end)
local tabCom = makeTab("Combat", 1); tabCom.MouseButton1Click:Connect(function() switchTab("Combat") end)
local tabSet = makeTab("UI Settings", 2); tabSet.MouseButton1Click:Connect(function() switchTab("UI Settings") end)

-- UI Helpers (Toggles, Sliders, Dropdowns)
local function makeToggle(name, key, parent, order, callback)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, -10, 0, 30); btn.BackgroundTransparency = 1; btn.Text = ""; btn.LayoutOrder = order; btn.Parent = parent
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -40, 1, 0); lbl.BackgroundTransparency = 1; lbl.Text = name; lbl.TextColor3 = Color3.fromRGB(200, 200, 200); lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = btn
    
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
    local frame = Instance.new("Frame"); frame.Size = UDim2.new(1, -10, 0, 40); frame.BackgroundTransparency = 1; frame.LayoutOrder = order; frame.Parent = parent
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, 0, 0, 15); lbl.BackgroundTransparency = 1; lbl.Text = name; lbl.TextColor3 = Color3.fromRGB(200, 200, 200); lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = frame
    local valLbl = Instance.new("TextLabel"); valLbl.Size = UDim2.new(1, 0, 0, 15); valLbl.BackgroundTransparency = 1; valLbl.Text = tostring(CFG[key]); valLbl.TextColor3 = Color3.fromRGB(100, 50, 200); valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 11; valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.Parent = frame
    
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
        CFG[key] = val; valLbl.Text = tostring(val); fill.Size = UDim2.new(rel, 0, 1, 0)
    end
    bar.MouseMoved:Connect(update)
    UserInputService.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then update(i.Position.X) end end)
end

local function makeDropdown(name, key, options, parent, order)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, -10, 0, 30); btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); btn.Text = ""; btn.LayoutOrder = order; btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -10, 1, 0); lbl.Position = UDim2.new(0, 5, 0, 0); lbl.BackgroundTransparency = 1; lbl.Text = name .. ": " .. CFG[key]; lbl.TextColor3 = Color3.fromRGB(200, 200, 200); lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = btn
    btn.MouseButton1Click:Connect(function()
        local curIdx = 1
        for i, v in ipairs(options) do if v == CFG[key] then curIdx = i; break end end
        CFG[key] = options[(curIdx % #options) + 1]
        lbl.Text = name .. ": " .. CFG[key]
    end)
end

-- Populate Visual Page
local visLayout = Instance.new("UIListLayout"); visLayout.Padding = UDim.new(0, 5); visLayout.Parent = VisualPage
makeToggle("Enable ESP", "ESPEnabled", VisualPage, 1)
makeToggle("Gun ESP", "GunESPEnabled", VisualPage, 2)
makeToggle("Auto Pickup", "AutoPickup", VisualPage, 3)

-- Populate Combat Page
local comLayout = Instance.new("UIListLayout"); comLayout.Padding = UDim.new(0, 5); comLayout.Parent = CombatPage
makeToggle("Silent Aim", "SilentAim", CombatPage, 1)
makeToggle("Wall Check", "WallCheck", CombatPage, 2)
makeDropdown("Target Part", "TargetPart", {"HumanoidRootPart", "Head"}, CombatPage, 3)
makeDropdown("Priority", "Priority", {"Crosshair", "Distance"}, CombatPage, 4)
makeToggle("Use FOV", "UseFOV", CombatPage, 5)
makeSlider("FOV Radius", "FOVRadius", 0, 800, CombatPage, 6)
makeSlider("FOV Thickness", "FOVThickness", 1, 10, CombatPage, 7)
makeSlider("Max Distance", "MaxDistance", 50, 5000, CombatPage, 8)
makeToggle("Snap Line", "SnapLine", CombatPage, 9)
makeSlider("Snap Thickness", "SnapThickness", 1, 10, CombatPage, 10)
makeToggle("Rage Bot", "RageBot", CombatPage, 11)
makeToggle("Auto Fire", "AutoFire", CombatPage, 12)
makeToggle("No Recoil", "NoRecoil", CombatPage, 13)
makeToggle("No Spread", "NoSpread", CombatPage, 14)

-- Populate UI Settings Page
local setLayout = Instance.new("UIListLayout"); setLayout.Padding = UDim.new(0, 5); setLayout.Parent = SettingsPage
makeToggle("GodMode (Semi)", "GodMode", SettingsPage, 1)
makeToggle("Infinite Jump", "InfiniteJump", SettingsPage, 2)
makeToggle("Auto Sprint", "AutoSprint", SettingsPage, 3)
local teleBtn = Instance.new("TextButton"); teleBtn.Size = UDim2.new(1, -10, 0, 30); teleBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 200); teleBtn.Text = "Teleport to Bag"; teleBtn.TextColor3 = Color3.fromRGB(255, 255, 255); teleBtn.Font = Enum.Font.GothamBold; teleBtn.LayoutOrder = 4; teleBtn.Parent = SettingsPage
Instance.new("UICorner", teleBtn).CornerRadius = UDim.new(0, 4)
teleBtn.MouseButton1Click:Connect(doTeleportBag)

-- Default Page
switchTab("Combat")

-- Draggable
local dragging, dragInput, dragStart, startPos
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
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

-- Expose toggle
local isOpen = true
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        isOpen = not isOpen
        MF.Visible = isOpen
    end
end)
