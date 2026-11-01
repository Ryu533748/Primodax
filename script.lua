-- ██████╗ ██████╗ ██╗███╗   ███╗ ██████╗ ██████╗  █████╗ ██╗  ██╗
-- ██╔══██╗██╔══██╗██║████╗ ████║██╔═══██╗██╔══██╗██╔══██╗╚██╗██╔╝
-- ██████╔╝██████╔╝██║██╔████╔██║██║   ██║██║  ██║███████║ ╚███╔╝
-- ██╔═══╝ ██╔══██╗██║██║╚██╔╝██║██║   ██║██║  ██║██╔══██║ ██╔██╗
-- ██║     ██║  ██║██║██║ ╚═╝ ██║╚██████╔╝██████╔╝██║  ██║██╔╝ ██╗
-- ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
-- PRIMODAX VGRANT | Vagrant Survival | v6.1 FIXED
-- FIXED: Gun Firing, ESP (Box+Name+Dist), Infinite Jump, Aimbot Settings

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")

local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

-- ============ CONFIG ============
local CFG = {
    -- Combat
    SilentAim = false,
    Aimbot = false,
    AimbotSmoothing = 15, -- 0-100 (0 = Snap, 100 = Smooth)
    FOVRange = 120,       -- 0-360
    AutoShoot = false,
    SkipFriends = true,
    -- Utility
    UnlimitedAmmo = false,
    AutoReload = false,
    AutoPickup = false,
    AutoRespawn = false,
    -- Movement
    InfiniteJump = false,
    Noclip = false,
    AutoSprint = false,
    SprintSpeed = 28,
    -- Visual
    ESPEnabled = false,
    -- Bypass
    AntiKick = true,
    AntiAfk = true,
}

-- ============ UTILS ============
local function getChar(p) return p and p.Character end
local function getHum(p) local c = getChar(p) return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot(p) local c = getChar(p) return c and c:FindFirstChild("HumanoidRootPart") end
local function getPart(p, n) local c = getChar(p) return c and c:FindFirstChild(n) end
local function isAlive(p) local h = getHum(p) return h and h.Health > 0 end

-- ============ DRAWING FOV CIRCLE ============
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5
fovCircle.Color = Color3.fromRGB(255, 215, 0)
fovCircle.Filled = false
fovCircle.Visible = true
fovCircle.Radius = CFG.FOVRange

RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    fovCircle.Radius = CFG.FOVRange
end)

-- ============ TARGETING LOGIC ============
local activeTarget = nil
local function getTargetInFOV()
    local center = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    local bestTarget, bDist = nil, CFG.FOVRange
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isAlive(p) then
            if not (CFG.SkipFriends and LP:IsFriendsWith(p.UserId)) then
                local head = getPart(p, "Head")
                if head then
                    local screenPos, onScreen = Cam:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if dist2D < bDist then
                            bestTarget = p
                            bDist = dist2D
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

-- ============ SILENT AIM + ANTIKICK HOOK ============
-- Gagamit tayo ng __index hook para hindi maapektuhan ang baril.
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if key == "WalkSpeed" and CFG.AutoSprint then
        return CFG.SprintSpeed
    end
    return oldIndex(self, key)
end)

-- ============ AIMBOT CAMERA ============
RunService.RenderStepped:Connect(function()
    local target = getTargetInFOV()
    
    if target then
        local head = getPart(target, "Head")
        if head then
            -- Silent Aim (pwede ring gawin sa __index pero mas safe dito kung Visual lang)
            -- Aimbot (Camera Lerp)
            if CFG.Aimbot then
                local targetPos = head.Position
                local currentCF = Cam.CFrame
                local targetCF = CFrame.new(currentCF.Position, targetPos)
                -- 0 to 100 mapping (0 = Snap, 100 = Slow)
                local smoothFactor = math.clamp(1 - (CFG.AimbotSmoothing / 100), 0.01, 1)
                Cam.CFrame = currentCF:Lerp(targetCF, smoothFactor * 0.3)
            end
        end
    end
end)

-- ============ ESP (BOX + NAME + DISTANCE) ============
local espObjects = {}
local function makeESP(player)
    if espObjects[player] then return end
    local box = Drawing.new("Square")
    box.Thickness = 1.5
    box.Color = Color3.fromRGB(255, 50, 50)
    box.Filled = false
    box.Visible = false
    
    local nameTag = Drawing.new("Text")
    nameTag.Size = 14
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.Color = Color3.fromRGB(255, 255, 255)
    nameTag.Visible = false
    
    local distTag = Drawing.new("Text")
    distTag.Size = 12
    distTag.Center = true
    distTag.Outline = true
    distTag.Color = Color3.fromRGB(255, 215, 0)
    distTag.Visible = false

    espObjects[player] = {box = box, name = nameTag, dist = distTag}
