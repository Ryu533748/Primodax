-- Vagrant Survival v10 — Shell + RemoteSpy (iisang execute)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local CONFIG_PATH = "VagrantShell_config.json"

-- ============ CONFIG ============
local Config = {
    silentAim = false, fovRadius = 120, autoShoot = false, rangeBot = false,
    skipFriends = true, infiniteJump = false, autoRespawn = false,
    autoLoot = false, espLoot = false, espGuns = false,
    antiAfk = true, autoServerHop = false,
}
local function saveConfig()
    if writefile then writefile(CONFIG_PATH, HttpService:JSONEncode(Config)) end
end
local function loadConfig()
    if isfile and isfile(CONFIG_PATH) then
        local ok, d = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_PATH)) end)
        if ok and type(d) == "table" then
            for k, v in pairs(d) do if Config[k] ~= nil then Config[k] = v end end
        end
    end
end
loadConfig()

-- ============ PROVIDER (pupunan mo pagkatapos ng spy) ============
local Provider = {
    fireWeapon = function(targetPos) end,
    respawnRemote = function() end,
    lootPrompt = function(p) p:InputHoldBegin(); task.wait(0.1); p:InputHoldEnd() end,
    getLootFolder = function() return nil end,
    getWeaponModels = function() return nil end,
}

-- ============ REMOTESPY ============
-- Kinakabit sa lahat ng RemoteEvent / RemoteFunction. Nililista ang path + args.
-- Hook: __namecall (mas mabilis at malinis kaysa sa babad na pcall loop).

local spyLog = {}          -- {text, time} para sa UI
local spyHookEnabled = true
local MAX_LOG = 200
local seenPaths = {}

local function pushLog(line)
    table.insert(spyLog, 1, { text = line, t = os.time() })
    while #spyLog > MAX_LOG do table.remove(spyLog) end
    if SpyWindow and SpyWindow.update then SpyWindow.update() end
end

