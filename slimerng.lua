--[[
╔══════════════════════════════════════════════════════════════╗
║              VAENHUB - SLIME RNG                             ║
║      DELTA EXECUTOR - FULLY FIXED & TESTED                   ║
║      Fix: PlayerGui parent, no AutomaticCanvasSize,          ║
║           manual UICorner, full pcall wrap, no gethui        ║
╚══════════════════════════════════════════════════════════════╝
]]

-- STEP 1: Konfirmasi script berjalan
print("[VaenHub] Script dimulai...")
warn("[VaenHub] Loading GUI...")

-- STEP 2: Wrap seluruh script dalam pcall agar error tidak silent
local SUCCESS, ERR = pcall(function()

-- ╔══════════════════════════════════════╗
-- ║         SERVICES                     ║
-- ╚══════════════════════════════════════╝
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui        = game:GetService("StarterGui")
local Lighting          = game:GetService("Lighting")

local LP        = Players.LocalPlayer
local PGui      = LP:WaitForChild("PlayerGui")
local Char      = LP.Character or LP.CharacterAdded:Wait()
local Hum       = Char:WaitForChild("Humanoid")
local HRP       = Char:WaitForChild("HumanoidRootPart")
local Cam       = workspace.CurrentCamera

print("[VaenHub] Services OK")

-- ╔══════════════════════════════════════╗
-- ║         SAFE INSTANCE CREATOR        ║
-- ║  Tidak pakai arg ke-2 di Instance.new║
-- ╚══════════════════════════════════════╝
local function New(class, props, parent)
    local ok, obj = pcall(function()
        local o = Instance.new(class)
        if props then
            for k, v in pairs(props) do
                pcall(function() o[k] = v end)
            end
        end
        if parent then
            pcall(function() o.Parent = parent end)
        end
        return o
    end)
    if ok then return obj end
    warn("[VaenHub] Instance.new("..class..") gagal")
    return nil
end

local function Corner(parent, radius)
    local c = New("UICorner", {CornerRadius = UDim.new(0, radius or 8)})
    if c and parent then pcall(function() c.Parent = parent end) end
    return c
end

local function Pad(parent, t, b, l, r)
    local p = New("UIPadding", {
        PaddingTop    = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft   = UDim.new(0, l or 0),
        PaddingRight  = UDim.new(0, r or 0),
    })
    if p and parent then pcall(function() p.Parent = parent end) end
    return p
end

print("[VaenHub] Helpers OK")

-- ╔══════════════════════════════════════╗
-- ║         THEME                        ║
-- ╚══════════════════════════════════════╝
local C = {
    Bg         = Color3.fromRGB(11,  13,  17),
    Surface    = Color3.fromRGB(17,  20,  26),
    Hover      = Color3.fromRGB(24,  28,  38),
    Card       = Color3.fromRGB(21,  25,  33),
    Border     = Color3.fromRGB(36,  42,  56),
    Accent     = Color3.fromRGB(0,  168, 255),
    AccentD    = Color3.fromRGB(0,  110, 195),
    AccentG    = Color3.fromRGB(0,  205, 255),
    TextA      = Color3.fromRGB(232, 240, 255),
    TextB      = Color3.fromRGB(135, 152, 175),
    TextC      = Color3.fromRGB(70,  85, 108),
    Green      = Color3.fromRGB(0,  200, 120),
    Yellow     = Color3.fromRGB(255, 175,   0),
    Red        = Color3.fromRGB(255,  60,  70),
    PillOff    = Color3.fromRGB(40,  46,  62),
    Sep        = Color3.fromRGB(26,  31,  42),
}

-- ╔══════════════════════════════════════╗
-- ║         STATE                        ║
-- ╚══════════════════════════════════════╝
local S = {
    -- toggles
    AutoFarm=false, AutoRoll=false, AutoEquipPet=false,
    AutoSell=false, AutoMerge=false, AutoBuyUpg=false,
    AutoRebirth=false, AutoClaimIdx=false, AutoClaimDaily=false,
    AutoLuckPot=false, AutoSpeedPot=false, AutoRarePot=false, AutoAllPot=false,
    AutoCraftBest=false, AutoCraftWep=false, AutoCraftArmor=false,
    ESPPlayers=false, ESPMobs=false, ESPDrops=false, ESPChests=false,
    FlyOn=false, NoClip=false, AntiAFK=false, PerfMode=false,
    -- values
    RollDelay=0.5, WalkSpd=16, JumpPow=50, Webhook="",
    -- stats
    Rolls=0, BestPet="None", Rares=0, SessTime=0,
}

-- ╔══════════════════════════════════════╗
-- ║         UTILITY                      ║
-- ╚══════════════════════════════════════╝
local function Safe(fn, ...)
    local a = {...}
    pcall(function() fn(table.unpack(a)) end)
end

local function Tw(obj, props, dur, style, dir)
    if not obj then return end
    pcall(function()
        TweenService:Create(obj,
            TweenInfo.new(dur or 0.2,
                Enum.EasingStyle[style or "Quad"],
                Enum.EasingDirection[dir or "Out"]),
            props):Play()
    end)
end

local function FireR(name, ...)
    pcall(function()
        local r = ReplicatedStorage:FindFirstChild(name, true)
        if r and r:IsA("RemoteEvent") then r:FireServer(...) end
    end)
end

local function Notify(title, msg, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification",
            {Title=title, Text=msg, Duration=dur or 3})
    end)
end

local function Round(n, d)
    local m = 10^(d or 0)
    return math.floor(n * m + 0.5) / m
end

local function FmtTime(s)
    return string.format("%02d:%02d:%02d",
        math.floor(s/3600), math.floor(s%3600/60), s%60)
end

print("[VaenHub] Utils OK")

-- ╔══════════════════════════════════════╗
-- ║         GAME LOOPS                   ║
-- ╚══════════════════════════════════════╝

-- Session timer
task.spawn(function()
    while true do
        task.wait(1)
        S.SessTime = S.SessTime + 1
    end
end)

-- Auto Roll
task.spawn(function()
    while true do
        local delay = (S.RollDelay and S.RollDelay > 0) and S.RollDelay or 0.5
        task.wait(delay)
        if S.AutoRoll then
            Safe(function()
                FireR("Roll") FireR("RollPet")
                FireR("SpinSlime") FireR("GachaRoll")
                for _, g in pairs(LP.PlayerGui:GetDescendants()) do
                    if g:IsA("GuiButton") then
                        local n = g.Name:lower()
                        if n:find("roll") or n:find("spin") then
                            pcall(function() g.Activated:Fire() end)
                        end
                    end
                end
                S.Rolls = S.Rolls + 1
            end)
        end
    end
end)

