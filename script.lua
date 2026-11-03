-- ██████╗ ██████╗ ██╗███╗   ███╗ ██████╗ ██████╗  █████╗ ██╗  ██╗
-- ██╔══██╗██╔══██╗██║████╗ ████║██╔═══██╗██╔══██╗██╔══██╗╚██╗██╔╝
-- ██████╔╝██████╔╝██║██╔████╔██║██║   ██║██║  ██║███████║ ╚███╔╝
-- ██╔═══╝ ██╔══██╗██║██║╚██╔╝██║██║   ██║██║  ██║██╔══██║ ██╔██╗
-- ██║     ██║  ██║██║██║ ╚═╝ ██║╚██████╔╝██████╔╝██║  ██║██╔╝ ██╗
-- ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
-- PRIMODAX HUB | VAGRANT SURVIVAL
-- Created By: BoboyTagaAquarius

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")
local CoreGui          = game:GetService("CoreGui")
local VirtualUser      = game:GetService("VirtualUser")
local StarterGui       = game:GetService("StarterGui")

local LP  = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

-- ════════════════════════════════════════
--              CONFIG
-- ════════════════════════════════════════
local CFG = {
    -- Silent Aim
    SilentAim       = false,
    WallCheck       = false,
    TargetPart      = "HumanoidRootPart",
    Priority        = "Crosshair",
    -- Rage Bot
    RageBot         = false,
    AutoFire        = false,
    VisibleCheck    = false,
    RageTarget      = "Head",
    MaxDistance     = 500,
    -- Weapons Mod
    NoRecoil        = false,
    NoSpread        = false,
    -- Visual
    PlayerESP       = false,
    BoxESP          = false,
    BoxFill         = false,
    FillTransparency= 0.7,
    TeamColor       = false,
    NameESP         = false,
    DistanceESP     = false,
    HealthBar       = false,
    Chams           = false,
    ESPMaxDist      = 10000,
    -- Player
    WalkSpeed       = 16,
    FlySpeed        = 60,
    IsFlying        = false,
    InfiniteJump    = false,
    AutoSprint      = false,
    SprintSpeed     = 22,
    NoClip          = false,
    GodMode         = false,
    -- FOV
    FOVRange        = 150,
    AimbotSmooth    = 15,
}

-- ════════════════════════════════════════
--              UTILS
-- ════════════════════════════════════════
local function getChar()  return LP.Character end
local function getRoot()  local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()   local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function isAlive(p)
    if not p or not p.Character then return false end
    local h = p.Character:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function isVisible(origin, target)
    local result = Workspace:Raycast(
        origin,
        (target - origin),
        RaycastParams.new()
    )
    if result then
        local hit = result.Instance
        if hit and hit:IsDescendantOf(Workspace) then
            -- check if it hit a player part
            local char = hit:FindFirstAncestorOfClass("Model")
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character == char and p ~= LP then return true end
            end
            return false
        end
    end
    return true
end

-- ════════════════════════════════════════
--              PREDICTOR
-- ════════════════════════════════════════
local prevPositions = {}
local prevTimes     = {}

local function getPredictedPosition(player, partName)
    local char = player.Character
    if not char then return nil end
    local part = char:FindFirstChild(partName)
    if not part then return nil end

    local now = tick()
    local pid = player.UserId

    local vel = Vector3.new(0,0,0)
    if prevPositions[pid] and prevTimes[pid] then
        local dt = now - prevTimes[pid]
        if dt > 0 and dt < 0.5 then
            vel = (part.Position - prevPositions[pid]) / dt
        end
    end

    prevPositions[pid] = part.Position
    prevTimes[pid]     = now

    -- predict ~2 frames ahead
    local ping = LP:GetNetworkPing()
    local ahead = ping + (1/60)*2
    return part.Position + vel * ahead
end

