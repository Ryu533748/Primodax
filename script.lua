-- PrimoDax Hub | Vagrant Survival
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
    -- Combat
    SilentAim = false, WallCheck = false, TargetPart = "HumanoidRootPart", Priority = "Crosshair", AutoFire = false, VisibleCheck = false, RageTarget = "Head", MaxDistance = 500,
    Aimbot = false, AimbotSmooth = 15, FOVRange = 150,
    NoRecoil = false, NoSpread = false,
    -- Visual
    PlayerESP = false, NameESP = false, DistanceESP = false, HealthBar = false, Chams = false, GunESP = false,
    -- Player
    WalkSpeed = 16, FlySpeed = 60, IsFlying = false, InfiniteJump = false, AutoSprint = false, SprintSpeed = 22, NoClip = false, GodMode = false
}

-- ============ UTILS ============
local function getChar()  return LP.Character end
local function getRoot()  local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()   local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function isAlive(p) local h = p and p.Character and p.Character:FindFirstChildOfClass("Humanoid"); return h and h.Health > 0 end

-- ============ ESP ============
local espObjects = {}
local function createESP(player)
    if espObjects[player] or player == LP then return end
    local box = Drawing.new("Square")
    box.Thickness = 1; box.Color = Color3.fromRGB(255, 50, 50); box.Filled = false; box.Visible = false
    local name = Drawing.new("Text")
    name.Size = 14; name.Center = true; name.Outline = true; name.Color = Color3.fromRGB(255, 255, 255); name.Visible = false
    local dist = Drawing.new("Text")
    dist.Size = 12; dist.Center = true; dist.Outline = true; dist.Color = Color3.fromRGB(200, 200, 200); dist.Visible = false
    espObjects[player] = {Box = box, Name = name, Dist = dist}
end

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(p)
    if espObjects[p] then
        espObjects[p].Box:Remove(); espObjects[p].Name:Remove(); espObjects[p].Dist:Remove(); espObjects[p] = nil
    end
end)

RunService.RenderStepped:Connect(function()
    for player, esp in pairs(espObjects) do
        if CFG.PlayerESP and isAlive(player) then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local pos, onS = Cam:WorldToViewportPoint(head.Position)
                if onS then
                    esp.Box.Visible = true; esp.Box.Size = Vector2.new(40, 50)
                    esp.Box.Position = Vector2.new(pos.X - 20, pos.Y - 25)
                    esp.Name.Visible = CFG.NameESP; esp.Name.Text = player.Name
                    esp.Name.Position = Vector2.new(pos.X, pos.Y - 40)
                    local root = getRoot()
                    if root then
                        esp.Dist.Visible = CFG.DistanceESP
                        esp.Dist.Text = math.floor((root.Position - head.Position).Magnitude) .. "m"
                        esp.Dist.Position = Vector2.new(pos.X, pos.Y + 30)
                    end
                else
                    esp.Box.Visible = false; esp.Name.Visible = false; esp.Dist.Visible = false
                end
            end
        else
            esp.Box.Visible = false; esp.Name.Visible = false; esp.Dist.Visible = false
        end
    end
end)

-- ============ AIMBOT & FOV ============
local activeTarget = nil
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5
fovCircle.Color = Color3.fromRGB(170, 100, 255)
fovCircle.Filled = false
fovCircle.Visible = false

RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    fovCircle.Radius = CFG.FOVRange
    fovCircle.Visible = CFG.SilentAim or CFG.Aimbot
    
    local center = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    local bestT, bDist = nil, CFG.FOVRange
    
    if CFG.SilentAim or CFG.Aimbot then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and isAlive(p) then
                local tPart = p.Character:FindFirstChild(CFG.TargetPart)
                if tPart then
                    local sPos, onS = Cam:WorldToViewportPoint(tPart.Position)
                    if onS then
                        local dist2D = (Vector2.new(sPos.X, sPos.Y) - center).Magnitude
                        if dist2D < bDist then
                            if (root.Position - tPart.Position).Magnitude <= CFG.MaxDistance then
                                bestT = p; bDist = dist2D 
                            end
                        end
                    end
                end
            end
        end
    end
    activeTarget = bestT
    
    if CFG.Aimbot and activeTarget then
        local tPart = activeTarget.Character:FindFirstChild(CFG.TargetPart)
        if tPart then
            local targetCF = CFrame.new(Cam.CFrame.Position, tPart.Position)
            local smooth = math.clamp(1 - (CFG.AimbotSmooth / 100), 0.05, 1)
            Cam.CFrame = Cam.CFrame:Lerp(targetCF, smooth)
        end
    end