-- Auto Farm
task.spawn(function()
    while true do
        task.wait(0.15)
        if S.AutoFarm then
            Safe(function()
                local best, bd = nil, math.huge
                for _, m in pairs(workspace:GetDescendants()) do
                    if m:IsA("Model") and m ~= Char then
                        local mh = m:FindFirstChildOfClass("Humanoid")
                        local mr = m:FindFirstChild("HumanoidRootPart")
                        if mh and mh.Health > 0 and mr then
                            local d = (HRP.Position - mr.Position).Magnitude
                            if d < bd then bd=d best=mr end
                        end
                    end
                end
                if best then
                    HRP.CFrame = best.CFrame * CFrame.new(0,0,-3.5)
                    FireR("Attack") FireR("DamageEnemy") FireR("HitMob")
                end
                for _, o in pairs(workspace:GetDescendants()) do
                    if o:IsA("BasePart") then
                        local n = o.Name:lower()
                        if (n:find("drop") or n:find("pickup") or n:find("collect"))
                            and (HRP.Position - o.Position).Magnitude < 40 then
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
        task.wait(3)
        if S.AutoSell then
            FireR("SellAll") FireR("AutoSell") FireR("SellItems")
        end
        if S.AutoMerge then
            FireR("MergeAll") FireR("AutoMerge") FireR("MergePets")
        end
        if S.AutoEquipPet then
            FireR("EquipBestPet") FireR("AutoEquip")
        end
    end
end)

-- Progression
task.spawn(function()
    while true do
        task.wait(2)
        if S.AutoBuyUpg   then FireR("BuyUpgrade") FireR("BuyAllUpgrades") end
        if S.AutoRebirth  then FireR("Rebirth") FireR("DoRebirth") end
        if S.AutoClaimIdx then FireR("ClaimIndexReward") FireR("ClaimAllIndex") end
    end
end)

-- Daily
task.spawn(function()
    while true do
        task.wait(60)
        if S.AutoClaimDaily then
            FireR("ClaimDaily") FireR("DailyReward")
        end
    end
end)

-- Potions
task.spawn(function()
    while true do
        task.wait(25)
        if S.AutoLuckPot  then FireR("UseLuckPotion")  FireR("ActivateLuck")  end
        if S.AutoSpeedPot then FireR("UseSpeedPotion") FireR("ActivateSpeed") end
        if S.AutoRarePot  then FireR("UseRarePotion")  FireR("ActivateRare")  end
        if S.AutoAllPot   then FireR("UseAllPotions")  FireR("ActivateAllBuffs") end
    end
end)

-- Crafting
task.spawn(function()
    while true do
        task.wait(2)
        if S.AutoCraftBest  then FireR("CraftBestItem")  end
        if S.AutoCraftWep   then FireR("CraftWeapon")    end
        if S.AutoCraftArmor then FireR("CraftArmor")     end
    end
end)

-- Speed enforcer
task.spawn(function()
    while true do
        task.wait(0.5)
        local h = Char:FindFirstChildOfClass("Humanoid")
        if h then
            h.WalkSpeed = S.WalkSpd
            h.JumpPower = S.JumpPow
        end
    end
end)

-- NoClip
RunService.Stepped:Connect(function()
    if S.NoClip then
        for _, p in pairs(Char:GetDescendants()) do
            if p:IsA("BasePart") then
                pcall(function() p.CanCollide = false end)
            end
        end
    end
end)

-- Anti AFK
task.spawn(function()
    while true do
        task.wait(55)
        if S.AntiAFK then
            pcall(function()
                local VIM = game:GetService("VirtualInputManager")
                VIM:SendKeyEvent(true,  Enum.KeyCode.F13, false, game)
                VIM:SendKeyEvent(false, Enum.KeyCode.F13, false, game)
            end)
        end
    end
end)

print("[VaenHub] Loops spawned OK")

-- ╔══════════════════════════════════════╗
-- ║         FLY                          ║
-- ╚══════════════════════════════════════╝
local FlyBV, FlyBG, FlyConn

local function StartFly()
    pcall(function()
        if FlyBV then FlyBV:Destroy() end
        if FlyBG then FlyBG:Destroy() end
        FlyBV = Instance.new("BodyVelocity")
        FlyBV.Velocity  = Vector3.zero
        FlyBV.MaxForce  = Vector3.new(1e9,1e9,1e9)
        FlyBV.Parent    = HRP
        FlyBG = Instance.new("BodyGyro")
        FlyBG.MaxTorque = Vector3.new(1e9,1e9,1e9)
        FlyBG.D         = 500
        FlyBG.Parent    = HRP
        if FlyConn then FlyConn:Disconnect() end
        FlyConn = RunService.Heartbeat:Connect(function()
            if not S.FlyOn then return end
            local spd = S.WalkSpd * 2
            local d   = Vector3.zero
            local UIS = UserInputService
            if UIS:IsKeyDown(Enum.KeyCode.W)           then d=d+Cam.CFrame.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.S)           then d=d-Cam.CFrame.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.A)           then d=d-Cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D)           then d=d+Cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space)       then d=d+Vector3.yAxis          end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then d=d-Vector3.yAxis          end
            FlyBV.Velocity = d.Magnitude>0 and d.Unit*spd or Vector3.zero
            FlyBG.CFrame   = Cam.CFrame
        end)
    end)
end

local function StopFly()
    pcall(function()
        if FlyConn then FlyConn:Disconnect() FlyConn=nil end
        if FlyBV   then FlyBV:Destroy() FlyBV=nil end
        if FlyBG   then FlyBG:Destroy() FlyBG=nil end
    end)
end

UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.F then
        S.FlyOn = not S.FlyOn
        if S.FlyOn then StartFly() else StopFly() end
    end
end)

print("[VaenHub] Fly OK")

-- ╔══════════════════════════════════════╗
-- ║         ESP                          ║
-- ╚══════════════════════════════════════╝
local ESPBin = {Players={},Mobs={},Drops={},Chests={}}

local function MakeESP(adornee, color, lbl)
    local ok, bb = pcall(function()
        local b = Instance.new("BillboardGui")
        b.Name        = "VH_ESP"
        b.AlwaysOnTop = true
        b.Size        = UDim2.new(0,105,0,38)
        b.StudsOffset = Vector3.new(0,3.2,0)
        b.Adornee     = adornee

        local bg = Instance.new("Frame")
        bg.Size                   = UDim2.fromScale(1,1)
        bg.BackgroundColor3       = Color3.fromRGB(0,0,0)
        bg.BackgroundTransparency = 0.55
        bg.BorderSizePixel        = 0
        bg.Parent                 = b
        Corner(bg, 4)

        local nl = Instance.new("TextLabel")
        nl.Size               = UDim2.new(1,0,0.58,0)
        nl.BackgroundTransparency = 1
        nl.Text               = lbl or adornee.Name
        nl.TextColor3         = color
        nl.TextSize           = 11
        nl.Font               = Enum.Font.GothamBold
        nl.TextXAlignment     = Enum.TextXAlignment.Center
        nl.Parent             = bg

        local dl = Instance.new("TextLabel")
        dl.Name               = "D"
        dl.Size               = UDim2.new(1,0,0.42,0)
        dl.Position           = UDim2.fromScale(0,0.58)
        dl.BackgroundTransparency = 1
        dl.TextColor3         = C.TextB
        dl.TextSize           = 9
        dl.Font               = Enum.Font.Gotham
        dl.TextXAlignment     = Enum.TextXAlignment.Center
        dl.Parent             = bg

        b.Parent = PGui

        RunService.Heartbeat:Connect(function()
            if not b or not b.Parent then return end
            if not adornee or not adornee.Parent then
                pcall(function() b:Destroy() end)
                return
            end
            local dist = (HRP.Position - adornee.Position).Magnitude
            dl.Text = Round(dist,1).." studs"
        end)
        return b
    end)
    if ok and bb then return bb end