local function serializeArg(a)
    local t = typeof(a)
    if t == "Vector3" then return string.format("V3(%.1f,%.1f,%.1f)", a.X, a.Y, a.Z) end
    if t == "CFrame" then local p = a.Position; return string.format("CF(%.1f,%.1f,%.1f)", p.X, p.Y, p.Z) end
    if t == "Instance" then return a.ClassName..":"..a.Name end
    if t == "string" then
        if #a > 40 then return '"'..a:sub(1,37)..'..."' end
        return '"'..a..'"'
    end
    if t == "number" or t == "boolean" or t == "nil" then return tostring(a) end
    if t == "table" then
        local parts = {}
        for i = 1, math.min(#a, 4) do parts[i] = serializeArg(a[i]) end
        return "{"..table.concat(parts, ",").."}"
    end
    return "<"..t..">"
end

local function fullPath(inst)
    local parts = { inst.Name }
    local p = inst.Parent
    while p and p ~= game do
        table.insert(parts, 1, p.Name)
        p = p.Parent
    end
    return table.concat(parts, ".")
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if spyHookEnabled and (method == "FireServer" or method == "InvokeServer") then
        local ok, path = pcall(fullPath, self)
        if ok then
            local args = { ... }
            local argStr = {}
            for i = 1, math.min(#args, 5) do argStr[i] = serializeArg(args[i]) end
            pushLog(string.format("[%s] %s(%s)", method, path, table.concat(argStr, ", ")))
        end
    end
    return oldNamecall(self, ...)
end)

-- Para sa pumasok na remote (server → client), kailangan i-hook ang bindable.
-- Ginagawa namin sa pag-scan ng ReplicatedStorage at pag-hook ng OnClientEvent.

local function hookIncoming(remote)
    if not remote:IsA("RemoteEvent") then return end
    if seenPaths[remote] then return end
    seenPaths[remote] = true
    local ok = pcall(function()
        remote.OnClientEvent:Connect(function(...)
            local args = { ... }
            local argStr = {}
            for i = 1, math.min(#args, 5) do argStr[i] = serializeArg(args[i]) end
            pushLog(string.format("[IN] %s(%s)", fullPath(remote), table.concat(argStr, ", ")))
        end)
    end)
end

for _, v in ipairs(game:GetDescendants()) do
    if v:IsA("RemoteEvent") then hookIncoming(v) end
end
game.DescendantAdded:Connect(function(v)
    if v:IsA("RemoteEvent") then hookIncoming(v) end
end)

-- ============ ESP ============
local espFolder = Instance.new("Folder")
espFolder.Name = "VagrantESP"; espFolder.Parent = CoreGui
local espCache = {}
local function addEsp(inst, color, label)
    if espCache[inst] then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Size = inst:IsA("BasePart") and inst.Size or Vector3.new(4,4,4)
    box.Adornee = inst; box.AlwaysOnTop = true; box.ZIndex = 10
    box.Transparency = 0.5; box.Color3 = color; box.Parent = espFolder
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0,120,0,24); bb.AlwaysOnTop = true
    bb.StudsOffset = Vector3.new(0,2,0); bb.Adornee = inst; bb.Parent = espFolder
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.fromScale(1,1); txt.BackgroundTransparency = 1
    txt.TextColor3 = color; txt.TextStrokeTransparency = 0
    txt.Text = label; txt.TextScaled = true; txt.Parent = bb
    espCache[inst] = { box = box, gui = bb, tag = label }
end
local function removeEsp(inst)
    if espCache[inst] then
        espCache[inst].box:Destroy(); espCache[inst].gui:Destroy(); espCache[inst] = nil
    end
end
local function refreshEsp()
    if Config.espLoot then
        local folder = Provider.getLootFolder()
        if folder then
            for _, v in ipairs(folder:GetDescendants()) do
                if v:IsA("Model") or v:IsA("BasePart") then addEsp(v, Color3.fromRGB(0,255,120), "LOOT") end
            end
        end
    end
    if Config.espGuns then
        local folder = Provider.getWeaponModels()
        if folder then
            for _, v in ipairs(folder:GetDescendants()) do
                if v:IsA("Model") or v:IsA("BasePart") then addEsp(v, Color3.fromRGB(255,80,80), "GUN") end
            end
        end
    end
    for inst, data in pairs(espCache) do
        local shouldKeep = (data.tag == "LOOT" and Config.espLoot) or (data.tag == "GUN" and Config.espGuns)
        if not shouldKeep then removeEsp(inst) end
    end
end
RunService.Heartbeat:Connect(refreshEsp)

-- ============ AIM / FOV ============
local fovGui = Instance.new("Frame")
fovGui.Name = "VagrantFOV"; fovGui.BackgroundTransparency = 1
fovGui.Size = UDim2.fromOffset(Config.fovRadius*2, Config.fovRadius*2)
fovGui.Position = UDim2.fromScale(0.5, 0.5)
fovGui.AnchorPoint = Vector2.new(0.5, 0.5); fovGui.Parent = CoreGui
Instance.new("UICorner", fovGui).CornerRadius = UDim.new(1, 0)
local fovStroke = Instance.new("UIStroke", fovGui)
fovStroke.Color = Color3.new(1,1,1); fovStroke.Transparency = 0.6

local function inFov(pos)
    local cam = workspace.CurrentCamera
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    return (Vector2.new(pos.X, pos.Y) - center).Magnitude <= Config.fovRadius
end
local function getTarget()
    local cam = workspace.CurrentCamera
    local best, bestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local head = p.Character:FindFirstChild("Head")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                local isFriend = LP:IsFriendsWith(p.UserId)
                if not (Config.skipFriends and isFriend) then
                    local pos, onScreen = cam:WorldToViewportPoint(head.Position)
                    if onScreen and inFov(pos) then
                        local d = (head.Position - cam.CFrame.Position).Magnitude
                        if d < bestDist then best, bestDist = head, d end
                    end
                end
            end
        end
    end
    return best
end
RunService.RenderStepped:Connect(function()
    if Config.silentAim then
        local t = getTarget()
        if t and Config.autoShoot then Provider.fireWeapon(t.Position) end
    end
end)

-- ============ INFINITE JUMP ============
local function doInfJump()
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if tick() - (doInfJump._last or 0) < 0.15 then return end
    doInfJump._last = tick()
    hrp.Velocity = Vector3.new(hrp.Velocity.X, 55, hrp.Velocity.Z)
end
UserInputService.JumpRequest:Connect(function()
    if Config.infiniteJump then doInfJump() end
end)

-- ============ ANTI-AFK / RESPAWN / LOOT ============
LP.Idled:Connect(function()
    if Config.antiAfk then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end
end)
RunService.Heartbeat:Connect(function()
    if Config.autoRespawn and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then Provider.respawnRemote() end
    end
end)
RunService.Heartbeat:Connect(function()
    if not Config.autoLoot then return end
    local loot = Provider.getLootFolder(); if not loot then return end
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    for _, v in ipairs(loot:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Enabled then
            local part = v.Parent
            if part and part:IsA("BasePart") and
               (part.Position - char.HumanoidRootPart.Position).Magnitude < 10 then
                Provider.lootPrompt(v)
            end
        end
    end
end)

-- ============ SERVER HOP ============
local function serverHop()
    local ok, servers = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if ok and servers and servers.data then
        for _, s in ipairs(servers.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP); return
            end
        end
    end
end

-- ============ UI: MAIN MENU ============
local function makeToggle(parent, label, key)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 26); row.BackgroundTransparency = 1; row.Parent = parent
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -60, 1, 0); txt.BackgroundTransparency = 1
    txt.TextColor3 = Color3.new(1,1,1); txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Font = Enum.Font.Gotham; txt.TextSize = 13; txt.Text = label; txt.Parent = row
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 48, 0, 20); btn.Position = UDim2.new(1, -48, 0, 3)
    btn.BackgroundColor3 = Config[key] and Color3.fromRGB(60,180,90) or Color3.fromRGB(60,60,60)
    btn.Text = Config[key] and "ON" or "OFF"; btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
    btn.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]
        btn.Text = Config[key] and "ON" or "OFF"
        btn.BackgroundColor3 = Config[key] and Color3.fromRGB(60,180,90) or Color3.fromRGB(60,60,60)
        saveConfig()
    end)