end)

-- Silent Aim Hook (Safe Mode)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    pcall(function()
        local method = getnamecallmethod()
        local args = { ... }
        
        if CFG.SilentAim and (method == "FireServer" or method == "InvokeServer") then
            if activeTarget and isAlive(activeTarget) then
                local targetPart = activeTarget.Character:FindFirstChild(CFG.TargetPart)
                if targetPart then
                    for i, v in ipairs(args) do
                        if typeof(v) == "Vector3" then args[i] = targetPart.Position
                        elseif typeof(v) == "CFrame" then args[i] = CFrame.lookAt(Cam.CFrame.Position, targetPart.Position)
                        elseif typeof(v) == "Instance" and v:IsA("BasePart") then args[i] = targetPart end
                    end
                end
            end
        end
        return oldNamecall(self, table.unpack(args))
    end)
end)

-- ============ CORE FEATURES ============
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
    pcall(function()
        local root = getRoot(); local hum = getHum(); local char = getChar()
        if not root or not hum or not char then return end
        
        if CFG.GodMode and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
        
        if CFG.AutoSprint then
            if hum.WalkSpeed < CFG.SprintSpeed then hum.WalkSpeed = CFG.SprintSpeed end
        else
            if hum.WalkSpeed == CFG.SprintSpeed then hum.WalkSpeed = 16 end
        end

        if CFG.NoClip then 
            for _, p in ipairs(char:GetDescendants()) do 
                if p:IsA("BasePart") then p.CanCollide = false end 
            end 
        end
    end)
end)

-- Fly
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

RunService.Heartbeat:Connect(function()
    pcall(function()
        if CFG.IsFlying then
            if not BodyVel then startFly() end
            local hum = getHum(); if hum then hum.PlatformStand = true end
            local dir = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Cam.CFrame.RightVector end
            if BodyVel then BodyVel.Velocity = dir.Magnitude > 0 and dir.Unit * CFG.FlySpeed or Vector3.new(0,0,0) end
            if BodyGyr then BodyGyr.CFrame = Cam.CFrame end
        else
            if BodyVel then stopFly() end
        end
    end)
end)

-- ============ UI SYSTEM (POTYZIUM STYLE) ============
local parentGui = gethui and gethui() or CoreGui
if parentGui:FindFirstChild("PrimoDaxUI") then parentGui:FindFirstChild("PrimoDaxUI"):Destroy() end

local BG_MAIN   = Color3.fromRGB(14, 14, 16)
local BG_SIDE   = Color3.fromRGB(20, 20, 24)
local BG_CARD   = Color3.fromRGB(26, 26, 30)
local ACCENT    = Color3.fromRGB(140, 80, 255) -- Purple
local TXT_MAIN  = Color3.fromRGB(240, 240, 240)
local TXT_SUB   = Color3.fromRGB(150, 150, 160)

local Gui = Instance.new("ScreenGui")
Gui.Name           = "PrimoDaxUI"
Gui.ResetOnSpawn   = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent         = parentGui
if protect_gui then pcall(protect_gui, Gui) end

-- FLOATING TOGGLE
local FloatBtn = Instance.new("ImageButton")
FloatBtn.Size = UDim2.new(0, 45, 0, 45)
FloatBtn.Position = UDim2.new(0, 20, 0, 20)
FloatBtn.BackgroundColor3 = BG_MAIN
FloatBtn.Image = "rbxassetid://105010692648927"
FloatBtn.ImageColor3 = ACCENT
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
Title.Text = "PrimoDax Hub"; Title.TextColor3 = ACCENT; Title.Font = Enum.Font.GothamBold; Title.TextSize = 14; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Parent = Sidebar

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

