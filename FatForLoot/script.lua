-- ██████╗  █████╗ ████████╗    ███████╗ ██████╗ ██████╗     ██╗      ██████╗  ██████╗ ████████╗
-- ██╔══██╗██╔══██╗╚══██╔══╝    ██╔════╝██╔═══██╗██╔══██╗    ██║     ██╔═══██╗██╔═══██╗╚══██╔══╝
-- ██████╔╝███████║   ██║       █████╗  ██║   ██║██████╔╝    ██║     ██║   ██║██║   ██║   ██║   
-- ██╔══██╗██╔══██║   ██║       ██╔══╝  ██║   ██║██╔══██╗    ██║     ██║   ██║██║   ██║   ██║   
-- ██║  ██║██║  ██║   ██║       ██║     ╚██████╔╝██║  ██║    ███████╗╚██████╔╝╚██████╔╝   ██║   
-- ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝       ╚═╝      ╚═════╝ ╚═╝  ╚═╝    ╚══════╝ ╚═════╝  ╚═════╝    ╚═╝   
-- AUTO CLICKER & LOOT FARMER

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

local CFG = {
    AutoClick = false, ClickDelay = 0.1,
    AutoFarm = false, FarmRadius = 30,
    AutoCollect = false,
    PlayerESP = false, ItemESP = false
}

-- ============ UTILS ============
local function getChar() return LP.Character end
local function getRoot() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end

-- ============ CORE FEATURES ============

-- 1. Auto Clicker (Clicks your screen/mouse automatically)
task.spawn(function()
    while task.wait(CFG.ClickDelay) do
        if CFG.AutoClick then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(0,0), Cam.CFrame)
            end)
        end
    end
end)

-- 2. Auto Collect Loot (Pulls nearby models/parts)
RunService.Heartbeat:Connect(function()
    if not CFG.AutoCollect then return end
    local root = getRoot()
    if not root then return end

    for _, obj in ipairs(Workspace:GetChildren()) do
        local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
        if part and (root.Position - part.Position).Magnitude < CFG.FarmRadius then
            local name = obj.Name:lower()
            -- Kung loot, pera, o item
            if name:find("loot") or name:find("coin") or name:find("food") or name:find("item") then
                pcall(function()
                    -- Kung may ProximityPrompt, pindutin
                    for _, v in ipairs(obj:GetDescendants()) do
                        if v:IsA("ProximityPrompt") then fireproximityprompt(v) end
                        if v:IsA("ClickDetector") then fireclickdetector(v) end
                    end
                    -- Kung kailangan ng touch (parang sa ibang laro), gawing position ng player
                    if part.CanCollide then
                        root.CFrame = part.CFrame
                    end
                end)
            end
        end
    end
end)

-- 3. Auto Farm (Teleports to loots)
task.spawn(function()
    while task.wait(0.5) do
        if CFG.AutoFarm then
            local root = getRoot()
            if not root then continue end
            
            local bestTarget, bDist = nil, CFG.FarmRadius
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name:lower():find("loot") then
                    local dist = (root.Position - obj.Position).Magnitude
                    if dist < bDist then bestTarget = obj; bDist = dist end
                end
            end
            
            if bestTarget then
                root.CFrame = bestTarget.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end
end)

-- 4. Player & Item ESP (Para makita mo kung nasaan ang pagkain)
local espObjects = {}
local function createESP(player)
    if espObjects[player] or player == LP then return end
    local box = Drawing.new("Square"); box.Thickness = 1; box.Color = Color3.fromRGB(255, 255, 255); box.Filled = false
    local name = Drawing.new("Text"); name.Size = 14; name.Center = true; name.Outline = true; name.Color = Color3.fromRGB(255, 255, 255)
    espObjects[player] = {Box = box, Name = name}
end

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)

