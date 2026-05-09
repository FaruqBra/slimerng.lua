--[[
╔══════════════════════════════════════════════════════════════╗
║                 VAENHUB - SLIME RNG                          ║
║         DELTA ANDROID - PRODUCTION FIXED                     ║
║  Fix: syntax lengkap, loop ringan, char respawn,             ║
║       no Activated:Fire, no memory leak ESP,                 ║
║       safe VIM, cached scan, full pcall                      ║
╚══════════════════════════════════════════════════════════════╝
]]

print("[VaenHub] >> Memulai eksekusi...")

-- ╔══════════════════════════════════════╗
-- ║  SERVICES                            ║
-- ╚══════════════════════════════════════╝
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui        = game:GetService("StarterGui")
local Lighting          = game:GetService("Lighting")

local LP   = Players.LocalPlayer
local PGui = LP:WaitForChild("PlayerGui")

print("[VaenHub] >> Services OK")

-- ╔══════════════════════════════════════╗
-- ║  CHARACTER SYSTEM (RESPAWN SAFE)     ║
-- ╚══════════════════════════════════════╝
local Char, Hum, HRP

local function UpdateChar(c)
    Char = c
    Hum  = c:WaitForChild("Humanoid",  10)
    HRP  = c:WaitForChild("HumanoidRootPart", 10)
    print("[VaenHub] >> Character updated: " .. tostring(c.Name))
end

UpdateChar(LP.Character or LP.CharacterAdded:Wait())
LP.CharacterAdded:Connect(UpdateChar)

print("[VaenHub] >> Character OK")

-- ╔══════════════════════════════════════╗
-- ║  STATE TABLE                         ║
-- ╚══════════════════════════════════════╝
local S = {
    AutoFarm      = false,
    AutoRoll      = false,
    AutoEquipPet  = false,
    AutoSell      = false,
    AutoMerge     = false,
    AutoBuyUpg    = false,
    AutoRebirth   = false,
    AutoClaimIdx  = false,
    AutoClaimDaily= false,
    AutoLuckPot   = false,
    AutoSpeedPot  = false,
    AutoRarePot   = false,
    AutoAllPot    = false,
    AutoCraftBest = false,
    AutoCraftWep  = false,
    AutoCraftArmor= false,
    ESPPlayers    = false,
    ESPMobs       = false,
    ESPDrops      = false,
    ESPChests     = false,
    FlyOn         = false,
    NoClip        = false,
    AntiAFK       = false,
    PerfMode      = false,
    RollDelay     = 0.8,
    WalkSpd       = 16,
    JumpPow       = 50,
    Webhook       = "",
    Rolls         = 0,
    BestPet       = "None",
    Rares         = 0,
    SessTime      = 0,
}

print("[VaenHub] >> State OK")

-- ╔══════════════════════════════════════╗
-- ║  THEME                               ║
-- ╚══════════════════════════════════════╝
local C = {
    Bg      = Color3.fromRGB(11,  13,  17),
    Surface = Color3.fromRGB(17,  20,  26),
    Hover   = Color3.fromRGB(24,  28,  38),
    Card    = Color3.fromRGB(21,  25,  33),
    Border  = Color3.fromRGB(36,  42,  56),
    Accent  = Color3.fromRGB(0,  168, 255),
    AccentD = Color3.fromRGB(0,  110, 195),
    AccentG = Color3.fromRGB(0,  205, 255),
    TextA   = Color3.fromRGB(232, 240, 255),
    TextB   = Color3.fromRGB(135, 152, 175),
    TextC   = Color3.fromRGB(70,  85,  108),
    Green   = Color3.fromRGB(0,   200, 120),
    Yellow  = Color3.fromRGB(255, 175,   0),
    Red     = Color3.fromRGB(255,  60,  70),
    PillOff = Color3.fromRGB(40,  46,  62),
    Sep     = Color3.fromRGB(26,  31,  42),
}

-- ╔══════════════════════════════════════╗
-- ║  UTILITY                             ║
-- ╚══════════════════════════════════════╝

-- Safe call wrapper
local function Safe(fn, ...)
    local args = {...}
    local ok, err = pcall(function()
        fn(table.unpack(args))
    end)
    if not ok then
        print("[VaenHub] pcall err: " .. tostring(err))
    end
end

-- Tween helper
local function Tw(obj, props, dur, style, dir)
    if not obj or not obj.Parent then return end
    pcall(function()
        TweenService:Create(
            obj,
            TweenInfo.new(
                dur   or 0.2,
                Enum.EasingStyle[style or "Quad"],
                Enum.EasingDirection[dir or "Out"]
            ),
            props
        ):Play()
    end)
end

-- Notify
local function Notify(title, msg, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = title,
            Text     = msg,
            Duration = dur or 3,
        })
    end)
end

-- Fire RemoteEvent
local function FireR(name, ...)
    pcall(function()
        local r = ReplicatedStorage:FindFirstChild(name, true)
        if r and r:IsA("RemoteEvent") then
            r:FireServer(...)
        end
    end)
end

-- Round number
local function Round(n, d)
    local m = 10 ^ (d or 0)
    return math.floor(n * m + 0.5) / m
end

-- Format time HH:MM:SS
local function FmtTime(s)
    s = math.floor(s)
    return string.format(
        "%02d:%02d:%02d",
        math.floor(s / 3600),
        math.floor((s % 3600) / 60),
        s % 60
    )
end

-- Safe Anti-AFK (tidak pakai VIM langsung)
local function DoAntiAFK()
    pcall(function()
        local ok2, VIM = pcall(function()
            return game:GetService("VirtualInputManager")
        end)
        if ok2 and VIM then
            VIM:SendKeyEvent(true,  Enum.KeyCode.F13, false, game)
            VIM:SendKeyEvent(false, Enum.KeyCode.F13, false, game)
        end
    end)
end

print("[VaenHub] >> Utils OK")

-- ╔══════════════════════════════════════╗
-- ║  CACHED SCAN SYSTEM (RINGAN)         ║
-- ║  Hanya scan tiap N detik, bukan      ║
-- ║  tiap frame. Jauh lebih hemat CPU.   ║
-- ╚══════════════════════════════════════╝
local Cache = {
    Mobs   = {},
    Drops  = {},
    Chests = {},
}

-- Refresh cache tiap 4 detik (bukan tiap frame)
task.spawn(function()
    while true do
        task.wait(4)

        -- Mobs
        local mobs = {}
        pcall(function()
            for _, m in ipairs(workspace:GetChildren()) do
                if m:IsA("Model") and m ~= Char then
                    local mh = m:FindFirstChildOfClass("Humanoid")
                    local mr = m:FindFirstChild("HumanoidRootPart")
                    if mh and mr and mh.Health > 0 then
                        table.insert(mobs, mr)
                    end
                end
            end
        end)
        Cache.Mobs = mobs

        -- Drops & Chests
        local drops  = {}
        local chests = {}
        pcall(function()
            for _, o in ipairs(workspace:GetChildren()) do
                if o:IsA("BasePart") then
                    local n = o.Name:lower()
                    if n:find("drop") or n:find("item") or n:find("pickup") then
                        table.insert(drops, o)
                    elseif n:find("chest") or n:find("lucky") then
                        table.insert(chests, o)
                    end
                elseif o:IsA("Model") then
                    local n  = o.Name:lower()
                    local pp = o.PrimaryPart
                    if pp then
                        if n:find("chest") or n:find("lucky") then
                            table.insert(chests, pp)
                        end
                    end
                end
            end
        end)
        Cache.Drops  = drops
        Cache.Chests = chests
    end
end)

print("[VaenHub] >> Cache system OK")

-- ╔══════════════════════════════════════╗
-- ║  GAME LOOPS (SEMUA task.spawn)       ║
-- ╚══════════════════════════════════════╝

-- Session timer
task.spawn(function()
    while true do
        task.wait(1)
        S.SessTime = S.SessTime + 1
    end
end)