end

local function ClearESP(cat)
    for _, v in pairs(ESPBin[cat] or {}) do
        pcall(function() if v and v.Parent then v:Destroy() end end)
    end
    ESPBin[cat] = {}
end

-- ESP scan loop
task.spawn(function()
    while true do
        task.wait(2.5)

        if S.ESPPlayers then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LP and plr.Character then
                    local root = plr.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local found = false
                        for _, e in pairs(ESPBin.Players) do
                            if e and e.Adornee == root then found=true break end
                        end
                        if not found then
                            local bb = MakeESP(root, C.AccentG, plr.Name)
                            if bb then table.insert(ESPBin.Players, bb) end
                        end
                    end
                end
            end
        end

        if S.ESPMobs then
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj ~= Char and obj:FindFirstChildOfClass("Humanoid") then
                    local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                    if root then
                        local found = false
                        for _, e in pairs(ESPBin.Mobs) do
                            if e and e.Adornee == root then found=true break end
                        end
                        if not found then
                            local bb = MakeESP(root, C.Yellow, "MOB:"..obj.Name)
                            if bb then table.insert(ESPBin.Mobs, bb) end
                        end
                    end
                end
            end
        end

        if S.ESPDrops then
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local n = obj.Name:lower()
                    if n:find("drop") or n:find("item") then
                        local found = false
                        for _, e in pairs(ESPBin.Drops) do
                            if e and e.Adornee == obj then found=true break end
                        end
                        if not found then
                            local rare = n:find("rare") or n:find("epic") or n:find("leg")
                            local bb = MakeESP(obj, rare and C.Yellow or C.Green, "DROP:"..obj.Name)
                            if bb then table.insert(ESPBin.Drops, bb) end
                        end
                    end
                end
            end
        end

        if S.ESPChests then
            for _, obj in pairs(workspace:GetDescendants()) do
                local n = obj.Name:lower()
                if n:find("chest") or n:find("lucky") then
                    local part = obj:IsA("BasePart") and obj
                        or (obj:IsA("Model") and obj.PrimaryPart)
                    if part then
                        local found = false
                        for _, e in pairs(ESPBin.Chests) do
                            if e and e.Adornee == part then found=true break end
                        end
                        if not found then
                            local lucky = n:find("lucky")
                            local bb = MakeESP(part, lucky and C.Yellow or C.Accent, "CHEST:"..obj.Name)
                            if bb then table.insert(ESPBin.Chests, bb) end
                        end
                    end
                end
            end
        end
    end
end)

print("[VaenHub] ESP OK")

-- ╔══════════════════════════════════════╗
-- ║    REMOVE OLD GUI & BUILD NEW        ║
-- ╚══════════════════════════════════════╝
pcall(function()
    local old = PGui:FindFirstChild("VaenHub")
    if old then old:Destroy() end
end)

-- ScreenGui — parent ke PlayerGui (PALING AMAN di semua executor)
local SG = Instance.new("ScreenGui")
SG.Name           = "VaenHub"
SG.ResetOnSpawn   = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.DisplayOrder   = 100
-- JANGAN set IgnoreGuiInset = true, bisa error di Delta
SG.Parent         = PGui

print("[VaenHub] ScreenGui created, parent="..tostring(SG.Parent))

-- ╔══════════════════════════════════════╗
-- ║    WINDOW SIZES                      ║
-- ╚══════════════════════════════════════╝
local WW, WH = 555, 570

-- ╔══════════════════════════════════════╗
-- ║    MAIN WINDOW                       ║
-- ╚══════════════════════════════════════╝
local Win = New("Frame", {
    Name             = "Win",
    Size             = UDim2.new(0,WW,0,WH),
    Position         = UDim2.new(0.5,-WW/2,0.5,-WH/2),
    BackgroundColor3 = C.Bg,
    BorderSizePixel  = 0,
    ClipsDescendants = true,
}, SG)
Corner(Win, 12)

-- Outer glow border
local OBor = New("Frame", {
    Name             = "OBor",
    Size             = UDim2.new(1,4,1,4),
    Position         = UDim2.new(0,-2,0,-2),
    BackgroundColor3 = C.Accent,
    BackgroundTransparency = 0.6,
    BorderSizePixel  = 0,
    ZIndex           = 0,
}, Win)
Corner(OBor, 14)

-- Glow pulse
task.spawn(function()
    while Win and Win.Parent do
        Tw(OBor,{BackgroundTransparency=0.4},0.9,"Sine","InOut")
        task.wait(0.9)
        Tw(OBor,{BackgroundTransparency=0.72},0.9,"Sine","InOut")
        task.wait(0.9)
    end
end)

print("[VaenHub] Window frame OK")

-- ╔══════════════════════════════════════╗
-- ║    TITLE BAR                         ║
-- ╚══════════════════════════════════════╝
local TB = New("Frame", {
    Name             = "TitleBar",
    Size             = UDim2.new(1,0,0,50),
    BackgroundColor3 = C.Surface,
    BorderSizePixel  = 0,
    ZIndex           = 5,
}, Win)
Corner(TB, 12)

-- Fix bottom corners of titlebar
New("Frame", {
    Size             = UDim2.new(1,0,0.5,0),
    Position         = UDim2.new(0,0,0.5,0),
    BackgroundColor3 = C.Surface,
    BorderSizePixel  = 0,
    ZIndex           = 5,
}, TB)

-- Accent line
local AL = New("Frame", {
    Size             = UDim2.new(1,0,0,2),
    Position         = UDim2.new(0,0,1,-2),
    BackgroundColor3 = C.Accent,
    BorderSizePixel  = 0,
    ZIndex           = 6,
}, TB)

local ALG = New("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,80,180)),
        ColorSequenceKeypoint.new(0.5, C.AccentG),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,80,180)),
    })
})
if ALG then pcall(function() ALG.Parent = AL end) end

-- Logo dot
local Dot = New("Frame", {
    Size             = UDim2.new(0,10,0,10),
    Position         = UDim2.new(0,16,0.5,-5),
    BackgroundColor3 = C.Accent,
    BorderSizePixel  = 0,
    ZIndex           = 6,
}, TB)
Corner(Dot, 999)

task.spawn(function()
    while Win and Win.Parent do
        Tw(Dot,{BackgroundColor3=C.AccentG},0.8,"Sine","InOut") task.wait(0.8)
        Tw(Dot,{BackgroundColor3=C.AccentD},0.8,"Sine","InOut") task.wait(0.8)
    end
end)