end

local function makeSlider(parent, label, key, min, max)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 40); row.BackgroundTransparency = 1; row.Parent = parent
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 0, 16); txt.BackgroundTransparency = 1
    txt.TextColor3 = Color3.new(1,1,1); txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Font = Enum.Font.Gotham; txt.TextSize = 12; txt.Text = label..": "..Config[key]; txt.Parent = row
    local bar = Instance.new("TextButton")
    bar.Size = UDim2.new(1, 0, 0, 6); bar.Position = UDim2.new(0, 0, 0, 22)
    bar.BackgroundColor3 = Color3.fromRGB(50,50,50); bar.Text = ""; bar.Parent = row
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((Config[key]-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(80,160,255); fill.Parent = bar
    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0, 10, 0, 14)
    handle.Position = UDim2.new((Config[key]-min)/(max-min), -5, -4, 0)
    handle.BackgroundColor3 = Color3.new(1,1,1); handle.Parent = bar
    local dragging = false
    bar.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    bar.MouseMoved:Connect(function(x)
        if dragging then
            local rel = math.clamp((x - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + rel*(max-min))
            Config[key] = val; txt.Text = label..": "..val
            fill.Size = UDim2.new(rel, 0, 1, 0)
            handle.Position = UDim2.new(rel, -5, -4, 0)
            if key == "fovRadius" then fovGui.Size = UDim2.fromOffset(val*2, val*2) end
            saveConfig()
        end
    end)
end

local function makeButton(parent, label, cb, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -10, 0, 26)
    b.BackgroundColor3 = color or Color3.fromRGB(45,45,55)
    b.Text = label; b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.Gotham; b.TextSize = 12; b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,4)
    b.MouseButton1Click:Connect(cb); return b
end

local function makeHeader(parent, text, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -10, 0, 24); l.BackgroundTransparency = 1
    l.TextColor3 = color or Color3.fromRGB(160,180,255)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.GothamBold; l.TextSize = 12; l.Text = "— "..text; l.Parent = parent
end

-- Main window
local win = Instance.new("Frame")
win.Name = "VagrantMenu"; win.Size = UDim2.fromOffset(280, 540)
win.Position = UDim2.new(0, 40, 0, 60)
win.BackgroundColor3 = Color3.fromRGB(20,20,25); win.BorderSizePixel = 0
win.Parent = CoreGui
Instance.new("UICorner", win).CornerRadius = UDim.new(0,8)
local ws = Instance.new("UIStroke", win)
ws.Color = Color3.fromRGB(80,80,120); ws.Thickness = 1

local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,30)
header.BackgroundColor3 = Color3.fromRGB(35,35,45); header.Parent = win
Instance.new("UICorner", header).CornerRadius = UDim.new(0,8)
local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1,1); title.BackgroundTransparency = 1
title.Text = "Vagrant Survival — Shell"
title.TextColor3 = Color3.new(1,1,1); title.Font = Enum.Font.GothamBold
title.TextSize = 13; title.Parent = header

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -40); scroll.Position = UDim2.new(0, 10, 0, 35)
scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 3
scroll.CanvasSize = UDim2.new(0,0,0,900); scroll.Parent = win