-- ════════════════════════════════════════
--              TARGET ENGINE
-- ════════════════════════════════════════
local activeTarget = nil
local fovCircle    = Drawing.new("Circle")
fovCircle.Thickness = 1.5
fovCircle.Color     = Color3.fromRGB(140, 80, 255)
fovCircle.Filled    = false
fovCircle.Visible   = false

local function getBestTarget(partName)
    local center  = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
    local best, bestDist = nil, CFG.FOVRange
    local root = getRoot()
    if not root then return nil end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isAlive(p) then
            local char = p.Character
            local tPart = char and char:FindFirstChild(partName)
            if tPart then
                local worldDist = (root.Position - tPart.Position).Magnitude
                if worldDist <= CFG.MaxDistance then
                    if not CFG.VisibleCheck or isVisible(root.Position, tPart.Position) then
                        local sPos, onS = Cam:WorldToViewportPoint(tPart.Position)
                        if onS then
                            local screen2D = Vector2.new(sPos.X, sPos.Y)
                            local d2D
                            if CFG.Priority == "Crosshair" then
                                d2D = (screen2D - center).Magnitude
                            else
                                d2D = worldDist / 10
                            end
                            if d2D < bestDist then
                                best     = p
                                bestDist = d2D
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
    fovCircle.Radius   = CFG.FOVRange
    fovCircle.Visible  = CFG.SilentAim or CFG.RageBot

    activeTarget = getBestTarget(CFG.TargetPart)
end)

-- ════════════════════════════════════════
--    SILENT AIM HOOK (FIXED — no reload break)
-- ════════════════════════════════════════
-- Only redirects Vector3/CFrame args when a valid target exists.
-- Does NOT touch reload or any non-aim remotes.
local saHook
if hookmetamethod then
    saHook = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args   = {...}

        if CFG.SilentAim
        and (method == "FireServer" or method == "InvokeServer")
        and activeTarget and isAlive(activeTarget)
        then
            -- only redirect if this looks like a shoot remote
            -- heuristic: remote name contains shoot/fire/attack/damage
            local reName = self.Name:lower()
            local isShoot = reName:find("shoot") or reName:find("fire")
                or reName:find("attack") or reName:find("damage")
                or reName:find("hit") or reName:find("bullet")
                or reName:find("proj")

            if isShoot then
                local predicted = getPredictedPosition(activeTarget, CFG.TargetPart)
                    or activeTarget.Character
                    and activeTarget.Character:FindFirstChild(CFG.TargetPart)
                    and activeTarget.Character[CFG.TargetPart].Position

                if predicted then
                    for i, v in ipairs(args) do
                        if typeof(v) == "Vector3" then
                            args[i] = predicted
                        elseif typeof(v) == "CFrame" then
                            args[i] = CFrame.lookAt(Cam.CFrame.Position, predicted)
                        elseif typeof(v) == "Instance" and v:IsA("BasePart") then
                            local tp = activeTarget.Character
                                and activeTarget.Character:FindFirstChild(CFG.TargetPart)
                            if tp then args[i] = tp end
                        end
                    end
                end
            end
        end

        return saHook(self, table.unpack(args))
    end))
end

-- ════════════════════════════════════════
--    NO RECOIL / NO SPREAD
-- ════════════════════════════════════════
if hookmetamethod and saHook then
    -- already hooked above; extend in same hook not needed separately
    -- NoRecoil: zero out camera kick via RenderStepped
end

local lastCamCF = CFrame.new()
RunService.RenderStepped:Connect(function()
    if CFG.NoRecoil then
        local root = getRoot()
        if root then
            -- lock camera pitch drift caused by recoil
            local cf   = Cam.CFrame
            local yaw  = math.atan2(-cf.LookVector.X, -cf.LookVector.Z)
            local pitch = math.asin(cf.LookVector.Y)
            if math.abs(pitch) > 0.8 then
                Cam.CFrame = CFrame.new(cf.Position)
                    * CFrame.Angles(0, yaw, 0)
                    * CFrame.Angles(math.clamp(pitch, -0.8, 0.8), 0, 0)
            end
        end
    end
end)

