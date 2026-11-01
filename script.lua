-- ██████╗ ██████╗ ██╗███╗   ███╗ ██████╗ ██████╗  █████╗ ██╗  ██╗
-- ██╔══██╗██╔══██╗██║████╗ ████║██╔═══██╗██╔══██╗██╔══██╗╚██╗██╔╝
-- ██████╔╝██████╔╝██║██╔████╔██║██║   ██║██║  ██║███████║ ╚███╔╝ 
-- ██╔═══╝ ██╔══██╗██║██║╚██╔╝██║██║   ██║██║  ██║██╔══██║ ██╔██╗ 
-- ██║     ██║  ██║██║██║ ╚═╝ ██║╚██████╔╝██████╔╝██║  ██║██╔╝ ██╗
-- ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
-- PRIMODAX VAGRANT SURVIVAL | v6.0 (SAFE MOBILE EDITION)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

-- ============ CONFIG (LAHAT OFF DEFAULT) ============
local CFG = {
    SilentAim = false, SilentAimFOV = 120, AutoShoot = false,
    SkipFriends = true, FloatMode = false, FloatPower = 55,
    Noclip = false, AutoSprint = false, SprintSpeed = 28,
    UnlimitedAmmo = false, AutoReload = false, AutoPickup = false,
    AutoPickupRange = 40, AutoRespawn = false, ESPEnabled = false,
    AntiAfk = true, AntiKick = true
}

-- ============ UTILS ============
local function getChar(p) return p and p.Character end
local function getHum(p) local c = getChar(p) return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot(p) local c = getChar(p) return c and c:FindFirstChild("HumanoidRootPart") end
local function getPart(p, n) local c = getChar(p) return c and c:FindFirstChild(n) end
local function isAlive(p) local h = getHum(p) return h and h.Health > 0 end

-- ============ SAFE FOV CIRCLE (GAMIT FRAME, HINDI DRAWING) ============
-- Ito ang dahilan kung bakit nag-fa-freeze camera dati: ginamit ang Drawing library.
-- Ngayon, gagamit tayo ng UI Frame na naka-center sa screen.
local fovFrame = Instance.new("Frame")
fovFrame.Name = "FOV"
fovFrame.BackgroundTransparency = 1
fovFrame.Size = UDim2.fromOffset(CFG.SilentAimFOV * 2, CFG.SilentAimFOV * 2)
fovFrame.Position = UDim2.fromScale(0.5, 0.5)
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fovFrame.Visible = false
fovFrame.Parent = CoreGui

local fovCorner = Instance.new("UICorner", fovFrame)
fovCorner.CornerRadius = UDim.new(1, 0)

local fovStroke = Instance.new("UIStroke", fovFrame)
fovStroke.Color = Color3.fromRGB(255, 215, 0)
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.5

-- ============ ESP LOGIC (SAFE FOR MOBILE) ============
local espBoxes = {}
local function updateESP()
    if not CFG.ESPEnabled then
        for _, box in pairs(espBoxes) do box.Visible = false end
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isAlive(p) then
            local head = getPart(p, "Head")
            local root = getRoot(p)
            if head and root then
                local pos, onScreen = Cam:WorldToViewportPoint(root.Position)
                if onScreen then
                    if not espBoxes[p] then
                        local b = Instance.new("Frame")
                        b.BackgroundTransparency = 1
                        b.BorderSizePixel = 2
                        b.BorderColor3 = Color3.fromRGB(255, 50, 50)
                        b.Parent = CoreGui
                        espBoxes[p] = b
                    end
                    local screenPos = Vector2.new(pos.X, pos.Y)
                    local headPos = Vector2.new(Cam:WorldToViewportPoint(head.Position).X, Cam:WorldToViewportPoint(head.Position).Y)
                    local height = math.abs(screenPos.Y - headPos.Y) * 2
                    espBoxes[p].Size = UDim2.fromOffset(height * 0.5, height)
                    espBoxes[p].Position = UDim2.fromOffset(screenPos.X - (height * 0.25), screenPos.Y - (height * 0.5))
                    espBoxes[p].Visible = true
                else
                    if espBoxes[p] then espBoxes[p].Visible = false end
                end
            end
        end
    end