makeHeader(scroll, "COMBAT")
makeToggle(scroll, "Silent Aim", "silentAim")
makeSlider(scroll, "FOV Radius", "fovRadius", 40, 400)
makeToggle(scroll, "Auto Shoot", "autoShoot")
makeToggle(scroll, "Range Bot (any angle)", "rangeBot")
makeToggle(scroll, "Skip Friends", "skipFriends")
makeHeader(scroll, "ABILITIES")
makeToggle(scroll, "Infinite Jump (hover)", "infiniteJump")
makeToggle(scroll, "Auto Respawn", "autoRespawn")
makeToggle(scroll, "Auto Loot", "autoLoot")
makeToggle(scroll, "ESP Loot", "espLoot")
makeToggle(scroll, "ESP Guns", "espGuns")
makeHeader(scroll, "SYSTEM")
makeToggle(scroll, "Anti-AFK", "antiAfk")
makeToggle(scroll, "Auto Server Hop", "autoServerHop")
makeHeader(scroll, "CONFIG")
makeButton(scroll, "Save Config", saveConfig)
makeButton(scroll, "Export Config (copied)", function()
    local d = HttpService:JSONEncode(Config)
    if setclipboard then setclipboard(d) end
end)
makeButton(scroll, "Import Config (from clipboard)", function()
    local d
    if getclipboard then d = getclipboard() end
    if not d then return end
    local ok, parsed = pcall(function() return HttpService:JSONDecode(d) end)
    if ok and type(parsed) == "table" then
        for k, v in pairs(parsed) do if Config[k] ~= nil then Config[k] = v end end
        saveConfig()
    end
end)
makeButton(scroll, "Server Hop", serverHop)
makeButton(scroll, "Open RemoteSpy Window", function()
    if SpyWindow then SpyWindow.show() end
end, Color3.fromRGB(60,60,110))