-- Auto Roll (delay dikontrol State)
task.spawn(function()
    while true do
        local d = (type(S.RollDelay) == "number" and S.RollDelay > 0)
            and S.RollDelay or 0.8
        task.wait(d)
        if S.AutoRoll then
            Safe(function()
                FireR("Roll")
                FireR("RollPet")
                FireR("SpinSlime")
                FireR("GachaRoll")
                -- TIDAK pakai Activated:Fire() -- invalid di Delta
                S.Rolls = S.Rolls + 1
            end)
        end
    end
end)

-- Auto Farm (pakai cache, wait 1 detik)
task.spawn(function()
    while true do
        task.wait(1)
        if S.AutoFarm and HRP then
            Safe(function()
                -- Cari mob terdekat dari cache
                local best, bd = nil, math.huge
                for _, mr in ipairs(Cache.Mobs) do
                    if mr and mr.Parent then
                        local d = (HRP.Position - mr.Position).Magnitude
                        if d < bd then
                            bd   = d
                            best = mr
                        end
                    end
                end

                if best then
                    HRP.CFrame = best.CFrame * CFrame.new(0, 0, -3.5)
                    FireR("Attack")
                    FireR("DamageEnemy")
                    FireR("HitMob")
                end

                -- Kumpul drop dari cache
                for _, o in ipairs(Cache.Drops) do
                    if o and o.Parent and HRP then
                        local d = (HRP.Position - o.Position).Magnitude
                        if d < 50 then
                            HRP.CFrame = CFrame.new(o.Position)
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Sell / Merge / Equip
task.spawn(function()
    while true do
        task.wait(4)
        if S.AutoSell     then FireR("SellAll")      FireR("AutoSell")     end
        if S.AutoMerge    then FireR("MergeAll")     FireR("AutoMerge")    end
        if S.AutoEquipPet then FireR("EquipBestPet") FireR("AutoEquip")    end
    end
end)

-- Progression
task.spawn(function()
    while true do
        task.wait(3)
        if S.AutoBuyUpg    then FireR("BuyUpgrade")      FireR("BuyAllUpgrades") end
        if S.AutoRebirth   then FireR("Rebirth")          FireR("DoRebirth")      end
        if S.AutoClaimIdx  then FireR("ClaimIndexReward") FireR("ClaimAllIndex")  end
        if S.AutoClaimDaily then FireR("ClaimDaily")      FireR("DailyReward")    end
    end
end)

-- Potions
task.spawn(function()
    while true do
        task.wait(25)
        if S.AutoLuckPot  then FireR("UseLuckPotion")  FireR("ActivateLuck")    end
        if S.AutoSpeedPot then FireR("UseSpeedPotion") FireR("ActivateSpeed")   end
        if S.AutoRarePot  then FireR("UseRarePotion")  FireR("ActivateRare")    end
        if S.AutoAllPot   then FireR("UseAllPotions")  FireR("ActivateAllBuffs") end
    end
end)

-- Crafting
task.spawn(function()
    while true do
        task.wait(2)
        if S.AutoCraftBest  then FireR("CraftBestItem") end
        if S.AutoCraftWep   then FireR("CraftWeapon")   end
        if S.AutoCraftArmor then FireR("CraftArmor")    end
    end
end)

-- WalkSpeed / JumpPower enforcer
task.spawn(function()
    while true do
        task.wait(1)
        if Hum and Hum.Parent then
            pcall(function()
                Hum.WalkSpeed = S.WalkSpd
                Hum.JumpPower = S.JumpPow
            end)
        end
    end
end)

-- NoClip (Stepped, ringan)
RunService.Stepped:Connect(function()
    if not S.NoClip or not Char then return end
    pcall(function()
        for _, p in ipairs(Char:GetChildren()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    end)
end)

-- Anti AFK
task.spawn(function()
    while true do
        task.wait(55)
        if S.AntiAFK then
            DoAntiAFK()
        end
    end
end)

print("[VaenHub] >> Loops OK")

-- ╔══════════════════════════════════════╗
-- ║  FLY SYSTEM                          ║
-- ╚══════════════════════════════════════╝
local FlyBV, FlyBG, FlyConn

local function StartFly()
    pcall(function()
        if not HRP then return end
        if FlyBV   then FlyBV:Destroy() end
        if FlyBG   then FlyBG:Destroy() end
        if FlyConn then FlyConn:Disconnect() end

        FlyBV          = Instance.new("BodyVelocity")
        FlyBV.Velocity  = Vector3.zero
        FlyBV.MaxForce  = Vector3.new(1e9, 1e9, 1e9)
        FlyBV.Parent    = HRP

        FlyBG           = Instance.new("BodyGyro")
        FlyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        FlyBG.D         = 500
        FlyBG.Parent    = HRP

        local Cam = workspace.CurrentCamera
        FlyConn = RunService.Heartbeat:Connect(function()
            if not S.FlyOn or not FlyBV or not FlyBV.Parent then return end
            local spd = S.WalkSpd * 2
            local dir = Vector3.zero
            local UIS = UserInputService
            if UIS:IsKeyDown(Enum.KeyCode.W)           then dir = dir + Cam.CFrame.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.S)           then dir = dir - Cam.CFrame.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.A)           then dir = dir - Cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D)           then dir = dir + Cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space)       then dir = dir + Vector3.yAxis          end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.yAxis          end
            FlyBV.Velocity = dir.Magnitude > 0 and dir.Unit * spd or Vector3.zero
            FlyBG.CFrame   = Cam.CFrame
        end)
    end)
end

local function StopFly()
    pcall(function()
        if FlyConn then FlyConn:Disconnect() FlyConn = nil end
        if FlyBV   then FlyBV:Destroy()      FlyBV   = nil end
        if FlyBG   then FlyBG:Destroy()      FlyBG   = nil end
    end)
end

-- Keybind F
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.F then
        S.FlyOn = not S.FlyOn
        if S.FlyOn then StartFly() else StopFly() end
        Notify("VaenHub", "Fly: " .. (S.FlyOn and "ON" or "OFF"), 2)
    end
end)

print("[VaenHub] >> Fly OK")

-- ╔══════════════════════════════════════╗
-- ║  ESP SYSTEM (NO MEMORY LEAK)         ║
-- ║  Pakai connection per-ESP yang       ║
-- ║  disconnect otomatis saat destroyed  ║
-- ╚══════════════════════════════════════╝
local ESPBin = { Players={}, Mobs={}, Drops={}, Chests={} }

local function MakeESP(adornee, color, label)
    if not adornee or not adornee.Parent then return nil end

    local bb, conn

    local ok, err2 = pcall(function()
        bb        = Instance.new("BillboardGui")
        bb.Name        = "VH_ESP"
        bb.AlwaysOnTop = true
        bb.Size        = UDim2.new(0, 105, 0, 36)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.Adornee     = adornee
        bb.Parent      = PGui

        local bg = Instance.new("Frame")
        bg.Size                   = UDim2.fromScale(1, 1)
        bg.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
        bg.BackgroundTransparency = 0.55
        bg.BorderSizePixel        = 0
        bg.Parent                 = bb

        local cr = Instance.new("UICorner")
        cr.CornerRadius = UDim.new(0, 4)
        cr.Parent       = bg

        local nl = Instance.new("TextLabel")
        nl.Size               = UDim2.new(1, 0, 0.58, 0)
        nl.BackgroundTransparency = 1
        nl.Text               = label or adornee.Name
        nl.TextColor3         = color
        nl.TextSize           = 11
        nl.Font               = Enum.Font.GothamBold
        nl.TextXAlignment     = Enum.TextXAlignment.Center
        nl.Parent             = bg

        local dl = Instance.new("TextLabel")
        dl.Name               = "Dist"
        dl.Size               = UDim2.new(1, 0, 0.42, 0)
        dl.Position           = UDim2.fromScale(0, 0.58)
        dl.BackgroundTransparency = 1
        dl.TextColor3         = C.TextB
        dl.TextSize           = 9
        dl.Font               = Enum.Font.Gotham
        dl.TextXAlignment     = Enum.TextXAlignment.Center
        dl.Parent             = bg

        -- Connection dengan auto-disconnect (FIX MEMORY LEAK)
        conn = RunService.Heartbeat:Connect(function()
            -- Kalau billboard atau adornee hilang, disconnect
            if not bb or not bb.Parent then
                conn:Disconnect()
                return
            end
            if not adornee or not adornee.Parent then
                conn:Disconnect()
                pcall(function() bb:Destroy() end)
                return
            end
            if not HRP then return end
            local dist = (HRP.Position - adornee.Position).Magnitude
            pcall(function()
                dl.Text = Round(dist, 1) .. " studs"
            end)
        end)
    end)

    if ok then
        return bb
    else
        print("[VaenHub] ESP error: " .. tostring(err2))
        return nil
    end