end
RunService.RenderStepped:Connect(updateESP)

-- ============ SAFE NAME CALL HOOK (SILENT AIM + ANTIKICK) ============
-- Ito ang pinaka-safe na paraan para hindi mag-crash ang executor.
local silentTarget = nil
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = { ... }
    
    if method == "FireServer" or method == "InvokeServer" then
        -- Anti-Kick (Safe)
        if CFG.AntiKick then
            local n = (self.Name or ""):lower()
            if n:find("kick") or n:find("ban") or n:find("cheat") or n:find("detect") then
                return nil
            end
        end
        
        -- Silent Aim
        if CFG.SilentAim and silentTarget and isAlive(silentTarget) then
            local targetPart = getPart(silentTarget, "Head")
            if targetPart then
                for i, v in ipairs(args) do
                    if typeof(v) == "Vector3" then
                        args[i] = targetPart.Position
                    elseif typeof(v) == "Instance" and v:IsA("BasePart") then
                        args[i] = targetPart
                    end
                end
            end
        end
    end
    return oldNamecall(self, table.unpack(args))
end)

-- ============ TARGETING LOGIC ============
local function getNearestTarget()
    local center = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    local best, bDist = nil, CFG.SilentAimFOV
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isAlive(p) then
            if not (CFG.SkipFriends and LP:IsFriendsWith(p.UserId)) then
                local head = getPart(p, "Head")
                if head then
                    local pos, onScreen = Cam:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if dist < bDist then
                            best, bDist = head, dist
                        end
                    end
                end
            end
        end
    end
    return best
end

RunService.RenderStepped:Connect(function()
    fovFrame.Size = UDim2.fromOffset(CFG.SilentAimFOV * 2, CFG.SilentAimFOV * 2)
    fovFrame.Visible = CFG.SilentAim
    
    if CFG.SilentAim then
        local t = getNearestTarget()
        silentTarget = t and t.Parent or nil
    else
        silentTarget = nil
    end
end)

-- ============ MOVEMENT (NOCLIP, FLOAT, SPRINT) ============
RunService.Stepped:Connect(function(_, dt)
    local char = getChar(LP)
    if not char then return end
    
    -- Noclip
    if CFG.Noclip then
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                v.CanCollide = false
            end
        end
    end
    
    -- Float Mode
    if CFG.FloatMode then
        local root = getRoot(LP)
        if root and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            root.CFrame = root.CFrame + Vector3.new(0, CFG.FloatPower * dt, 0)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if CFG.AutoSprint then
        local hum = getHum(LP)
        if hum and hum.WalkSpeed < CFG.SprintSpeed then
            hum.WalkSpeed = CFG.SprintSpeed
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

-- ============ UI (GAMIT ANG STYLE NG LUMANG SCRIPT MO) ============
local SG = Instance.new("ScreenGui")
SG.Name = "PrimodaxGUI"
SG.ResetOnSpawn = false
SG.IgnoreGuiInset = true
if gethui then SG.Parent = gethui() else SG.Parent = CoreGui end

local MF = Instance.new("Frame")
MF.Size = UDim2.fromOffset(280, 500)
MF.Position = UDim2.new(0.5, -140, 0.5, -250)
MF.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
MF.BorderSizePixel = 0
MF.Visible = false
MF.Parent = SG
Instance.new("UICorner", MF).CornerRadius = UDim.new(0, 12)

local mfStroke = Instance.new("UIStroke", MF)
mfStroke.Color = Color3.fromRGB(255, 215, 0)
mfStroke.Thickness = 1.5

local TB = Instance.new("Frame")
TB.Size = UDim2.new(1, 0, 0, 50)
TB.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
TB.Parent = MF
Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 12)

local TL = Instance.new("TextLabel")
TL.Size = UDim2.new(1, -50, 0, 28)
TL.Position = UDim2.new(0, 10, 0, 2)
TL.BackgroundTransparency = 1
TL.Text = "⚡ PRIMODAX V6 ⚡"
TL.TextColor3 = Color3.fromRGB(0, 0, 0)
TL.TextSize = 14
TL.Font = Enum.Font.GothamBold
TL.TextXAlignment = Enum.TextXAlignment.Left
TL.Parent = TB

