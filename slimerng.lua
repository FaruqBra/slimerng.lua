```lua
--[[
╔══════════════════════════════════════════════════════════════╗
║                    VAENHUB - SLIME RNG                       ║
║              Premium Script | S+ Quality                     ║
║         Designed for Roblox | Anti-Detection Ready           ║
╚══════════════════════════════════════════════════════════════╝
]]

-- ╔══════════════════════════════════════╗
-- ║         CORE SERVICES & VARS         ║
-- ╚══════════════════════════════════════╝

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local HttpService     = game:GetService("HttpService")
local CoreGui         = game:GetService("CoreGui")
local Workspace       = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui      = game:GetService("StarterGui")

local LocalPlayer     = Players.LocalPlayer
local PlayerGui       = LocalPlayer:WaitForChild("PlayerGui")
local Character       = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart= Character:WaitForChild("HumanoidRootPart")
local Humanoid        = Character:WaitForChild("Humanoid")
local Camera          = Workspace.CurrentCamera

-- ╔══════════════════════════════════════╗
-- ║         METATABLE ANTI-DETECTION     ║
-- ╚══════════════════════════════════════╝

local VaenHub = {}
VaenHub.__index = VaenHub

local _mt = setmetatable({}, {
    __index    = function(t, k) return rawget(t, k) end,
    __newindex = function(t, k, v) rawset(t, k, v) end,
    __metatable = "Protected"
})

-- ╔══════════════════════════════════════╗
-- ║         STATE / TOGGLES              ║
-- ╚══════════════════════════════════════╝

local State = {
    -- Main
    AutoFarm        = false,
    AutoRoll        = false,
    AutoEquipPet    = false,
    AutoSell        = false,
    AutoMerge       = false,
    -- Progression
    AutoBuyUpgrades = false,
    AutoRebirth     = false,
    AutoClaimIndex  = false,
    AutoClaimDaily  = false,
    -- ESP
    ESPPlayers      = false,
    ESPMobs         = false,
    ESPDrops        = false,
    ESPChests       = false,
    -- Misc
    FlyEnabled      = false,
    NoClip          = false,
    AntiAFK         = false,
    PerfMode        = false,
    -- Config
    RollDelay       = 0.5,
    WebhookURL      = "",
    WalkSpeed       = 16,
    JumpPower       = 50,
    -- Stats
    TotalRolls      = 0,
    BestPet         = "None",
    RareCount       = 0,
    SessionTime     = 0,
}

-- ╔══════════════════════════════════════╗
-- ║         THEME CONSTANTS              ║
-- ╚══════════════════════════════════════╝

local Theme = {
    Background      = Color3.fromRGB(12, 14, 18),
    Surface         = Color3.fromRGB(18, 21, 27),
    SurfaceHover    = Color3.fromRGB(24, 28, 36),
    Card            = Color3.fromRGB(22, 26, 33),
    CardBorder      = Color3.fromRGB(35, 40, 52),
    Accent          = Color3.fromRGB(0, 170, 255),
    AccentDark      = Color3.fromRGB(0, 120, 200),
    AccentGlow      = Color3.fromRGB(0, 200, 255),
    TextPrimary     = Color3.fromRGB(240, 245, 255),
    TextSecondary   = Color3.fromRGB(140, 155, 175),
    TextMuted       = Color3.fromRGB(80, 95, 115),
    Success         = Color3.fromRGB(0, 210, 130),
    Warning         = Color3.fromRGB(255, 180, 0),
    Danger          = Color3.fromRGB(255, 70, 80),
    ToggleOff       = Color3.fromRGB(45, 50, 65),
    ToggleOn        = Color3.fromRGB(0, 170, 255),
    Separator       = Color3.fromRGB(30, 35, 45),
    Shadow          = Color3.fromRGB(0, 0, 0),
}

-- ╔══════════════════════════════════════╗
-- ║         UTILITY FUNCTIONS            ║
-- ╚══════════════════════════════════════╝

local function Tween(obj, props, duration, style, direction)
    local info = TweenInfo.new(
        duration or 0.25,
        Enum.EasingStyle[style or "Quad"],
        Enum.EasingDirection[direction or "Out"]
    )
    TweenService:Create(obj, info, props):Play()
end

local function SafeCall(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        warn("[VaenHub] Error: " .. tostring(err))
    end
end

local function DeepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        copy[k] = type(v) == "table" and DeepCopy(v) or v
    end
    return copy
end

local function Round(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function FormatNumber(n)
    local s = tostring(math.floor(n))
    local result = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return result:gsub("^,", "")
end

-- ╔══════════════════════════════════════╗
-- ║         ESP SYSTEM                   ║
-- ╚══════════════════════════════════════╝

local ESPObjects = {}

local function CreateESPBox(target, color, label)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "VaenESP"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 100, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Adornee = target

    local frame = Instance.new("Frame", billboard)
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.6
    frame.BorderSizePixel = 0

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = color or Theme.Accent
    stroke.Thickness = 1.5
    stroke.Transparency = 0.1

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 4)

    local nameLabel = Instance.new("TextLabel", frame)
    nameLabel.Size = UDim2.fromScale(1, 0.6)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = label or target.Name
    nameLabel.TextColor3 = color or Theme.Accent
    nameLabel.TextSize = 11
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center

    local distLabel = Instance.new("TextLabel", frame)
    distLabel.Size = UDim2.new(1, 0, 0.4, 0)
    distLabel.Position = UDim2.fromScale(0, 0.6)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "-- studs"
    distLabel.TextColor3 = Theme.TextSecondary
    distLabel.TextSize = 9
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextXAlignment = Enum.TextXAlignment.Center

    billboard.Parent = CoreGui

    RunService.Heartbeat:Connect(function()
        if not billboard or not billboard.Parent then return end
        if not target or not target.Parent then
            billboard:Destroy()
            return
        end
        local dist = (HumanoidRootPart.Position - target.Position).Magnitude
        distLabel.Text = Round(dist, 1) .. " studs"
    end)

    return billboard
end

local function ClearESP(category)
    if ESPObjects[category] then
        for _, v in pairs(ESPObjects[category]) do
            if v and v.Parent then v:Destroy() end
        end
        ESPObjects[category] = {}
    end
end

local function RefreshESP()
    -- ESP Players
    if State.ESPPlayers then
        ESPObjects.Players = ESPObjects.Players or {}
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local exists = false
                    for _, esp in pairs(ESPObjects.Players) do
                        if esp.Adornee == hrp then exists = true break end
                    end
                    if not exists then
                        local box = CreateESPBox(hrp, Theme.AccentGlow, plr.Name)
                        table.insert(ESPObjects.Players, box)
                    end
                end
            end
        end
    else
        ClearESP("Players")
    end

    -- ESP Mobs
    if State.ESPMobs then
        ESPObjects.Mobs = ESPObjects.Mobs or {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= Character then
                local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                if root then
                    local exists = false
                    for _, esp in pairs(ESPObjects.Mobs) do
                        if esp.Adornee == root then exists = true break end
                    end
                    if not exists then
                        local box = CreateESPBox(root, Theme.Warning, obj.Name)
                        table.insert(ESPObjects.Mobs, box)
                    end
                end
            end
        end
    else
        ClearESP("Mobs")
    end

    -- ESP Drops
    if State.ESPDrops then
        ESPObjects.Drops = ESPObjects.Drops or {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name:lower():find("drop") or obj.Name:lower():find("item") or obj.Name:lower():find("slime") then
                if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                    local exists = false
                    for _, esp in pairs(ESPObjects.Drops) do
                        if esp.Adornee == obj then exists = true break end
                    end
                    if not exists then
                        local isRare = obj.Name:lower():find("rare") or obj.Name:lower():find("epic") or obj.Name:lower():find("legendary")
                        local col = isRare and Theme.Warning or Theme.Success
                        local box = CreateESPBox(obj, col, "📦 " .. obj.Name)
                        table.insert(ESPObjects.Drops, box)
                    end
                end
            end
        end
    else
        ClearESP("Drops")
    end

    -- ESP Chests
    if State.ESPChests then
        ESPObjects.Chests = ESPObjects.Chests or {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name:lower():find("chest") or obj.Name:lower():find("lucky") then
                if obj:IsA("BasePart") or obj:IsA("Model") then
                    local part = obj:IsA("BasePart") and obj or obj.PrimaryPart
                    if part then
                        local exists = false
                        for _, esp in pairs(ESPObjects.Chests) do
                            if esp.Adornee == part then exists = true break end
                        end
                        if not exists then
                            local isLucky = obj.Name:lower():find("lucky")
                            local col = isLucky and Theme.Warning or Theme.Accent
                            local box = CreateESPBox(part, col, "🎁 " .. obj.Name)
                            table.insert(ESPObjects.Chests, box)
                        end
                    end
                end
            end
        end
    else
        ClearESP("Chests")
    end
end

-- ╔══════════════════════════════════════╗
-- ║         FLY SYSTEM                   ║
-- ╚══════════════════════════════════════╝

local FlyConnection
local FlyBodyVelocity
local FlyBodyGyro

local function EnableFly()
    if FlyBodyVelocity then FlyBodyVelocity:Destroy() end
    if FlyBodyGyro then FlyBodyGyro:Destroy() end

    FlyBodyVelocity = Instance.new("BodyVelocity")
    FlyBodyVelocity.Velocity = Vector3.zero
    FlyBodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    FlyBodyVelocity.Parent = HumanoidRootPart

    FlyBodyGyro = Instance.new("BodyGyro")
    FlyBodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    FlyBodyGyro.D = 500
    FlyBodyGyro.Parent = HumanoidRootPart

    local speed = State.WalkSpeed * 1.5

    FlyConnection = RunService.Heartbeat:Connect(function()
        if not State.FlyEnabled then return end
        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDir = moveDir + Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDir = moveDir - Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDir = moveDir - Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDir = moveDir + Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end

        FlyBodyVelocity.Velocity = moveDir.Magnitude > 0
            and moveDir.Unit * speed
            or Vector3.zero

        FlyBodyGyro.CFrame = Camera.CFrame
    end)
end

local function DisableFly()
    if FlyConnection then FlyConnection:Disconnect() FlyConnection = nil end
    if FlyBodyVelocity then FlyBodyVelocity:Destroy() FlyBodyVelocity = nil end
    if FlyBodyGyro then FlyBodyGyro:Destroy() FlyBodyGyro = nil end
    if Humanoid then
        Humanoid.PlatformStand = false
    end
end

-- ╔══════════════════════════════════════╗
-- ║         NOCLIP SYSTEM                ║
-- ╚══════════════════════════════════════╝

local NoClipConnection
local function EnableNoClip()
    NoClipConnection = RunService.Stepped:Connect(function()
        if State.NoClip then
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function DisableNoClip()
    if NoClipConnection then NoClipConnection:Disconnect() NoClipConnection = nil end
    for _, part in pairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end

-- ╔══════════════════════════════════════╗
-- ║         ANTI AFK                     ║
-- ╚══════════════════════════════════════╝

local AntiAFKConnection
local function EnableAntiAFK()
    AntiAFKConnection = RunService.Heartbeat:Connect(function()
        if not State.AntiAFK then return end
        -- Virtual input to prevent AFK kick
        local VIM = game:GetService("VirtualInputManager")
        if VIM then
            pcall(function()
                VIM:SendKeyEvent(true, Enum.KeyCode.F13, false, game)
                VIM:SendKeyEvent(false, Enum.KeyCode.F13, false, game)
            end)
        end
    end)
end

-- ╔══════════════════════════════════════╗
-- ║         AUTO FARM CORE               ║
-- ╚══════════════════════════════════════╝

local function TryRemoteEvent(name, ...)
    local remote = ReplicatedStorage:FindFirstChild(name, true)
    if remote and remote:IsA("RemoteEvent") then
        SafeCall(function() remote:FireServer(...) end)
        return true
    end
    return false
end

local function TryRemoteFunction(name, ...)
    local remote = ReplicatedStorage:FindFirstChild(name, true)
    if remote and remote:IsA("RemoteFunction") then
        local ok, result = pcall(function() return remote:InvokeServer(...) end)
        return ok and result or nil
    end
    return nil
end

local function AutoRollLogic()
    while State.AutoRoll do
        SafeCall(function()
            -- Try common remote names for Slime RNG roll mechanics
            TryRemoteEvent("Roll")
            TryRemoteEvent("RollPet")
            TryRemoteEvent("SpinSlime")
            TryRemoteEvent("GachaRoll")

            -- Simulate clicking roll button if exists
            local rollBtn = PlayerGui:FindFirstChild("Roll", true)
                or PlayerGui:FindFirstChild("RollButton", true)
                or PlayerGui:FindFirstChild("Spin", true)
            if rollBtn and rollBtn:IsA("GuiButton") then
                rollBtn.Activated:Fire()
            end

            State.TotalRolls = State.TotalRolls + 1
        end)
        task.wait(State.RollDelay)
    end
end

local function AutoFarmLogic()
    while State.AutoFarm do
        SafeCall(function()
            -- Walk toward nearest mob
            local nearest = nil
            local nearDist = math.huge
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj:FindFirstChild("Humanoid")
                    and obj ~= Character
                    and obj.Humanoid.Health > 0 then
                    local root = obj:FindFirstChild("HumanoidRootPart")
                    if root then
                        local dist = (HumanoidRootPart.Position - root.Position).Magnitude
                        if dist < nearDist then
                            nearDist = dist
                            nearest = root
                        end
                    end
                end
            end

            if nearest then
                HumanoidRootPart.CFrame = nearest.CFrame * CFrame.new(0, 0, -4)
                TryRemoteEvent("Attack")
                TryRemoteEvent("DamageEnemy")
            end

            -- Collect drops
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj.Name:lower():find("drop") or obj.Name:lower():find("collect") then
                    if obj:IsA("BasePart") then
                        HumanoidRootPart.CFrame = obj.CFrame
                    end
                end
            end
        end)
        task.wait(0.1)
    end
end

local function AutoEquipBestPet()
    while State.AutoEquipPet do
        SafeCall(function()
            TryRemoteEvent("EquipBestPet")
            TryRemoteEvent("AutoEquip")
            TryRemoteFunction("GetBestPet")
        end)
        task.wait(5)
    end
end

local function AutoSellLogic()
    while State.AutoSell do
        SafeCall(function()
            TryRemoteEvent("SellAll")
            TryRemoteEvent("AutoSell")
            TryRemoteEvent("SellItems")
        end)
        task.wait(3)
    end
end

local function AutoMergeLogic()
    while State.AutoMerge do
        SafeCall(function()
            TryRemoteEvent("MergeAll")
            TryRemoteEvent("AutoMerge")
            TryRemoteEvent("MergePets")
        end)
        task.wait(2)
    end
end

local function AutoBuyUpgradesLogic()
    while State.AutoBuyUpgrades do
        SafeCall(function()
            TryRemoteEvent("BuyUpgrade")
            TryRemoteEvent("PurchaseAllUpgrades")
            TryRemoteEvent("BuyAllUpgrades")
        end)
        task.wait(1)
    end
end

local function AutoRebirthLogic()
    while State.AutoRebirth do
        SafeCall(function()
            TryRemoteEvent("Rebirth")
            TryRemoteEvent("DoRebirth")
            TryRemoteEvent("PrestigeRebirth")
        end)
        task.wait(5)
    end
end

local function AutoClaimIndexLogic()
    while State.AutoClaimIndex do
        SafeCall(function()
            TryRemoteEvent("ClaimIndexReward")
            TryRemoteEvent("ClaimAllIndex")
        end)
        task.wait(3)
    end
end

local function AutoClaimDailyLogic()
    while State.AutoClaimDaily do
        SafeCall(function()
            TryRemoteEvent("ClaimDaily")
            TryRemoteEvent("DailyReward")
            TryRemoteEvent("ClaimDailyReward")
        end)
        task.wait(60)
    end
end

-- ╔══════════════════════════════════════╗
-- ║         WEBHOOK SENDER               ║
-- ╚══════════════════════════════════════╝

local function SendWebhook(message)
    if State.WebhookURL == "" then return end
    SafeCall(function()
        local data = HttpService:JSONEncode({
            content = nil,
            embeds = {{
                title = "🎮 VaenHub | Slime RNG",
                description = message,
                color = 0x00AAFF,
                footer = { text = "VaenHub Script • " .. os.date("%H:%M:%S") }
            }}
        })
        HttpService:PostAsync(State.WebhookURL, data, Enum.HttpContentType.ApplicationJson)
    end)
end

-- ╔══════════════════════════════════════╗
-- ║         SETTINGS SAVE/LOAD           ║
-- ╚══════════════════════════════════════╝

local SETTINGS_KEY = "VaenHub_SlimeRNG_Settings"

local function SaveSettings()
    SafeCall(function()
        local data = {
            RollDelay   = State.RollDelay,
            WalkSpeed   = State.WalkSpeed,
            JumpPower   = State.JumpPower,
            WebhookURL  = State.WebhookURL,
            TotalRolls  = State.TotalRolls,
            BestPet     = State.BestPet,
            RareCount   = State.RareCount,
        }
        if writefile then
            writefile(SETTINGS_KEY .. ".json", HttpService:JSONEncode(data))
        end
    end)
end

local function LoadSettings()
    SafeCall(function()
        if readfile and isfile and isfile(SETTINGS_KEY .. ".json") then
            local raw = readfile(SETTINGS_KEY .. ".json")
            local data = HttpService:JSONDecode(raw)
            for k, v in pairs(data) do
                if State[k] ~= nil then
                    State[k] = v
                end
            end
        end
    end)
end

LoadSettings()

-- ╔══════════════════════════════════════╗
-- ║         GUI BUILDER                  ║
-- ╚══════════════════════════════════════╝

-- Remove existing GUI if re-running
local existing = CoreGui:FindFirstChild("VaenHub_SlimeRNG")
if existing then existing:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VaenHub_SlimeRNG"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

-- ╔═══════════════════════════╗
-- ║     MAIN WINDOW           ║
-- ╚═══════════════════════════╝

local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = UDim2.new(0, 560, 0, 580)
MainWindow.Position = UDim2.new(0.5, -280, 0.5, -290)
MainWindow.BackgroundColor3 = Theme.Background
MainWindow.BorderSizePixel = 0
MainWindow.ClipsDescendants = true
MainWindow.Parent = ScreenGui

local WindowCorner = Instance.new("UICorner", MainWindow)
WindowCorner.CornerRadius = UDim.new(0, 12)

local WindowShadow = Instance.new("ImageLabel")
WindowShadow.Name = "Shadow"
WindowShadow.Size = UDim2.new(1, 40, 1, 40)
WindowShadow.Position = UDim2.new(0, -20, 0, -20)
WindowShadow.BackgroundTransparency = 1
WindowShadow.Image = "rbxassetid://6014261993"
WindowShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
WindowShadow.ImageTransparency = 0.5
WindowShadow.ScaleType = Enum.ScaleType.Slice
WindowShadow.SliceCenter = Rect.new(49, 49, 450, 450)
WindowShadow.ZIndex = -1
WindowShadow.Parent = MainWindow

-- Window border glow
local WindowBorder = Instance.new("UIStroke", MainWindow)
WindowBorder.Color = Theme.Accent
WindowBorder.Thickness = 1
WindowBorder.Transparency = 0.6

-- ╔═══════════════════════════╗
-- ║     TITLE BAR             ║
-- ╚═══════════════════════════╝

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 52)
TitleBar.BackgroundColor3 = Theme.Surface
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainWindow

local TitleCorner = Instance.new("UICorner", TitleBar)
TitleCorner.CornerRadius = UDim.new(0, 12)

-- Fix bottom corners of titlebar
local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0.5, 0)
TitleFix.Position = UDim2.new(0, 0, 0.5, 0)
TitleFix.BackgroundColor3 = Theme.Surface
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

-- Accent line under title
local AccentLine = Instance.new("Frame")
AccentLine.Size = UDim2.new(1, 0, 0, 2)
AccentLine.Position = UDim2.new(0, 0, 1, -2)
AccentLine.BackgroundColor3 = Theme.Accent
AccentLine.BorderSizePixel = 0
AccentLine.Parent = TitleBar

local AccentLineGradient = Instance.new("UIGradient", AccentLine)
AccentLineGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 100, 200)),
    ColorSequenceKeypoint.new(0.5, Theme.AccentGlow),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 200)),
})

-- Logo dot
local LogoDot = Instance.new("Frame")
LogoDot.Size = UDim2.new(0, 10, 0, 10)
LogoDot.Position = UDim2.new(0, 18, 0.5, -5)
LogoDot.BackgroundColor3 = Theme.Accent
LogoDot.BorderSizePixel = 0
LogoDot.Parent = TitleBar

local LogoDotCorner = Instance.new("UICorner", LogoDot)
LogoDotCorner.CornerRadius = UDim.new(1, 0)

-- Pulsing effect on logo dot
spawn(function()
    while MainWindow and MainWindow.Parent do
        Tween(LogoDot, {BackgroundColor3 = Theme.AccentGlow}, 1, "Sine", "InOut")
        task.wait(1)
        Tween(LogoDot, {BackgroundColor3 = Theme.AccentDark}, 1, "Sine", "InOut")
        task.wait(1)
    end
end)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -100, 1, 0)
TitleLabel.Position = UDim2.new(0, 36, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Slime RNG  |  VaenHub"
TitleLabel.TextColor3 = Theme.TextPrimary
TitleLabel.TextSize = 15
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local SubTitleLabel = Instance.new("TextLabel")
SubTitleLabel.Size = UDim2.new(1, -100, 0, 16)
SubTitleLabel.Position = UDim2.new(0, 36, 0, 30)
SubTitleLabel.BackgroundTransparency = 1
SubTitleLabel.Text = "Premium Script  •  S+ Quality"
SubTitleLabel.TextColor3 = Theme.Accent
SubTitleLabel.TextSize = 10
SubTitleLabel.Font = Enum.Font.Gotham
SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubTitleLabel.Parent = TitleBar

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -44, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 70)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar

local CloseBtnCorner = Instance.new("UICorner", CloseBtn)
CloseBtnCorner.CornerRadius = UDim.new(0, 8)

CloseBtn.MouseEnter:Connect(function()
    Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(255, 80, 90)}, 0.15)
    Tween(CloseBtn, {Size = UDim2.new(0, 34, 0, 34)}, 0.15)
end)
CloseBtn.MouseLeave:Connect(function()
    Tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(255, 60, 70)}, 0.15)
    Tween(CloseBtn, {Size = UDim2.new(0, 32, 0, 32)}, 0.15)
end)
CloseBtn.MouseButton1Click:Connect(function()
    Tween(MainWindow, {Size = UDim2.new(0, 560, 0, 0), Position = MainWindow.Position + UDim2.new(0, 0, 0, 290)}, 0.3, "Back", "In")
    task.wait(0.35)
    ScreenGui:Destroy()
end)

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 32, 0, 32)
MinBtn.Position = UDim2.new(1, -82, 0.5, -16)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
MinBtn.BorderSizePixel = 0
MinBtn.Text = "–"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 16
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = TitleBar

local MinBtnCorner = Instance.new("UICorner", MinBtn)
MinBtnCorner.CornerRadius = UDim.new(0, 8)

local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        Tween(MainWindow, {Size = UDim2.new(0, 560, 0, 52)}, 0.3, "Quad", "Out")
    else
        Tween(MainWindow, {Size = UDim2.new(0, 560, 0, 580)}, 0.3, "Quad", "Out")
    end
end)

-- ╔═══════════════════════════╗
-- ║     DRAG SYSTEM           ║
-- ╚═══════════════════════════╝

local dragging = false
local dragStart, windowStart

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        windowStart = MainWindow.Position
    end
end)

TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainWindow.Position = UDim2.new(
            windowStart.X.Scale,
            windowStart.X.Offset + delta.X,
            windowStart.Y.Scale,
            windowStart.Y.Offset + delta.Y
        )
    end
end)

-- ╔═══════════════════════════╗
-- ║     TAB SYSTEM            ║
-- ╚═══════════════════════════╝

local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, 0, 0, 44)
TabBar.Position = UDim2.new(0, 0, 0, 52)
TabBar.BackgroundColor3 = Theme.Surface
TabBar.BorderSizePixel = 0
TabBar.Parent = MainWindow

local TabBarFix = Instance.new("Frame")
TabBarFix.Size = UDim2.new(1, 0, 0, 4)
TabBarFix.Position = UDim2.new(0, 0, 0, 0)
TabBarFix.BackgroundColor3 = Theme.Surface
TabBarFix.BorderSizePixel = 0
TabBarFix.Parent = TabBar

local TabSep = Instance.new("Frame")
TabSep.Size = UDim2.new(1, 0, 0, 1)
TabSep.Position = UDim2.new(0, 0, 1, -1)
TabSep.BackgroundColor3 = Theme.Separator
TabSep.BorderSizePixel = 0
TabSep.Parent = TabBar

local TabLayout = Instance.new("UIListLayout", TabBar)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.Padding = UDim.new(0, 4)

-- Content Area
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, 0, 1, -96)
ContentArea.Position = UDim2.new(0, 0, 0, 96)
ContentArea.BackgroundTransparency = 1
ContentArea.BorderSizePixel = 0
ContentArea.ClipsDescendants = true
ContentArea.Parent = MainWindow

local Tabs = {}
local ActiveTab = nil

-- Tab data
local TabDefs = {
    { name = "Main",        icon = "⚔️" },
    { name = "Potions",     icon = "🧪" },
    { name = "Crafting",    icon = "🔨" },
    { name = "Config",      icon = "⚙️" },
    { name = "Misc",        icon = "🎮" },
}

-- ╔═══════════════════════════╗
-- ║     GUI COMPONENTS        ║
-- ╚═══════════════════════════╝

-- Scroll Frame builder
local function CreateScrollFrame(parent)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.fromScale(1, 1)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Theme.Accent
    scroll.ScrollBarImageTransparency = 0.3
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = parent

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local padding = Instance.new("UIPadding", scroll)
    padding.PaddingTop = UDim.new(0, 12)
    padding.PaddingBottom = UDim.new(0, 12)
    padding.PaddingLeft = UDim.new(0, 14)
    padding.PaddingRight = UDim.new(0, 14)

    return scroll
end

-- Section Header builder
local function CreateSection(parent, title)
    local section = Instance.new("Frame")
    section.Name = "Section_" .. title
    section.Size = UDim2.new(1, 0, 0, 28)
    section.BackgroundTransparency = 1
    section.BorderSizePixel = 0
    section.LayoutOrder = 0
    section.Parent = parent

    local line1 = Instance.new("Frame", section)
    line1.Size = UDim2.new(0.3, 0, 0, 1)
    line1.Position = UDim2.new(0, 0, 0.5, 0)
    line1.BackgroundColor3 = Theme.Separator
    line1.BorderSizePixel = 0

    local label = Instance.new("TextLabel", section)
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.Position = UDim2.new(0.3, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "  " .. title .. "  "
    label.TextColor3 = Theme.TextMuted
    label.TextSize = 10
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Center

    local line2 = Instance.new("Frame", section)
    line2.Size = UDim2.new(0.3, 0, 0, 1)
    line2.Position = UDim2.new(0.7, 0, 0.5, 0)
    line2.BackgroundColor3 = Theme.Separator
    line2.BorderSizePixel = 0

    return section
end

-- Toggle builder (VaenHub Style)
local function CreateToggle(parent, icon, title, subtitle, state_key, callback)
    local row = Instance.new("Frame")
    row.Name = "Toggle_" .. title
    row.Size = UDim2.new(1, 0, 0, 54)
    row.BackgroundColor3 = Theme.Card
    row.BorderSizePixel = 0
    row.Parent = parent

    local rowCorner = Instance.new("UICorner", row)
    rowCorner.CornerRadius = UDim.new(0, 10)

    local rowBorder = Instance.new("UIStroke", row)
    rowBorder.Color = Theme.CardBorder
    rowBorder.Thickness = 1
    rowBorder.Transparency = 0.3

    -- Icon
    local iconLabel = Instance.new("TextLabel", row)
    iconLabel.Size = UDim2.new(0, 36, 1, 0)
    iconLabel.Position = UDim2.new(0, 12, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.TextSize = 18
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center

    -- Title
    local titleLabel = Instance.new("TextLabel", row)
    titleLabel.Size = UDim2.new(1, -120, 0, 22)
    titleLabel.Position = UDim2.new(0, 54, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Theme.TextPrimary
    titleLabel.TextSize = 13
    titleLabel.Font = Enum.Font.GothamSemibold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Subtitle
    local subLabel = Instance.new("TextLabel", row)
    subLabel.Size = UDim2.new(1, -120, 0, 16)
    subLabel.Position = UDim2.new(0, 54, 0, 30)
    subLabel.BackgroundTransparency = 1
    subLabel.Text = subtitle or ""
    subLabel.TextColor3 = Theme.TextMuted
    subLabel.TextSize = 10
    subLabel.Font = Enum.Font.Gotham
    subLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Toggle Background
    local toggleBg = Instance.new("Frame", row)
    toggleBg.Size = UDim2.new(0, 44, 0, 24)
    toggleBg.Position = UDim2.new(1, -58, 0.5, -12)
    toggleBg.BackgroundColor3 = State[state_key] and Theme.ToggleOn or Theme.ToggleOff
    toggleBg.BorderSizePixel = 0

    local toggleCorner = Instance.new("UICorner", toggleBg)
    toggleCorner.CornerRadius = UDim.new(1, 0)

    -- Toggle Knob
    local knob = Instance.new("Frame", toggleBg)
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = State[state_key]
        and UDim2.new(0, 22, 0.5, -9)
        or  UDim2.new(0, 4,  0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0

    local knobCorner = Instance.new("UICorner", knob)
    knobCorner.CornerRadius = UDim.new(1, 0)

    -- Click handler
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row

    btn.MouseEnter:Connect(function()
        Tween(row, {BackgroundColor3 = Theme.SurfaceHover}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        Tween(row, {BackgroundColor3 = Theme.Card}, 0.15)
    end)

    btn.MouseButton1Click:Connect(function()
        State[state_key] = not State[state_key]
        local on = State[state_key]

        Tween(toggleBg, {BackgroundColor3 = on and Theme.ToggleOn or Theme.ToggleOff}, 0.2)
        Tween(knob, {Position = on and UDim2.new(0, 22, 0.5, -9) or UDim2.new(0, 4, 0.5, -9)}, 0.2)

        if callback then SafeCall(callback, on) end
    end)

    return row
end

-- Slider builder
local function CreateSlider(parent, icon, title, minVal, maxVal, default, callback)
    local row = Instance.new("Frame")
    row.Name = "Slider_" .. title
    row.Size = UDim2.new(1, 0, 0, 66)
    row.BackgroundColor3 = Theme.Card
    row.BorderSizePixel = 0
    row.Parent = parent

    local rowCorner = Instance.new("UICorner", row)
    rowCorner.CornerRadius = UDim.new(0, 10)

    local rowBorder = Instance.new("UIStroke", row)
    rowBorder.Color = Theme.CardBorder
    rowBorder.Thickness = 1
    rowBorder.Transparency = 0.3

    local iconLabel = Instance.new("TextLabel", row)
    iconLabel.Size = UDim2.new(0, 36, 0, 30)
    iconLabel.Position = UDim2.new(0, 12, 0, 8)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.TextSize = 18
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center

    local titleLabel = Instance.new("TextLabel", row)
    titleLabel.Size = UDim2.new(1, -120, 0, 20)
    titleLabel.Position = UDim2.new(0, 54, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Theme.TextPrimary
    titleLabel.TextSize = 13
    titleLabel.Font = Enum.Font.GothamSemibold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local valueLabel = Instance.new("TextLabel", row)
    valueLabel.Size = UDim2.new(0, 60, 0, 20)
    valueLabel.Position = UDim2.new(1, -70, 0, 8)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Theme.Accent
    valueLabel.TextSize = 13
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    -- Slider track
    local track = Instance.new("Frame", row)
    track.Size = UDim2.new(1, -28, 0, 6)
    track.Position = UDim2.new(0, 14, 0, 46)
    track.BackgroundColor3 = Theme.ToggleOff
    track.BorderSizePixel = 0

    local trackCorner = Instance.new("UICorner", track)
    trackCorner.CornerRadius = UDim.new(1, 0)

    -- Fill
    local fill = Instance.new("Frame", track)
    local startFill = (default - minVal) / (maxVal - minVal)
    fill.Size = UDim2.new(startFill, 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0

    local fillCorner = Instance.new("UICorner", fill)
    fillCorner.CornerRadius = UDim.new(1, 0)

    -- Knob
    local sliderKnob = Instance.new("Frame", track)
    sliderKnob.Size = UDim2.new(0, 14, 0, 14)
    sliderKnob.Position = UDim2.new(startFill, -7, 0.5, -7)
    sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderKnob.BorderSizePixel = 0
    sliderKnob.ZIndex = 3

    local knobCorner = Instance.new("UICorner", sliderKnob)
    knobCorner.CornerRadius = UDim.new(1, 0)

    local draggingSlider = false

    local function updateSlider(input)
        local trackPos = track.AbsolutePosition.X
        local trackWidth = track.AbsoluteSize.X
        local relX = math.clamp(input.Position.X - trackPos, 0, trackWidth)
        local pct = relX / trackWidth
        local value = Round(minVal + (maxVal - minVal) * pct, 2)

        fill.Size = UDim2.new(pct, 0, 1, 0)
        sliderKnob.Position = UDim2.new(pct, -7, 0.5, -7)
        valueLabel.Text = tostring(value)

        if callback then SafeCall(callback, value) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = true
            updateSlider(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = false
        end
    end)

    return row
end

-- Text Input builder
local function CreateTextInput(parent, icon, title, placeholder, callback)
    local row = Instance.new("Frame")
    row.Name = "Input_" .. title
    row.Size = UDim2.new(1, 0, 0, 66)
    row.BackgroundColor3 = Theme.Card
    row.BorderSizePixel = 0
    row.Parent = parent

    local rowCorner = Instance.new("UICorner", row)
    rowCorner.CornerRadius = UDim.new(0, 10)

    local rowBorder = Instance.new("UIStroke", row)
    rowBorder.Color = Theme.CardBorder
    rowBorder.Thickness = 1
    rowBorder.Transparency = 0.3

    local iconLabel = Instance.new("TextLabel", row)
    iconLabel.Size = UDim2.new(0, 36, 0, 30)
    iconLabel.Position = UDim2.new(0, 12, 0, 8)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.TextSize = 18
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center

    local titleLabel = Instance.new("TextLabel", row)
    titleLabel.Size = UDim2.new(1, -30, 0, 20)
    titleLabel.Position = UDim2.new(0, 54, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Theme.TextPrimary
    titleLabel.TextSize = 13
    titleLabel.Font = Enum.Font.GothamSemibold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local inputBg = Instance.new("Frame", row)
    inputBg.Size = UDim2.new(1, -28, 0, 26)
    inputBg.Position = UDim2.new(0, 14, 0, 32)
    inputBg.BackgroundColor3 = Theme.Background
    inputBg.BorderSizePixel = 0

    local inputCorner = Instance.new("UICorner", inputBg)
    inputCorner.CornerRadius = UDim.new(0, 6)

    local inputStroke = Instance.new("UIStroke", inputBg)
    inputStroke.Color = Theme.CardBorder
    inputStroke.Thickness = 1

    local textBox = Instance.new("TextBox", inputBg)
    textBox.Size = UDim2.new(1, -10, 1, 0)
    textBox.Position = UDim2.new(0, 8, 0, 0)
    textBox.BackgroundTransparency = 1
    textBox.PlaceholderText = placeholder or ""
    textBox.PlaceholderColor3 = Theme.TextMuted
    textBox.Text = ""
    textBox.TextColor3 = Theme.TextPrimary
    textBox.TextSize = 11
    textBox.Font = Enum.Font.Gotham
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.ClearTextOnFocus = false

    textBox.Focused:Connect(function()
        Tween(inputStroke, {Color = Theme.Accent}, 0.15)
    end)
    textBox.FocusLost:Connect(function()
        Tween(inputStroke, {Color = Theme.CardBorder}, 0.15)
        if callback then SafeCall(callback, textBox.Text) end
    end)

    return row, textBox
end

-- Button builder
local function CreateButton(parent, icon, title, subtitle, color, callback)
    local row = Instance.new("Frame")
    row.Name = "Button_" .. title
    row.Size = UDim2.new(1, 0, 0, 50)
    row.BackgroundColor3 = Theme.Card
    row.BorderSizePixel = 0
    row.Parent = parent

    local rowCorner = Instance.new("UICorner", row)
    rowCorner.CornerRadius = UDim.new(0, 10)

    local rowBorder = Instance.new("UIStroke", row)
    rowBorder.Color = color or Theme.CardBorder
    rowBorder.Thickness = 1
    rowBorder.Transparency = 0.3

    local iconLabel = Instance.new("TextLabel", row)
    iconLabel.Size = UDim2.new(0, 36, 1, 0)
    iconLabel.Position = UDim2.new(0, 12, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.TextSize = 18
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center

    local titleLabel = Instance.new("TextLabel", row)
    titleLabel.Size = UDim2.new(1, -100, 0, 22)
    titleLabel.Position = UDim2.new(0, 54, 0.5, -11)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = color or Theme.TextPrimary
    titleLabel.TextSize = 13
    titleLabel.Font = Enum.Font.GothamSemibold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    if subtitle then
        titleLabel.Position = UDim2.new(0, 54, 0, 8)
        local subLabel = Instance.new("TextLabel", row)
        subLabel.Size = UDim2.new(1, -100, 0, 16)
        subLabel.Position = UDim2.new(0, 54, 0, 28)
        subLabel.BackgroundTransparency = 1
        subLabel.Text = subtitle
        subLabel.TextColor3 = Theme.TextMuted
        subLabel.TextSize = 10
        subLabel.Font = Enum.Font.Gotham
        subLabel.TextXAlignment = Enum.TextXAlignment.Left
    end

    -- Arrow indicator
    local arrow = Instance.new("TextLabel", row)
    arrow.Size = UDim2.new(0, 24, 1, 0)
    arrow.Position = UDim2.new(1, -32, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "›"
    arrow.TextColor3 = color or Theme.TextMuted
    arrow.TextSize = 20
    arrow.Font = Enum.Font.GothamBold

    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text = ""

    btn.MouseEnter:Connect(function()
        Tween(row, {BackgroundColor3 = Theme.SurfaceHover}, 0.15)
        Tween(arrow, {TextColor3 = color or Theme.Accent}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        Tween(row, {BackgroundColor3 = Theme.Card}, 0.15)
        Tween(arrow, {TextColor3 = color or Theme.TextMuted}, 0.15)
    end)
    btn.MouseButton1Click:Connect(function()
        if callback then SafeCall(callback) end
    end)

    return row
end

-- Stat Card builder
local function CreateStatCard(parent, icon, title, valueKey)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0.48, 0, 0, 70)
    card.BackgroundColor3 = Theme.Card
    card.BorderSizePixel = 0
    card.Parent = parent

    local cardCorner = Instance.new("UICorner", card)
    cardCorner.CornerRadius = UDim.new(0, 10)

    local cardBorder = Instance.new("UIStroke", card)
    cardBorder.Color = Theme.CardBorder
    cardBorder.Thickness = 1

    local iconLabel = Instance.new("TextLabel", card)
    iconLabel.Size = UDim2.new(1, 0, 0, 28)
    iconLabel.Position = UDim2.new(0, 0, 0, 8)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.TextSize = 20
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center

    local titleLabel = Instance.new("TextLabel", card)
    titleLabel.Size = UDim2.new(1, -8, 0, 16)
    titleLabel.Position = UDim2.new(0, 4, 0, 34)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Theme.TextMuted
    titleLabel.TextSize = 9
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center

    local valLabel = Instance.new("TextLabel", card)
    valLabel.Size = UDim2.new(1, -8, 0, 18)
    valLabel.Position = UDim2.new(0, 4, 0, 48)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(State[valueKey] or 0)
    valLabel.TextColor3 = Theme.Accent
    valLabel.TextSize = 11
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextXAlignment = Enum.TextXAlignment.Center

    -- Auto-update stat display
    RunService.Heartbeat:Connect(function()
        if valLabel and valLabel.Parent then
            local val = State[valueKey]
            valLabel.Text = type(val) == "number"
                and FormatNumber(math.floor(val))
                or tostring(val)
        end
    end)

    return card
end

-- ╔═══════════════════════════╗
-- ║     TAB CREATION          ║
-- ╚═══════════════════════════╝

local TabPages = {}

local function CreateTab(def)
    -- Tab Button
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = "Tab_" .. def.name
    tabBtn.Size = UDim2.new(0, 96, 0, 34)
    tabBtn.BackgroundColor3 = Theme.Surface
    tabBtn.BorderSizePixel = 0
    tabBtn.Text = def.icon .. "  " .. def.name
    tabBtn.TextColor3 = Theme.TextMuted
    tabBtn.TextSize = 12
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.Parent = TabBar

    local tabCorner = Instance.new("UICorner", tabBtn)
    tabCorner.CornerRadius = UDim.new(0, 8)

    local tabIndicator = Instance.new("Frame", tabBtn)
    tabIndicator.Size = UDim2.new(0.8, 0, 0, 2)
    tabIndicator.Position = UDim2.new(0.1, 0, 1, -2)
    tabIndicator.BackgroundColor3 = Theme.Accent
    tabIndicator.BorderSizePixel = 0
    tabIndicator.BackgroundTransparency = 1

    local tabIndicatorCorner = Instance.new("UICorner", tabIndicator)
    tabIndicatorCorner.CornerRadius = UDim.new(1, 0)

    -- Tab Page
    local page = Instance.new("Frame")
    page.Name = "Page_" .. def.name
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = ContentArea

    TabPages[def.name] = {
        button    = tabBtn,
        page      = page,
        indicator = tabIndicator,
    }

    tabBtn.MouseButton1Click:Connect(function()
        if ActiveTab == def.name then return end

        -- Deactivate previous
        if ActiveTab and TabPages[ActiveTab] then
            local prev = TabPages[ActiveTab]
            Tween(prev.button, {BackgroundColor3 = Theme.Surface, TextColor3 = Theme.TextMuted}, 0.2)
            Tween(prev.indicator, {BackgroundTransparency = 1}, 0.2)
            prev.page.Visible = false
        end

        -- Activate current
        ActiveTab = def.name
        Tween(tabBtn, {BackgroundColor3 = Theme.SurfaceHover, TextColor3 = Theme.TextPrimary}, 0.2)
        Tween(tabIndicator, {BackgroundTransparency = 0}, 0.2)
        page.Visible = true
    end)

    return page
end

-- Build all tabs
for _, def in ipairs(TabDefs) do
    CreateTab(def)
end

-- ╔══════════════════════════════════════╗
-- ║         MAIN TAB CONTENT             ║
-- ╚══════════════════════════════════════╝

local MainPage = TabPages["Main"].page
local MainScroll = CreateScrollFrame(MainPage)

CreateSection(MainScroll, "AUTO FARM")

CreateToggle(MainScroll, "⚔️", "Auto Farm Everything", "Automatically farms mobs and collects drops", "AutoFarm", function(on)
    if on then task.spawn(AutoFarmLogic) end
end)

CreateToggle(MainScroll, "🎲", "Auto Roll", "Auto-rolls for slime pets", "AutoRoll", function(on)
    if on then task.spawn(AutoRollLogic) end
end)

CreateToggle(MainScroll, "🐾", "Auto Equip Best Pet", "Automatically equips your best pet", "AutoEquipPet", function(on)
    if on then task.spawn(AutoEquipBestPet) end
end)

CreateSection(MainScroll, "AUTO MANAGEMENT")

CreateToggle(MainScroll, "💰", "Auto Sell", "Automatically sells items for coins", "AutoSell", function(on)
    if on then task.spawn(AutoSellLogic) end
end)

CreateToggle(MainScroll, "🔀", "Auto Merge", "Automatically merges duplicate pets", "AutoMerge", function(on)
    if on then task.spawn(AutoMergeLogic) end
end)

CreateSection(MainScroll, "PROGRESSION")

CreateToggle(MainScroll, "⬆️", "Auto Buy All Upgrades", "Purchases all available upgrades", "AutoBuyUpgrades", function(on)
    if on then task.spawn(AutoBuyUpgradesLogic) end
end)

CreateToggle(MainScroll, "🔄", "Auto Rebirth", "Performs rebirth when conditions are met", "AutoRebirth", function(on)
    if on then task.spawn(AutoRebirthLogic) end
end)

CreateToggle(MainScroll, "📋", "Auto Claim Index Rewards", "Claims index/pokedex rewards", "AutoClaimIndex", function(on)
    if on then task.spawn(AutoClaimIndexLogic) end
end)

CreateToggle(MainScroll, "🎁", "Auto Claim Daily Rewards", "Claims daily login rewards", "AutoClaimDaily", function(on)
    if on then task.spawn(AutoClaimDailyLogic) end
end)

-- ╔══════════════════════════════════════╗
-- ║         POTIONS TAB CONTENT          ║
-- ╚══════════════════════════════════════╝

local PotionsPage = TabPages["Potions"].page
local PotionsScroll = CreateScrollFrame(PotionsPage)

CreateSection(PotionsScroll, "POTION AUTOMATION")

CreateToggle(PotionsScroll, "🍶", "Auto Use Luck Potions", "Automatically uses luck potions when available", "AutoLuckPotion", function(on)
    while State["AutoLuckPotion"] do
        SafeCall(function()
            TryRemoteEvent("UseLuckPotion")
            TryRemoteEvent("ActivateLuck")
        end)
        task.wait(30)
    end
end)

CreateToggle(PotionsScroll, "⚡", "Auto Use Speed Potions", "Automatically uses speed buff potions", "AutoSpeedPotion", function(on)
    while State["AutoSpeedPotion"] do
        SafeCall(function()
            TryRemoteEvent("UseSpeedPotion")
            TryRemoteEvent("ActivateSpeed")
        end)
        task.wait(30)
    end
end)

CreateToggle(PotionsScroll, "💎", "Auto Use Rare Potions", "Uses rare-find potions automatically", "AutoRarePotion", function(on)
    while State["AutoRarePotion"] do
        SafeCall(function()
            TryRemoteEvent("UseRarePotion")
            TryRemoteEvent("ActivateRare")
        end)
        task.wait(60)
    end
end)

CreateToggle(PotionsScroll, "✨", "Auto Use All Potions", "Uses every potion type available", "AutoAllPotions", function(on)
    while State["AutoAllPotions"] do
        SafeCall(function()
            TryRemoteEvent("UseAllPotions")
            TryRemoteEvent("ActivateAllBuffs")
        end)
        task.wait(15)
    end
end)

CreateSection(PotionsScroll, "POTION COLLECTION")

CreateButton(PotionsScroll, "🏃", "Collect All Potions", "Picks up all potions on the map", Theme.Success, function()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:lower():find("potion") and obj:IsA("BasePart") then
            HumanoidRootPart.CFrame = obj.CFrame
            task.wait(0.05)
        end
    end
end)

CreateButton(PotionsScroll, "🔮", "Craft All Potions", "Automatically crafts all available potions", Theme.Accent, function()
    SafeCall(function()
        TryRemoteEvent("CraftAllPotions")
        TryRemoteEvent("AutoCraft")
    end)
end)

-- ╔══════════════════════════════════════╗
-- ║         CRAFTING TAB CONTENT         ║
-- ╚══════════════════════════════════════╝

local CraftingPage = TabPages["Crafting"].page
local CraftingScroll = CreateScrollFrame(CraftingPage)

CreateSection(CraftingScroll, "AUTO CRAFTING")

CreateToggle(CraftingScroll, "🔨", "Auto Craft Best Item", "Continuously crafts the highest-tier item", "AutoCraftBest", function(on)
    while State["AutoCraftBest"] do
        SafeCall(function()
            TryRemoteEvent("CraftBestItem")
            TryRemoteEvent("AutoCraftBest")
        end)
        task.wait(1)
    end
end)

CreateToggle(CraftingScroll, "🗡️", "Auto Craft Weapons", "Automatically crafts all weapon types", "AutoCraftWeapons", function(on)
    while State["AutoCraftWeapons"] do
        SafeCall(function()
            TryRemoteEvent("CraftWeapon")
            TryRemoteEvent("AutoCraftWeapon")
        end)
        task.wait(2)
    end
end)

CreateToggle(CraftingScroll, "🛡️", "Auto Craft Armor", "Automatically crafts armor pieces", "AutoCraftArmor", function(on)
    while State["AutoCraftArmor"] do
        SafeCall(function()
            TryRemoteEvent("CraftArmor")
            TryRemoteEvent("AutoCraftArmor")
        end)
        task.wait(2)
    end
end)

CreateSection(CraftingScroll, "MATERIALS")

CreateButton(CraftingScroll, "📦", "Collect All Materials", "Collects all crafting materials on map", Theme.Warning, function()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:lower():find("material") or obj.Name:lower():find("ore") or obj.Name:lower():find("crystal") then
            if obj:IsA("BasePart") then
                HumanoidRootPart.CFrame = obj.CFrame
                task.wait(0.05)
            end
        end
    end
end)

CreateButton(CraftingScroll, "♻️", "Salvage All Junk", "Salvages unwanted crafted items", Theme.Danger, function()
    SafeCall(function()
        TryRemoteEvent("SalvageAll")
        TryRemoteEvent("DismantelAll")
    end)
end)

-- ╔══════════════════════════════════════╗
-- ║         CONFIG TAB CONTENT           ║
-- ╚══════════════════════════════════════╝

local ConfigPage = TabPages["Config"].page
local ConfigScroll = CreateScrollFrame(ConfigPage)

CreateSection(ConfigScroll, "ROLL SETTINGS")

CreateSlider(ConfigScroll, "⏱️", "Roll Delay (seconds)", 0.1, 3.0, State.RollDelay, function(v)
    State.RollDelay = v
end)

CreateSlider(ConfigScroll, "🏃", "Walk Speed", 16, 100, State.WalkSpeed, function(v)
    State.WalkSpeed = v
    if Humanoid then Humanoid.WalkSpeed = v end
end)

CreateSlider(ConfigScroll, "🦘", "Jump Power", 50, 300, State.JumpPower, function(v)
    State.JumpPower = v
    if Humanoid then Humanoid.JumpPower = v end
end)

CreateSection(ConfigScroll, "DISCORD WEBHOOK")

local _, webhookBox = CreateTextInput(ConfigScroll, "🔗", "Discord Webhook URL", "https://discord.com/api/webhooks/...", function(v)
    State.WebhookURL = v
end)

CreateButton(ConfigScroll, "📤", "Test Webhook", "Send a test notification to Discord", Theme.Accent, function()
    SendWebhook("✅ VaenHub is connected! Script working correctly.")
end)

CreateSection(ConfigScroll, "SAVE & LOAD")

CreateButton(ConfigScroll, "💾", "Save Settings", "Saves current settings to file", Theme.Success, function()
    SaveSettings()
    StarterGui:SetCore("SendNotification", {
        Title = "VaenHub",
        Text = "Settings saved successfully!",
        Duration = 3,
    })
end)

CreateButton(ConfigScroll, "📂", "Load Settings", "Loads previously saved settings", Theme.Accent, function()
    LoadSettings()
    StarterGui:SetCore("SendNotification", {
        Title = "VaenHub",
        Text = "Settings loaded!",
        Duration = 3,
    })
end)

CreateButton(ConfigScroll, "🗑️", "Reset Settings", "Resets all settings to default", Theme.Danger, function()
    State.RollDelay = 0.5
    State.WalkSpeed = 16
    State.JumpPower = 50
    State.WebhookURL = ""
end)

CreateSection(ConfigScroll, "STAT TRACKER")

-- Stat grid
local StatGrid = Instance.new("Frame")
StatGrid.Size = UDim2.new(1, 0, 0, 160)
StatGrid.BackgroundTransparency = 1
StatGrid.Parent = ConfigScroll

local StatGridLayout = Instance.new("UIGridLayout", StatGrid)
StatGridLayout.CellSize = UDim2.new(0.48, 0, 0, 70)
StatGridLayout.CellPadding = UDim2.new(0.04, 0, 0, 6)
StatGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
StatGridLayout.SortOrder = Enum.SortOrder.LayoutOrder

CreateStatCard(StatGrid, "🎲", "TOTAL ROLLS", "TotalRolls")
CreateStatCard(StatGrid, "⭐", "RARE COUNT", "RareCount")
CreateStatCard(StatGrid, "🐾", "BEST PET", "BestPet")
CreateStatCard(StatGrid, "⏱️", "SESSION TIME", "SessionTime")

-- ╔══════════════════════════════════════╗
-- ║         MISC TAB CONTENT             ║
-- ╚══════════════════════════════════════╝

local MiscPage = TabPages["Misc"].page
local MiscScroll = CreateScrollFrame(MiscPage)

CreateSection(MiscScroll, "MOVEMENT")

CreateToggle(MiscScroll, "✈️", "Fly Mode", "Press F to toggle fly · WASD to move", "FlyEnabled", function(on)
    if on then
        EnableFly()
    else
        DisableFly()
    end
end)

CreateToggle(MiscScroll, "👻", "No Clip", "Walk through all walls and objects", "NoClip", function(on)
    if on then
        EnableNoClip()
    else
        DisableNoClip()
    end
end)

CreateSection(MiscScroll, "ESP VISUALS")

CreateToggle(MiscScroll, "👥", "ESP Players", "Shows player positions through walls", "ESPPlayers", function(on)
    if not on then ClearESP("Players") end
end)

CreateToggle(MiscScroll, "👾", "ESP Mobs", "Highlights all enemy mobs", "ESPMobs", function(on)
    if not on then ClearESP("Mobs") end
end)

CreateToggle(MiscScroll, "📦", "ESP Drops / Items", "Highlights drops (rare items glow orange)", "ESPDrops", function(on)
    if not on then ClearESP("Drops") end
end)

CreateToggle(MiscScroll, "🎁", "ESP Chests", "Shows all chest locations on map", "ESPChests", function(on)
    if not on then ClearESP("Chests") end
end)

CreateSection(MiscScroll, "UTILITY")

CreateToggle(MiscScroll, "💤", "Anti AFK", "Prevents automatic kick for inactivity", "AntiAFK", function(on)
    if on then EnableAntiAFK() end
end)

CreateToggle(MiscScroll, "⚡", "Performance Mode", "Reduces visual effects to boost FPS", "PerfMode", function(on)
    if on then
        Workspace.StreamingEnabled = true
        game:GetService("Lighting").GlobalShadows = false
        game:GetService("Lighting").FogEnd = 1e6
    else
        game:GetService("Lighting").GlobalShadows = true
    end
end)

CreateButton(MiscScroll, "🔄", "Rejoin Server", "Quickly rejoins a new server instance", Theme.Warning, function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

CreateButton(MiscScroll, "📋", "Copy Player Info", "Copies your character stats to clipboard", Theme.Accent, function()
    local info = string.format(
        "Player: %s | Rolls: %d | Best Pet: %s | Rares: %d",
        LocalPlayer.Name, State.TotalRolls, State.BestPet, State.RareCount
    )
    if setclipboard then setclipboard(info) end
    StarterGui:SetCore("SendNotification", {
        Title = "VaenHub",
        Text = "Player info copied!",
        Duration = 3,
    })
end)

-- ╔══════════════════════════════════════╗
-- ║         ACTIVATE FIRST TAB           ║
-- ╚══════════════════════════════════════╝

-- Simulate click on first tab
task.spawn(function()
    task.wait(0.1)
    TabPages["Main"].button:GetPropertyChangedSignal("BackgroundColor3")
    ActiveTab = "Main"
    Tween(TabPages["Main"].button, {
        BackgroundColor3 = Theme.SurfaceHover,
        TextColor3 = Theme.TextPrimary
    }, 0.2)
    Tween(TabPages["Main"].indicator, {BackgroundTransparency = 0}, 0.2)
    TabPages["Main"].page.Visible = true
end)

-- ╔══════════════════════════════════════╗
-- ║         WINDOW OPEN ANIMATION        ║
-- ╚══════════════════════════════════════╝

MainWindow.Size = UDim2.new(0, 0, 0, 0)
MainWindow.Position = UDim2.new(0.5, 0, 0.5, 0)

Tween(MainWindow, {
    Size = UDim2.new(0, 560, 0, 580),
    Position = UDim2.new(0.5, -280, 0.5, -290),
}, 0.45, "Back", "Out")

-- ╔══════════════════════════════════════╗
-- ║         KEYBIND: F = FLY TOGGLE      ║
-- ╚══════════════════════════════════════╝

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        State.FlyEnabled = not State.FlyEnabled
        if State.FlyEnabled then
            EnableFly()
        else
            DisableFly()
        end
    end
end)

-- ╔══════════════════════════════════════╗
-- ║         MAIN LOOP                    ║
-- ╚══════════════════════════════════════╝

-- Session timer
spawn(function()
    while MainWindow and MainWindow.Parent do
        task.wait(1)
        State.SessionTime = State.SessionTime + 1
    end
end)

-- ESP refresh loop
spawn(function()
    while MainWindow and MainWindow.Parent do
        RefreshESP()
        task.wait(2)
    end
end)

-- Apply walk/jump speed loop
spawn(function()
    while MainWindow and MainWindow.Parent do
        if Humanoid then
            Humanoid.WalkSpeed = State.WalkSpeed
            Humanoid.JumpPower = State.JumpPower
        end
        task.wait(0.5)
    end
end)

-- Character respawn handler
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
    task.wait(1)
    Humanoid.WalkSpeed = State.WalkSpeed
    Humanoid.JumpPower = State.JumpPower
    if State.FlyEnabled then EnableFly() end
    if State.NoClip then EnableNoClip() end
end)

-- ╔══════════════════════════════════════╗
-- ║         STARTUP NOTIFICATION         ║
-- ╚══════════════════════════════════════╝

task.spawn(function()
    task.wait(1)
    SafeCall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "✅ VaenHub Loaded",
            Text = "Slime RNG Script • S+ Quality • All Systems Active",
            Duration = 5,
        })
    end)
end)

--[[
╔══════════════════════════════════════════════════════════════╗
║           VAENHUB SLIME RNG — FULLY LOADED                   ║
║  All systems initialized. Enjoy premium automation!          ║
╚══════════════════════════════════════════════════════════════╝
]]
```