-- Title
New("TextLabel", {
    Size               = UDim2.new(1,-110,0,26),
    Position           = UDim2.new(0,34,0,5),
    BackgroundTransparency = 1,
    Text               = "Slime RNG  ·  VaenHub",
    TextColor3         = C.TextA,
    TextSize           = 15,
    Font               = Enum.Font.GothamBold,
    TextXAlignment     = Enum.TextXAlignment.Left,
    ZIndex             = 6,
}, TB)

New("TextLabel", {
    Size               = UDim2.new(1,-110,0,14),
    Position           = UDim2.new(0,34,0,30),
    BackgroundTransparency = 1,
    Text               = "Premium Script  ·  Delta Compatible  ·  S+ Quality",
    TextColor3         = C.Accent,
    TextSize           = 9,
    Font               = Enum.Font.Gotham,
    TextXAlignment     = Enum.TextXAlignment.Left,
    ZIndex             = 6,
}, TB)

-- Close button
local CloseBtn = New("TextButton", {
    Size             = UDim2.new(0,28,0,28),
    Position         = UDim2.new(1,-38,0.5,-14),
    BackgroundColor3 = Color3.fromRGB(255,55,65),
    BorderSizePixel  = 0,
    Text             = "✕",
    TextColor3       = Color3.fromRGB(255,255,255),
    TextSize         = 13,
    Font             = Enum.Font.GothamBold,
    ZIndex           = 7,
}, TB)
Corner(CloseBtn, 7)

CloseBtn.MouseEnter:Connect(function()
    Tw(CloseBtn,{BackgroundColor3=Color3.fromRGB(255,80,88)},0.12)
end)
CloseBtn.MouseLeave:Connect(function()
    Tw(CloseBtn,{BackgroundColor3=Color3.fromRGB(255,55,65)},0.12)
end)
CloseBtn.MouseButton1Click:Connect(function()
    Tw(Win,{Size=UDim2.new(0,WW,0,0),
        Position=UDim2.new(0.5,-WW/2,0.5,0)},0.25,"Back","In")
    task.delay(0.28, function() pcall(function() SG:Destroy() end) end)
end)

-- Minimize button
local MinBtn = New("TextButton", {
    Size             = UDim2.new(0,28,0,28),
    Position         = UDim2.new(1,-72,0.5,-14),
    BackgroundColor3 = Color3.fromRGB(255,168,0),
    BorderSizePixel  = 0,
    Text             = "–",
    TextColor3       = Color3.fromRGB(255,255,255),
    TextSize         = 16,
    Font             = Enum.Font.GothamBold,
    ZIndex           = 7,
}, TB)
Corner(MinBtn, 7)

local minimd = false
MinBtn.MouseButton1Click:Connect(function()
    minimd = not minimd
    Tw(Win,{Size=minimd and UDim2.new(0,WW,0,50) or UDim2.new(0,WW,0,WH)},0.25,"Quad","Out")
end)

print("[VaenHub] TitleBar OK")

-- ╔══════════════════════════════════════╗
-- ║    DRAG                              ║
-- ╚══════════════════════════════════════╝
local drg, drgS, winS = false, nil, nil
TB.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        drg=true drgS=inp.Position winS=Win.Position
    end
end)
TB.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then drg=false end
end)
UserInputService.InputChanged:Connect(function(inp)
    if drg and inp.UserInputType == Enum.UserInputType.MouseMovement and winS then
        local d = inp.Position - drgS
        Win.Position = UDim2.new(winS.X.Scale, winS.X.Offset+d.X,
                                  winS.Y.Scale, winS.Y.Offset+d.Y)
    end
end)

-- ╔══════════════════════════════════════╗
-- ║    TAB BAR                           ║
-- ╚══════════════════════════════════════╝
local TAB_H    = 42
local TAB_TOP  = 50

local TBg = New("Frame", {
    Size             = UDim2.new(1,0,0,TAB_H),
    Position         = UDim2.new(0,0,0,TAB_TOP),
    BackgroundColor3 = C.Surface,
    BorderSizePixel  = 0,
    ZIndex           = 4,
}, Win)

-- Separator line
New("Frame", {
    Size             = UDim2.new(1,0,0,1),
    Position         = UDim2.new(0,0,1,-1),
    BackgroundColor3 = C.Sep,
    BorderSizePixel  = 0,
    ZIndex           = 5,
}, TBg)

-- Content area
local ContentY = TAB_TOP + TAB_H
local CA = New("Frame", {
    Size             = UDim2.new(1,0,1,-ContentY),
    Position         = UDim2.new(0,0,0,ContentY),
    BackgroundTransparency = 1,
    BorderSizePixel  = 0,
    ClipsDescendants = true,
}, Win)

-- ╔══════════════════════════════════════╗
-- ║    TAB SYSTEM                        ║
-- ╚══════════════════════════════════════╝
local TABS    = {"Main","Potions","Crafting","Config","Misc"}
local TABICON = {Main="⚔️",Potions="🧪",Crafting="🔨",Config="⚙️",Misc="🎮"}
local TabData = {}
local ActiveT = nil

local TBTN_W = math.floor((WW - 20) / #TABS)

for i, id in ipairs(TABS) do
    local xOff = 10 + (i-1)*(TBTN_W+2)

    local btn = New("TextButton", {
        Size             = UDim2.new(0, TBTN_W, 0, 32),
        Position         = UDim2.new(0, xOff, 0.5, -16),
        BackgroundColor3 = C.Surface,
        BorderSizePixel  = 0,
        Text             = TABICON[id].."  "..id,
        TextColor3       = C.TextC,
        TextSize         = 11,
        Font             = Enum.Font.GothamSemibold,
        ZIndex           = 5,
    }, TBg)
    Corner(btn, 7)

    local bar = New("Frame", {
        Size             = UDim2.new(0.7,0,0,2),
        Position         = UDim2.new(0.15,0,1,-2),
        BackgroundColor3 = C.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ZIndex           = 6,
    }, btn)
    Corner(bar, 99)

    local page = New("Frame", {
        Name             = "Page_"..id,
        Size             = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        Visible          = false,
    }, CA)

    TabData[id] = {btn=btn, bar=bar, page=page}

    btn.MouseButton1Click:Connect(function()
        if ActiveT == id then return end
        if ActiveT and TabData[ActiveT] then
            local p = TabData[ActiveT]
            Tw(p.btn,{BackgroundColor3=C.Surface,TextColor3=C.TextC},0.15)
            Tw(p.bar,{BackgroundTransparency=1},0.15)
            p.page.Visible = false
        end
        ActiveT = id
        Tw(btn,{BackgroundColor3=C.Hover,TextColor3=C.TextA},0.15)
        Tw(bar,{BackgroundTransparency=0},0.15)
        page.Visible = true
    end)
end

print("[VaenHub] Tabs OK")

-- ╔══════════════════════════════════════╗
-- ║    SCROLL FRAME BUILDER              ║
-- ║    TANPA AutomaticCanvasSize !       ║
-- ╚══════════════════════════════════════╝
local function MakeScroll(parent)
    local sf = New("ScrollingFrame", {
        Size                  = UDim2.fromScale(1,1),
        BackgroundTransparency= 1,
        BorderSizePixel       = 0,
        ScrollBarThickness    = 3,
        ScrollBarImageColor3  = C.Accent,
        ScrollBarImageTransparency = 0.4,
        -- Canvas size statis, cukup besar
        CanvasSize            = UDim2.new(0,0,0,2000),
        ScrollingDirection    = Enum.ScrollingDirection.Y,
    }, parent)

    local ul = New("UIListLayout", {
        Padding              = UDim.new(0,6),
        HorizontalAlignment  = Enum.HorizontalAlignment.Center,
        SortOrder            = Enum.SortOrder.LayoutOrder,
    })
    if ul then pcall(function() ul.Parent = sf end) end

    Pad(sf, 10, 12, 12, 12)

    -- Auto-resize canvas berdasarkan content
    if ul then
        ul:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            pcall(function()
                sf.CanvasSize = UDim2.new(0,0,0, ul.AbsoluteContentSize.Y + 24)
            end)
        end)
    end

    return sf