end

local function ClearESP(cat)
    for _, v in ipairs(ESPBin[cat] or {}) do
        pcall(function()
            if v and v.Parent then v:Destroy() end
        end)
    end
    ESPBin[cat] = {}
end

-- ESP scan loop (4 detik, bukan Heartbeat)
task.spawn(function()
    while true do
        task.wait(4)

        -- Players ESP
        if S.ESPPlayers then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP and plr.Character then
                    local root = plr.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local found = false
                        for _, e in ipairs(ESPBin.Players) do
                            if e and e.Adornee == root then found = true break end
                        end
                        if not found then
                            local bb = MakeESP(root, C.AccentG, plr.Name)
                            if bb then table.insert(ESPBin.Players, bb) end
                        end
                    end
                end
            end
        end

        -- Mobs ESP (dari cache)
        if S.ESPMobs then
            for _, mr in ipairs(Cache.Mobs) do
                if mr and mr.Parent then
                    local found = false
                    for _, e in ipairs(ESPBin.Mobs) do
                        if e and e.Adornee == mr then found = true break end
                    end
                    if not found then
                        local bb = MakeESP(mr, C.Yellow, "MOB")
                        if bb then table.insert(ESPBin.Mobs, bb) end
                    end
                end
            end
        end

        -- Drops ESP (dari cache)
        if S.ESPDrops then
            for _, o in ipairs(Cache.Drops) do
                if o and o.Parent then
                    local found = false
                    for _, e in ipairs(ESPBin.Drops) do
                        if e and e.Adornee == o then found = true break end
                    end
                    if not found then
                        local n    = o.Name:lower()
                        local rare = n:find("rare") or n:find("epic") or n:find("legend")
                        local bb   = MakeESP(o, rare and C.Yellow or C.Green, "DROP")
                        if bb then table.insert(ESPBin.Drops, bb) end
                    end
                end
            end
        end

        -- Chests ESP (dari cache)
        if S.ESPChests then
            for _, o in ipairs(Cache.Chests) do
                if o and o.Parent then
                    local found = false
                    for _, e in ipairs(ESPBin.Chests) do
                        if e and e.Adornee == o then found = true break end
                    end
                    if not found then
                        local n     = o.Name:lower()
                        local lucky = n:find("lucky")
                        local bb    = MakeESP(o, lucky and C.Yellow or C.Accent, "CHEST")
                        if bb then table.insert(ESPBin.Chests, bb) end
                    end
                end
            end
        end

    end -- while true
end)

print("[VaenHub] >> ESP OK")

-- ╔══════════════════════════════════════╗
-- ║  REMOVE OLD GUI                      ║
-- ╚══════════════════════════════════════╝
pcall(function()
    local old = PGui:FindFirstChild("VaenHub")
    if old then old:Destroy() end
end)

-- ╔══════════════════════════════════════╗
-- ║  SCREEN GUI                          ║
-- ╚══════════════════════════════════════╝
local SG = Instance.new("ScreenGui")
SG.Name           = "VaenHub"
SG.ResetOnSpawn   = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.DisplayOrder   = 100
SG.Parent         = PGui

print("[VaenHub] >> ScreenGui parent: " .. tostring(SG.Parent))

-- ╔══════════════════════════════════════╗
-- ║  WINDOW                              ║
-- ╚══════════════════════════════════════╝
local WW, WH = 550, 565

local Win = Instance.new("Frame")
Win.Name             = "Win"
Win.Size             = UDim2.new(0, WW, 0, WH)
Win.Position         = UDim2.new(0.5, -WW/2, 0.5, -WH/2)
Win.BackgroundColor3 = C.Bg
Win.BorderSizePixel  = 0
Win.ClipsDescendants = true
Win.Parent           = SG

local WinCorner = Instance.new("UICorner")
WinCorner.CornerRadius = UDim.new(0, 12)
WinCorner.Parent       = Win

-- Outer glow
local OG = Instance.new("Frame")
OG.Name             = "OuterGlow"
OG.Size             = UDim2.new(1, 6, 1, 6)
OG.Position         = UDim2.new(0, -3, 0, -3)
OG.BackgroundColor3 = C.Accent
OG.BackgroundTransparency = 0.62
OG.BorderSizePixel  = 0
OG.ZIndex           = 0
OG.Parent           = Win

local OGC = Instance.new("UICorner")
OGC.CornerRadius = UDim.new(0, 15)
OGC.Parent       = OG

-- Glow pulse
task.spawn(function()
    while Win and Win.Parent do
        Tw(OG, {BackgroundTransparency = 0.42}, 0.9, "Sine", "InOut")
        task.wait(0.9)
        Tw(OG, {BackgroundTransparency = 0.72}, 0.9, "Sine", "InOut")
        task.wait(0.9)
    end
end)

print("[VaenHub] >> Window OK")

-- ╔══════════════════════════════════════╗
-- ║  TITLE BAR                           ║
-- ╚══════════════════════════════════════╝
local TB = Instance.new("Frame")
TB.Name             = "TitleBar"
TB.Size             = UDim2.new(1, 0, 0, 50)
TB.BackgroundColor3 = C.Surface
TB.BorderSizePixel  = 0
TB.ZIndex           = 5
TB.Parent           = Win

local TBC = Instance.new("UICorner")
TBC.CornerRadius = UDim.new(0, 12)
TBC.Parent       = TB

-- Fix bottom corners titlebar
local TBF = Instance.new("Frame")
TBF.Size             = UDim2.new(1, 0, 0.5, 0)
TBF.Position         = UDim2.new(0, 0, 0.5, 0)
TBF.BackgroundColor3 = C.Surface
TBF.BorderSizePixel  = 0
TBF.ZIndex           = 5
TBF.Parent           = TB

-- Accent line bawah titlebar
local AL = Instance.new("Frame")
AL.Size             = UDim2.new(1, 0, 0, 2)
AL.Position         = UDim2.new(0, 0, 1, -2)
AL.BackgroundColor3 = C.Accent
AL.BorderSizePixel  = 0
AL.ZIndex           = 6
AL.Parent           = TB

local ALG = Instance.new("UIGradient")
ALG.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0, 80, 180)),
    ColorSequenceKeypoint.new(0.5, C.AccentG),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0, 80, 180)),
})
ALG.Parent = AL

-- Dot logo
local Dot = Instance.new("Frame")
Dot.Size             = UDim2.new(0, 10, 0, 10)
Dot.Position         = UDim2.new(0, 16, 0.5, -5)
Dot.BackgroundColor3 = C.Accent
Dot.BorderSizePixel  = 0
Dot.ZIndex           = 6
Dot.Parent           = TB

local DotC = Instance.new("UICorner")
DotC.CornerRadius = UDim.new(1, 0)
DotC.Parent       = Dot

task.spawn(function()
    while Win and Win.Parent do
        Tw(Dot, {BackgroundColor3 = C.AccentG}, 0.8, "Sine", "InOut")
        task.wait(0.8)
        Tw(Dot, {BackgroundColor3 = C.AccentD}, 0.8, "Sine", "InOut")
        task.wait(0.8)
    end
end)

-- Title text
local TL = Instance.new("TextLabel")
TL.Size               = UDim2.new(1, -115, 0, 26)
TL.Position           = UDim2.new(0, 34, 0, 4)
TL.BackgroundTransparency = 1
TL.Text               = "Slime RNG  ·  VaenHub"
TL.TextColor3         = C.TextA
TL.TextSize           = 15
TL.Font               = Enum.Font.GothamBold
TL.TextXAlignment     = Enum.TextXAlignment.Left
TL.ZIndex             = 6
TL.Parent             = TB