-- ════════════════════════════════════════
--              ESP (Drawing API)
-- ════════════════════════════════════════
local espObjects = {}

local function removeESP(p)
    if espObjects[p] then
        for _, d in pairs(espObjects[p]) do pcall(function() d:Remove() end) end
        espObjects[p] = nil
    end
end

local function ensureESP(p)
    if espObjects[p] or p == LP then return end
    espObjects[p] = {
        Box    = Drawing.new("Square"),
        Fill   = Drawing.new("Square"),
        Name   = Drawing.new("Text"),
        Dist   = Drawing.new("Text"),
        Health = Drawing.new("Square"),
        HealthFill = Drawing.new("Square"),
    }
    local e = espObjects[p]
    e.Box.Thickness  = 1; e.Box.Filled = false; e.Box.Visible = false
    e.Fill.Filled    = true; e.Fill.Visible = false
    e.Name.Size      = 13; e.Name.Center = true; e.Name.Outline = true; e.Name.Visible = false
    e.Dist.Size      = 11; e.Dist.Center = true; e.Dist.Outline = true; e.Dist.Visible = false
    e.Health.Thickness = 1; e.Health.Filled = false; e.Health.Visible = false
    e.HealthFill.Filled = true; e.HealthFill.Visible = false
end

for _, p in ipairs(Players:GetPlayers()) do ensureESP(p) end
Players.PlayerAdded:Connect(ensureESP)
Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
    local root = getRoot()
    for p, e in pairs(espObjects) do
        local show = CFG.PlayerESP and isAlive(p)
        if show then
            local head = p.Character:FindFirstChild("Head")
            local hum  = p.Character:FindFirstChildOfClass("Humanoid")
            local hrp  = p.Character:FindFirstChild("HumanoidRootPart")
            if head and hrp then
                local dist = root and (root.Position - hrp.Position).Magnitude or 0
                if dist > CFG.ESPMaxDist then
                    for _, d in pairs(e) do d.Visible = false end
                    continue
                end

                local topPos, topOn = Cam:WorldToViewportPoint(head.Position + Vector3.new(0,0.7,0))
                local botPos, botOn = Cam:WorldToViewportPoint(hrp.Position - Vector3.new(0,3,0))

                if topOn and botOn then
                    local h    = math.abs(topPos.Y - botPos.Y)
                    local w    = h * 0.5
                    local x    = topPos.X - w/2
                    local y    = topPos.Y
                    local col  = CFG.TeamColor
                        and (p.TeamColor and p.TeamColor.Color or Color3.fromRGB(255,50,50))
                        or  Color3.fromRGB(255,50,50)

                    if CFG.BoxESP then
                        e.Box.Visible   = true
                        e.Box.Size      = Vector2.new(w, h)
                        e.Box.Position  = Vector2.new(x, y)
                        e.Box.Color     = col
                    else e.Box.Visible = false end

                    if CFG.BoxFill then
                        e.Fill.Visible      = true
                        e.Fill.Size         = Vector2.new(w, h)
                        e.Fill.Position     = Vector2.new(x, y)
                        e.Fill.Color        = col
                        e.Fill.Transparency = CFG.FillTransparency
                    else e.Fill.Visible = false end

                    if CFG.NameESP then
                        e.Name.Visible   = true
                        e.Name.Text      = p.Name
                        e.Name.Position  = Vector2.new(topPos.X, y - 16)
                        e.Name.Color     = Color3.fromRGB(255,255,255)
                    else e.Name.Visible = false end

                    if CFG.DistanceESP then
                        e.Dist.Visible  = true
                        e.Dist.Text     = math.floor(dist) .. "m"
                        e.Dist.Position = Vector2.new(topPos.X, botPos.Y + 4)
                        e.Dist.Color    = Color3.fromRGB(200,200,200)
                    else e.Dist.Visible = false end

                    if CFG.HealthBar and hum then
                        local hp  = hum.Health / hum.MaxHealth
                        local bx  = x - 6
                        e.Health.Visible   = true
                        e.Health.Size      = Vector2.new(4, h)
                        e.Health.Position  = Vector2.new(bx, y)
                        e.Health.Color     = Color3.fromRGB(50,50,50)
                        e.HealthFill.Visible  = true
                        e.HealthFill.Size     = Vector2.new(4, h * hp)
                        e.HealthFill.Position = Vector2.new(bx, y + h*(1-hp))
                        e.HealthFill.Color    = Color3.fromRGB(
                            math.floor(255*(1-hp)), math.floor(255*hp), 0)
                    else
                        e.Health.Visible     = false
                        e.HealthFill.Visible = false
                    end

                    -- Chams
                    if CFG.Chams then
                        for _, part in ipairs(p.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.Material          = Enum.Material.Neon
                                part.BrickColor        = BrickColor.new("Bright violet")
                                part.CastShadow        = false
                            end
                        end
                    end
                else
                    for _, d in pairs(e) do d.Visible = false end
                end
            else
                for _, d in pairs(e) do d.Visible = false end
            end
        else
            for _, d in pairs(e) do d.Visible = false end
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
        local hum  = getHum(); local root = getRoot()
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
    pcall(function()
        local root = getRoot(); local hum = getHum(); local char = getChar()
        if not hum or not char then return end

        if CFG.GodMode then hum.Health = hum.MaxHealth end

        if CFG.AutoSprint then
            hum.WalkSpeed = CFG.SprintSpeed
        else
            hum.WalkSpeed = CFG.WalkSpeed
        end

        if CFG.NoClip then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end

        if CFG.IsFlying then
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
end)

-- ════════════════════════════════════════
--              GUI
-- ════════════════════════════════════════
local parentGui = (gethui and gethui()) or CoreGui
if parentGui:FindFirstChild("PrimoDaxVS") then
    parentGui:FindFirstChild("PrimoDaxVS"):Destroy()
end

local ACCENT  = Color3.fromRGB(140, 80, 255)   -- purple, matches screenshots
local BG_DARK = Color3.fromRGB(14, 14, 16)
local BG_CARD = Color3.fromRGB(26, 26, 30)
local BG_MID  = Color3.fromRGB(20, 20, 24)
local TXT     = Color3.fromRGB(240, 240, 240)
local TXT_DIM = Color3.fromRGB(150, 150, 160)

local Gui = Instance.new("ScreenGui")
Gui.Name           = "PrimoDaxVS"
Gui.ResetOnSpawn   = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent         = parentGui
if protect_gui then pcall(protect_gui, Gui) end

-- ════════════ FLOATING "P" BUTTON ════════════
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
Main.Size             = UDim2.new(0,580,0,360)
Main.Position         = UDim2.new(0.5,-290,0.5,-180)
Main.BackgroundColor3 = BG_DARK
Main.BorderSizePixel  = 0
Main.Visible          = false
Main.Active           = true
Main.Parent           = Gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,6)
local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Color     = Color3.fromRGB(45,45,50)
mainStroke.Thickness = 1

