-- =============================================
-- SLIME RNG - VaenHub Style (VERSI STABIL)
-- =============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

print("🚀 Loading VaenHub Style GUI...")

-- Settings
local State = {
    AutoFarm = false,
    AutoRoll = false,
    FlyEnabled = false,
    NoClip = false,
    WalkSpeed = 120,
    JumpPower = 120,
}

-- Simple Custom GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VaenHubSlime"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 520, 0, 580)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -290)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 12)

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
TitleBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "   Slime RNG | VaenHub"
Title.TextColor3 = Color3.fromRGB(0, 170, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 40, 0, 40)
Close.Position = UDim2.new(1, -45, 0, 5)
Close.BackgroundTransparency = 1
Close.Text = "✕"
Close.TextColor3 = Color3.fromRGB(255, 80, 80)
Close.TextSize = 20
Close.Parent = TitleBar
Close.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Content Scrolling
local Scrolling = Instance.new("ScrollingFrame")
Scrolling.Size = UDim2.new(1, 0, 1, -55)
Scrolling.Position = UDim2.new(0, 0, 0, 55)
Scrolling.BackgroundTransparency = 1
Scrolling.ScrollBarThickness = 5
Scrolling.Parent = MainFrame

local List = Instance.new("UIListLayout", Scrolling)
List.Padding = UDim.new(0, 8)
List.SortOrder = Enum.SortOrder.LayoutOrder

-- Toggle Function
local function CreateToggle(name, default, key)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.95, 0, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    frame.Parent = Scrolling

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "   " .. name
    label.TextColor3 = Color3.new(1,1,1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 70, 0, 30)
    toggle.Position = UDim2.new(0.85, 0, 0.5, -15)
    toggle.BackgroundColor3 = default and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(60, 60, 70)
    toggle.Text = default and "ON" or "OFF"
    toggle.TextColor3 = Color3.new(1,1,1)
    toggle.Parent = frame

    local enabled = default
    toggle.MouseButton1Click:Connect(function()
        enabled = not enabled
        State[key] = enabled
        toggle.BackgroundColor3 = enabled and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(60, 60, 70)
        toggle.Text = enabled and "ON" or "OFF"
    end)
end

-- Tambahkan Fitur
CreateToggle("Auto Farm Everything", false, "AutoFarm")
CreateToggle("Auto Roll", false, "AutoRoll")
CreateToggle("Fly (F)", false, "FlyEnabled")
CreateToggle("No Clip", false, "NoClip")

print("✅ VaenHub Style GUI Loaded! (Versi Stabil)")

-- Basic Loop
RunService.Heartbeat:Connect(function()
    if humanoid then
        humanoid.WalkSpeed = State.WalkSpeed
        humanoid.JumpPower = State.JumpPower
    end
end)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F then
        State.FlyEnabled = not State.FlyEnabled
        print("Fly:", State.FlyEnabled)
    end
end)