local SL = Instance.new("TextLabel")
SL.Size               = UDim2.new(1, -115, 0, 14)
SL.Position           = UDim2.new(0, 34, 0, 30)
SL.BackgroundTransparency = 1
SL.Text               = "Premium · Delta Android Fixed · S+ Quality"
SL.TextColor3         = C.Accent
SL.TextSize           = 9
SL.Font               = Enum.Font.Gotham
SL.TextXAlignment     = Enum.TextXAlignment.Left
SL.ZIndex             = 6
SL.Parent             = TB

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size             = UDim2.new(0, 28, 0, 28)
CloseBtn.Position         = UDim2.new(1, -38, 0.5, -14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 55, 65)
CloseBtn.BorderSizePixel  = 0
CloseBtn.Text             = "✕"
CloseBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize         = 13
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.ZIndex           = 7
CloseBtn.Parent           = TB

local CloseBtnC = Instance.new("UICorner")
CloseBtnC.CornerRadius = UDim.new(0, 7)
CloseBtnC.Parent       = CloseBtn

CloseBtn.MouseEnter:Connect(function()
    Tw(CloseBtn, {BackgroundColor3 = Color3.fromRGB(255, 80, 88)}, 0.12)
end)
CloseBtn.MouseLeave:Connect(function()
    Tw(CloseBtn, {BackgroundColor3 = Color3.fromRGB(255, 55, 65)}, 0.12)
end)
CloseBtn.MouseButton1Click:Connect(function()
    Tw(Win, {
        Size     = UDim2.new(0, WW, 0, 0),
        Position = UDim2.new(0.5, -WW/2, 0.5, 0),
    }, 0.25, "Back", "In")
    task.delay(0.28, function()
        pcall(function() SG:Destroy() end)
    end)
end)

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size             = UDim2.new(0, 28, 0, 28)
MinBtn.Position         = UDim2.new(1, -72, 0.5, -14)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 168, 0)
MinBtn.BorderSizePixel  = 0
MinBtn.Text             = "–"
MinBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize         = 16
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.ZIndex           = 7
MinBtn.Parent           = TB

local MinBtnC = Instance.new("UICorner")
MinBtnC.CornerRadius = UDim.new(0, 7)
MinBtnC.Parent       = MinBtn

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Tw(Win, {
        Size = minimized
            and UDim2.new(0, WW, 0, 50)
            or  UDim2.new(0, WW, 0, WH),
    }, 0.25, "Quad", "Out")
end)

print("[VaenHub] >> TitleBar OK")

-- ╔══════════════════════════════════════╗
-- ║  DRAG                                ║
-- ╚══════════════════════════════════════╝
local drg, drgStart, winStart = false, nil, nil

TB.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        drg      = true
        drgStart = inp.Position
        winStart = Win.Position
    end
end)

TB.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        drg = false
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if drg and inp.UserInputType == Enum.UserInputType.MouseMovement and winStart then
        local delta = inp.Position - drgStart
        Win.Position = UDim2.new(
            winStart.X.Scale, winStart.X.Offset + delta.X,
            winStart.Y.Scale, winStart.Y.Offset + delta.Y
        )
    end
end)

-- ╔══════════════════════════════════════╗
-- ║  TAB BAR                             ║
-- ╚══════════════════════════════════════╝
local TAB_TOP = 50
local TAB_H   = 42

local TBg = Instance.new("Frame")
TBg.Name             = "TabBar"
TBg.Size             = UDim2.new(1, 0, 0, TAB_H)
TBg.Position         = UDim2.new(0, 0, 0, TAB_TOP)
TBg.BackgroundColor3 = C.Surface
TBg.BorderSizePixel  = 0
TBg.ZIndex           = 4
TBg.Parent           = Win

-- Separator
local TSep = Instance.new("Frame")
TSep.Size             = UDim2.new(1, 0, 0, 1)
TSep.Position         = UDim2.new(0, 0, 1, -1)
TSep.BackgroundColor3 = C.Sep
TSep.BorderSizePixel  = 0
TSep.ZIndex           = 5
TSep.Parent           = TBg

-- Content Area
local CONT_Y = TAB_TOP + TAB_H

local CA = Instance.new("Frame")
CA.Name             = "ContentArea"
CA.Size             = UDim2.new(1, 0, 1, -CONT_Y)
CA.Position         = UDim2.new(0, 0, 0, CONT_Y)
CA.BackgroundTransparency = 1
CA.BorderSizePixel  = 0
CA.ClipsDescendants = true
CA.Parent           = Win

-- ╔══════════════════════════════════════╗
-- ║  TAB SYSTEM                          ║
-- ╚══════════════════════════════════════╝
local TABS = {
    {id="Main",     icon="⚔️"},
    {id="Potions",  icon="🧪"},
    {id="Crafting", icon="🔨"},
    {id="Config",   icon="⚙️"},
    {id="Misc",     icon="🎮"},
}

local TabData = {}
local ActiveT = nil

local TBTN_W = math.floor((WW - 20) / #TABS)

for i, def in ipairs(TABS) do
    local xOff = 10 + (i - 1) * (TBTN_W + 2)

    -- Tab button
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, TBTN_W, 0, 32)
    btn.Position         = UDim2.new(0, xOff, 0.5, -16)
    btn.BackgroundColor3 = C.Surface
    btn.BorderSizePixel  = 0
    btn.Text             = def.icon .. " " .. def.id
    btn.TextColor3       = C.TextC
    btn.TextSize         = 11
    btn.Font             = Enum.Font.GothamSemibold
    btn.ZIndex           = 5
    btn.Parent           = TBg

    local btnC = Instance.new("UICorner")
    btnC.CornerRadius = UDim.new(0, 7)
    btnC.Parent       = btn

    -- Active indicator bar
    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0.7, 0, 0, 2)
    bar.Position         = UDim2.new(0.15, 0, 1, -2)
    bar.BackgroundColor3 = C.Accent
    bar.BackgroundTransparency = 1
    bar.BorderSizePixel  = 0
    bar.ZIndex           = 6
    bar.Parent           = btn

    local barC = Instance.new("UICorner")
    barC.CornerRadius = UDim.new(1, 0)
    barC.Parent       = bar

    -- Page frame
    local page = Instance.new("Frame")
    page.Name             = "Page_" .. def.id
    page.Size             = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.Visible          = false
    page.Parent           = CA

    TabData[def.id] = {btn = btn, bar = bar, page = page}

    btn.MouseButton1Click:Connect(function()
        if ActiveT == def.id then return end

        -- Deactivate previous
        if ActiveT and TabData[ActiveT] then
            local prev = TabData[ActiveT]
            Tw(prev.btn, {BackgroundColor3 = C.Surface, TextColor3 = C.TextC}, 0.15)
            Tw(prev.bar, {BackgroundTransparency = 1}, 0.15)
            prev.page.Visible = false
        end

        -- Activate current
        ActiveT = def.id
        Tw(btn, {BackgroundColor3 = C.Hover, TextColor3 = C.TextA}, 0.15)
        Tw(bar, {BackgroundTransparency = 0}, 0.15)
        page.Visible = true
    end)
end

print("[VaenHub] >> Tabs OK")