RunService.RenderStepped:Connect(function()
    if not CFG.PlayerESP then
        for _, esp in pairs(espObjects) do esp.Box.Visible = false; esp.Name.Visible = false end
        return
    end

    for player, esp in pairs(espObjects) do
        local char = player.Character
        local head = char and char:FindFirstChild("Head")
        if head then
            local pos, onS = Cam:WorldToViewportPoint(head.Position)
            if onS then
                esp.Box.Visible = true
                esp.Box.Size = Vector2.new(40, 50)
                esp.Box.Position = Vector2.new(pos.X - 20, pos.Y - 25)
                esp.Name.Visible = true
                esp.Name.Text = player.Name
                esp.Name.Position = Vector2.new(pos.X, pos.Y - 40)
            else
                esp.Box.Visible = false; esp.Name.Visible = false
            end
        end
    end
end)

-- ============ UI SYSTEM ============
local parentGui = gethui and gethui() or CoreGui
if parentGui:FindFirstChild("FatForLootUI") then parentGui:FindFirstChild("FatForLootUI"):Destroy() end

local SG = Instance.new("ScreenGui")
SG.Name = "FatForLootUI"; SG.ResetOnSpawn = false; SG.IgnoreGuiInset = true; SG.Parent = parentGui
if protect_gui then pcall(protect_gui, SG) end

local FloatBtn = Instance.new("TextButton")
FloatBtn.Size = UDim2.new(0, 40, 0, 40); FloatBtn.Position = UDim2.new(0, 20, 0, 20)
FloatBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); FloatBtn.Text = "⚙️"; FloatBtn.TextSize = 20; FloatBtn.TextColor3 = Color3.fromRGB(100, 200, 50); FloatBtn.Parent = SG
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(1, 0)

local MF = Instance.new("Frame")
MF.Size = UDim2.new(0, 350, 0, 240); MF.Position = UDim2.new(0.5, -175, 0.5, -120)
MF.BackgroundColor3 = Color3.fromRGB(12, 12, 12); MF.BorderSizePixel = 0; MF.Active = true; MF.Visible = false; MF.Parent = SG
Instance.new("UICorner", MF).CornerRadius = UDim.new(0, 8)

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 30); TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20); TopBar.Parent = MF
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 1, 0); Title.Position = UDim2.new(0, 10, 0, 0); Title.BackgroundTransparency = 1
Title.Text = "Fat For Loot v1.0"; Title.TextColor3 = Color3.fromRGB(200, 200, 200); Title.Font = Enum.Font.GothamBold; Title.TextSize = 13; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Parent = TopBar

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -20, 1, -40); Content.Position = UDim2.new(0, 10, 0, 35); Content.BackgroundTransparency = 1; Content.Parent = MF
local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 5); layout.Parent = Content

-- Helpers
local function makeToggle(name, key, callback)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, 0, 0, 30); btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25); btn.Text = ""; btn.Parent = Content
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -40, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0); lbl.BackgroundTransparency = 1; lbl.Text = name; lbl.TextColor3 = Color3.fromRGB(200, 200, 200); lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = btn
    local ind = Instance.new("Frame"); ind.Size = UDim2.new(0, 30, 0, 14); ind.Position = UDim2.new(1, -40, 0.5, -7); ind.BackgroundColor3 = CFG[key] and Color3.fromRGB(100, 200, 50) or Color3.fromRGB(50, 50, 50); ind.Parent = btn
    Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)
    btn.MouseButton1Click:Connect(function()
        CFG[key] = not CFG[key]
        ind.BackgroundColor3 = CFG[key] and Color3.fromRGB(100, 200, 50) or Color3.fromRGB(50, 50, 50)
        if callback then callback() end
    end)
end

makeToggle("Auto Click", "AutoClick")
makeToggle("Auto Farm (Loot)", "AutoFarm")
makeToggle("Auto Collect (Radius)", "AutoCollect")
makeToggle("Player ESP", "PlayerESP")

local dragging, dragStart, startPos
TopBar.InputBegan:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = MF.Position end 
end)
UserInputService.InputChanged:Connect(function(input) 
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then 
        local delta = input.Position - dragStart; MF.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) 
    end 
end)
UserInputService.InputEnded:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end 
end)

local isOpen = false
FloatBtn.MouseButton1Click:Connect(function() isOpen = not isOpen; MF.Visible = isOpen end)