-- ════════════ SIDEBAR ════════════
local Sidebar = Instance.new("Frame")
Sidebar.Size             = UDim2.new(0,115,1,0)
Sidebar.BackgroundColor3 = BG_MID
Sidebar.BorderSizePixel  = 0
Sidebar.Parent           = Main
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0,6)

local STitle = Instance.new("TextLabel")
STitle.Text           = "PrimoDax Hub"
STitle.Font           = Enum.Font.GothamBold
STitle.TextSize       = 13
STitle.TextColor3     = ACCENT
STitle.Size           = UDim2.new(1,-10,0,22)
STitle.Position       = UDim2.new(0,8,0,6)
STitle.BackgroundTransparency = 1
STitle.TextXAlignment = Enum.TextXAlignment.Left
STitle.Parent         = Sidebar

local SBy = Instance.new("TextLabel")
SBy.Text           = "By: BoboyTagaAquarius"
SBy.Font           = Enum.Font.Gotham
SBy.TextSize       = 9
SBy.TextColor3     = TXT_DIM
SBy.Size           = UDim2.new(1,-10,0,12)
SBy.Position       = UDim2.new(0,8,0,26)
SBy.BackgroundTransparency = 1
SBy.TextXAlignment = Enum.TextXAlignment.Left
SBy.Parent         = Sidebar