-- ╔══════════════════════════════════════╗
-- ║  SCROLL FRAME BUILDER                ║
-- ║  Tidak pakai AutomaticCanvasSize     ║
-- ║  Pakai UIListLayout AbsoluteContent  ║
-- ╚══════════════════════════════════════╝
local function MakeScroll(parent)
    local sf = Instance.new("ScrollingFrame")
    sf.Size                   = UDim2.fromScale(1, 1)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel        = 0
    sf.ScrollBarThickness     = 3
    sf.ScrollBarImageColor3   = C.Accent
    sf.ScrollBarImageTransparency = 0.4
    sf.CanvasSize             = UDim2.new(0, 0, 0, 1500)
    sf.ScrollingDirection     = Enum.ScrollingDirection.Y
    sf.Parent                 = parent

    local ul = Instance.new("UIListLayout")
    ul.Padding             = UDim.new(0, 6)
    ul.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ul.SortOrder           = Enum.SortOrder.LayoutOrder
    ul.Parent              = sf

    local pd = Instance.new("UIPadding")
    pd.PaddingTop    = UDim.new(0, 10)
    pd.PaddingBottom = UDim.new(0, 14)
    pd.PaddingLeft   = UDim.new(0, 12)
    pd.PaddingRight  = UDim.new(0, 12)
    pd.Parent        = sf

    -- Auto-resize canvas
    ul:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        pcall(function()
            sf.CanvasSize = UDim2.new(0, 0, 0, ul.AbsoluteContentSize.Y + 26)
        end)
    end)

    return sf
end

-- ╔══════════════════════════════════════╗
-- ║  COMPONENT: SECTION LABEL            ║
-- ╚══════════════════════════════════════╝
local function Sec(parent, text, order)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, 0, 0, 22)
    f.BackgroundTransparency = 1
    f.LayoutOrder      = order or 0
    f.Parent           = parent

    local l1 = Instance.new("Frame")
    l1.Size             = UDim2.new(0.28, 0, 0, 1)
    l1.Position         = UDim2.new(0, 0, 0.5, 0)
    l1.BackgroundColor3 = C.Sep
    l1.BorderSizePixel  = 0
    l1.Parent           = f

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(0.44, 0, 1, 0)
    lbl.Position           = UDim2.new(0.28, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = "  " .. text:upper() .. "  "
    lbl.TextColor3         = C.TextC
    lbl.TextSize           = 9
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextXAlignment     = Enum.TextXAlignment.Center
    lbl.Parent             = f

    local l2 = Instance.new("Frame")
    l2.Size             = UDim2.new(0.28, 0, 0, 1)
    l2.Position         = UDim2.new(0.72, 0, 0.5, 0)
    l2.BackgroundColor3 = C.Sep
    l2.BorderSizePixel  = 0
    l2.Parent           = f

    return f
end

-- ╔══════════════════════════════════════╗
-- ║  COMPONENT: TOGGLE ROW               ║
-- ╚══════════════════════════════════════╝
local ToggleSync = {}

local function Tog(parent, icon, title, sub, key, order, cb)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 54)
    row.BackgroundColor3 = C.Card
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order or 99
    row.Parent           = parent

    local rowC = Instance.new("UICorner")
    rowC.CornerRadius = UDim.new(0, 10)
    rowC.Parent       = row

    -- Icon
    local ic = Instance.new("TextLabel")
    ic.Size               = UDim2.new(0, 34, 1, 0)
    ic.Position           = UDim2.new(0, 10, 0, 0)
    ic.BackgroundTransparency = 1
    ic.Text               = icon
    ic.TextSize           = 17
    ic.TextXAlignment     = Enum.TextXAlignment.Center
    ic.ZIndex             = 2
    ic.Parent             = row

    -- Title
    local tl = Instance.new("TextLabel")
    tl.Size               = UDim2.new(1, -108, 0, 22)
    tl.Position           = UDim2.new(0, 48, 0, 7)
    tl.BackgroundTransparency = 1
    tl.Text               = title
    tl.TextColor3         = C.TextA
    tl.TextSize           = 13
    tl.Font               = Enum.Font.GothamSemibold
    tl.TextXAlignment     = Enum.TextXAlignment.Left
    tl.ZIndex             = 2
    tl.Parent             = row

    -- Subtitle
    local sl = Instance.new("TextLabel")
    sl.Size               = UDim2.new(1, -108, 0, 16)
    sl.Position           = UDim2.new(0, 48, 0, 30)
    sl.BackgroundTransparency = 1
    sl.Text               = sub or ""
    sl.TextColor3         = C.TextC
    sl.TextSize           = 10
    sl.Font               = Enum.Font.Gotham
    sl.TextXAlignment     = Enum.TextXAlignment.Left
    sl.ZIndex             = 2
    sl.Parent             = row

    -- Toggle pill
    local initOn = S[key] == true

    local pill = Instance.new("Frame")
    pill.Size             = UDim2.new(0, 40, 0, 21)
    pill.Position         = UDim2.new(1, -52, 0.5, -10)
    pill.BackgroundColor3 = initOn and C.Accent or C.PillOff
    pill.BorderSizePixel  = 0
    pill.ZIndex           = 2
    pill.Parent           = row

    local pillC = Instance.new("UICorner")
    pillC.CornerRadius = UDim.new(1, 0)
    pillC.Parent       = pill

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 15, 0, 15)
    knob.Position         = initOn
        and UDim2.new(1, -18, 0.5, -7)
        or  UDim2.new(0, 3,   0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 3
    knob.Parent           = pill

    local knobC = Instance.new("UICorner")
    knobC.CornerRadius = UDim.new(1, 0)
    knobC.Parent       = knob

    -- Sync function (untuk reset dari luar)
    local function Sync(state)
        pcall(function()
            Tw(pill, {BackgroundColor3 = state and C.Accent or C.PillOff}, 0.18)
            Tw(knob, {
                Position = state
                    and UDim2.new(1, -18, 0.5, -7)
                    or  UDim2.new(0, 3,   0.5, -7),
            }, 0.18)
        end)
    end

    ToggleSync[key] = Sync

    -- Click button overlay
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text             = ""
    btn.ZIndex           = 4
    btn.Parent           = row

    btn.MouseEnter:Connect(function()
        Tw(row, {BackgroundColor3 = C.Hover}, 0.12)
    end)
    btn.MouseLeave:Connect(function()
        Tw(row, {BackgroundColor3 = C.Card}, 0.12)
    end)
    btn.MouseButton1Click:Connect(function()
        S[key] = not S[key]
        Sync(S[key])
        if cb then Safe(cb, S[key]) end
    end)

    return row
end

-- ╔══════════════════════════════════════╗
-- ║  COMPONENT: BUTTON ROW               ║
-- ╚══════════════════════════════════════╝
local function Btn(parent, icon, title, sub, accent, order, cb)
    local h = sub and 54 or 44

    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, h)
    row.BackgroundColor3 = C.Card
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order or 99
    row.Parent           = parent

    local rowC = Instance.new("UICorner")
    rowC.CornerRadius = UDim.new(0, 10)
    rowC.Parent       = row

    local ic = Instance.new("TextLabel")
    ic.Size               = UDim2.new(0, 34, 1, 0)
    ic.Position           = UDim2.new(0, 10, 0, 0)
    ic.BackgroundTransparency = 1
    ic.Text               = icon
    ic.TextSize           = 17
    ic.TextXAlignment     = Enum.TextXAlignment.Center
    ic.ZIndex             = 2
    ic.Parent             = row

    local tl = Instance.new("TextLabel")
    tl.Size               = UDim2.new(1, -68, 0, 22)
    tl.Position           = sub and UDim2.new(0, 48, 0, 7) or UDim2.new(0, 48, 0.5, -11)
    tl.BackgroundTransparency = 1
    tl.Text               = title
    tl.TextColor3         = accent or C.TextA
    tl.TextSize           = 13
    tl.Font               = Enum.Font.GothamSemibold
    tl.TextXAlignment     = Enum.TextXAlignment.Left
    tl.ZIndex             = 2
    tl.Parent             = row

    if sub then
        local sl = Instance.new("TextLabel")
        sl.Size               = UDim2.new(1, -68, 0, 16)
        sl.Position           = UDim2.new(0, 48, 0, 30)
        sl.BackgroundTransparency = 1
        sl.Text               = sub
        sl.TextColor3         = C.TextC
        sl.TextSize           = 10
        sl.Font               = Enum.Font.Gotham
        sl.TextXAlignment     = Enum.TextXAlignment.Left
        sl.ZIndex             = 2
        sl.Parent             = row
    end

    local arr = Instance.new("TextLabel")
    arr.Size               = UDim2.new(0, 20, 1, 0)
    arr.Position           = UDim2.new(1, -28, 0, 0)
    arr.BackgroundTransparency = 1
    arr.Text               = "›"
    arr.TextColor3         = accent or C.TextC
    arr.TextSize           = 20
    arr.Font               = Enum.Font.GothamBold
    arr.ZIndex             = 2
    arr.Parent             = row

    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text             = ""
    btn.ZIndex           = 3
    btn.Parent           = row

    btn.MouseEnter:Connect(function()
        Tw(row, {BackgroundColor3 = C.Hover}, 0.12)
        Tw(arr, {TextColor3 = C.Accent}, 0.12)
    end)
    btn.MouseLeave:Connect(function()
        Tw(row, {BackgroundColor3 = C.Card}, 0.12)
        Tw(arr, {TextColor3 = accent or C.TextC}, 0.12)
    end)
    btn.MouseButton1Click:Connect(function()
        if cb then Safe(cb) end
    end)

    return row