-- ============ UI: SPY WINDOW ============
local spyWin = Instance.new("Frame")
spyWin.Name = "VagrantSpy"; spyWin.Size = UDim2.fromOffset(380, 400)
spyWin.Position = UDim2.new(0, 340, 0, 60)
spyWin.BackgroundColor3 = Color3.fromRGB(15,15,20); spyWin.BorderSizePixel = 0
spyWin.Parent = CoreGui; spyWin.Visible = false
Instance.new("UICorner", spyWin).CornerRadius = UDim.new(0,8)
local sps = Instance.new("UIStroke", spyWin)
sps.Color = Color3.fromRGB(80,80,120); sps.Thickness = 1

local spyHeader = Instance.new("Frame")
spyHeader.Size = UDim2.new(1,0,0,30)
spyHeader.BackgroundColor3 = Color3.fromRGB(35,35,50); spyHeader.Parent = spyWin
Instance.new("UICorner", spyHeader).CornerRadius = UDim.new(0,8)
local spyTitle = Instance.new("TextLabel")
spyTitle.Size = UDim2.fromScale(1,1); spyTitle.BackgroundTransparency = 1
spyTitle.Text = "RemoteSpy — live"
spyTitle.TextColor3 = Color3.new(1,1,1); spyTitle.Font = Enum.Font.GothamBold
spyTitle.TextSize = 12; spyTitle.Parent = spyHeader

local spyList = Instance.new("ScrollingFrame")
spyList.Size = UDim2.new(1, -20, 1, -80)
spyList.Position = UDim2.new(0, 10, 0, 35)
spyList.BackgroundTransparency = 1; spyList.ScrollBarThickness = 3
spyList.CanvasSize = UDim2.new(0,0,0,0); spyList.Parent = spyWin

local buttonRow = Instance.new("Frame")
buttonRow.Size = UDim2.new(1, -20, 0, 34)
buttonRow.Position = UDim2.new(0, 10, 1, -40)
buttonRow.BackgroundTransparency = 1; buttonRow.Parent = spyWin

local function spyBtn(label, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 100, 0, 26)
    b.BackgroundColor3 = Color3.fromRGB(45,45,55)
    b.Text = label; b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.Gotham; b.TextSize = 11
    b.Parent = buttonRow
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,4)
    b.MouseButton1Click:Connect(cb); return b
end

local copyBtn = spyBtn("Copy Selected", function() end)
copyBtn.Position = UDim2.new(0, 0, 0, 0)
local clearBtn = spyBtn("Clear", function() spyLog = {}; SpyWindow.update() end)
clearBtn.Position = UDim2.new(0, 106, 0, 0)
local pauseBtn = spyBtn("Pause", function()
    spyHookEnabled = not spyHookEnabled
    pauseBtn.Text = spyHookEnabled and "Pause" or "Resume"
    pauseBtn.BackgroundColor3 = spyHookEnabled and Color3.fromRGB(45,45,55) or Color3.fromRGB(180,80,80)
end)
pauseBtn.Position = UDim2.new(0, 212, 0, 0)

local function renderSpy()
    for _, c in ipairs(spyList:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end
    local y = 0
    for _, entry in ipairs(spyLog) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -4, 0, 22)
        b.Position = UDim2.new(0, 0, 0, y)
        b.BackgroundColor3 = Color3.fromRGB(25,25,30)
        b.TextColor3 = Color3.fromRGB(200,220,255)
        b.Font = Enum.Font.Code; b.TextSize = 11
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.Text = entry.text
        b.Parent = spyList
        b.MouseButton1Click:Connect(function()
            if setclipboard then setclipboard(entry.text) end
        end)
        y = y + 24
    end
    spyList.CanvasSize = UDim2.new(0, 0, 0, y + 10)
end

SpyWindow = { update = renderSpy, show = function() spyWin.Visible = true; renderSpy() end }

-- drag for both windows
local function draggable(frame, handle)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = i.Position; startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                       startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end
draggable(win, header)
draggable(spyWin, spyHeader)

-- initial spy render
renderSpy()