-- ════════════ TOP BAR (drag area) ════════════
local TopBar = Instance.new("Frame")
TopBar.Size             = UDim2.new(1,-115,0,32)
TopBar.Position         = UDim2.new(0,115,0,0)
TopBar.BackgroundColor3 = BG_DARK
TopBar.BorderSizePixel  = 0
TopBar.Parent           = Main

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text             = "✕"
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 12
CloseBtn.TextColor3       = Color3.fromRGB(255,80,80)
CloseBtn.Size             = UDim2.new(0,28,0,22)
CloseBtn.Position         = UDim2.new(1,-32,0,5)
CloseBtn.BackgroundTransparency = 1
CloseBtn.BorderSizePixel  = 0
CloseBtn.Parent           = TopBar
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

-- drag main via topbar
local mDrag, mDragStart, mStartPos = false, nil, nil
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

-- ════════════ CONTENT SCROLL ════════════
local Content = Instance.new("ScrollingFrame")
Content.Size                = UDim2.new(1,-115,1,-32)
Content.Position            = UDim2.new(0,115,0,32)
Content.BackgroundTransparency = 1
Content.ScrollBarThickness  = 3
Content.ScrollBarImageColor3= ACCENT
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.CanvasSize          = UDim2.new(0,0,0,0)
Content.Parent              = Main
local ContentPad = Instance.new("UIPadding", Content)
ContentPad.PaddingLeft   = UDim.new(0,8)
ContentPad.PaddingRight  = UDim.new(0,8)
ContentPad.PaddingTop    = UDim.new(0,6)
ContentPad.PaddingBottom = UDim.new(0,6)

-- pages dict
local pages = {}
local function makePage(name)
    local f = Instance.new("Frame")
    f.Size                   = UDim2.new(1,0,1,0)
    f.AutomaticSize          = Enum.AutomaticSize.Y
    f.BackgroundTransparency = 1
    f.Visible                = false
    f.Parent                 = Content
    local l = Instance.new("UIListLayout", f)
    l.Padding   = UDim.new(0,8)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    pages[name] = f
    return f
end

local pageCombat   = makePage("Combat")
local pageVisual   = makePage("Visual")
local pagePlayer   = makePage("Player")
local pageSettings = makePage("Settings")

-- Sidebar tab buttons
local tabDefs = {
    {"Visual",   "👁", 1},
    {"Combat",   "⚔", 2},
    {"Player",   "🏃", 3},
    {"Settings", "⚙", 4},
}
local sideTabBtns = {}

local function switchPage(name)
    for n, p in pairs(pages) do p.Visible = (n == name) end
    for n, b in pairs(sideTabBtns) do
        b.TextColor3       = TXT_DIM
        b.BackgroundColor3 = BG_MID
    end
    if sideTabBtns[name] then
        sideTabBtns[name].TextColor3       = TXT
        sideTabBtns[name].BackgroundColor3 = BG_CARD
    end
end