end

-- ╔══════════════════════════════════════╗
-- ║    COMPONENT BUILDERS                ║
-- ╚══════════════════════════════════════╝

-- Section label
local function Sec(parent, text, order)
    local f = New("Frame", {
        Size             = UDim2.new(1,0,0,22),
        BackgroundTransparency = 1,
        LayoutOrder      = order or 0,
    }, parent)

    New("Frame", {
        Size             = UDim2.new(0.28,0,0,1),
        Position         = UDim2.new(0,0,0.5,0),
        BackgroundColor3 = C.Sep,
        BorderSizePixel  = 0,
    }, f)

    New("TextLabel", {
        Size             = UDim2.new(0.44,0,1,0),
        Position         = UDim2.new(0.28,0,0,0),
        BackgroundTransparency = 1,
        Text             = "  "..text:upper().."  ",
        TextColor3       = C.TextC,
        TextSize         = 9,
        Font             = Enum.Font.GothamBold,
        TextXAlignment   = Enum.TextXAlignment.Center,
    }, f)

    New("Frame", {
        Size             = UDim2.new(0.28,0,0,1),
        Position         = UDim2.new(0.72,0,0.5,0),
        BackgroundColor3 = C.Sep,
        BorderSizePixel  = 0,
    }, f)

    return f
end

-- Toggle row — returns frame + sync function
local ToggleSync = {}

local function Tog(parent, icon, title, sub, key, order, cb)
    local row = New("Frame", {
        Size             = UDim2.new(1,0,0,54),
        BackgroundColor3 = C.Card,
        BorderSizePixel  = 0,
        LayoutOrder      = order or 99,
    }, parent)
    Corner(row, 10)

    New("TextLabel", {
        Size             = UDim2.new(0,34,1,0),
        Position         = UDim2.new(0,10,0,0),
        BackgroundTransparency = 1,
        Text             = icon,
        TextSize         = 17,
        TextXAlignment   = Enum.TextXAlignment.Center,
        ZIndex           = 2,
    }, row)

    New("TextLabel", {
        Size             = UDim2.new(1,-108,0,22),
        Position         = UDim2.new(0,48,0,7),
        BackgroundTransparency = 1,
        Text             = title,
        TextColor3       = C.TextA,
        TextSize         = 13,
        Font             = Enum.Font.GothamSemibold,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 2,
    }, row)

    New("TextLabel", {
        Size             = UDim2.new(1,-108,0,16),
        Position         = UDim2.new(0,48,0,30),
        BackgroundTransparency = 1,
        Text             = sub or "",
        TextColor3       = C.TextC,
        TextSize         = 10,
        Font             = Enum.Font.Gotham,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 2,
    }, row)

    local on = S[key]

    local pill = New("Frame", {
        Size             = UDim2.new(0,40,0,21),
        Position         = UDim2.new(1,-52,0.5,-10),
        BackgroundColor3 = on and C.Accent or C.PillOff,
        BorderSizePixel  = 0,
        ZIndex           = 2,
    }, row)
    Corner(pill, 99)

    local knob = New("Frame", {
        Size             = UDim2.new(0,15,0,15),
        Position         = on and UDim2.new(1,-18,0.5,-7) or UDim2.new(0,3,0.5,-7),
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        BorderSizePixel  = 0,
        ZIndex           = 3,
    }, pill)
    Corner(knob, 99)

    local function Sync(state)
        pcall(function()
            Tw(pill,  {BackgroundColor3 = state and C.Accent or C.PillOff}, 0.18)
            Tw(knob,  {Position = state
                and UDim2.new(1,-18,0.5,-7)
                or  UDim2.new(0,3, 0.5,-7)}, 0.18)
        end)
    end

    ToggleSync[key] = Sync

    local btn = New("TextButton", {
        Size             = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        Text             = "",
        ZIndex           = 4,
    }, row)

    btn.MouseEnter:Connect(function()
        Tw(row,{BackgroundColor3=C.Hover},0.12)
    end)
    btn.MouseLeave:Connect(function()
        Tw(row,{BackgroundColor3=C.Card},0.12)
    end)
    btn.MouseButton1Click:Connect(function()
        S[key] = not S[key]
        Sync(S[key])
        if cb then Safe(cb, S[key]) end
    end)

    return row
end

-- Button row
local function Btn(parent, icon, title, sub, accent, order, cb)
    local h = sub and 54 or 44
    local row = New("Frame", {
        Size             = UDim2.new(1,0,0,h),
        BackgroundColor3 = C.Card,
        BorderSizePixel  = 0,
        LayoutOrder      = order or 99,
    }, parent)
    Corner(row, 10)

    New("TextLabel", {
        Size             = UDim2.new(0,34,1,0),
        Position         = UDim2.new(0,10,0,0),
        BackgroundTransparency = 1,
        Text             = icon,
        TextSize         = 17,
        TextXAlignment   = Enum.TextXAlignment.Center,
        ZIndex           = 2,
    }, row)

    local tl = New("TextLabel", {
        Size             = UDim2.new(1,-68, sub and 0 or 1, 0),
        Position         = sub and UDim2.new(0,48,0,7) or UDim2.new(0,48,0,0),
        BackgroundTransparency = 1,
        Text             = title,
        TextColor3       = accent or C.TextA,
        TextSize         = 13,
        Font             = Enum.Font.GothamSemibold,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 2,
    }, row)
    if not sub then
        pcall(function() tl.TextYAlignment = Enum.TextYAlignment.Center end)
    end

    if sub then
        New("TextLabel", {
            Size             = UDim2.new(1,-68,0,16),
            Position         = UDim2.new(0,48,0,30),
            BackgroundTransparency = 1,
            Text             = sub,
            TextColor3       = C.TextC,
            TextSize         = 10,
            Font             = Enum.Font.Gotham,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 2,
        }, row)
    end

    New("TextLabel", {
        Size             = UDim2.new(0,20,1,0),
        Position         = UDim2.new(1,-28,0,0),
        BackgroundTransparency = 1,
        Text             = "›",
        TextColor3       = accent or C.TextC,
        TextSize         = 20,
        Font             = Enum.Font.GothamBold,
        ZIndex           = 2,
    }, row)

    local btn = New("TextButton", {
        Size             = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        Text             = "",
        ZIndex           = 3,
    }, row)

    btn.MouseEnter:Connect(function()
        Tw(row,{BackgroundColor3=C.Hover},0.12)
    end)
    btn.MouseLeave:Connect(function()
        Tw(row,{BackgroundColor3=C.Card},0.12)
    end)
    btn.MouseButton1Click:Connect(function()
        if cb then Safe(cb) end
    end)
    return row