local XBtn = Instance.new("TextButton")
XBtn.Size = UDim2.new(0, 36, 0, 36)
XBtn.Position = UDim2.new(1, -42, 0, 7)
XBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
XBtn.Text = "✕"
XBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
XBtn.TextSize = 16
XBtn.Font = Enum.Font.GothamBold
XBtn.Parent = TB
Instance.new("UICorner", XBtn).CornerRadius = UDim.new(1, 0)
XBtn.MouseButton1Click:Connect(function() MF.Visible = false end)

local SF = Instance.new("ScrollingFrame")
SF.Size = UDim2.new(1, -10, 1, -58)
SF.Position = UDim2.new(0, 5, 0, 54)
SF.BackgroundTransparency = 1
SF.ScrollBarThickness = 3
SF.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
SF.CanvasSize = UDim2.new(0, 0, 0, 0)
SF.AutomaticCanvasSize = Enum.AutomaticSize.Y
SF.Parent = MF

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 5)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = SF

-- ============ UI HELPER FUNCTIONS ============
local toggleRefs = {}

local function makeToggle(name, key, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Text = "  " .. name
    btn.LayoutOrder = order
    btn.Parent = SF
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local function updateUI()
        btn.Text = (CFG[key] and "🟢 " or "🔴 ") .. name
        btn.BackgroundColor3 = CFG[key] and Color3.fromRGB(35, 80, 40) or Color3.fromRGB(30, 30, 30)
    end
    updateUI()
    toggleRefs[key] = updateUI

    btn.MouseButton1Click:Connect(function()
        CFG[key] = not CFG[key]
        updateUI()
    end)
end

local function makeSection(name, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    lbl.Parent = SF
end

local function makeSlider(name, key, min, max, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 40)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = order
    frame.Parent = SF

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = name .. ": " .. CFG[key]
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local bar = Instance.new("TextButton")
    bar.Size = UDim2.new(1, 0, 0, 8)
    bar.Position = UDim2.new(0, 0, 0, 24)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
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
    bar.MouseMoved:Connect(function(x)
        if dragging then
            local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + rel * (max - min))
            CFG[key] = val
            lbl.Text = name .. ": " .. val
            fill.Size = UDim2.new(rel, 0, 1, 0)
        end
    end)
end

local function makeButton(name, color, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.48, 0, 0, 32)
    btn.BackgroundColor3 = color
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.LayoutOrder = order
    btn.Parent = SF
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
end

-- ============ BUILD MENU ============
makeSection("── COMBAT ──", 1)
makeToggle("Silent Aim", "SilentAim", 2)
makeSlider("Silent Aim FOV", "SilentAimFOV", 10, 400, 3)
makeToggle("Auto Shoot", "AutoShoot", 4)
makeToggle("Skip Friends", "SkipFriends", 5)
makeToggle("Unlimited Ammo", "UnlimitedAmmo", 6)
makeToggle("Auto Reload", "AutoReload", 7)

makeSection("── MOVEMENT ──", 10)
makeToggle("Float Mode (Space)", "FloatMode", 11)
makeSlider("Float Power", "FloatPower", 10, 200, 12)
makeToggle("Noclip", "Noclip", 13)
makeToggle("Auto Sprint", "AutoSprint", 14)
makeSlider("Sprint Speed", "SprintSpeed", 16, 100, 15)

makeSection("── UTILITY ──", 20)
makeToggle("Auto Pickup", "AutoPickup", 21)
makeToggle("Auto Respawn", "AutoRespawn", 22)

makeSection("── VISUAL ──", 30)
makeToggle("ESP", "ESPEnabled", 31)

makeSection("── SYSTEM ──", 40)
makeToggle("Anti AFK", "AntiAfk", 41)
makeToggle("Anti Kick", "AntiKick", 42)
makeButton("Server Hop", Color3.fromRGB(180, 80, 80), 43, serverHop)

-- ============ FLOATING TOGGLE BUTTON ============
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

print("✅ PRIMODAX V6 Loaded successfully!")