for _, def in ipairs(tabDefs) do
    local name, icon, order = def[1], def[2], def[3]
    local btn = Instance.new("TextButton")
    btn.Text             = "  " .. icon .. "  " .. name
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 11
    btn.TextColor3       = TXT_DIM
    btn.Size             = UDim2.new(1,-10,0,32)
    btn.Position         = UDim2.new(0,5,0,42 + (order-1)*36)
    btn.BackgroundColor3 = BG_MID
    btn.BorderSizePixel  = 0
    btn.TextXAlignment   = Enum.TextXAlignment.Left
    btn.Parent           = Sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
    sideTabBtns[name] = btn
    btn.MouseButton1Click:Connect(function() switchPage(name) end)
end

-- Footer
local Footer = Instance.new("TextLabel")
Footer.Text           = "Vagrant Survival v1.0  |  discord.gg/krvsuC9jy"
Footer.Font           = Enum.Font.Gotham
Footer.TextSize       = 9
Footer.TextColor3     = TXT_DIM
Footer.Size           = UDim2.new(1,-10,0,14)
Footer.Position       = UDim2.new(0,5,1,-16)
Footer.BackgroundTransparency = 1
Footer.TextXAlignment = Enum.TextXAlignment.Left
Footer.Parent         = Sidebar

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
    row.Size             = UDim2.new(1,0,0,24)
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
        and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5)
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
            CFG[cfgKey] = not CFG[cfgKey]; refresh()
        end
    end)
    return row
end

local function mkSlider(parent, label, cfgKey, min, max, order)
    local frame = Instance.new("Frame")
    frame.Size             = UDim2.new(1,0,0,32)
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
    bar.Position         = UDim2.new(0,0,0,17)
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
    frame.Size             = UDim2.new(1,0,0,24)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder      = order or 0
    frame.Parent           = parent

    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1,0,1,0)
    btn.BackgroundColor3 = Color3.fromRGB(38,38,44)
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

    local list = Instance.new("Frame")
    list.Size             = UDim2.new(1,0,0,0)
    list.AutomaticSize    = Enum.AutomaticSize.Y
    list.Position         = UDim2.new(0,0,1,2)
    list.BackgroundColor3 = Color3.fromRGB(38,38,44)
    list.BorderSizePixel  = 0
    list.Visible          = false
    list.ZIndex           = 20
    list.Parent           = btn
    Instance.new("UICorner", list).CornerRadius = UDim.new(0,4)
    local lfl = Instance.new("UIListLayout", list)
    lfl.SortOrder = Enum.SortOrder.LayoutOrder

    for i, opt in ipairs(options) do
        local ob = Instance.new("TextButton")
        ob.Text             = opt
        ob.Font             = Enum.Font.Gotham
        ob.TextSize         = 10
        ob.TextColor3       = TXT
        ob.Size             = UDim2.new(1,0,0,22)
        ob.BackgroundTransparency = 1
        ob.BorderSizePixel  = 0
        ob.LayoutOrder      = i
        ob.ZIndex           = 21
        ob.Parent           = list
        ob.MouseButton1Click:Connect(function()
            CFG[cfgKey]  = opt
            lbl.Text     = label .. ": " .. opt
            list.Visible = false
        end)
    end
    btn.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
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

-- ════════════ POPULATE PAGES ════════════

-- VISUAL
do
    local c = mkCard(pageVisual, "👁  ESP", 1)
    mkToggle(c, "Enable ESP",    "PlayerESP",  1)
    mkToggle(c, "Box ESP",       "BoxESP",     2)
    mkToggle(c, "Box Fill",      "BoxFill",    3)
    mkSlider(c, "Fill Transparency","FillTransparency",0,1, 4)
    mkToggle(c, "Team Color",    "TeamColor",  5)
    mkToggle(c, "Name ESP",      "NameESP",    6)
    mkToggle(c, "Distance ESP",  "DistanceESP",7)
    mkToggle(c, "Health Bar",    "HealthBar",  8)
    mkToggle(c, "Chams",         "Chams",      9)
    mkSlider(c, "Max Distance",  "ESPMaxDist", 100, 10000, 10)
