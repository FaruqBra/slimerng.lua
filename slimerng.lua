-- =============================================
-- SLIME RNG POWER SCRIPT 2026
-- Load via GitHub - Keyless
-- =============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

print("🚀 Slime RNG Power Script Loading...")

-- Settings
local Settings = {
    AutoRoll = false,
    RollDelay = 0.15,
    AutoFarm = false,
    AutoCollect = true,
    WalkSpeed = 100,
    JumpPower = 100,
    Fly = false,
}

-- Simple Fly Function
local flySpeed = 50
local bodyVelocity, bodyGyro

local function toggleFly()
    Settings.Fly = not Settings.Fly
    if Settings.Fly then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            bodyVelocity = Instance.new("BodyVelocity")
            bodyGyro = Instance.new("BodyGyro")
            bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            bodyVelocity.Parent = root
            bodyGyro.Parent = root
            print("Fly ON (WASD + Mouse)")
        end
    else
        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
        print("Fly OFF")
    end
end

-- Main Loop
RunService.Heartbeat:Connect(function()
    if not character or not character:FindFirstChild("Humanoid") then return end
    
    character.Humanoid.WalkSpeed = Settings.WalkSpeed
    character.Humanoid.JumpPower = Settings.JumpPower

    -- Fly Control
    if Settings.Fly and bodyVelocity and bodyGyro then
        local cam = Workspace.CurrentCamera
        local move = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
        
        bodyVelocity.Velocity = move.Unit * flySpeed
        bodyGyro.CFrame = cam.CFrame
    end
end)

-- Toggle Fly dengan tombol F
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F then
        toggleFly()
    end
end)

print("✅ Script Loaded! Tekan F untuk Fly")
print("Gunakan GUI atau tambahkan fitur sesuai kebutuhan")