end

-- Slider row
local function Sldr(parent, icon, title, minV, maxV, default, key, order, cb)
    local row = New("Frame", {
        Size             = UDim2.new(1,0,0,66),
        BackgroundColor3 = C.Card,
        BorderSizePixel  = 0,
        LayoutOrder      = order or 99,
    }, parent)
    Corner(row, 10)

    New("TextLabel", {
        Size             = UDim2.new(0,34,0,28),
        Position         = UDim2.new(0,10,0,6),
        BackgroundTransparency = 1,
        Text             = icon,
        TextSize         = 17,
        TextXAlignment   = Enum.TextXAlignment.Center,
        ZIndex           = 2,
    }, row)

    New("TextLabel", {
        Size             = UDim2.new(1,-100,0,20),
        Position         = UDim2.new(0,48,0,6),
        BackgroundTransparency = 1,
        Text             = title,
        TextColor3       = C.TextA,
        TextSize         = 13,
        Font             = Enum.Font.GothamSemibold,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 2,
    }, row)

    local vl = New("TextLabel", {
        Size             = UDim2.new(0,52,0,20),
        Position         = UDim2.new(1,-58,0,6),
        BackgroundTransparency = 1,
        Text             = tostring(default),
        TextColor3       = C.Accent,
        TextSize         = 13,
        Font             = Enum.Font.GothamBold,
        TextXAlignment   = Enum.TextXAlignment.Right,
        ZIndex           = 2,
    }, row)

    local track = New("Frame", {
        Size             = UDim2.new(1,-24,0,5),
        Position         = UDim2.new(0,12,0,46),
        BackgroundColor3 = C.PillOff,
        BorderSizePixel  = 0,
        ZIndex           = 2,
    }, row)
    Corner(track, 99)

    local pct0 = math.clamp((default-minV)/(maxV-minV),0,1)

    local fill = New("Frame", {
        Size             = UDim2.new(pct0,0,1,0),
        BackgroundColor3 = C.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 3,
    }, track)
    Corner(fill, 99)

    local knob = New("Frame", {
        Size             = UDim2.new(0,13,0,13),
        Position         = UDim2.new(pct0,-6,0.5,-6),
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        BorderSizePixel  = 0,
        ZIndex           = 4,
    }, track)
    Corner(knob, 99)

    local drgS2 = false

    local function UpdSldr(inp)
        if not track then return end
        local ax = track.AbsolutePosition.X
        local aw = track.AbsoluteSize.X
        if aw == 0 then return end
        local p = math.clamp((inp.Position.X - ax) / aw, 0, 1)
        local v = Round(minV + (maxV-minV)*p, 2)
        pcall(function()
            fill.Size     = UDim2.new(p,0,1,0)
            knob.Position = UDim2.new(p,-6,0.5,-6)
            vl.Text       = tostring(v)
        end)
        if key then S[key] = v end
        if cb  then Safe(cb, v) end
    end

    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            drgS2=true UpdSldr(inp)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drgS2 and inp.UserInputType == Enum.UserInputType.MouseMovement then
            UpdSldr(inp)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then drgS2=false end
    end)

    return row
end

-- Text input
local function Inp(parent, icon, title, hint, key, order, cb)
    local row = New("Frame", {
        Size             = UDim2.new(1,0,0,66),
        BackgroundColor3 = C.Card,
        BorderSizePixel  = 0,
        LayoutOrder      = order or 99,
    }, parent)
    Corner(row, 10)

    New("TextLabel", {
        Size             = UDim2.new(0,34,0,28),
        Position         = UDim2.new(0,10,0,5),
        BackgroundTransparency = 1,
        Text             = icon,
        TextSize         = 17,
        TextXAlignment   = Enum.TextXAlignment.Center,
        ZIndex           = 2,
    }, row)

    New("TextLabel", {
        Size             = UDim2.new(1,-28,0,20),
        Position         = UDim2.new(0,48,0,5),
        BackgroundTransparency = 1,
        Text             = title,
        TextColor3       = C.TextA,
        TextSize         = 13,
        Font             = Enum.Font.GothamSemibold,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 2,
    }, row)

    local ibg = New("Frame", {
        Size             = UDim2.new(1,-24,0,24),
        Position         = UDim2.new(0,12,0,36),
        BackgroundColor3 = C.Bg,
        BorderSizePixel  = 0,
        ZIndex           = 2,
    }, row)
    Corner(ibg, 6)

    local tb = New("TextBox", {
        Size             = UDim2.new(1,-10,1,0),
        Position         = UDim2.new(0,6,0,0),
        BackgroundTransparency = 1,
        PlaceholderText  = hint or "",
        PlaceholderColor3= C.TextC,
        Text             = (key and tostring(S[key])) or "",
        TextColor3       = C.TextA,
        TextSize         = 11,
        Font             = Enum.Font.Gotham,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex           = 3,
    }, ibg)

    if tb then
        tb.FocusLost:Connect(function()
            if key then S[key] = tb.Text end
            if cb  then Safe(cb, tb.Text) end
        end)
    end

    return row, tb
end