end

-- COMBAT
do
    local c = mkCard(pageCombat, "🎯  Silent Aim", 1)
    mkToggle(c,   "Enable Silent Aim", "SilentAim",  1)
    mkToggle(c,   "Wall Check",        "WallCheck",  2)
    mkDropdown(c, "Target Part", "TargetPart",
        {"HumanoidRootPart","Head","Torso"}, 3)
    mkDropdown(c, "Priority", "Priority",
        {"Crosshair","Distance"}, 4)
    mkSlider(c,   "FOV Range",  "FOVRange", 10, 500, 5)
end

do
    local c = mkCard(pageCombat, "🤖  Rage Bot", 2)
    mkToggle(c,   "Enable Rage Bot",  "RageBot",     1)
    mkToggle(c,   "Auto Fire",        "AutoFire",    2)
    mkToggle(c,   "Visible Check",    "VisibleCheck",3)
    mkDropdown(c, "Target Part", "RageTarget",
        {"Head","HumanoidRootPart","Torso"}, 4)
    mkSlider(c,   "Max Distance", "MaxDistance", 50, 5000, 5)
end

do
    local c = mkCard(pageCombat, "🔫  Weapons Mod", 3)
    mkToggle(c, "No Recoil", "NoRecoil", 1)
    mkToggle(c, "No Spread", "NoSpread", 2)
end

-- PLAYER
do
    local c = mkCard(pagePlayer, "🏃  Movement", 1)
    mkSlider(c,  "Walk Speed",  "WalkSpeed",  16, 250, 1)
    mkToggle(c,  "Auto Sprint", "AutoSprint", 2)
    mkSlider(c,  "Sprint Speed","SprintSpeed",16, 100, 3)
    mkToggle(c,  "Fly",         "IsFlying",   4)
    mkSlider(c,  "Fly Speed",   "FlySpeed",   10, 400, 5)
    mkToggle(c,  "Infinite Jump","InfiniteJump",6)
    mkToggle(c,  "No Clip",     "NoClip",     7)
    mkToggle(c,  "God Mode",    "GodMode",    8)
end

-- SETTINGS
do
    local c = mkCard(pageSettings, "🔧  Menu", 1)
    mkButton(c, "Reset Position", function()
        Main.Position = UDim2.new(0.5,-290,0.5,-180)
    end, 1)
    mkButton(c, "Toggle FOV Circle", function()
        fovCircle.Visible = not fovCircle.Visible
    end, 2)
end
do
    local c = mkCard(pageSettings, "💾  Configuration", 2)
    mkButton(c, "Save Config", function()
        pcall(function()
            local data = game:GetService("HttpService"):JSONEncode(CFG)
            setclipboard(data)
        end)
        pcall(function()
            StarterGui:SetCore("SendNotification",{
                Title="PrimoDax Hub",Text="Config copied to clipboard!",Duration=3})
        end)
    end, 1)
    mkButton(c, "Load Config (paste)", function()
        pcall(function()
            local data = getclipboard()
            local decoded = game:GetService("HttpService"):JSONDecode(data)
            for k, v in pairs(decoded) do
                if CFG[k] ~= nil then CFG[k] = v end
            end
        end)
    end, 2)
    mkButton(c, "Reset Autoload", function()
        pcall(function()
            StarterGui:SetCore("SendNotification",{
                Title="PrimoDax Hub",Text="Autoload reset.",Duration=2})
        end)
    end, 3)
end

-- ════════════ INIT ════════════
switchPage("Visual")

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Insert
    or input.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
    end
end)

pcall(function()
    StarterGui:SetCore("SendNotification",{
        Title   = "PrimoDax Hub",
        Text    = "Vagrant Survival loaded! By: BoboyTagaAquarius",
        Duration= 4,
    })
end)

print("[PrimoDax Hub | Vagrant Survival] Loaded — Created By: BoboyTagaAquarius")