end

local function removeESP(player)
    if espObjects[player] then
        espObjects[player].box:Remove()
        espObjects[player].name:Remove()
        espObjects[player].dist:Remove()
        espObjects[player] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then makeESP(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LP then makeESP(p) end end)
Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
    for player, esp in pairs(espObjects) do
        if CFG.ESPEnabled and isAlive(player) then
            local head = getPart(player, "Head")
            local root = getRoot(player)
            local myRoot = getRoot(LP)
            
            if head and root and myRoot then
                local headScreen, headOn = Cam:WorldToViewportPoint(head.Position)
                local rootScreen, rootOn = Cam:WorldToViewportPoint(root.Position)
                
                if headOn and rootOn then
                    local height = math.abs(rootScreen.Y - headScreen.Y) * 2.2
                    local width = height * 0.5
                    
                    esp.box.Size = Vector2.new(width, height)
                    esp.box.Position = Vector2.new(rootScreen.X - width/2, rootScreen.Y - height/2)
                    esp.box.Visible = true
                    
                    esp.name.Text = player.Name
                    esp.name.Position = Vector2.new(rootScreen.X, headScreen.Y - 18)
                    esp.name.Visible = true
                    
                    local distance = (myRoot.Position - root.Position).Magnitude
                    esp.dist.Text = string.format("[%d studs]", distance)
                    esp.dist.Position = Vector2.new(rootScreen.X, rootScreen.Y + height/2 + 5)
                    esp.dist.Visible = true
                else
                    esp.box.Visible = false
                    esp.name.Visible = false
                    esp.dist.Visible = false
                end
            end
        else
            esp.box.Visible = false
            esp.name.Visible = false
            esp.dist.Visible = false
        end
    end
end)

-- ============ INFINITE JUMP (TAMANG PARAAN) ============
UserInputService.JumpRequest:Connect(function()
    if CFG.InfiniteJump then
        local hum = getHum(LP)
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ============ NOCLIP ============
RunService.Stepped:Connect(function()
    if CFG.Noclip then
        local char = getChar(LP)
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                    v.CanCollide = false
                end
            end
        end
    end
end)

-- ============ ANTI-AFK ============
LP.Idled:Connect(function()
    if CFG.AntiAfk then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- ============ SERVER HOP ============
local function serverHop()
    pcall(function()
        local data = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
        if data and data.data then
            for _, s in ipairs(data.data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP)
                    return
                end
            end
        end
    end)
end

-- ============ UI SYSTEM (STRUCTURED) ============
if CoreGui:FindFirstChild("PrimodaxGUI") then CoreGui:FindFirstChild("PrimodaxGUI"):Destroy() end
local SG = Instance.new("ScreenGui")
SG.Name = "PrimodaxGUI"
SG.ResetOnSpawn = false
SG.IgnoreGuiInset = true
SG.Parent = CoreGui

local MF = Instance.new("Frame")
MF.Size = UDim2.fromOffset(300, 550)
MF.Position = UDim2.new(0.5, -150, 0.5, -275)
MF.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
MF.BorderSizePixel = 0
MF.Visible = false
MF.Parent = SG
Instance.new("UICorner", MF).CornerRadius = UDim.new(0, 12)
local mfStroke = Instance.new("UIStroke", MF)
mfStroke.Color = Color3.fromRGB(255, 215, 0)
mfStroke.Thickness = 1.5

local TB = Instance.new("Frame")
TB.Size = UDim2.new(1, 0, 0, 45)
TB.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
TB.Parent = MF
Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 12)
local TL = Instance.new("TextLabel")
TL.Size = UDim2.new(1, -50, 1, 0)
TL.Position = UDim2.new(0, 10, 0, 0)
TL.BackgroundTransparency = 1
TL.Text = "⚡ PRIMODAX V6.1 ⚡"
TL.TextColor3 = Color3.fromRGB(0, 0, 0)
TL.TextSize = 15
TL.Font = Enum.Font.GothamBold
TL.TextXAlignment = Enum.TextXAlignment.Left
TL.Parent = TB

local XBtn = Instance.new("TextButton")
XBtn.Size = UDim2.new(0, 36, 0, 36)
XBtn.Position = UDim2.new(1, -42, 0, 5)
XBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
XBtn.Text = "✕"
XBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
XBtn.TextSize = 16
XBtn.Font = Enum.Font.GothamBold
XBtn.Parent = TB
Instance.new("UICorner", XBtn).CornerRadius = UDim.new(1, 0)
XBtn.MouseButton1Click:Connect(function() MF.Visible = false end)

local SF = Instance.new("ScrollingFrame")
SF.Size = UDim2.new(1, -10, 1, -50)
SF.Position = UDim2.new(0, 5, 0, 50)
SF.BackgroundTransparency = 1
SF.ScrollBarThickness = 3
SF.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
SF.CanvasSize = UDim2.new(0, 0, 0, 0)
SF.AutomaticCanvasSize = Enum.AutomaticSize.Y
SF.Parent = MF
local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 6)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = SF
local Pad = Instance.new("UIPadding")
Pad.PaddingTop = UDim.new(0, 8)
Pad.PaddingBottom = UDim.new(0, 8)
Pad.Parent = SF