end

-- ╔══════════════════════════════════════╗
-- ║  COMPONENT: SLIDER                   ║
-- ╚══════════════════════════════════════╝
local function Sldr(parent, icon, title, minV, maxV, default, key, order, cb)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 66)
    row.BackgroundColor3 = C.Card
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order or 99
    row.Parent           = parent

    local rowC = Instance.new("UICorner")
    rowC.CornerRadius = UDim.new(0, 10)
    rowC.Parent       = row

    local ic = Instance.new("TextLabel")
    ic.Size               = UDim2.new(0, 34, 0, 28)
    ic.Position           = UDim2.new(0, 10, 0, 5)
    ic.BackgroundTransparency = 1
    ic.Text               = icon
    ic.TextSize           = 17
    ic.TextXAlignment     = Enum.TextXAlignment.Center
    ic.ZIndex             = 2
    ic.Parent             = row

    local tl = Instance.new("TextLabel")
    tl.Size               = UDim2.new(1, -100, 0, 20)
    tl.Position           = UDim2.new(0, 48, 0, 5)
    tl.BackgroundTransparency = 1
    tl.Text               = title
    tl.TextColor3         = C.TextA
    tl.TextSize           = 13
    tl.Font               = Enum.Font.GothamSemibold
    tl.TextXAlignment     = Enum.TextXAlignment.Left
    tl.ZIndex             = 2
    tl.Parent             = row

    local vl = Instance.new("TextLabel")
    vl.Size               = UDim2.new(0, 52, 0, 20)
    vl.Position           = UDim2.new(1, -58, 0, 5)
    vl.BackgroundTransparency = 1
    vl.Text               = tostring(default)
    vl.TextColor3         = C.Accent
    vl.TextSize           = 13
    vl.Font               = Enum.Font.GothamBold
    vl.TextXAlignment     = Enum.TextXAlignment.Right
    vl.ZIndex             = 2
    vl.Parent             = row

    -- Track
    local track = Instance.new("Frame")
    track.Size             = UDim2.new(1, -24, 0, 5)
    track.Position         = UDim2.new(0, 12, 0, 46)
    track.BackgroundColor3 = C.PillOff
    track.BorderSizePixel  = 0
    track.ZIndex           = 2
    track.Parent           = row

    local trackC = Instance.new("UICorner")
    trackC.CornerRadius = UDim.new(1, 0)
    trackC.Parent       = track

    local pct0 = math.clamp((default - minV) / (maxV - minV), 0, 1)

    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new(pct0, 0, 1, 0)
    fill.BackgroundColor3 = C.Accent
    fill.BorderSizePixel  = 0
    fill.ZIndex           = 3
    fill.Parent           = track

    local fillC = Instance.new("UICorner")
    fillC.CornerRadius = UDim.new(1, 0)
    fillC.Parent       = fill

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 13, 0, 13)
    knob.Position         = UDim2.new(pct0, -6, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 4
    knob.Parent           = track

    local knobC = Instance.new("UICorner")
    knobC.CornerRadius = UDim.new(1, 0)
    knobC.Parent       = knob

    local drgSldr = false

    local function UpdateSldr(inp)
        if not track or not track.Parent then return end
        local ax = track.AbsolutePosition.X
        local aw = track.AbsoluteSize.X
        if aw == 0 then return end
        local pct = math.clamp((inp.Position.X - ax) / aw, 0, 1)
        local val = Round(minV + (maxV - minV) * pct, 2)
        pcall(function()
            fill.Size     = UDim2.new(pct, 0, 1, 0)
            knob.Position = UDim2.new(pct, -6, 0.5, -6)
            vl.Text       = tostring(val)
        end)
        if key then S[key] = val end
        if cb  then Safe(cb, val) end
    end

    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            drgSldr = true
            UpdateSldr(inp)
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if drgSldr and inp.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateSldr(inp)
        end
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            drgSldr = false
        end
    end)

    return row
end

-- ╔══════════════════════════════════════╗
-- ║  COMPONENT: TEXT INPUT               ║
-- ╚══════════════════════════════════════╝
local function Inp(parent, icon, title, hint, key, order, cb)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 66)
    row.BackgroundColor3 = C.Card
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order or 99
    row.Parent           = parent

    local rowC = Instance.new("UICorner")
    rowC.CornerRadius = UDim.new(0, 10)
    rowC.Parent       = row

    local ic = Instance.new("TextLabel")
    ic.Size               = UDim2.new(0, 34, 0, 28)
    ic.Position           = UDim2.new(0, 10, 0, 4)
    ic.BackgroundTransparency = 1
    ic.Text               = icon
    ic.TextSize           = 17
    ic.TextXAlignment     = Enum.TextXAlignment.Center
    ic.ZIndex             = 2
    ic.Parent             = row

    local tl = Instance.new("TextLabel")
    tl.Size               = UDim2.new(1, -28, 0, 20)
    tl.Position           = UDim2.new(0, 48, 0, 4)
    tl.BackgroundTransparency = 1
    tl.Text               = title
    tl.TextColor3         = C.TextA
    tl.TextSize           = 13
    tl.Font               = Enum.Font.GothamSemibold
    tl.TextXAlignment     = Enum.TextXAlignment.Left
    tl.ZIndex             = 2
    tl.Parent             = row

    local ibg = Instance.new("Frame")
    ibg.Size             = UDim2.new(1, -24, 0, 24)
    ibg.Position         = UDim2.new(0, 12, 0, 36)
    ibg.BackgroundColor3 = C.Bg
    ibg.BorderSizePixel  = 0
    ibg.ZIndex           = 2
    ibg.Parent           = row

    local ibgC = Instance.new("UICorner")
    ibgC.CornerRadius = UDim.new(0, 6)
    ibgC.Parent       = ibg

    local tb = Instance.new("TextBox")
    tb.Size              = UDim2.new(1, -10, 1, 0)
    tb.Position          = UDim2.new(0, 6, 0, 0)
    tb.BackgroundTransparency = 1
    tb.PlaceholderText   = hint or ""
    tb.PlaceholderColor3 = C.TextC
    tb.Text              = (key and tostring(S[key])) or ""
    tb.TextColor3        = C.TextA
    tb.TextSize          = 11
    tb.Font              = Enum.Font.Gotham
    tb.TextXAlignment    = Enum.TextXAlignment.Left
    tb.ClearTextOnFocus  = false
    tb.ZIndex            = 3
    tb.Parent            = ibg

    tb.FocusLost:Connect(function()
        if key then S[key] = tb.Text end
        if cb  then Safe(cb, tb.Text) end
    end)

    return row, tb
end

