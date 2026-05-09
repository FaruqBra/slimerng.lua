-- =============================================
-- SLIME RNG GUI - VERSI STABIL 2026
-- =============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

print("🚀 Slime RNG GUI Loading...")

-- Simple Custom GUI (tidak pakai external library)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SlimeRNG_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 400, 0, 500)
Frame.Position = UDim2.new(0.5, -200, 0.5, -250)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
Title.Text = "Slime RNG GUI"
Title.TextColor3 = Color3.new(1,1,1)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.Parent = Frame

-- Function untuk membuat toggle
local function CreateToggle(name, yOffset, callback)
    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(0.9, 0, 0, 40)
    Toggle.Position = UDim2.new(0.05, 0, 0, yOffset)
    Toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    Toggle.Text = "🔴 " .. name
    Toggle.TextColor3 = Color3.new(1,1,1)
    Toggle.TextSize = 14
    Toggle.Font = Enum.Font.GothamSemibold
    Toggle.Parent = Frame
    
    local enabled = false
    Toggle.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            Toggle.Text = "🟢 " .. name
            Toggle.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
        else
            Toggle.Text = "🔴 " .. name
            Toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        end
        callback(enabled)
    end)
end

-- ==================== TOGGLES ====================
CreateToggle("Auto Roll", 70, function(state)
    print("Auto Roll:", state)
end)

CreateToggle("Auto Farm Slime", 120, function(state)
    print("Auto Farm:", state)
end)

CreateToggle("Auto Collect Drops", 170, function(state)
    print("Auto Collect:", state)
end)

CreateToggle("ESP Players", 220, function(state)
    print("ESP Players:", state)
end)

CreateToggle("Fly (F)", 270, function(state)
    print("Fly:", state)
end)

-- WalkSpeed Slider sederhana
local WSLabel = Instance.new("TextLabel")
WSLabel.Size = UDim2.new(0.9, 0, 0, 30)
WSLabel.Position = UDim2.new(0.05, 0, 0, 330)
WSLabel.BackgroundTransparency = 1
WSLabel.Text = "WalkSpeed: 120"
WSLabel.TextColor3 = Color3.new(1,1,1)
WSLabel.Parent = Frame

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 80, 0, 30)
CloseBtn.Position = UDim2.new(0.5, -40, 1, -40)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
CloseBtn.Text = "Close"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.Parent = Frame

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

print("✅ GUI berhasil dimuat! Cek di layar.")
