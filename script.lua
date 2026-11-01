-- ██████╗ ██████╗ ██╗███╗   ███╗ ██████╗ ██████╗  █████╗ ██╗  ██╗
-- ██╔══██╗██╔══██╗██║████╗ ████║██╔═══██╗██╔══██╗██╔══██╗╚██╗██╔╝
-- ██████╔╝██████╔╝██║██╔████╔██║██║   ██║██║  ██║███████║ ╚███╔╝
-- ██╔═══╝ ██╔══██╗██║██║╚██╔╝██║██║   ██║██║  ██║██╔══██║ ██╔██╗
-- ██║     ██║  ██║██║██║ ╚═╝ ██║╚██████╔╝██████╔╝██║  ██║██╔╝ ██╗
-- ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
-- PRIMODAX VGRANT v6.6 | ANTI-KICK FIX | FORCE RELOAD

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
    SilentAim = false, Aimbot = false, AimbotSmoothing = 15, FOVRange = 120,
    SkipFriends = true, AutoRespawn = false, RespawnToBag = false,
    InfiniteJump = false, AutoSprint = false, SprintSpeed = 20, -- MAX 20 to 22 lang para di ma-kick
    ESPEnabled = false, AutoPickup = false, PickupPriority = "Random", 
    AntiKick = true, UnlimitedAmmo = false, AutoReload = false,
    WideScreen = false, CameraFOV = 70,
}

-- ============ UTILS ============
local function getChar(p) return p and p.Character end
local function getHum(p) local c = getChar(p) return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot(p) local c = getChar(p) return c and c:FindFirstChild("HumanoidRootPart") end
local function getPart(p, n) local c = getChar(p) return c and c:FindFirstChild(n) end
local function isAlive(p) local h = getHum(p) return h and h.Health > 0 end

-- ============ WIDE SCREEN (CAMERA FOV) ============
local function updateCameraFOV()
    if CFG.WideScreen then
        Cam.FieldOfView = CFG.CameraFOV
    else
        Cam.FieldOfView = 70
    end
end

-- ============ FOV CIRCLE ============
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5
fovCircle.Color = Color3.fromRGB(255, 215, 0)
fovCircle.Filled = false
fovCircle.Visible = true
fovCircle.Radius = CFG.FOVRange

-- ============ TARGETING ============
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
                        if dist2D < bDist then bestTarget = p; bDist = dist2D end
                    end
                end
            end
        end
    end
    return bestTarget
end

-- ============ SILENT AIM ============
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = { ... }
    if method == "FireServer" or method == "InvokeServer" then
        if CFG.AntiKick then
            local n = (self.Name or ""):lower()
            if n:find("kick") or n:find("ban") or n:find("cheat") or n:find("detect") then return nil end
        end
        if CFG.SilentAim and activeTarget and isAlive(activeTarget) then
            local targetChar = getChar(activeTarget)
            local targetHead = targetChar and targetChar:FindFirstChild("Head")
            if targetHead then
                for i, v in ipairs(args) do
                    if typeof(v) == "Vector3" then args[i] = targetHead.Position
                    elseif typeof(v) == "CFrame" then
                        local lookDir = (targetHead.Position - Cam.CFrame.Position).Unit
                        args[i] = CFrame.new(Cam.CFrame.Position, Cam.CFrame.Position + lookDir)
                    elseif typeof(v) == "Instance" then
                        if v:IsA("BasePart") then args[i] = targetHead
                        elseif v:IsA("Model") then args[i] = targetChar end
                    end
                end
            end
        end
    end
    return oldNamecall(self, table.unpack(args))
end)

-- ============ MAIN RENDER (AIMBOT & FOV) ============
RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    fovCircle.Radius = CFG.FOVRange
    activeTarget = getTargetInFOV()
    if activeTarget then
        local head = getPart(activeTarget, "Head")
        if head and CFG.Aimbot then
            local targetCF = CFrame.new(Cam.CFrame.Position, head.Position)
            local smoothFactor = math.clamp(1 - (CFG.AimbotSmoothing / 100), 0.05, 1)
            Cam.CFrame = Cam.CFrame:Lerp(targetCF, smoothFactor)
        end
    end