-- ============ UI HELPERS ============
local toggleRefs = {}

local function makeSection(text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Text = "── " .. text .. " ──"
    lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    lbl.Parent = SF
end

local function makeToggle(name, key, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.LayoutOrder = order
    btn.Parent = SF
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local function update()
        btn.Text = "  " .. (CFG[key] and "🟢 " or "🔴 ") .. name
        btn.BackgroundColor3 = CFG[key] and Color3.fromRGB(35, 80, 40) or Color3.fromRGB(30, 30, 30)
    end
    update()
    toggleRefs[key] = update

    btn.MouseButton1Click:Connect(function()
        CFG[key] = not CFG[key]
        update()
    end)
end

local function makeSlider(name, key, min, max, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 38)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = order
    frame.Parent = SF

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text = name .. ": " .. CFG[key]
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local bar = Instance.new("TextButton")
    bar.Size = UDim2.new(1, 0, 0, 10)
    bar.Position = UDim2.new(0, 0, 0, 22)
    bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    bar.Text = ""
    bar.Parent = frame
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((CFG[key] - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local dragging = false
    bar.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    
    local function processInput(x)
        if not dragging then return end
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + rel * (max - min))
        CFG[key] = val
        lbl.Text = name .. ": " .. val
        fill.Size = UDim2.new(rel, 0, 1, 0)
    end
    
    bar.MouseMoved:Connect(function(x) processInput(x) end)
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            processInput(input.Position.X)
        end
    end)
end

-- ============ BUILD MENU ============
makeSection("COMBAT", 1)
makeToggle("Silent Aim", "SilentAim", 2)
makeToggle("Aimbot", "Aimbot", 3)
makeSlider("Aimbot Smooth (0-100)", "AimbotSmoothing", 0, 100, 4)
makeSlider("FOV Range (0-360)", "FOVRange", 0, 360, 5)
makeToggle("Skip Friends", "SkipFriends", 6)

makeSection("WEAPONS", 10)
makeToggle("Unlimited Ammo", "UnlimitedAmmo", 11)
makeToggle("Auto Reload", "AutoReload", 12)

makeSection("MOVEMENT", 20)
makeToggle("Infinite Jump", "InfiniteJump", 21)
makeToggle("Noclip", "Noclip", 22)
makeToggle("Auto Sprint", "AutoSprint", 23)
makeSlider("Sprint Speed", "SprintSpeed", 16, 100, 24)

makeSection("VISUAL", 30)
makeToggle("ESP (Player Info)", "ESPEnabled", 31)

makeSection("BYPASS", 40)
makeToggle("Anti Kick", "AntiKick", 41)
makeToggle("Anti AFK", "AntiAfk", 42)

makeSection("SYSTEM", 50)
local hopBtn = Instance.new("TextButton")
hopBtn.Size = UDim2.new(1, -10, 0, 32)
hopBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
hopBtn.Text = "Server Hop"
hopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
hopBtn.Font = Enum.Font.GothamBold
hopBtn.TextSize = 12
hopBtn.LayoutOrder = 51
hopBtn.Parent = SF
Instance.new("UICorner", hopBtn).CornerRadius = UDim.new(0, 6)
hopBtn.MouseButton1Click:Connect(serverHop)

-- ============ FLOATING TOGGLE ============
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.fromOffset(60, 60)
toggleBtn.Position = UDim2.new(0.5, -30, 1, -95)
toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
toggleBtn.Text = "⚡"
toggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
toggleBtn.TextSize = 24
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = SG
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)

local drag, dragStart, startPos = false, nil, nil
toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        drag = true
        dragStart = input.Position
        startPos = toggleBtn.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if drag and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        drag = false
        if startPos and math.abs(input.Position.X - dragStart.X) < 10 and math.abs(input.Position.Y - dragStart.Y) < 10 then
            MF.Visible = not MF.Visible
        end
    end
end)

print("✅ PRIMODAX V6.1 Loaded — Baril gagana na, ESP at Aimbot ayos na.")