-- Stat card (kecil, grid manual)
local function StatCard(parent, icon, lbl, stateKey, xPos, yPos)
    local card = New("Frame", {
        Size             = UDim2.new(0,120,0,72),
        Position         = UDim2.new(0,xPos,0,yPos),
        BackgroundColor3 = C.Card,
        BorderSizePixel  = 0,
    }, parent)
    Corner(card, 10)

    New("TextLabel", {
        Size             = UDim2.new(1,0,0,26),
        Position         = UDim2.new(0,0,0,5),
        BackgroundTransparency = 1,
        Text             = icon,
        TextSize         = 18,
        TextXAlignment   = Enum.TextXAlignment.Center,
        ZIndex           = 2,
    }, card)

    local vl = New("TextLabel", {
        Size             = UDim2.new(1,-4,0,18),
        Position         = UDim2.new(0,2,0,29),
        BackgroundTransparency = 1,
        TextColor3       = C.Accent,
        TextSize         = 12,
        Font             = Enum.Font.GothamBold,
        TextXAlignment   = Enum.TextXAlignment.Center,
        ZIndex           = 2,
    }, card)

    New("TextLabel", {
        Size             = UDim2.new(1,-4,0,14),
        Position         = UDim2.new(0,2,0,50),
        BackgroundTransparency = 1,
        Text             = lbl,
        TextColor3       = C.TextC,
        TextSize         = 9,
        Font             = Enum.Font.GothamBold,
        TextXAlignment   = Enum.TextXAlignment.Center,
        ZIndex           = 2,
    }, card)

    if vl then
        RunService.Heartbeat:Connect(function()
            if not vl or not vl.Parent then return end
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

    return card
end

print("[VaenHub] Component builders OK")

-- ╔══════════════════════════════════════╗
-- ║    BUILD PAGES                       ║
-- ╚══════════════════════════════════════╝

-- ── MAIN ──────────────────────────────
local pMain = MakeScroll(TabData["Main"].page)
Sec(pMain,"Auto Farm",1)
Tog(pMain,"⚔️","Auto Farm Everything","Farms mobs & collects drops","AutoFarm",2)
Tog(pMain,"🎲","Auto Roll","Auto rolls for slime pets","AutoRoll",3)
Tog(pMain,"🐾","Auto Equip Best Pet","Equips highest power pet","AutoEquipPet",4)
Sec(pMain,"Management",5)
Tog(pMain,"💰","Auto Sell","Sells items for coins","AutoSell",6)
Tog(pMain,"🔀","Auto Merge","Merges duplicate pets","AutoMerge",7)
Sec(pMain,"Progression",8)
Tog(pMain,"⬆️","Auto Buy Upgrades","Buys all upgrades","AutoBuyUpg",9)
Tog(pMain,"🔄","Auto Rebirth","Auto-rebirth when ready","AutoRebirth",10)
Tog(pMain,"📋","Auto Claim Index","Claims index rewards","AutoClaimIdx",11)
Tog(pMain,"🎁","Auto Claim Daily","Claims daily login reward","AutoClaimDaily",12)

-- ── POTIONS ────────────────────────────
local pPot = MakeScroll(TabData["Potions"].page)
Sec(pPot,"Automation",1)
Tog(pPot,"🍀","Auto Luck Potion","Uses luck potion every 25s","AutoLuckPot",2)
Tog(pPot,"⚡","Auto Speed Potion","Uses speed potion every 25s","AutoSpeedPot",3)
Tog(pPot,"💎","Auto Rare Potion","Uses rare-find potion","AutoRarePot",4)
Tog(pPot,"✨","Auto Use All Potions","Activates all buff potions","AutoAllPot",5)
Sec(pPot,"Actions",6)
Btn(pPot,"🏃","Collect All Potions","Teleports to all potions",C.Green,7,function()
    for _, o in pairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") and o.Name:lower():find("potion") then
            HRP.CFrame = CFrame.new(o.Position) task.wait(0.06)
        end
    end
    Notify("VaenHub","Potions collected!")
end)
Btn(pPot,"🔮","Craft All Potions","Crafts every potion type",C.Accent,8,function()
    FireR("CraftAllPotions") FireR("AutoCraft")
end)

-- ── CRAFTING ───────────────────────────
local pCraft = MakeScroll(TabData["Crafting"].page)
Sec(pCraft,"Auto Crafting",1)
Tog(pCraft,"🔨","Auto Craft Best","Crafts highest-tier item","AutoCraftBest",2)
Tog(pCraft,"🗡️","Auto Craft Weapons","Crafts weapons continuously","AutoCraftWep",3)
Tog(pCraft,"🛡️","Auto Craft Armor","Crafts armor pieces","AutoCraftArmor",4)
Sec(pCraft,"Actions",5)
Btn(pCraft,"📦","Collect Materials","Picks up ores & crystals",C.Yellow,6,function()
    for _, o in pairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") then
            local n = o.Name:lower()
            if n:find("ore") or n:find("crystal") or n:find("shard") or n:find("material") then
                HRP.CFrame = CFrame.new(o.Position) task.wait(0.05)
            end
        end
    end
    Notify("VaenHub","Materials collected!")
end)
Btn(pCraft,"♻️","Salvage All Junk","Dismantles unwanted items",C.Red,7,function()
    FireR("SalvageAll") FireR("DismantelAll")
end)
Btn(pCraft,"⚗️","Max Craft All","Crafts max quantity",C.Accent,8,function()
    FireR("MaxCraftAll") FireR("CraftMax")
end)

-- ── CONFIG ─────────────────────────────
local pCfg = MakeScroll(TabData["Config"].page)
Sec(pCfg,"Timings",1)
Sldr(pCfg,"⏱️","Roll Delay (sec)", 0.1, 5.0, S.RollDelay, "RollDelay", 2)
Sldr(pCfg,"🏃","Walk Speed",       16,  150, S.WalkSpd,  "WalkSpd",  3, function(v)
    local h = Char:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = v end
end)
Sldr(pCfg,"🦘","Jump Power",       50,  500, S.JumpPow,  "JumpPow",  4, function(v)
    local h = Char:FindFirstChildOfClass("Humanoid")
    if h then h.JumpPower = v end
end)
Sec(pCfg,"Webhook",5)
Inp(pCfg,"🔗","Discord Webhook URL","https://discord.com/api/webhooks/...","Webhook",6)
Btn(pCfg,"📤","Test Webhook","Send test to Discord",C.Accent,7,function()
    if S.Webhook == "" then
        Notify("VaenHub","Masukkan webhook URL dulu!") return
    end
    pcall(function()
        local HS = game:GetService("HttpService")
        local data = HS:JSONEncode({
            embeds = {{
                title       = "✅ VaenHub · Slime RNG",
                description = "Script running!\nPlayer: **"..LP.Name.."**\nTotal Rolls: **"..S.Rolls.."**",
                color       = 0x00AAFF,
            }}
        })
        HS:PostAsync(S.Webhook, data, Enum.HttpContentType.ApplicationJson)
    end)
    Notify("VaenHub","Webhook terkirim!")
end)
Sec(pCfg,"Save & Load",8)
Btn(pCfg,"💾","Save Settings","Simpan ke file",C.Green,9,function()
    pcall(function()
        if writefile then
            local HS = game:GetService("HttpService")
            writefile("VaenHub_SRNG.json", HS:JSONEncode({
                RollDelay=S.RollDelay, WalkSpd=S.WalkSpd,
                JumpPow=S.JumpPow, Webhook=S.Webhook,
                Rolls=S.Rolls, BestPet=S.BestPet, Rares=S.Rares,
            }))
            Notify("VaenHub","Settings tersimpan!")
        else
            Notify("VaenHub","writefile tidak tersedia di executor ini")
        end
    end)
end)
Btn(pCfg,"📂","Load Settings","Load dari file",C.Accent,10,function()
    pcall(function()
        if readfile and isfile and isfile("VaenHub_SRNG.json") then
            local HS = game:GetService("HttpService")
            local d = HS:JSONDecode(readfile("VaenHub_SRNG.json"))
            for k,v in pairs(d) do if S[k]~=nil then S[k]=v end end
            Notify("VaenHub","Settings loaded!")
        else
            Notify("VaenHub","Belum ada file settings")
        end
    end)
end)
Btn(pCfg,"🗑️","Reset Settings","Kembalikan ke default",C.Red,11,function()
    S.RollDelay=0.5 S.WalkSpd=16 S.JumpPow=50 S.Webhook=""
    Notify("VaenHub","Settings direset!")
end)

-- Stat cards (manual positioning, no UIGridLayout)
Sec(pCfg,"Stat Tracker",12)

local statHolder = New("Frame", {
    Size             = UDim2.new(1,0,0,158),
    BackgroundTransparency = 1,
    LayoutOrder      = 13,
}, pCfg)

if statHolder then
    StatCard(statHolder,"🎲","TOTAL ROLLS","Rolls",  5,   4)
    StatCard(statHolder,"⭐","RARE COUNT","Rares",  130,  4)
    StatCard(statHolder,"🐾","BEST PET","BestPet",  5,  82)
    StatCard(statHolder,"⏱️","SESSION","SessTime", 130, 82)
end

-- ── MISC ───────────────────────────────
local pMisc = MakeScroll(TabData["Misc"].page)
Sec(pMisc,"Movement",1)
Tog(pMisc,"✈️","Fly Mode","Tekan F untuk toggle · WASD/Space","FlyOn",2,function(on)
    if on then StartFly() else StopFly() end
end)
Tog(pMisc,"👻","No Clip","Menembus semua objek solid","NoClip",3)
Sec(pMisc,"ESP Visuals",4)
Tog(pMisc,"👥","ESP Players","Lihat pemain lewat tembok","ESPPlayers",5,function(on)
    if not on then ClearESP("Players") end
end)
Tog(pMisc,"👾","ESP Mobs","Highlight semua enemy","ESPMobs",6,function(on)
    if not on then ClearESP("Mobs") end
end)
Tog(pMisc,"📦","ESP Drops","Highlight drops (rare=oranye)","ESPDrops",7,function(on)
    if not on then ClearESP("Drops") end
end)
Tog(pMisc,"🎁","ESP Chests","Tampilkan lokasi chest","ESPChests",8,function(on)
    if not on then ClearESP("Chests") end
end)
Sec(pMisc,"Utility",9)
Tog(pMisc,"💤","Anti AFK","Mencegah kick otomatis","AntiAFK",10)
Tog(pMisc,"⚡","Performance Mode","Matikan shadow untuk FPS+","PerfMode",11,function(on)
    pcall(function()
        Lighting.GlobalShadows = not on
        Lighting.FogEnd = on and 1e7 or 2000
    end)
end)
Btn(pMisc,"🧹","Clear All ESP","Hapus semua overlay ESP",C.Red,12,function()
    S.ESPPlayers=false S.ESPMobs=false S.ESPDrops=false S.ESPChests=false
    ClearESP("Players") ClearESP("Mobs") ClearESP("Drops") ClearESP("Chests")
    for _, k in pairs({"ESPPlayers","ESPMobs","ESPDrops","ESPChests"}) do
        if ToggleSync[k] then ToggleSync[k](false) end
    end
    Notify("VaenHub","ESP dihapus!")
end)
Btn(pMisc,"🔄","Rejoin Server","Pindah ke server baru",C.Yellow,13,function()
    pcall(function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
    end)
end)
Btn(pMisc,"📋","Copy Stats","Salin statistik ke clipboard",C.Accent,14,function()
    local txt = string.format("[VaenHub] %s | Rolls:%d | Rares:%d | Best:%s",
        LP.Name, S.Rolls, S.Rares, S.BestPet)
    pcall(function() setclipboard(txt) end)
    Notify("VaenHub","Stats disalin!")
end)

print("[VaenHub] All pages built OK")

-- ╔══════════════════════════════════════╗
-- ║    CHARACTER RESPAWN HANDLER         ║
-- ╚══════════════════════════════════════╝
LP.CharacterAdded:Connect(function(c)
    Char = c
    HRP  = c:WaitForChild("HumanoidRootPart")
    Hum  = c:WaitForChild("Humanoid")
    task.wait(1)
    Hum.WalkSpeed = S.WalkSpd
    Hum.JumpPower = S.JumpPow
    if S.FlyOn then StartFly() end
end)

-- ╔══════════════════════════════════════╗
-- ║    OPEN ANIMATION + FIRST TAB        ║
-- ╚══════════════════════════════════════╝
Win.Size     = UDim2.new(0,WW,0,0)
Win.Position = UDim2.new(0.5,-WW/2,0.5,0)

Tw(Win,{
    Size     = UDim2.new(0,WW,0,WH),
    Position = UDim2.new(0.5,-WW/2,0.5,-WH/2),
},0.38,"Back","Out")

-- Activate first tab after brief delay
task.delay(0.15, function()
    TabData["Main"].btn:GetPropertyChangedSignal("BackgroundColor3")
    ActiveT = "Main"
    pcall(function()
        TabData["Main"].btn.BackgroundColor3 = C.Hover
        TabData["Main"].btn.TextColor3       = C.TextA
        TabData["Main"].bar.BackgroundTransparency = 0
        TabData["Main"].page.Visible         = true
    end)
end)

task.delay(0.9, function()
    Notify("✅ VaenHub Loaded","Slime RNG · Delta Fixed · Semua Sistem Aktif", 5)
end)

print("[VaenHub] ✅ FULLY LOADED!")

-- Akhir pcall wrapper
end)