end)

-- ============ ESP ============
local espObjects = {}
local function makeESP(player)
    if espObjects[player] then return end
    local box = Drawing.new("Square"); box.Thickness = 1.5; box.Color = Color3.fromRGB(255, 50, 50); box.Filled = false; box.Visible = false
    local nameTag = Drawing.new("Text"); nameTag.Size = 14; nameTag.Center = true; nameTag.Outline = true; nameTag.Color = Color3.fromRGB(255, 255, 255); nameTag.Visible = false
    local distTag = Drawing.new("Text"); distTag.Size = 12; distTag.Center = true; distTag.Outline = true; distTag.Color = Color3.fromRGB(255, 215, 0); distTag.Visible = false
    espObjects[player] = {box = box, name = nameTag, dist = distTag}
end
for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then makeESP(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LP then makeESP(p) end end)

RunService.Heartbeat:Connect(function()
    if not CFG.ESPEnabled then
        for _, esp in pairs(espObjects) do esp.box.Visible = false; esp.name.Visible = false; esp.dist.Visible = false end
        return
    end
    for player, esp in pairs(espObjects) do
        if isAlive(player) then
            local head = getPart(player, "Head")
            local root = getRoot(player)
            local myRoot = getRoot(LP)
            if head and root and myRoot then
                local headScreen, headOn = Cam:WorldToViewportPoint(head.Position)
                local rootScreen, rootOn = Cam:WorldToViewportPoint(root.Position)
                if headOn and rootOn then
                    local height = math.abs(rootScreen.Y - headScreen.Y) * 2.2
                    local width = height * 0.5
                    esp.box.Size = Vector2.new(width, height); esp.box.Position = Vector2.new(rootScreen.X - width/2, rootScreen.Y - height/2); esp.box.Visible = true
                    esp.name.Text = player.Name; esp.name.Position = Vector2.new(rootScreen.X, headScreen.Y - 18); esp.name.Visible = true
                    esp.dist.Text = string.format("[%d studs]", (myRoot.Position - root.Position).Magnitude); esp.dist.Position = Vector2.new(rootScreen.X, rootScreen.Y + height/2 + 5); esp.dist.Visible = true
                else
                    esp.box.Visible = false; esp.name.Visible = false; esp.dist.Visible = false
                end
            end
        else
            esp.box.Visible = false; esp.name.Visible = false; esp.dist.Visible = false
        end
    end
end)

-- ============ FORCE RELOAD & INFINITE AMMO ============
-- Ang Crossbow ay may "Draw Time". Para ma-force reload, i-unequip at i-equip natin nang mabilis.
local lastReloadTime = 0
RunService.Heartbeat:Connect(function()
    if not CFG.UnlimitedAmmo and not CFG.AutoReload then return end
    local char = getChar(LP)
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    local hum = getHum(LP)
    if not hum then return end

    -- Force Auto Reload (Crossbow Fix)
    if CFG.AutoReload and tick() - lastReloadTime > 1.5 then
        local isReloading = tool:GetAttribute("Reloading") or tool:GetAttribute("IsReloading")
        local ammo = tool:GetAttribute("Ammo") or tool:GetAttribute("CurrentAmmo") or tool:GetAttribute("StoredAmmo")
        
        -- Kung kulang sa bala o nagre-reload state, pilitin i-refresh
        if isReloading == true or (ammo and ammo == 0) then
            hum:UnequipTools()
            task.wait(0.1)
            hum:EquipTool(tool)
            lastReloadTime = tick()
        end
    end

    -- Infinite Ammo (Fallback sa Values)
    if CFG.UnlimitedAmmo then
        for _, v in ipairs(tool:GetDescendants()) do
            local n = v.Name:lower()
            if v:IsA("IntValue") or v:IsA("NumberValue") then
                if n:find("ammo") or n:find("bullet") or n:find("mag") or n:find("bolt") then
                    if v.Value < 5 then v.Value = 999 end
                end
            end
        end
    end
end)

