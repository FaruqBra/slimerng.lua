-- =============================================
-- SLIME RNG | VAENHUB STYLE (STABIL 2026)
-- Dioptimalkan untuk Delta Executor
-- =============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for character
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

print("🚀 Loading VaenHub Style GUI...")

-- State
local State = {
    AutoFarm = false,
    AutoRoll = false,
    AutoEquipPet = false,
    AutoSell = false,
    FlyEnabled = false,
    NoClip = false,
    AntiAFK = true,
    WalkSpeed = 120,
    JumpPower = 120,
    RollDelay = 0.5,
}

-- Simple GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VaenHub_SlimeRNG"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 500, 0, 580)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -290)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
TitleBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "   Slime RNG | VaenHub"
Title.TextColor3 = Color3.fromRGB(0, 170, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -45, 0, 5)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.TextSize = 20
CloseBtn.Parent = TitleBar
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Scrolling Content
local Scrolling = Instance.new("ScrollingFrame")
Scrolling.Size = UDim2.new(1, 0, 1, -55)
Scrolling.Position = UDim2.new(0, 0, 0, 55)
Scrolling.BackgroundTransparency = 1
Scrolling.ScrollBarThickness = 6
Scrolling.ScrollBarImageColor3 = Color3.fromRGB(0, 170, 255)
Scrolling.Parent = MainFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 10)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = Scrolling

-- Toggle Creator
local function CreateToggle(name, default, key, callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(0.95, 0, 0, 52)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    ToggleFrame.Parent = Scrolling

    local Corner = Instance.new("UICorner", ToggleFrame)
    Corner.CornerRadius = UDim.new(0, 10)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.65, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = "   " .. name
    Label.TextColor3 = Color3.new(1,1,1)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 14
    Label.Parent = ToggleFrame

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 70, 0, 32)
    ToggleBtn.Position = UDim2.new(0.85, 0, 0.5, -16)
    ToggleBtn.BackgroundColor3 = default and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(60, 60, 70)
    ToggleBtn.Text = default and "ON" or "OFF"
    ToggleBtn.TextColor3 = Color3.new(1,1,1)
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.Parent = ToggleFrame

    local enabled = default
    ToggleBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        State[key] = enabled
        ToggleBtn.BackgroundColor3 = enabled and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(60, 60, 70)
        ToggleBtn.Text = enabled and "ON" or "OFF"
        if callback then callback(enabled) end
    end)
end

-- ==================== FITUR ====================
CreateToggle("Auto Farm Everything", false, "AutoFarm")
CreateToggle("Auto Roll", false, "AutoRoll")
CreateToggle("Auto Equip Best Pet", false, "AutoEquipPet")
CreateToggle("Auto Sell", false, "AutoSell")
CreateToggle("Fly (F)", false, "FlyEnabled")
CreateToggle("No Clip", false, "NoClip")
CreateToggle("Anti AFK", true, "AntiAFK")

print("✅ VaenHub Style GUI Loaded (Stabil Version)")

-- ==================== CORE LOOP ====================
RunService.Heartbeat:Connect(function()
    if humanoid then
        humanoid.WalkSpeed = State.WalkSpeed
        humanoid.JumpPower = State.JumpPower
    end
end)

-- Fly Toggle
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F then
        State.FlyEnabled = not State.FlyEnabled
        print("Fly Mode:", State.FlyEnabled)
    end
end)

-- Character Respawn
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    root = newChar:WaitForChild("HumanoidRootPart")
    humanoid = newChar:WaitForChild("Humanoid")
end)

StarterGui:SetCore("SendNotification", {
    Title = "VaenHub",
    Text = "Slime RNG GUI Loaded Successfully!",
    Duration = 4
})