local PageCombat = makePage("Combat")
local PageVisual = makePage("Visual")
local PagePlayer = makePage("Player")
local PageSettings = makePage("Settings")

local function switchTab(name)
    for n, p in pairs(Pages) do p.Visible = (n == name) end
end

local tabC = makeTab("Combat", "⚔", 0); tabC.MouseButton1Click:Connect(function() switchTab("Combat") end)
local tabV = makeTab("Visual", "👁", 1); tabV.MouseButton1Click:Connect(function() switchTab("Visual") end)
local tabP = makeTab("Player", "🏃", 2); tabP.MouseButton1Click:Connect(function() switchTab("Player") end)
local tabS = makeTab("UI Settings", "⚙", 3); tabS.MouseButton1Click:Connect(function() switchTab("Settings") end)

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

-- POPULATE COMBAT
local c1 = mkCard(PageCombat, "Silent Aim", 1)
mkToggle(c1, "Enable Silent Aim", "SilentAim", 1)
mkToggle(c1, "Wall Check", "WallCheck", 2)
mkDropdown(c1, "Target Part", "TargetPart", {"Head","HumanoidRootPart","Torso"}, 3)
mkDropdown(c1, "Priority", "Priority", {"Crosshair", "Distance"}, 4)

local c2 = mkCard(PageCombat, "Rage Bot", 2)
mkToggle(c2, "Enable Rage Bot", "AutoFire", 1)
mkToggle(c2, "Visible Check", "VisibleCheck", 2)
mkDropdown(c2, "Target Part", "RageTarget", {"Head","HumanoidRootPart","Torso"}, 3)
mkSlider(c2, "Max Distance", "MaxDistance", 50, 1000, 4)

local c3 = mkCard(PageCombat, "Weapons Mod", 3)
mkToggle(c3, "No Recoil", "NoRecoil", 1)
mkToggle(c3, "No Spread", "NoSpread", 2)

-- POPULATE VISUAL
local c4 = mkCard(PageVisual, "ESP", 1)
mkToggle(c4, "Enable ESP", "PlayerESP", 1)
mkToggle(c4, "Box ESP", "BoxESP", 2)
mkToggle(c4, "Name ESP", "NameESP", 3)
mkToggle(c4, "Distance ESP", "DistanceESP", 4)
mkToggle(c4, "Health Bar", "HealthBar", 5)
mkToggle(c4, "Chams", "Chams", 6)
mkToggle(c4, "Gun ESP", "GunESP", 7)

-- POPULATE PLAYER
local c5 = mkCard(PagePlayer, "Movement", 1)
mkToggle(c5, "Fly", "IsFlying", 1)
mkSlider(c5, "Fly Speed", "FlySpeed", 10, 400, 2)
mkToggle(c5, "Infinite Jump", "InfiniteJump", 3)
mkToggle(c5, "Auto Sprint", "AutoSprint", 4)
mkSlider(c5, "Sprint Speed", "SprintSpeed", 16, 100, 5)
mkToggle(c5, "No Clip", "NoClip", 6)
mkToggle(c5, "GodMode", "GodMode", 7)

-- Initial Tab
tabC.TextColor3 = TXT_MAIN
tabC.BackgroundColor3 = BG_CARD
switchTab("Combat")

-- Footer
local Footer = Instance.new("TextLabel")
Footer.Size = UDim2.new(1, -120, 0, 20); Footer.Position = UDim2.new(0, 120, 1, -20); Footer.BackgroundTransparency = 1
Footer.Text = "Vagrant Survival 0.9"; Footer.TextColor3 = TXT_SUB; Footer.Font = Enum.Font.Gotham; Footer.TextSize = 9; Footer.TextXAlignment = Enum.TextXAlignment.Right; Footer.Parent = Main

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