-- ============ MOVEMENT (INF JUMP & SPRINT) ============
RunService.Heartbeat:Connect(function()
    local char = getChar(LP)
    if not char then return end
    local hum = getHum(LP)
    if not hum then return end

    -- Auto Sprint (Safe Speed 20-22)
    if CFG.AutoSprint then
        if hum.WalkSpeed < CFG.SprintSpeed then
            hum.WalkSpeed = CFG.SprintSpeed
        end
    elseif hum.WalkSpeed == CFG.SprintSpeed then
        hum.WalkSpeed = 16 -- Reset sa default
    end

    -- Infinite Jump
    if CFG.InfiniteJump then
        local jumpHeld = UserInputService:IsKeyDown(Enum.KeyCode.Space) or 
                         UserInputService:IsKeyDown(Enum.KeyCode.ButtonA) or 
                         (UserInputService.TouchEnabled and hum:GetState() == Enum.HumanoidStateType.Jumping)
        if jumpHeld then
            if hum:GetState() ~= Enum.HumanoidStateType.Jumping and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

-- ============ AUTO PICKUP ============
RunService.Heartbeat:Connect(function()
    if not CFG.AutoPickup then return end
    local root = getRoot(LP) if not root then return end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and obj ~= getChar(LP) then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
            if part and (root.Position - part.Position).Magnitude < 40 then
                local name = obj.Name:lower()
                local priority = false
                if CFG.PickupPriority == "Random" then priority = true
                elseif CFG.PickupPriority == "Guns" and (name:find("gun") or name:find("weapon") or name:find("crossbow")) then priority = true
                elseif CFG.PickupPriority == "Heals" and (name:find("med") or name:find("kit")) then priority = true end
                if priority then
                    for _, v in ipairs(obj:GetDescendants()) do
                        if v:IsA("ProximityPrompt") then pcall(fireproximityprompt, v) end
                        if v:IsA("ClickDetector") then pcall(fireclickdetector, v) end
                    end
                end
            end
        end
    end
end)

-- ============ AUTO RESPAWN ============
local function clickRespawnUI()
    local guis = {CoreGui, LP:WaitForChild("PlayerGui")}
    for _, gui in ipairs(guis) do
        for _, obj in ipairs(gui:GetDescendants()) do
            if obj:IsA("TextButton") then
                local txt = obj.Text:lower()
                local nm = obj.Name:lower()
                if txt:find("select") or txt:find("respawn") or txt:find("spawn") or nm:find("select") then
                    pcall(function() obj:Fire("MouseButton1Click") end)
                    pcall(function() obj:Activate() end)
                end
            end
        end
    end
end

local function findOwnBag()
    local root = getRoot(LP) if not root then return nil end
    local best, bDist = nil, 300
    local lname = LP.Name:lower()
    for _, obj in ipairs(Workspace:GetChildren()) do
        local n = obj.Name:lower()
        if n:find("bag") or n:find(lname) then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
            if part then
                local d = (root.Position - part.Position).Magnitude
                if d < bDist then best = part; bDist = d end
            end
        end
    end
    return best
end

LP.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum.Died:Connect(function()
            if not CFG.AutoRespawn then return end
            for i = 1, 15 do task.wait(1); clickRespawnUI() end
            if CFG.RespawnToBag then
                task.wait(1.5)
                local newRoot = getRoot(LP)
                local bag = findOwnBag()
                if newRoot and bag then newRoot.CFrame = bag.CFrame + Vector3.new(0, 5, 0) end
            end
        end)
    end
end)

-- ============ UI SYSTEM ============
if CoreGui:FindFirstChild("PrimodaxGUI") then CoreGui:FindFirstChild("PrimodaxGUI"):Destroy() end
local SG = Instance.new("ScreenGui")
SG.Name = "PrimodaxGUI"
SG.ResetOnSpawn = false
SG.IgnoreGuiInset = true
SG.Parent = CoreGui

