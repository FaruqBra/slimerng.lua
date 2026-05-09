-- =============================================
-- SLIME RNG GUI SCRIPT 2026
-- Dengan Kavo UI - Mudah Dipakai
-- =============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

print("🚀 Loading Slime RNG GUI...")

-- Load Kavo UI Library
local Kavo = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()

local Window = Kavo:CreateLib("Slime RNG GUI", "Ocean")

-- Tabs
local Main = Window:NewTab("Main")
local Farm = Window:NewTab("Auto Farm")
local Visual = Window:NewTab("Visual")
local Misc = Window:NewTab("Misc")

-- Settings Table
local Settings = {
    AutoRoll = false,
    WalkSpeed = 120,
    JumpPower = 120,
    Fly = false,
}

-- ==================== MAIN TAB ====================
local MainSection = Main:NewSection("Auto Roll")

MainSection:NewToggle("Auto Roll", "Roll otomatis", function(state)
    Settings.AutoRoll = state
    print("Auto Roll:", state)
end)

MainSection:NewSlider("Roll Delay", "0.1 = Cepat", 10, 0.1, 2, function(value)
    print("Delay diatur ke:", value)
end)

-- ==================== FARM TAB ====================
local FarmSection = Farm:NewSection("Farming")

FarmSection:NewToggle("Auto Farm Slime", "", function(state)
    print("Auto Farm:", state)
end)

FarmSection:NewToggle("Auto Collect Drops", "", function(state)
    print("Auto Collect:", state)
end)

-- ==================== VISUAL TAB ====================
local VisualSection = Visual:NewSection("ESP & Visual")

VisualSection:NewToggle("ESP Players", "", function(state)
    print("ESP Players:", state)
end)

VisualSection:NewToggle("ESP Drops", "", function(state)
    print("ESP Drops:", state)
end)

-- ==================== MISC TAB ====================
local MiscSection = Misc:NewSection("Movement")

MiscSection:NewToggle("Fly (Tekan F)", "Toggle Fly", function(state)
    Settings.Fly = state
    print("Fly:", state and "ON" or "OFF")
end)

MiscSection:NewSlider("WalkSpeed", "", 500, 16, 500, function(value)
    Settings.WalkSpeed = value
end)

MiscSection:NewSlider("JumpPower", "", 300, 50, 300, function(value)
    Settings.JumpPower = value
end)

-- ==================== FLY & WALKSPEED LOOP ====================
RunService.Heartbeat:Connect(function()
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.WalkSpeed = Settings.WalkSpeed
        character.Humanoid.JumpPower = Settings.JumpPower
    end
end)

-- Fly Toggle dengan tombol F
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F then
        Settings.Fly = not Settings.Fly
        print("Fly toggled:", Settings.Fly)
    end
end)

print("✅ GUI Slime RNG berhasil dimuat!")
print("Tekan F untuk Fly")