-- ╔══════════════════════════════════════╗
-- ║  COMPONENT: STAT CARD                ║
-- ║  Manual positioning, no GridLayout   ║
-- ╚══════════════════════════════════════╝
local function StatCard(parent, icon, lbl, stateKey, xPos, yPos)
    local card = Instance.new("Frame")
    card.Size             = UDim2.new(0, 118, 0, 70)
    card.Position         = UDim2.new(0, xPos, 0, yPos)
    card.BackgroundColor3 = C.Card
    card.BorderSizePixel  = 0
    card.Parent           = parent

    local cardC = Instance.new("UICorner")
    cardC.CornerRadius = UDim.new(0, 10)
    cardC.Parent       = card

    local ic = Instance.new("TextLabel")
    ic.Size               = UDim2.new(1, 0, 0, 24)
    ic.Position           = UDim2.new(0, 0, 0, 5)
    ic.BackgroundTransparency = 1
    ic.Text               = icon
    ic.TextSize           = 17
    ic.TextXAlignment     = Enum.TextXAlignment.Center
    ic.ZIndex             = 2
    ic.Parent             = card

    local vl = Instance.new("TextLabel")
    vl.Size               = UDim2.new(1, -4, 0, 18)
    vl.Position           = UDim2.new(0, 2, 0, 28)
    vl.BackgroundTransparency = 1
    vl.TextColor3         = C.Accent
    vl.TextSize           = 12
    vl.Font               = Enum.Font.GothamBold
    vl.TextXAlignment     = Enum.TextXAlignment.Center
    vl.ZIndex             = 2
    vl.Parent             = card

    local ll = Instance.new("TextLabel")
    ll.Size               = UDim2.new(1, -4, 0, 13)
    ll.Position           = UDim2.new(0, 2, 0, 50)
    ll.BackgroundTransparency = 1
    ll.Text               = lbl
    ll.TextColor3         = C.TextC
    ll.TextSize           = 9
    ll.Font               = Enum.Font.GothamBold
    ll.TextXAlignment     = Enum.TextXAlignment.Center
    ll.ZIndex             = 2
    ll.Parent             = card

    -- Live update tiap 1 detik (bukan Heartbeat, lebih hemat)
    task.spawn(function()
        while vl and vl.Parent do
            task.wait(1)
            pcall(function()
                local v = S[stateKey]
                if stateKey == "SessTime" then
                    vl.Text = FmtTime(math.floor(v))
                elseif type(v) == "number" then
                    vl.Text = tostring(math.floor(v))
                else
                    vl.Text = tostring(v)
                end
            end)
        end
    end)

    return card
end

print("[VaenHub] >> Components OK, building pages...")

-- ╔══════════════════════════════════════╗
-- ║  PAGE: MAIN                          ║
-- ╚══════════════════════════════════════╝
do
    local sf = MakeScroll(TabData["Main"].page)
    Sec(sf, "Auto Farm", 1)
    Tog(sf, "⚔️", "Auto Farm Everything", "Farms mobs & collects drops",     "AutoFarm",       2)
    Tog(sf, "🎲", "Auto Roll",            "Auto rolls for slime pets",         "AutoRoll",       3)
    Tog(sf, "🐾", "Auto Equip Best Pet",  "Equips highest power pet",          "AutoEquipPet",   4)
    Sec(sf, "Management", 5)
    Tog(sf, "💰", "Auto Sell",            "Sells items for coins",             "AutoSell",       6)
    Tog(sf, "🔀", "Auto Merge",           "Merges duplicate pets",             "AutoMerge",      7)
    Sec(sf, "Progression", 8)
    Tog(sf, "⬆️", "Auto Buy Upgrades",   "Buys all available upgrades",       "AutoBuyUpg",     9)
    Tog(sf, "🔄", "Auto Rebirth",         "Auto-rebirth when conditions met",  "AutoRebirth",   10)
    Tog(sf, "📋", "Auto Claim Index",     "Claims index/pokedex rewards",      "AutoClaimIdx",  11)
    Tog(sf, "🎁", "Auto Claim Daily",     "Claims daily login reward",         "AutoClaimDaily",12)
end

-- ╔══════════════════════════════════════╗
-- ║  PAGE: POTIONS                       ║
-- ╚══════════════════════════════════════╝
do
    local sf = MakeScroll(TabData["Potions"].page)
    Sec(sf, "Automation", 1)
    Tog(sf, "🍀", "Auto Luck Potion",     "Uses luck potion every 25s",       "AutoLuckPot",  2)
    Tog(sf, "⚡", "Auto Speed Potion",    "Uses speed potion every 25s",      "AutoSpeedPot", 3)
    Tog(sf, "💎", "Auto Rare Potion",     "Uses rare-find potion",            "AutoRarePot",  4)
    Tog(sf, "✨", "Auto All Potions",     "Activates every buff potion",      "AutoAllPot",   5)
    Sec(sf, "Actions", 6)
    Btn(sf, "🏃", "Collect All Potions",  "Teleports to all map potions",     C.Green, 7, function()
        for _, o in ipairs(workspace:GetChildren()) do
            if o:IsA("BasePart") and o.Name:lower():find("potion") and HRP then
                HRP.CFrame = CFrame.new(o.Position)
                task.wait(0.08)
            end
        end
        Notify("VaenHub", "Potions collected!")
    end)
    Btn(sf, "🔮", "Craft All Potions",    "Crafts every available potion",    C.Accent, 8, function()
        FireR("CraftAllPotions")
        FireR("AutoCraft")
    end)
end

-- ╔══════════════════════════════════════╗
-- ║  PAGE: CRAFTING                      ║
-- ╚══════════════════════════════════════╝
do
    local sf = MakeScroll(TabData["Crafting"].page)
    Sec(sf, "Auto Crafting", 1)
    Tog(sf, "🔨", "Auto Craft Best",      "Crafts highest-tier item",         "AutoCraftBest",  2)
    Tog(sf, "🗡️", "Auto Craft Weapons",  "Crafts weapons continuously",      "AutoCraftWep",   3)
    Tog(sf, "🛡️", "Auto Craft Armor",    "Crafts armor pieces",              "AutoCraftArmor", 4)
    Sec(sf, "Actions", 5)
    Btn(sf, "📦", "Collect Materials",    "Picks up ores and crystals",       C.Yellow, 6, function()
        for _, o in ipairs(workspace:GetChildren()) do
            if o:IsA("BasePart") and HRP then
                local n = o.Name:lower()
                if n:find("ore") or n:find("crystal") or n:find("shard") or n:find("material") then
                    HRP.CFrame = CFrame.new(o.Position)
                    task.wait(0.06)
                end
            end
        end
        Notify("VaenHub", "Materials collected!")
    end)
    Btn(sf, "♻️", "Salvage All Junk",    "Dismantles unwanted items",        C.Red, 7, function()
        FireR("SalvageAll")
        FireR("DismantelAll")
    end)
    Btn(sf, "⚗️", "Max Craft All",       "Crafts maximum quantity",          C.Accent, 8, function()
        FireR("MaxCraftAll")
        FireR("CraftMax")
    end)
end

