-- =============================================
-- SLIME RNG | VAENHUB STYLE GUI
-- =============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VaenHub_SlimeRNG"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 460, 0, 520)
MainFrame.Position = UDim2.new(0.5, -230, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
TitleBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "Slime RNG | VaenHub"
Title.TextColor3 = Color3.fromRGB(0, 170, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.Parent = TitleBar

-- Close Button
local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 40, 0, 40)
Close.Position = UDim2.new(1, -40, 0, 5)
Close.BackgroundTransparency = 1
Close.Text = "✕"
Close.TextColor3 = Color3.fromRGB(255, 80, 80)
Close.TextSize = 20
Close.Parent = TitleBar
Close.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Tab System (Simple)
local TabFrame = Instance.new("Frame")
TabFrame.Size = UDim2.new(1, 0, 0, 40)
TabFrame.Position = UDim2.new(0, 0, 0, 50)
TabFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
TabFrame.Parent = MainFrame

-- Content Frame
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -90)
Content.Position = UDim2.new(0, 0, 0, 90)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- ==================== TOGGLE FUNCTION ====================
local y = 10
local function AddToggle(name, default, callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(0.95, 0, 0, 50)
    ToggleFrame.Position = UDim2.new(0.025, 0, 0, y)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    ToggleFrame.Parent = Content
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = "   " .. name
    Label.TextColor3 = Color3.new(1,1,1)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 15
    Label.Parent = ToggleFrame
    
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 60, 0, 30)
    ToggleButton.Position = UDim2.new(0.85, 0, 0.5, -15)
    ToggleButton.BackgroundColor3 = default and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(80, 80, 85)
    ToggleButton.Text = default and "ON" or "OFF"
    ToggleButton.TextColor3 = Color3.new(1,1,1)
    ToggleButton.Parent = ToggleFrame
    
    local enabled = default
    ToggleButton.MouseButton1Click:Connect(function()
        enabled = not enabled
        ToggleButton.BackgroundColor3 = enabled and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(80, 80, 85)
        ToggleButton.Text = enabled and "ON" or "OFF"
        callback(enabled)
    end)
    
    y = y + 60
end

-- ==================== FITUR ====================
AddToggle("Auto Farm EVERYTHING", true, function(s) print("Auto Farm:", s) end)
AddToggle("Auto Roll", false, function(s) print("Auto Roll:", s) end)
AddToggle("Auto Collect Drops", true, function(s) print("Auto Collect:", s) end)
AddToggle("Auto Buy ALL Upgrades", false, function(s) print("Auto Upgrade:", s) end)
AddToggle("Auto Rebirth", false, function(s) print("Auto Rebirth:", s) end)
AddToggle("Auto Claim Rewards", false, function(s) print("Auto Claim:", s) end)

print("✅ VaenHub Style GUI Loaded!")
print("GUI bisa digeser dengan mouse")

-- Drag Script
local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        update(input)
    end
end)