-- ╔══════════════════════════════════════╗
-- ║    ERROR REPORTER                    ║
-- ╚══════════════════════════════════════╝
if not SUCCESS then
    warn("[VaenHub] ❌ FATAL ERROR: " .. tostring(ERR))
    -- Coba tampilkan error sederhana di layar
    pcall(function()
        local PGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        local sg   = Instance.new("ScreenGui")
        sg.Name    = "VaenHub_ERR"
        sg.ResetOnSpawn = false
        sg.Parent  = PGui
        local f    = Instance.new("Frame", sg)
        f.Size     = UDim2.new(0,420,0,100)
        f.Position = UDim2.new(0.5,-210,0,20)
        f.BackgroundColor3 = Color3.fromRGB(40,10,10)
        f.BorderSizePixel  = 0
        local lbl  = Instance.new("TextLabel", f)
        lbl.Size   = UDim2.fromScale(1,1)
        lbl.BackgroundTransparency = 1
        lbl.Text   = "❌ VaenHub Error:\n"..tostring(ERR)
        lbl.TextColor3 = Color3.fromRGB(255,100,100)
        lbl.TextSize   = 12
        lbl.Font       = Enum.Font.Gotham
        lbl.TextWrapped = true
        task.delay(10, function() pcall(function() sg:Destroy() end) end)
    end)
end