-- ╔══════════════════════════════════════╗
-- ║  PAGE: CONFIG                        ║
-- ╚══════════════════════════════════════╝
do
    local sf = MakeScroll(TabData["Config"].page)

    Sec(sf, "Timings", 1)
    Sldr(sf, "⏱️", "Roll Delay (sec)", 0.1, 5.0, S.RollDelay, "RollDelay", 2)
    Sldr(sf, "🏃",  "Walk Speed",      16,   150, S.WalkSpd,  "WalkSpd",   3, function(v)
        if Hum and Hum.Parent then
            pcall(function() Hum.WalkSpeed = v end)
        end
    end)
    Sldr(sf, "🦘",  "Jump Power",      50,   500, S.JumpPow,  "JumpPow",   4, function(v)
        if Hum and Hum.Parent then
            pcall(function() Hum.JumpPower = v end)
        end
    end)

    Sec(sf, "Discord Webhook", 5)
    Inp(sf, "🔗", "Webhook URL", "https://discord.com/api/webhooks/...", "Webhook", 6)

    Btn(sf, "📤", "Test Webhook", "Send test notification to Discord", C.Accent, 7, function()
        if S.Webhook == "" then
            Notify("VaenHub", "Masukkan webhook URL dulu!")
            return
        end
        pcall(function()
            local HS   = game:GetService("HttpService")
            local data = HS:JSONEncode({
                embeds = {{
                    title       = "VaenHub · Slime RNG",
                    description = "Script aktif!\nPlayer: **"..LP.Name.."**\nTotal Rolls: **"..S.Rolls.."**",
                    color       = 0x00A8FF,
                }}
            })
            HS:PostAsync(S.Webhook, data, Enum.HttpContentType.ApplicationJson)
        end)
        Notify("VaenHub", "Webhook terkirim!")
    end)

    Sec(sf, "Save & Load", 8)

    Btn(sf, "💾", "Save Settings", "Simpan config ke file", C.Green, 9, function()
        pcall(function()
            if not writefile then
                Notify("VaenHub", "writefile tidak tersedia")
                return
            end
            local HS = game:GetService("HttpService")
            writefile("VaenHub_SRNG.json", HS:JSONEncode({
                RollDelay = S.RollDelay,
                WalkSpd   = S.WalkSpd,
                JumpPow   = S.JumpPow,
                Webhook   = S.Webhook,
                Rolls     = S.Rolls,
                BestPet   = S.BestPet,
                Rares     = S.Rares,
            }))
            Notify("VaenHub", "Settings tersimpan!")
        end)
    end)

    Btn(sf, "📂", "Load Settings", "Load config dari file", C.Accent, 10, function()
        pcall(function()
            if not readfile or not isfile then
                Notify("VaenHub", "readfile tidak tersedia")
                return
            end
            if not isfile("VaenHub_SRNG.json") then
                Notify("VaenHub", "Belum ada file settings")
                return
            end
            local HS = game:GetService("HttpService")
            local d  = HS:JSONDecode(readfile("VaenHub_SRNG.json"))
            for k, v in pairs(d) do
                if S[k] ~= nil then S[k] = v end
            end
            Notify("VaenHub", "Settings loaded!")
        end)
    end)

    Btn(sf, "🗑️", "Reset Settings", "Kembalikan ke default", C.Red, 11, function()
        S.RollDelay = 0.8
        S.WalkSpd   = 16
        S.JumpPow   = 50
        S.Webhook   = ""
        Notify("VaenHub", "Settings direset!")
    end)

    -- Stat Tracker (manual grid, no UIGridLayout)
    Sec(sf, "Stat Tracker", 12)

    local statFrame = Instance.new("Frame")
    statFrame.Size             = UDim2.new(1, 0, 0, 155)
    statFrame.BackgroundTransparency = 1
    statFrame.LayoutOrder      = 13
    statFrame.Parent           = sf

    StatCard(statFrame, "🎲", "TOTAL ROLLS", "Rolls",    5,   5)
    StatCard(statFrame, "⭐", "RARE COUNT",  "Rares",  128,   5)
    StatCard(statFrame, "🐾", "BEST PET",   "BestPet",  5,  80)
    StatCard(statFrame, "⏱️", "SESSION",    "SessTime",128,  80)
end

-- ╔══════════════════════════════════════╗
-- ║  PAGE: MISC                          ║
-- ╚══════════════════════════════════════╝
do
    local sf = MakeScroll(TabData["Misc"].page)

    Sec(sf, "Movement", 1)
    Tog(sf, "✈️", "Fly Mode",    "Tekan F untuk toggle · WASD/Space/Ctrl", "FlyOn",  2, function(on)
        if on then StartFly() else StopFly() end
    end)
    Tog(sf, "👻", "No Clip",     "Menembus semua objek solid",             "NoClip", 3)

    Sec(sf, "ESP Visuals", 4)
    Tog(sf, "👥", "ESP Players", "Tampilkan pemain lewat tembok",          "ESPPlayers", 5, function(on)
        if not on then ClearESP("Players") end
    end)
    Tog(sf, "👾", "ESP Mobs",    "Highlight semua enemy mob",              "ESPMobs",    6, function(on)
        if not on then ClearESP("Mobs") end
    end)
    Tog(sf, "📦", "ESP Drops",   "Highlight drops (rare=oranye)",          "ESPDrops",   7, function(on)
        if not on then ClearESP("Drops") end
    end)
    Tog(sf, "🎁", "ESP Chests",  "Tampilkan lokasi semua chest",           "ESPChests",  8, function(on)
        if not on then ClearESP("Chests") end
    end)

    Sec(sf, "Utility", 9)
    Tog(sf, "💤", "Anti AFK",         "Cegah kick otomatis",             "AntiAFK",  10)
    Tog(sf, "⚡", "Performance Mode", "Matikan shadow untuk FPS lebih",  "PerfMode", 11, function(on)
        pcall(function()
            Lighting.GlobalShadows = not on
            Lighting.FogEnd        = on and 1e7 or 2000
        end)
    end)

    Btn(sf, "🧹", "Clear All ESP",  "Hapus semua overlay ESP",         C.Red,    12, function()
        S.ESPPlayers = false
        S.ESPMobs    = false
        S.ESPDrops   = false
        S.ESPChests  = false
        ClearESP("Players")
        ClearESP("Mobs")
        ClearESP("Drops")
        ClearESP("Chests")
        for _, k in ipairs({"ESPPlayers","ESPMobs","ESPDrops","ESPChests"}) do
            if ToggleSync[k] then ToggleSync[k](false) end
        end
        Notify("VaenHub", "Semua ESP dihapus!")
    end)

    Btn(sf, "🔄", "Rejoin Server", "Pindah ke server baru",            C.Yellow, 13, function()
        pcall(function()
            game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
        end)
    end)

    Btn(sf, "📋", "Copy Stats",    "Salin statistik ke clipboard",     C.Accent, 14, function()
        local txt = string.format(
            "[VaenHub] %s | Rolls:%d | Rares:%d | Best:%s",
            LP.Name, S.Rolls, S.Rares, S.BestPet
        )
        pcall(function() setclipboard(txt) end)
        Notify("VaenHub", "Stats disalin!")
    end)
end

print("[VaenHub] >> Pages OK")

-- ╔══════════════════════════════════════╗
-- ║  OPEN ANIMATION                      ║
-- ╚══════════════════════════════════════╝
Win.Size     = UDim2.new(0, WW, 0, 0)
Win.Position = UDim2.new(0.5, -WW/2, 0.5, 0)

Tw(Win, {
    Size     = UDim2.new(0, WW, 0, WH),
    Position = UDim2.new(0.5, -WW/2, 0.5, -WH/2),
}, 0.38, "Back", "Out")

-- ╔══════════════════════════════════════╗
-- ║  ACTIVATE FIRST TAB                  ║
-- ╚══════════════════════════════════════╝
task.delay(0.12, function()
    ActiveT = "Main"
    pcall(function()
        TabData["Main"].btn.BackgroundColor3       = C.Hover
        TabData["Main"].btn.TextColor3             = C.TextA
        TabData["Main"].bar.BackgroundTransparency = 0
        TabData["Main"].page.Visible               = true
    end)
end)

-- ╔══════════════════════════════════════╗
-- ║  STARTUP NOTIFICATION                ║
-- ╚══════════════════════════════════════╝
task.delay(0.8, function()
    Notify("✅ VaenHub", "Slime RNG · Delta Fixed · Siap digunakan!", 5)
end)

print("[VaenHub] >> ✅ SEMUA SISTEM AKTIF!")

--[[
╔══════════════════════════════════════════════════════════════╗
║              VAENHUB SLIME RNG — LOADED                      ║
║  Fixes applied:                                              ║
║  ✅ Syntax lengkap, tidak terpotong                          ║
║  ✅ Loop ringan (GetChildren bukan GetDescendants)           ║
║  ✅ Cache scan tiap 4 detik                                  ║
║  ✅ No Activated:Fire()                                      ║
║  ✅ Character respawn safe                                   ║
║  ✅ ESP memory leak fixed (auto-disconnect)                  ║
║  ✅ VIM dalam pcall                                          ║
║  ✅ Parent ke PlayerGui (paling aman)                        ║
║  ✅ No AutomaticCanvasSize                                   ║
║  ✅ UICorner dibuat manual, tidak pakai arg ke-2             ║
╚══════════════════════════════════════════════════════════════╝
]]