local MF = Instance.new("Frame")
MF.Size = UDim2.fromOffset(300, 580)
MF.Position = UDim2.new(0.5, -150, 0.5, -290)
MF.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
MF.BorderSizePixel = 0
MF.Visible = false
MF.Parent = SG
Instance.new("UICorner", MF).CornerRadius = UDim.new(0, 12)
local mfStroke = Instance.new("UIStroke", MF); mfStroke.Color = Color3.fromRGB(255, 215, 0); mfStroke.Thickness = 1.5

local TB = Instance.new("Frame")
TB.Size = UDim2.new(1, 0, 0, 55); TB.BackgroundColor3 = Color3.fromRGB(255, 215, 0); TB.Parent = MF
Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 12)

local TL = Instance.new("TextLabel")
TL.Size = UDim2.new(1, -50, 0, 30); TL.Position = UDim2.new(0, 10, 0, 5); TL.BackgroundTransparency = 1
TL.Text = "⚡ PRIMODAX VGRANT ⚡"; TL.TextColor3 = Color3.fromRGB(0, 0, 0); TL.TextSize = 15; TL.Font = Enum.Font.GothamBold; TL.TextXAlignment = Enum.TextXAlignment.Left; TL.Parent = TB

local SUB = Instance.new("TextLabel")
SUB.Size = UDim2.new(1, -50, 0, 15); SUB.Position = UDim2.new(0, 10, 0, 28); SUB.BackgroundTransparency = 1
SUB.Text = "Vagrant Survival v10 | By: BoboyTagaAquarius"; SUB.TextColor3 = Color3.fromRGB(30, 30, 30); SUB.TextSize = 10; SUB.Font = Enum.Font.Gotham; SUB.TextXAlignment = Enum.TextXAlignment.Left; SUB.Parent = TB

local XBtn = Instance.new("TextButton")
XBtn.Size = UDim2.new(0, 36, 0, 36); XBtn.Position = UDim2.new(1, -42, 0, 10); XBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); XBtn.Text = "✕"; XBtn.TextColor3 = Color3.fromRGB(255, 215, 0); XBtn.TextSize = 16; XBtn.Font = Enum.Font.GothamBold; XBtn.Parent = TB
Instance.new("UICorner", XBtn).CornerRadius = UDim.new(1, 0)
XBtn.MouseButton1Click:Connect(function() MF.Visible = false end)

local SF = Instance.new("ScrollingFrame")
SF.Size = UDim2.new(1, -10, 1, -60); SF.Position = UDim2.new(0, 5, 0, 60); SF.BackgroundTransparency = 1; SF.ScrollBarThickness = 3; SF.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0); SF.CanvasSize = UDim2.new(0, 0, 0, 0); SF.AutomaticCanvasSize = Enum.AutomaticSize.Y; SF.Parent = MF
local Layout = Instance.new("UIListLayout"); Layout.Padding = UDim.new(0, 6); Layout.SortOrder = Enum.SortOrder.LayoutOrder; Layout.Parent = SF
local Pad = Instance.new("UIPadding"); Pad.PaddingTop = UDim.new(0, 8); Pad.PaddingBottom = UDim.new(0, 8); Pad.Parent = SF

-- UI Helpers
local function makeSection(text, order)
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -10, 0, 24); lbl.BackgroundTransparency = 1; lbl.Text = "── " .. text .. " ──"; lbl.TextColor3 = Color3.fromRGB(255, 215, 0); lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.LayoutOrder = order; lbl.Parent = SF
end
local function makeToggle(name, key, order)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, -10, 0, 32); btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.Font = Enum.Font.Gotham; btn.TextSize = 12; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.LayoutOrder = order; btn.Parent = SF
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local function update() btn.Text = "  " .. (CFG[key] and "🟢 " or "🔴 ") .. name; btn.BackgroundColor3 = CFG[key] and Color3.fromRGB(35, 80, 40) or Color3.fromRGB(30, 30, 30) end
    update()
    btn.MouseButton1Click:Connect(function() CFG[key] = not CFG[key]; update() end)
end
local function makeSlider(name, key, min, max, order, callback)
    local frame = Instance.new("Frame"); frame.Size = UDim2.new(1, -10, 0, 38); frame.BackgroundTransparency = 1; frame.LayoutOrder = order; frame.Parent = SF
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, 0, 0, 18); lbl.BackgroundTransparency = 1; lbl.Text = name .. ": " .. CFG[key]; lbl.TextColor3 = Color3.fromRGB(200, 200, 200); lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = frame
    local bar = Instance.new("TextButton"); bar.Size = UDim2.new(1, 0, 0, 10); bar.Position = UDim2.new(0, 0, 0, 22); bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40); bar.Text = ""; bar.Parent = frame
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame"); fill.Size = UDim2.new((CFG[key] - min) / (max - min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(255, 215, 0); fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local dragging = false
    bar.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
    local function processInput(x) 
        if not dragging then return end
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + rel * (max - min))
        CFG[key] = val; lbl.Text = name .. ": " .. val; fill.Size = UDim2.new(rel, 0, 1, 0)
        if callback then callback() end
    end
    bar.MouseMoved:Connect(function(x) processInput(x) end)
    UserInputService.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then processInput(input.Position.X) end end)
end
local function makeButton(name, color, order, callback)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, -10, 0, 32); btn.BackgroundColor3 = color; btn.Text = name; btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.Font = Enum.Font.GothamBold; btn.TextSize = 12; btn.LayoutOrder = order; btn.Parent = SF
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
end

-- Build Menu
makeSection("COMBAT", 1)
makeToggle("Silent Aim", "SilentAim", 2)
makeToggle("Aimbot", "Aimbot", 3)
makeSlider("Aimbot Smooth", "AimbotSmoothing", 0, 100, 4)
makeSlider("FOV Range", "FOVRange", 0, 360, 5)
makeToggle("Skip Friends", "SkipFriends", 6)

makeSection("WEAPONS", 10)
makeToggle("Unlimited Ammo", "UnlimitedAmmo", 11)
makeToggle("Force Reload (Crossbow)", "AutoReload", 12)

makeSection("MOVEMENT", 20)
makeToggle("Infinite Jump", "InfiniteJump", 21)
makeToggle("Auto Sprint (Safe)", "AutoSprint", 22)
makeSlider("Sprint Speed (Max 22)", "SprintSpeed", 16, 22, 23)

makeSection("VISUAL & CAMERA", 30)
makeToggle("ESP", "ESPEnabled", 31)
makeToggle("Wide Screen (Ipad View)", "WideScreen", 32, updateCameraFOV)
makeSlider("Camera FOV", "CameraFOV", 40, 120, 33, updateCameraFOV)

makeSection("LOOT & RESPAWN", 40)
makeToggle("Auto Pickup", "AutoPickup", 41)
makeToggle("Auto Respawn", "AutoRespawn", 42)
makeToggle("Respawn to Bag", "RespawnToBag", 43)

makeSection("SYSTEM", 50)
makeButton("Server Hop", Color3.fromRGB(180, 80, 80), 51, function()
    pcall(function()
        local data = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
        if data and data.data then for _, s in ipairs(data.data) do if s.playing < s.maxPlayers and s.id ~= game.JobId then TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP); return end end end
    end)
end)

-- Floating Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.fromOffset(60, 60); toggleBtn.Position = UDim2.new(0.5, -30, 1, -95); toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0); toggleBtn.Text = "⚡"; toggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0); toggleBtn.TextSize = 24; toggleBtn.Font = Enum.Font.GothamBold; toggleBtn.Parent = SG
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)

local drag, dragStart, startPos = false, nil, nil
toggleBtn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; dragStart = input.Position; startPos = toggleBtn.Position end end)
UserInputService.InputChanged:Connect(function(input) if drag and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then local delta = input.Position - dragStart; toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then drag = false; if startPos and math.abs(input.Position.X - dragStart.X) < 10 and math.abs(input.Position.Y - dragStart.Y) < 10 then MF.Visible = not MF.Visible end end end)

print("✅ PRIMODAX v6.6 Loaded — Safe Speed, Force Reload Activated")
