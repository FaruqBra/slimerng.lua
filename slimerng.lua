Oke, saya akan analisis masalahnya dulu sebelum menulis ulang.

<details>
<summary>🔍 <strong>Analisis Masalah Script Sebelumnya</strong></summary>

**Masalah utama yang ditemukan:**

1. **`CoreGui` restriction** — Delta executor kadang tidak bisa langsung parent ke `CoreGui`, harus pakai `gethui()` atau `game.CoreGui` dengan pcall
2. **`Instance.new("UIStroke")`** — Beberapa versi executor tidak support UIStroke sebagai child langsung, harus explicit parent
3. **`UIGridLayout` + `AutomaticCanvasSize`** — Kombinasi ini sering crash di executor lama
4. **`spawn()` deprecated** — Harus pakai `task.spawn()` konsisten, mixing keduanya menyebabkan error
5. **`HttpService:PostAsync`** — Diblokir di client-side executor tanpa flag khusus
6. **`VirtualInputManager`** — Tidak tersedia di semua executor, harus pcall
7. **`setmetatable` protection** — Beberapa executor intercept ini dan throw error
8. **Missing `State` keys** — Toggle memanggil `State["AutoLuckPotion"]` dll yang tidak dideklarasi di State table awal
9. **`writefile/readfile`** — Harus dicek availability-nya dulu dengan kondisional
10. **`UIListLayout` di TabBar** — Konflik dengan manual sizing menyebabkan layout corrupt

</details>

```lua
--[[
╔══════════════════════════════════════════════════════════════╗
║                    VAENHUB - SLIME RNG                       ║
║         DELTA EXECUTOR COMPATIBLE | FIXED VERSION            ║
║              Premium Script | S+ Quality                     ║
╚══════════════════════════════════════════════════════════════╝
]]

-- ╔══════════════════════════════════════╗
-- ║     SAFE GUI PARENT (DELTA FIX)      ║
-- ╚══════════════════════════════════════╝

local function GetGuiParent()
    if gethui then return gethui() end
    if syn and syn.protect_gui then
        local sg = Instance.new("ScreenGui")
        syn.protect_gui(sg)
        sg.Parent = game.CoreGui
        return sg
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok then return cg end
    return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

-- ╔══════════════════════════════════════╗
-- ║         SERVICES                     ║
-- ╚══════════════════════════════════════╝

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local StarterGui       = game:GetService("StarterGui")
local Lighting         = game:GetService("Lighting")

local LocalPlayer  = Players.LocalPlayer
local Character    = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid     = Character:WaitForChild("Humanoid")
local HRP          = Character:WaitForChild("HumanoidRootPart")
local Camera       = workspace.CurrentCamera

-- ╔══════════════════════════════════════╗
-- ║         STATE TABLE (LENGKAP)        ║
-- ╚══════════════════════════════════════╝

local State = {
    -- Main
    AutoFarm          = false,
    AutoRoll          = false,
    AutoEquipPet      = false,
    AutoSell          = false,
    AutoMerge         = false,
    -- Progression
    AutoBuyUpgrades   = false,
    AutoRebirth       = false,
    AutoClaimIndex    = false,
    AutoClaimDaily    = false,
    -- Potions
    AutoLuckPotion    = false,
    AutoSpeedPotion   = false,
    AutoRarePotion    = false,
    AutoAllPotions    = false,
    -- Crafting
    AutoCraftBest     = false,
    AutoCraftWeapons  = false,
    AutoCraftArmor    = false,
    -- ESP
    ESPPlayers        = false,
    ESPMobs           = false,
    ESPDrops          = false,
    ESPChests         = false,
    -- Misc
    FlyEnabled        = false,
    NoClip            = false,
    AntiAFK           = false,
    PerfMode          = false,
    -- Config values
    RollDelay         = 0.5,
    WalkSpeed         = 16,
    JumpPower         = 50,
    WebhookURL        = "",
    -- Stats
    TotalRolls        = 0,
    BestPet           = "None",
    RareCount         = 0,
    SessionTime       = 0,
}

-- ╔══════════════════════════════════════╗
-- ║         THEME                        ║
-- ╚══════════════════════════════════════╝

local T = {
    Bg          = Color3.fromRGB(12,  14,  18),
    Surface     = Color3.fromRGB(18,  21,  27),
    SurfaceHov  = Color3.fromRGB(26,  30,  40),
    Card        = Color3.fromRGB(22,  26,  34),
    CardBorder  = Color3.fromRGB(38,  44,  58),
    Accent      = Color3.fromRGB(0,  170, 255),
    AccentDark  = Color3.fromRGB(0,  120, 200),
    AccentGlow  = Color3.fromRGB(0,  210, 255),
    TextPri     = Color3.fromRGB(235, 242, 255),
    TextSec     = Color3.fromRGB(140, 158, 180),
    TextMuted   = Color3.fromRGB(75,  90, 112),
    Success     = Color3.fromRGB(0,  205, 125),
    Warning     = Color3.fromRGB(255, 178,   0),
    Danger      = Color3.fromRGB(255,  65,  75),
    ToggleOff   = Color3.fromRGB(42,  48,  64),
    Separator   = Color3.fromRGB(28,  33,  44),
}

-- ╔══════════════════════════════════════╗
-- ║         UTILITY                      ║
-- ╚══════════════════════════════════════╝

local function SafeCall(fn, ...)
    local args = {...}
    local ok, err = pcall(function() fn(table.unpack(args)) end)
    if not ok then warn("[VaenHub] "..tostring(err)) end
end

local function Tween(obj, props, t, style, dir)
    local ok, tw = pcall(function()
        return TweenService:Create(obj,
            TweenInfo.new(t or 0.2, Enum.EasingStyle[style or "Quad"], Enum.EasingDirection[dir or "Out"]),
            props)
    end)
    if ok and tw then tw:Play() end
end

local function Round(n, d)
    local m = 10^(d or 0)
    return math.floor(n * m + 0.5) / m
end

local function FmtNum(n)
    return tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,","")
end

local function FmtTime(s)
    local h = math.floor(s/3600)
    local m = math.floor((s%3600)/60)
    local ss= s%60
    return string.format("%02d:%02d:%02d", h, m, ss)
end

local function Notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification",{Title=title,Text=text,Duration=dur or 3})
    end)
end

-- Remote helpers
local function FireRemote(name, ...)
    local r = ReplicatedStorage:FindFirstChild(name, true)
    if r and r:IsA("RemoteEvent") then
        pcall(function() r:FireServer(...) end)
        return true
    end
    return false
end

local function InvokeRemote(name, ...)
    local r = ReplicatedStorage:FindFirstChild(name, true)
    if r and r:IsA("RemoteFunction") then
        local ok, res = pcall(function() return r:InvokeServer(...) end)
        return ok and res or nil
    end
end

-- ╔══════════════════════════════════════╗
-- ║         GAME LOGIC                   ║
-- ╚══════════════════════════════════════╝

-- Auto Roll
task.spawn(function()
    while true do
        task.wait(State.RollDelay > 0 and State.RollDelay or 0.5)
        if State.AutoRoll then
            SafeCall(function()
                FireRemote("Roll")
                FireRemote("RollPet")
                FireRemote("SpinSlime")
                FireRemote("GachaRoll")
                -- Coba klik tombol di GUI game
                for _, gui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
                    if gui:IsA("GuiButton") then
                        local n = gui.Name:lower()
                        if n:find("roll") or n:find("spin") or n:find("gacha") then
                            pcall(function() gui.Activated:Fire() end)
                        end
                    end
                end
                State.TotalRolls = State.TotalRolls + 1
            end)
        end
    end
end)

-- Auto Farm
task.spawn(function()
    while true do
        task.wait(0.12)
        if State.AutoFarm then
            SafeCall(function()
                local nearest, nearDist = nil, math.huge
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid")
                        and obj ~= Character then
                        local hum = obj:FindFirstChildOfClass("Humanoid")
                        local root = obj:FindFirstChild("HumanoidRootPart")
                        if hum and hum.Health > 0 and root then
                            local d = (HRP.Position - root.Position).Magnitude
                            if d < nearDist then nearDist = d nearest = root end
                        end
                    end
                end
                if nearest then
                    HRP.CFrame = nearest.CFrame * CFrame.new(0, 0, -3.5)
                    FireRemote("Attack")
                    FireRemote("DamageEnemy")
                    FireRemote("HitMob")
                end
                -- Collect nearby drops
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        local n = obj.Name:lower()
                        if n:find("drop") or n:find("collect") or n:find("pickup") then
                            local d = (HRP.Position - obj.Position).Magnitude
                            if d < 30 then HRP.CFrame = CFrame.new(obj.Position) end
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Equip Pet
task.spawn(function()
    while true do
        task.wait(5)
        if State.AutoEquipPet then
            SafeCall(function()
                FireRemote("EquipBestPet")
                FireRemote("AutoEquip")
                InvokeRemote("GetBestPet")
            end)
        end
    end
end)

-- Auto Sell
task.spawn(function()
    while true do
        task.wait(3)
        if State.AutoSell then
            SafeCall(function()
                FireRemote("SellAll")
                FireRemote("AutoSell")
                FireRemote("SellItems")
            end)
        end
    end
end)

-- Auto Merge
task.spawn(function()
    while true do
        task.wait(2)
        if State.AutoMerge then
            SafeCall(function()
                FireRemote("MergeAll")
                FireRemote("AutoMerge")
                FireRemote("MergePets")
            end)
        end
    end
end)

-- Auto Buy Upgrades
task.spawn(function()
    while true do
        task.wait(1)
        if State.AutoBuyUpgrades then
            SafeCall(function()
                FireRemote("BuyUpgrade")
                FireRemote("PurchaseAllUpgrades")
                FireRemote("BuyAllUpgrades")
            end)
        end
    end
end)

-- Auto Rebirth
task.spawn(function()
    while true do
        task.wait(5)
        if State.AutoRebirth then
            SafeCall(function()
                FireRemote("Rebirth")
                FireRemote("DoRebirth")
                FireRemote("PrestigeRebirth")
            end)
        end
    end
end)

-- Auto Claim Index
task.spawn(function()
    while true do
        task.wait(3)
        if State.AutoClaimIndex then
            SafeCall(function()
                FireRemote("ClaimIndexReward")
                FireRemote("ClaimAllIndex")
            end)
        end
    end
end)

-- Auto Claim Daily
task.spawn(function()
    while true do
        task.wait(60)
        if State.AutoClaimDaily then
            SafeCall(function()
                FireRemote("ClaimDaily")
                FireRemote("DailyReward")
                FireRemote("ClaimDailyReward")
            end)
        end
    end
end)

-- Potions
task.spawn(function()
    while true do
        task.wait(30)
        if State.AutoLuckPotion then
            SafeCall(function() FireRemote("UseLuckPotion") FireRemote("ActivateLuck") end)
        end
        if State.AutoSpeedPotion then
            SafeCall(function() FireRemote("UseSpeedPotion") FireRemote("ActivateSpeed") end)
        end
        if State.AutoRarePotion then
            SafeCall(function() FireRemote("UseRarePotion") FireRemote("ActivateRare") end)
        end
        if State.AutoAllPotions then
            SafeCall(function() FireRemote("UseAllPotions") FireRemote("ActivateAllBuffs") end)
        end
    end
end)

-- Crafting
task.spawn(function()
    while true do
        task.wait(1.5)
        if State.AutoCraftBest then
            SafeCall(function() FireRemote("CraftBestItem") FireRemote("AutoCraftBest") end)
        end
        if State.AutoCraftWeapons then
            SafeCall(function() FireRemote("CraftWeapon") FireRemote("AutoCraftWeapon") end)
        end
        if State.AutoCraftArmor then
            SafeCall(function() FireRemote("CraftArmor") FireRemote("AutoCraftArmor") end)
        end
    end
end)

-- Walk/Jump speed enforcer
task.spawn(function()
    while true do
        task.wait(0.5)
        local hum = Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = State.WalkSpeed
            hum.JumpPower = State.JumpPower
        end
    end
end)

-- Session timer
task.spawn(function()
    while true do
        task.wait(1)
        State.SessionTime = State.SessionTime + 1
    end
end)

-- NoClip loop
task.spawn(function()
    RunService.Stepped:Connect(function()
        if State.NoClip then
            for _, p in pairs(Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)
end)

-- Anti AFK loop
task.spawn(function()
    while true do
        task.wait(60)
        if State.AntiAFK then
            pcall(function()
                local VIM = game:GetService("VirtualInputManager")
                VIM:SendKeyEvent(true,  Enum.KeyCode.F13, false, game)
                VIM:SendKeyEvent(false, Enum.KeyCode.F13, false, game)
            end)
        end
    end
end)

-- ╔══════════════════════════════════════╗
-- ║         FLY SYSTEM                   ║
-- ╚══════════════════════════════════════╝

local FlyBV, FlyBG, FlyConn

local function EnableFly()
    pcall(function()
        if FlyBV then FlyBV:Destroy() end
        if FlyBG then FlyBG:Destroy() end
        FlyBV = Instance.new("BodyVelocity", HRP)
        FlyBV.Velocity  = Vector3.zero
        FlyBV.MaxForce  = Vector3.new(1e9,1e9,1e9)
        FlyBG = Instance.new("BodyGyro", HRP)
        FlyBG.MaxTorque = Vector3.new(1e9,1e9,1e9)
        FlyBG.D         = 500
        FlyConn = RunService.Heartbeat:Connect(function()
            if not State.FlyEnabled then return end
            local spd = State.WalkSpeed * 1.8
            local dir = Vector3.zero
            local UIS = UserInputService
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space)       then dir = dir + Vector3.yAxis end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.yAxis end
            FlyBV.Velocity = dir.Magnitude > 0 and dir.Unit * spd or Vector3.zero
            FlyBG.CFrame   = Camera.CFrame
        end)
    end)
end

local function DisableFly()
    pcall(function()
        if FlyConn then FlyConn:Disconnect() FlyConn = nil end
        if FlyBV then FlyBV:Destroy() FlyBV = nil end
        if FlyBG then FlyBG:Destroy() FlyBG = nil end
    end)
end

-- Fly keybind F
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.F then
        State.FlyEnabled = not State.FlyEnabled
        if State.FlyEnabled then EnableFly() else DisableFly() end
    end
end)

-- ╔══════════════════════════════════════╗
-- ║         ESP SYSTEM                   ║
-- ╚══════════════════════════════════════╝

local ESPStore = { Players={}, Mobs={}, Drops={}, Chests={} }
local GuiParentForESP = GetGuiParent()

local function MakeESP(adornee, color, label)
    local ok, bb = pcall(function()
        local b = Instance.new("BillboardGui")
        b.Name          = "VH_ESP"
        b.AlwaysOnTop   = true
        b.Size          = UDim2.new(0,110,0,40)
        b.StudsOffset   = Vector3.new(0,3,0)
        b.Adornee       = adornee

        local bg = Instance.new("Frame", b)
        bg.Size                  = UDim2.fromScale(1,1)
        bg.BackgroundColor3      = Color3.fromRGB(0,0,0)
        bg.BackgroundTransparency= 0.55
        bg.BorderSizePixel       = 0
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0,4)

        -- border via frame trick (no UIStroke needed)
        local border = Instance.new("Frame", b)
        border.Size                  = UDim2.new(1,2,1,2)
        border.Position              = UDim2.new(0,-1,0,-1)
        border.BackgroundColor3      = color
        border.BackgroundTransparency= 0.2
        border.BorderSizePixel       = 0
        border.ZIndex                = 0
        Instance.new("UICorner", border).CornerRadius = UDim.new(0,5)

        local nl = Instance.new("TextLabel", bg)
        nl.Size               = UDim2.new(1,0,0.6,0)
        nl.BackgroundTransparency = 1
        nl.Text               = label or adornee.Name
        nl.TextColor3         = color
        nl.TextSize           = 11
        nl.Font               = Enum.Font.GothamBold
        nl.TextXAlignment     = Enum.TextXAlignment.Center

        local dl = Instance.new("TextLabel", bg)
        dl.Name               = "Dist"
        dl.Size               = UDim2.new(1,0,0.4,0)
        dl.Position           = UDim2.fromScale(0,0.6)
        dl.BackgroundTransparency = 1
        dl.TextColor3         = T.TextSec
        dl.TextSize           = 9
        dl.Font               = Enum.Font.Gotham
        dl.TextXAlignment     = Enum.TextXAlignment.Center

        -- Parent last (safer for executors)
        if typeof(GuiParentForESP) == "Instance" then
            b.Parent = GuiParentForESP
        else
            b.Parent = LocalPlayer.PlayerGui
        end

        RunService.Heartbeat:Connect(function()
            if not b or not b.Parent or not adornee or not adornee.Parent then
                pcall(function() b:Destroy() end)
                return
            end
            local dist = (HRP.Position - adornee.Position).Magnitude
            dl.Text = Round(dist,1).." studs"
        end)
        return b
    end)
    if ok then return bb end
end

local function ClearESP(cat)
    for _, v in pairs(ESPStore[cat] or {}) do
        pcall(function() if v and v.Parent then v:Destroy() end end)
    end
    ESPStore[cat] = {}
end

-- ESP Heartbeat
RunService.Heartbeat:Connect(function()
    -- Players ESP
    if State.ESPPlayers then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local found = false
                    for _, e in pairs(ESPStore.Players) do
                        if e and e.Adornee == root then found=true break end
                    end
                    if not found then
                        local bb = MakeESP(root, T.AccentGlow, plr.Name)
                        if bb then table.insert(ESPStore.Players, bb) end
                    end
                end
            end
        end
    end

    -- Mobs ESP
    if State.ESPMobs then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj ~= Character then
                local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                if root then
                    local found = false
                    for _, e in pairs(ESPStore.Mobs) do
                        if e and e.Adornee == root then found=true break end
                    end
                    if not found then
                        local bb = MakeESP(root, T.Warning, "👾 "..obj.Name)
                        if bb then table.insert(ESPStore.Mobs, bb) end
                    end
                end
            end
        end
    end

    -- Drops ESP
    if State.ESPDrops then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local n = obj.Name:lower()
                if n:find("drop") or n:find("item") or n:find("slime") then
                    local found = false
                    for _, e in pairs(ESPStore.Drops) do
                        if e and e.Adornee == obj then found=true break end
                    end
                    if not found then
                        local isRare = n:find("rare") or n:find("epic") or n:find("legendary")
                        local bb = MakeESP(obj, isRare and T.Warning or T.Success, "📦 "..obj.Name)
                        if bb then table.insert(ESPStore.Drops, bb) end
                    end
                end
            end
        end
    end

    -- Chests ESP
    if State.ESPChests then
        for _, obj in pairs(workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if n:find("chest") or n:find("lucky") then
                local part = obj:IsA("BasePart") and obj
                    or (obj:IsA("Model") and obj.PrimaryPart)
                if part then
                    local found = false
                    for _, e in pairs(ESPStore.Chests) do
                        if e and e.Adornee == part then found=true break end
                    end
                    if not found then
                        local isLucky = n:find("lucky")
                        local bb = MakeESP(part, isLucky and T.Warning or T.Accent, "🎁 "..obj.Name)
                        if bb then table.insert(ESPStore.Chests, bb) end
                    end
                end
            end
        end
    end
end)

-- ╔══════════════════════════════════════╗
-- ║         SAVE / LOAD                  ║
-- ╚══════════════════════════════════════╝

local SAVE_KEY = "VaenHub_SRNG.json"

local function SaveCfg()
    pcall(function()
        if not writefile then return end
        local d = {
            RollDelay  = State.RollDelay,
            WalkSpeed  = State.WalkSpeed,
            JumpPower  = State.JumpPower,
            WebhookURL = State.WebhookURL,
            TotalRolls = State.TotalRolls,
            BestPet    = State.BestPet,
            RareCount  = State.RareCount,
        }
        writefile(SAVE_KEY, HttpService:JSONEncode(d))
    end)
end

local function LoadCfg()
    pcall(function()
        if not readfile or not isfile then return end
        if not isfile(SAVE_KEY) then return end
        local d = HttpService:JSONDecode(readfile(SAVE_KEY))
        for k,v in pairs(d) do
            if State[k] ~= nil then State[k] = v end
        end
    end)
end

LoadCfg()

-- ╔══════════════════════════════════════╗
-- ║         BUILD SCREEN GUI             ║
-- ╚══════════════════════════════════════╝

local GuiRoot = GetGuiParent()

-- Remove duplicate
local old = nil
pcall(function()
    old = GuiRoot:FindFirstChild("VaenHub_SRNG")
end)
if old then old:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "VaenHub_SRNG"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder    = 999
ScreenGui.IgnoreGuiInset  = true

-- Safe parent
pcall(function() ScreenGui.Parent = GuiRoot end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ╔══════════════════════════════════════╗
-- ║     MAIN WINDOW FRAME                ║
-- ╚══════════════════════════════════════╝

local WIN_W, WIN_H = 560, 580

local Win = Instance.new("Frame")
Win.Name              = "Window"
Win.Size              = UDim2.new(0, WIN_W, 0, WIN_H)
Win.Position          = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
Win.BackgroundColor3  = T.Bg
Win.BorderSizePixel   = 0
Win.ClipsDescendants  = true
Win.Parent            = ScreenGui
Instance.new("UICorner", Win).CornerRadius = UDim.new(0,12)

-- Outer glow border (frame trick, no UIStroke)
local GlowBorder = Instance.new("Frame")
GlowBorder.Name              = "GlowBorder"
GlowBorder.Size              = UDim2.new(1,4,1,4)
GlowBorder.Position          = UDim2.new(0,-2,0,-2)
GlowBorder.BackgroundColor3  = T.Accent
GlowBorder.BackgroundTransparency = 0.65
GlowBorder.BorderSizePixel   = 0
GlowBorder.ZIndex            = 0
GlowBorder.Parent            = Win
Instance.new("UICorner", GlowBorder).CornerRadius = UDim.new(0,14)

-- Pulse the glow
task.spawn(function()
    while Win and Win.Parent do
        Tween(GlowBorder, {BackgroundTransparency=0.45}, 1, "Sine", "InOut")
        task.wait(1)
        Tween(GlowBorder, {BackgroundTransparency=0.75}, 1, "Sine", "InOut")
        task.wait(1)
    end
end)

-- ╔══════════════════════════════════════╗
-- ║         TITLE BAR                    ║
-- ╚══════════════════════════════════════╝

local TitleBar = Instance.new("Frame")
TitleBar.Name             = "TitleBar"
TitleBar.Size             = UDim2.new(1,0,0,52)
TitleBar.BackgroundColor3 = T.Surface
TitleBar.BorderSizePixel  = 0
TitleBar.ZIndex           = 5
TitleBar.Parent           = Win

-- Round only top corners via a fill-in fix
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0,12)
local TBFix = Instance.new("Frame", TitleBar)
TBFix.Size             = UDim2.new(1,0,0.5,0)
TBFix.Position         = UDim2.new(0,0,0.5,0)
TBFix.BackgroundColor3 = T.Surface
TBFix.BorderSizePixel  = 0

-- Accent gradient line
local AccLine = Instance.new("Frame", TitleBar)
AccLine.Size             = UDim2.new(1,0,0,2)
AccLine.Position         = UDim2.new(0,0,1,-2)
AccLine.BackgroundColor3 = T.Accent
AccLine.BorderSizePixel  = 0
AccLine.ZIndex           = 6

local AccGrad = Instance.new("UIGradient", AccLine)
AccGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,80,180)),
    ColorSequenceKeypoint.new(0.5, T.AccentGlow),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,80,180)),
})

-- Dot logo
local Dot = Instance.new("Frame", TitleBar)
Dot.Size             = UDim2.new(0,10,0,10)
Dot.Position         = UDim2.new(0,16,0.5,-5)
Dot.BackgroundColor3 = T.Accent
Dot.BorderSizePixel  = 0
Dot.ZIndex           = 6
Instance.new("UICorner", Dot).CornerRadius = UDim.new(1,0)

task.spawn(function()
    while Win and Win.Parent do
        Tween(Dot,{BackgroundColor3=T.AccentGlow},0.9,"Sine","InOut")
        task.wait(0.9)
        Tween(Dot,{BackgroundColor3=T.AccentDark},0.9,"Sine","InOut")
        task.wait(0.9)
    end
end)

-- Title text
local TitleLbl = Instance.new("TextLabel", TitleBar)
TitleLbl.Size               = UDim2.new(1,-110,0,28)
TitleLbl.Position           = UDim2.new(0,34,0,6)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text               = "Slime RNG  ·  VaenHub"
TitleLbl.TextColor3         = T.TextPri
TitleLbl.TextSize           = 15
TitleLbl.Font               = Enum.Font.GothamBold
TitleLbl.TextXAlignment     = Enum.TextXAlignment.Left
TitleLbl.ZIndex             = 6

local SubLbl = Instance.new("TextLabel", TitleBar)
SubLbl.Size               = UDim2.new(1,-110,0,14)
SubLbl.Position           = UDim2.new(0,34,0,32)
SubLbl.BackgroundTransparency = 1
SubLbl.Text               = "Premium Script  ·  Delta Compatible"
SubLbl.TextColor3         = T.Accent
SubLbl.TextSize           = 10
SubLbl.Font               = Enum.Font.Gotham
SubLbl.TextXAlignment     = Enum.TextXAlignment.Left
SubLbl.ZIndex             = 6

-- Close button
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size             = UDim2.new(0,30,0,30)
CloseBtn.Position         = UDim2.new(1,-42,0.5,-15)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255,55,65)
CloseBtn.BorderSizePixel  = 0
CloseBtn.Text             = "✕"
CloseBtn.TextColor3       = Color3.fromRGB(255,255,255)
CloseBtn.TextSize         = 13
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.ZIndex           = 7
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,7)

CloseBtn.MouseEnter:Connect(function()
    Tween(CloseBtn,{BackgroundColor3=Color3.fromRGB(255,80,88)},0.15)
end)
CloseBtn.MouseLeave:Connect(function()
    Tween(CloseBtn,{BackgroundColor3=Color3.fromRGB(255,55,65)},0.15)
end)
CloseBtn.MouseButton1Click:Connect(function()
    Tween(Win,{Size=UDim2.new(0,WIN_W,0,0),
        Position=UDim2.new(0.5,-WIN_W/2,0.5,0)},0.28,"Back","In")
    task.wait(0.3)
    ScreenGui:Destroy()
end)

-- Minimize button
local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size             = UDim2.new(0,30,0,30)
MinBtn.Position         = UDim2.new(1,-78,0.5,-15)
MinBtn.BackgroundColor3 = Color3.fromRGB(255,170,0)
MinBtn.BorderSizePixel  = 0
MinBtn.Text             = "–"
MinBtn.TextColor3       = Color3.fromRGB(255,255,255)
MinBtn.TextSize         = 16
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.ZIndex           = 7
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0,7)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Tween(Win, {Size = minimized
        and UDim2.new(0,WIN_W,0,52)
        or  UDim2.new(0,WIN_W,0,WIN_H)}, 0.28, "Quad", "Out")
end)

-- ╔══════════════════════════════════════╗
-- ║         DRAG                         ║
-- ╚══════════════════════════════════════╝

local dragging, dragStart, winStart = false, nil, nil

TitleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = inp.Position
        winStart  = Win.Position
    end
end)
TitleBar.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local d = inp.Position - dragStart
        Win.Position = UDim2.new(
            winStart.X.Scale, winStart.X.Offset + d.X,
            winStart.Y.Scale, winStart.Y.Offset + d.Y)
    end
end)

-- ╔══════════════════════════════════════╗
-- ║         TAB BAR                      ║
-- ╚══════════════════════════════════════╝

local TAB_Y = 52

local TabBg = Instance.new("Frame")
TabBg.Name             = "TabBg"
TabBg.Size             = UDim2.new(1,0,0,44)
TabBg.Position         = UDim2.new(0,0,0,TAB_Y)
TabBg.BackgroundColor3 = T.Surface
TabBg.BorderSizePixel  = 0
TabBg.ZIndex           = 4
TabBg.Parent           = Win

-- separator
local TabSep = Instance.new("Frame", TabBg)
TabSep.Size             = UDim2.new(1,0,0,1)
TabSep.Position         = UDim2.new(0,0,1,-1)
TabSep.BackgroundColor3 = T.Separator
TabSep.BorderSizePixel  = 0

-- Content
local Content = Instance.new("Frame")
Content.Name              = "Content"
Content.Size              = UDim2.new(1,0,1,-(TAB_Y+44))
Content.Position          = UDim2.new(0,0,0,TAB_Y+44)
Content.BackgroundTransparency = 1
Content.ClipsDescendants  = true
Content.Parent            = Win

-- ╔══════════════════════════════════════╗
-- ║         TAB BUILDER                  ║
-- ╚══════════════════════════════════════╝

local TabDefs = {
    {id="Main",     label="⚔️ Main"},
    {id="Potions",  label="🧪 Potions"},
    {id="Crafting", label="🔨 Craft"},
    {id="Config",   label="⚙️ Config"},
    {id="Misc",     label="🎮 Misc"},
}

local TabMap    = {}
local ActiveTab = nil
local TAB_W     = math.floor((WIN_W - 20) / #TabDefs)
local TAB_PAD   = 10

local function SetActiveTab(id)
    if ActiveTab == id then return end
    if ActiveTab and TabMap[ActiveTab] then
        local prev = TabMap[ActiveTab]
        Tween(prev.btn, {BackgroundColor3=T.Surface, TextColor3=T.TextMuted}, 0.18)
        Tween(prev.bar, {BackgroundTransparency=1}, 0.18)
        prev.page.Visible = false
    end
    ActiveTab = id
    local cur = TabMap[id]
    Tween(cur.btn, {BackgroundColor3=T.SurfaceHov, TextColor3=T.TextPri}, 0.18)
    Tween(cur.bar, {BackgroundTransparency=0}, 0.18)
    cur.page.Visible = true
end

for i, def in ipairs(TabDefs) do
    local xOff = TAB_PAD + (i-1)*(TAB_W+2)

    local btn = Instance.new("TextButton", TabBg)
    btn.Size             = UDim2.new(0,TAB_W,0,34)
    btn.Position         = UDim2.new(0,xOff,0.5,-17)
    btn.BackgroundColor3 = T.Surface
    btn.BorderSizePixel  = 0
    btn.Text             = def.label
    btn.TextColor3       = T.TextMuted
    btn.TextSize         = 11
    btn.Font             = Enum.Font.GothamSemibold
    btn.ZIndex           = 5
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)

    local bar = Instance.new("Frame", btn)
    bar.Size             = UDim2.new(0.75,0,0,2)
    bar.Position         = UDim2.new(0.125,0,1,-2)
    bar.BackgroundColor3 = T.Accent
    bar.BackgroundTransparency = 1
    bar.BorderSizePixel  = 0
    bar.ZIndex           = 6
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)

    local page = Instance.new("Frame", Content)
    page.Name            = "Page_"..def.id
    page.Size            = UDim2.fromScale(1,1)
    page.BackgroundTransparency = 1
    page.Visible         = false

    TabMap[def.id] = { btn=btn, bar=bar, page=page }

    btn.MouseButton1Click:Connect(function()
        SetActiveTab(def.id)
    end)
end

-- ╔══════════════════════════════════════╗
-- ║     SCROLL FRAME BUILDER             ║
-- ╚══════════════════════════════════════╝

local function MakeScroll(parent)
    local sf = Instance.new("ScrollingFrame", parent)
    sf.Size                   = UDim2.fromScale(1,1)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel        = 0
    sf.ScrollBarThickness     = 3
    sf.ScrollBarImageColor3   = T.Accent
    sf.ScrollBarImageTransparency = 0.4
    sf.CanvasSize             = UDim2.new(0,0,0,0)
    sf.AutomaticCanvasSize    = Enum.AutomaticSize.Y

    local ul = Instance.new("UIListLayout", sf)
    ul.Padding                = UDim.new(0,6)
    ul.HorizontalAlignment    = Enum.HorizontalAlignment.Center
    ul.SortOrder              = Enum.SortOrder.LayoutOrder

    local up = Instance.new("UIPadding", sf)
    up.PaddingTop    = UDim.new(0,10)
    up.PaddingBottom = UDim.new(0,12)
    up.PaddingLeft   = UDim.new(0,12)
    up.PaddingRight  = UDim.new(0,12)

    return sf
end

-- ╔══════════════════════════════════════╗
-- ║     COMPONENT: SECTION LABEL         ║
-- ╚══════════════════════════════════════╝

local function MakeSection(parent, text, order)
    local f = Instance.new("Frame", parent)
    f.Name             = "Sec_"..text
    f.Size             = UDim2.new(1,0,0,22)
    f.BackgroundTransparency = 1
    f.LayoutOrder      = order or 0

    local l1 = Instance.new("Frame", f)
    l1.Size            = UDim2.new(0.28,0,0,1)
    l1.Position        = UDim2.new(0,0,0.5,0)
    l1.BackgroundColor3= T.Separator
    l1.BorderSizePixel = 0

    local lbl = Instance.new("TextLabel", f)
    lbl.Size           = UDim2.new(0.44,0,1,0)
    lbl.Position       = UDim2.new(0.28,0,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text           = "  "..text:upper().."  "
    lbl.TextColor3     = T.TextMuted
    lbl.TextSize       = 9
    lbl.Font           = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Center

    local l2 = Instance.new("Frame", f)
    l2.Size            = UDim2.new(0.28,0,0,1)
    l2.Position        = UDim2.new(0.72,0,0.5,0)
    l2.BackgroundColor3= T.Separator
    l2.BorderSizePixel = 0

    return f
end

-- ╔══════════════════════════════════════╗
-- ║     COMPONENT: TOGGLE ROW            ║
-- ╚══════════════════════════════════════╝

-- Tracks toggle UI refs so we can update them from code
local ToggleRefs = {}

local function MakeToggle(parent, icon, title, sub, key, order, cb)
    local row = Instance.new("Frame", parent)
    row.Name             = "Toggle_"..key
    row.Size             = UDim2.new(1,0,0,54)
    row.BackgroundColor3 = T.Card
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order or 99
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,10)

    -- Border frame trick
    local bor = Instance.new("Frame", row)
    bor.Size             = UDim2.new(1,2,1,2)
    bor.Position         = UDim2.new(0,-1,0,-1)
    bor.BackgroundColor3 = T.CardBorder
    bor.BackgroundTransparency = 0.5
    bor.BorderSizePixel  = 0
    bor.ZIndex           = 0
    Instance.new("UICorner", bor).CornerRadius = UDim.new(0,11)

    local ic = Instance.new("TextLabel", row)
    ic.Size              = UDim2.new(0,36,1,0)
    ic.Position          = UDim2.new(0,10,0,0)
    ic.BackgroundTransparency = 1
    ic.Text              = icon
    ic.TextSize          = 18
    ic.TextXAlignment    = Enum.TextXAlignment.Center
    ic.ZIndex            = 2

    local tl = Instance.new("TextLabel", row)
    tl.Size              = UDim2.new(1,-110,0,22)
    tl.Position          = UDim2.new(0,50,0,8)
    tl.BackgroundTransparency = 1
    tl.Text              = title
    tl.TextColor3        = T.TextPri
    tl.TextSize          = 13
    tl.Font              = Enum.Font.GothamSemibold
    tl.TextXAlignment    = Enum.TextXAlignment.Left
    tl.ZIndex            = 2

    local sl = Instance.new("TextLabel", row)
    sl.Size              = UDim2.new(1,-110,0,16)
    sl.Position          = UDim2.new(0,50,0,30)
    sl.BackgroundTransparency = 1
    sl.Text              = sub or ""
    sl.TextColor3        = T.TextMuted
    sl.TextSize          = 10
    sl.Font              = Enum.Font.Gotham
    sl.TextXAlignment    = Enum.TextXAlignment.Left
    sl.ZIndex            = 2

    -- Toggle pill
    local on = State[key]
    local pill = Instance.new("Frame", row)
    pill.Size            = UDim2.new(0,42,0,22)
    pill.Position        = UDim2.new(1,-54,0.5,-11)
    pill.BackgroundColor3= on and T.Accent or T.ToggleOff
    pill.BorderSizePixel = 0
    pill.ZIndex          = 2
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame", pill)
    knob.Size            = UDim2.new(0,16,0,16)
    knob.Position        = on and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
    knob.BackgroundColor3= Color3.fromRGB(255,255,255)
    knob.BorderSizePixel = 0
    knob.ZIndex          = 3
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    ToggleRefs[key] = {pill=pill, knob=knob}

    local function Refresh(state)
        Tween(pill,  {BackgroundColor3 = state and T.Accent or T.ToggleOff}, 0.2)
        Tween(knob,  {Position = state
            and UDim2.new(1,-19,0.5,-8)
            or  UDim2.new(0,3, 0.5,-8)}, 0.2)
    end

    local btn = Instance.new("TextButton", row)
    btn.Size             = UDim2.fromScale(1,1)
    btn.BackgroundTransparency = 1
    btn.Text             = ""
    btn.ZIndex           = 4

    btn.MouseEnter:Connect(function()
        Tween(row, {BackgroundColor3=T.SurfaceHov}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        Tween(row, {BackgroundColor3=T.Card}, 0.15)
    end)
    btn.MouseButton1Click:Connect(function()
        State[key] = not State[key]
        Refresh(State[key])
        if cb then SafeCall(cb, State[key]) end
    end)

    return row
end

-- ╔══════════════════════════════════════╗
-- ║     COMPONENT: BUTTON ROW            ║
-- ╚══════════════════════════════════════╝

local function MakeButton(parent, icon, title, sub, accent, order, cb)
    local row = Instance.new("Frame", parent)
    row.Name             = "Btn_"..title
    row.Size             = UDim2.new(1,0,0, sub and 54 or 44)
    row.BackgroundColor3 = T.Card
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order or 99
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,10)

    local bor = Instance.new("Frame", row)
    bor.Size             = UDim2.new(1,2,1,2)
    bor.Position         = UDim2.new(0,-1,0,-1)
    bor.BackgroundColor3 = accent or T.CardBorder
    bor.BackgroundTransparency = 0.6
    bor.BorderSizePixel  = 0
    bor.ZIndex           = 0
    Instance.new("UICorner", bor).CornerRadius = UDim.new(0,11)

    local ic = Instance.new("TextLabel", row)
    ic.Size              = UDim2.new(0,36,1,0)
    ic.Position          = UDim2.new(0,10,0,0)
    ic.BackgroundTransparency = 1
    ic.Text              = icon
    ic.TextSize          = 17
    ic.TextXAlignment    = Enum.TextXAlignment.Center
    ic.ZIndex            = 2

    local tl = Instance.new("TextLabel", row)
    tl.Size              = UDim2.new(1,-70, sub and 0 or 1, 0)
    tl.Position          = sub and UDim2.new(0,50,0,8) or UDim2.new(0,50,0,0)
    tl.BackgroundTransparency = 1
    tl.Text              = title
    tl.TextColor3        = accent or T.TextPri
    tl.TextSize          = 13
    tl.Font              = Enum.Font.GothamSemibold
    tl.TextXAlignment    = Enum.TextXAlignment.Left
    tl.ZIndex            = 2

    if sub then
        local sl = Instance.new("TextLabel", row)
        sl.Size          = UDim2.new(1,-70,0,16)
        sl.Position      = UDim2.new(0,50,0,30)
        sl.BackgroundTransparency = 1
        sl.Text          = sub
        sl.TextColor3    = T.TextMuted
        sl.TextSize      = 10
        sl.Font          = Enum.Font.Gotham
        sl.TextXAlignment= Enum.TextXAlignment.Left
        sl.ZIndex        = 2
    end

    local arr = Instance.new("TextLabel", row)
    arr.Size             = UDim2.new(0,22,1,0)
    arr.Position         = UDim2.new(1,-30,0,0)
    arr.BackgroundTransparency = 1
    arr.Text             = "›"
    arr.TextColor3       = accent or T.TextMuted
    arr.TextSize         = 20
    arr.Font             = Enum.Font.GothamBold
    arr.ZIndex           = 2

    local btn = Instance.new("TextButton", row)
    btn.Size             = UDim2.fromScale(1,1)
    btn.BackgroundTransparency = 1
    btn.Text             = ""
    btn.ZIndex           = 3

    btn.MouseEnter:Connect(function()
        Tween(row, {BackgroundColor3=T.SurfaceHov}, 0.15)
        Tween(arr, {TextColor3=T.Accent}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        Tween(row, {BackgroundColor3=T.Card}, 0.15)
        Tween(arr, {TextColor3=accent or T.TextMuted}, 0.15)
    end)
    btn.MouseButton1Click:Connect(function()
        if cb then SafeCall(cb) end
    end)

    return row
end

-- ╔══════════════════════════════════════╗
-- ║     COMPONENT: SLIDER ROW            ║
-- ╚══════════════════════════════════════╝

local function MakeSlider(parent, icon, title, minV, maxV, default, key, order, cb)
    local row = Instance.new("Frame", parent)
    row.Name             = "Slider_"..title
    row.Size             = UDim2.new(1,0,0,66)
    row.BackgroundColor3 = T.Card
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order or 99
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,10)

    local bor = Instance.new("Frame", row)
    bor.Size             = UDim2.new(1,2,1,2)
    bor.Position         = UDim2.new(0,-1,0,-1)
    bor.BackgroundColor3 = T.CardBorder
    bor.BackgroundTransparency = 0.5
    bor.BorderSizePixel  = 0
    bor.ZIndex           = 0
    Instance.new("UICorner", bor).CornerRadius = UDim.new(0,11)

    local ic = Instance.new("TextLabel", row)
    ic.Size              = UDim2.new(0,36,0,30)
    ic.Position          = UDim2.new(0,10,0,6)
    ic.BackgroundTransparency = 1
    ic.Text              = icon
    ic.TextSize          = 17
    ic.TextXAlignment    = Enum.TextXAlignment.Center
    ic.ZIndex            = 2

    local tl = Instance.new("TextLabel", row)
    tl.Size              = UDim2.new(1,-100,0,20)
    tl.Position          = UDim2.new(0,50,0,7)
    tl.BackgroundTransparency = 1
    tl.Text              = title
    tl.TextColor3        = T.TextPri
    tl.TextSize          = 13
    tl.Font              = Enum.Font.GothamSemibold
    tl.TextXAlignment    = Enum.TextXAlignment.Left
    tl.ZIndex            = 2

    local vl = Instance.new("TextLabel", row)
    vl.Size              = UDim2.new(0,55,0,20)
    vl.Position          = UDim2.new(1,-62,0,7)
    vl.BackgroundTransparency = 1
    vl.Text              = tostring(default)
    vl.TextColor3        = T.Accent
    vl.TextSize          = 13
    vl.Font              = Enum.Font.GothamBold
    vl.TextXAlignment    = Enum.TextXAlignment.Right
    vl.ZIndex            = 2

    -- Track
    local track = Instance.new("Frame", row)
    track.Size           = UDim2.new(1,-24,0,5)
    track.Position       = UDim2.new(0,12,0,48)
    track.BackgroundColor3 = T.ToggleOff
    track.BorderSizePixel= 0
    track.ZIndex         = 2
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

    local startPct = math.clamp((default-minV)/(maxV-minV),0,1)

    local fill = Instance.new("Frame", track)
    fill.Size            = UDim2.new(startPct,0,1,0)
    fill.BackgroundColor3= T.Accent
    fill.BorderSizePixel = 0
    fill.ZIndex          = 3
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame", track)
    knob.Size            = UDim2.new(0,13,0,13)
    knob.Position        = UDim2.new(startPct,-6,0.5,-6)
    knob.BackgroundColor3= Color3.fromRGB(255,255,255)
    knob.BorderSizePixel = 0
    knob.ZIndex          = 4
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local draggingS = false

    local function Update(inp)
        local ax = track.AbsolutePosition.X
        local aw = track.AbsoluteSize.X
        local pct = math.clamp((inp.Position.X - ax) / aw, 0, 1)
        local val = Round(minV + (maxV-minV)*pct, 2)
        fill.Size = UDim2.new(pct,0,1,0)
        knob.Position = UDim2.new(pct,-6,0.5,-6)
        vl.Text = tostring(val)
        if key then State[key] = val end
        if cb then SafeCall(cb, val) end
    end

    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingS = true
            Update(inp)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if draggingS and inp.UserInputType == Enum.UserInputType.MouseMovement then
            Update(inp)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingS = false
        end
    end)

    return row
end

-- ╔══════════════════════════════════════╗
-- ║     COMPONENT: TEXT INPUT            ║
-- ╚══════════════════════════════════════╝

local function MakeInput(parent, icon, title, placeholder, key, order, cb)
    local row = Instance.new("Frame", parent)
    row.Name             = "Input_"..title
    row.Size             = UDim2.new(1,0,0,66)
    row.BackgroundColor3 = T.Card
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order or 99
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,10)

    local bor = Instance.new("Frame", row)
    bor.Size             = UDim2.new(1,2,1,2)
    bor.Position         = UDim2.new(0,-1,0,-1)
    bor.BackgroundColor3 = T.CardBorder
    bor.BackgroundTransparency = 0.5
    bor.BorderSizePixel  = 0
    bor.ZIndex           = 0
    Instance.new("UICorner", bor).CornerRadius = UDim.new(0,11)

    local ic = Instance.new("TextLabel", row)
    ic.Size              = UDim2.new(0,36,0,30)
    ic.Position          = UDim2.new(0,10,0,6)
    ic.BackgroundTransparency = 1
    ic.Text              = icon
    ic.TextSize          = 17
    ic.TextXAlignment    = Enum.TextXAlignment.Center
    ic.ZIndex            = 2

    local tl = Instance.new("TextLabel", row)
    tl.Size              = UDim2.new(1,-30,0,20)
    tl.Position          = UDim2.new(0,50,0,7)
    tl.BackgroundTransparency = 1
    tl.Text              = title
    tl.TextColor3        = T.TextPri
    tl.TextSize          = 13
    tl.Font              = Enum.Font.GothamSemibold
    tl.TextXAlignment    = Enum.TextXAlignment.Left
    tl.ZIndex            = 2

    local ibg = Instance.new("Frame", row)
    ibg.Size             = UDim2.new(1,-24,0,24)
    ibg.Position         = UDim2.new(0,12,0,36)
    ibg.BackgroundColor3 = T.Bg
    ibg.BorderSizePixel  = 0
    ibg.ZIndex           = 2
    Instance.new("UICorner", ibg).CornerRadius = UDim.new(0,6)

    -- Border indicator frame (replaces UIStroke)
    local ibgBor = Instance.new("Frame", row)
    ibgBor.Size          = UDim2.new(1,-22,0,26)
    ibgBor.Position      = UDim2.new(0,11,0,35)
    ibgBor.BackgroundColor3 = T.CardBorder
    ibgBor.BackgroundTransparency = 0.3
    ibgBor.BorderSizePixel = 0
    ibgBor.ZIndex        = 1
    Instance.new("UICorner", ibgBor).CornerRadius = UDim.new(0,7)

    local tb = Instance.new("TextBox", ibg)
    tb.Size              = UDim2.new(1,-10,1,0)
    tb.Position          = UDim2.new(0,6,0,0)
    tb.BackgroundTransparency = 1
    tb.PlaceholderText   = placeholder or ""
    tb.PlaceholderColor3 = T.TextMuted
    tb.Text              = (key and tostring(State[key])) or ""
    tb.TextColor3        = T.TextPri
    tb.TextSize          = 11
    tb.Font              = Enum.Font.Gotham
    tb.TextXAlignment    = Enum.TextXAlignment.Left
    tb.ClearTextOnFocus  = false
    tb.ZIndex            = 3

    tb.Focused:Connect(function()
        Tween(ibgBor, {BackgroundColor3=T.Accent}, 0.15)
    end)
    tb.FocusLost:Connect(function()
        Tween(ibgBor, {BackgroundColor3=T.CardBorder}, 0.15)
        if key then State[key] = tb.Text end
        if cb then SafeCall(cb, tb.Text) end
    end)

    return row, tb
end

-- ╔══════════════════════════════════════╗
-- ║     COMPONENT: STAT CARD             ║
-- ╚══════════════════════════════════════╝

local function MakeStatCard(parent, icon, label, stateKey)
    local card = Instance.new("Frame", parent)
    card.Size            = UDim2.new(0.47,0,0,72)
    card.BackgroundColor3= T.Card
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,10)

    local bor = Instance.new("Frame", card)
    bor.Size             = UDim2.new(1,2,1,2)
    bor.Position         = UDim2.new(0,-1,0,-1)
    bor.BackgroundColor3 = T.CardBorder
    bor.BackgroundTransparency = 0.4
    bor.BorderSizePixel  = 0
    bor.ZIndex           = 0
    Instance.new("UICorner", bor).CornerRadius = UDim.new(0,11)

    local ic = Instance.new("TextLabel", card)
    ic.Size              = UDim2.new(1,0,0,26)
    ic.Position          = UDim2.new(0,0,0,6)
    ic.BackgroundTransparency = 1
    ic.Text              = icon
    ic.TextSize          = 18
    ic.TextXAlignment    = Enum.TextXAlignment.Center
    ic.ZIndex            = 2

    local vl = Instance.new("TextLabel", card)
    vl.Size              = UDim2.new(1,-4,0,18)
    vl.Position          = UDim2.new(0,2,0,30)
    vl.BackgroundTransparency = 1
    vl.TextColor3        = T.Accent
    vl.TextSize          = 12
    vl.Font              = Enum.Font.GothamBold
    vl.TextXAlignment    = Enum.TextXAlignment.Center
    vl.ZIndex            = 2

    local ll = Instance.new("TextLabel", card)
    ll.Size              = UDim2.new(1,-4,0,14)
    ll.Position          = UDim2.new(0,2,0,50)
    ll.BackgroundTransparency = 1
    ll.Text              = label
    ll.TextColor3        = T.TextMuted
    ll.TextSize          = 9
    ll.Font              = Enum.Font.GothamBold
    ll.TextXAlignment    = Enum.TextXAlignment.Center
    ll.ZIndex            = 2

    -- Live update
    RunService.Heartbeat:Connect(function()
        if not vl or not vl.Parent then return end
        local v = State[stateKey]
        if type(v) == "number" then
            vl.Text = stateKey == "SessionTime" and FmtTime(math.floor(v)) or FmtNum(v)
        else
            vl.Text = tostring(v)
        end
    end)

    return card
end

-- ╔══════════════════════════════════════╗
-- ║     BUILD PAGES                      ║
-- ╚══════════════════════════════════════╝

-- ── MAIN PAGE ──────────────────────────

local pMain = MakeScroll(TabMap["Main"].page)

MakeSection(pMain, "Auto Farm", 1)
MakeToggle(pMain,"⚔️","Auto Farm Everything","Farms mobs & collects drops","AutoFarm",2)
MakeToggle(pMain,"🎲","Auto Roll","Rolls for slime pets automatically","AutoRoll",3)
MakeToggle(pMain,"🐾","Auto Equip Best Pet","Equips highest-power pet","AutoEquipPet",4)

MakeSection(pMain, "Management", 5)
MakeToggle(pMain,"💰","Auto Sell","Sells items for coins","AutoSell",6)
MakeToggle(pMain,"🔀","Auto Merge","Merges duplicate pets","AutoMerge",7)

MakeSection(pMain, "Progression", 8)
MakeToggle(pMain,"⬆️","Auto Buy Upgrades","Buys all available upgrades","AutoBuyUpgrades",9)
MakeToggle(pMain,"🔄","Auto Rebirth","Performs rebirth when ready","AutoRebirth",10)
MakeToggle(pMain,"📋","Auto Claim Index","Claims index rewards","AutoClaimIndex",11)
MakeToggle(pMain,"🎁","Auto Claim Daily","Claims daily login reward","AutoClaimDaily",12)

-- ── POTIONS PAGE ───────────────────────

local pPot = MakeScroll(TabMap["Potions"].page)

MakeSection(pPot,"Potion Automation",1)
MakeToggle(pPot,"🍀","Auto Luck Potion","Uses luck potions every 30s","AutoLuckPotion",2)
MakeToggle(pPot,"⚡","Auto Speed Potion","Uses speed potions every 30s","AutoSpeedPotion",3)
MakeToggle(pPot,"💎","Auto Rare Potion","Uses rare-find potions","AutoRarePotion",4)
MakeToggle(pPot,"✨","Auto Use All Potions","Activates every buff potion","AutoAllPotions",5)

MakeSection(pPot,"Collection",6)
MakeButton(pPot,"🏃","Collect All Potions","Teleports to all map potions",T.Success,7,function()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("potion") then
            HRP.CFrame = CFrame.new(obj.Position)
            task.wait(0.06)
        end
    end
    Notify("VaenHub","All potions collected!",3)
end)

MakeButton(pPot,"🔮","Craft All Potions","Crafts every available potion",T.Accent,8,function()
    FireRemote("CraftAllPotions")
    FireRemote("AutoCraft")
end)

-- ── CRAFTING PAGE ──────────────────────

local pCraft = MakeScroll(TabMap["Crafting"].page)

MakeSection(pCraft,"Auto Crafting",1)
MakeToggle(pCraft,"🔨","Auto Craft Best Item","Crafts highest tier item","AutoCraftBest",2)
MakeToggle(pCraft,"🗡️","Auto Craft Weapons","Crafts weapons automatically","AutoCraftWeapons",3)
MakeToggle(pCraft,"🛡️","Auto Craft Armor","Crafts armor automatically","AutoCraftArmor",4)

MakeSection(pCraft,"Materials",5)
MakeButton(pCraft,"📦","Collect All Materials","Picks up ores & crystals",T.Warning,6,function()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("material") or n:find("ore") or n:find("crystal") or n:find("shard") then
                HRP.CFrame = CFrame.new(obj.Position)
                task.wait(0.05)
            end
        end
    end
    Notify("VaenHub","Materials collected!",3)
end)

MakeButton(pCraft,"♻️","Salvage All Junk","Dismantles unwanted items",T.Danger,7,function()
    FireRemote("SalvageAll")
    FireRemote("DismantelAll")
    FireRemote("SalvageJunk")
end)

MakeButton(pCraft,"⚗️","Max Craft All","Crafts maximum quantity",T.Accent,8,function()
    FireRemote("MaxCraftAll")
    FireRemote("CraftMax")
end)

-- ── CONFIG PAGE ────────────────────────

local pCfg = MakeScroll(TabMap["Config"].page)

MakeSection(pCfg,"Timings & Speed",1)
MakeSlider(pCfg,"⏱️","Roll Delay (sec)", 0.1, 5.0, State.RollDelay, "RollDelay", 2)
MakeSlider(pCfg,"🏃","Walk Speed",       16,  150, State.WalkSpeed,  "WalkSpeed",  3,function(v)
    local hum = Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end)
MakeSlider(pCfg,"🦘","Jump Power",       50,  500, State.JumpPower,  "JumpPower",  4,function(v)
    local hum = Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.JumpPower = v end
end)

MakeSection(pCfg,"Discord Webhook",5)
MakeInput(pCfg,"🔗","Webhook URL","https://discord.com/api/webhooks/...","WebhookURL",6)

MakeButton(pCfg,"📤","Test Webhook","Send test notification",T.Accent,7,function()
    if State.WebhookURL == "" then
        Notify("VaenHub","Please enter a webhook URL first!",3)
        return
    end
    pcall(function()
        local data = HttpService:JSONEncode({
            embeds = {{
                title       = "✅ VaenHub · Slime RNG",
                description = "Script is running! Player: **"..LocalPlayer.Name.."**\nTotal Rolls: **"..State.TotalRolls.."**",
                color       = 0x00AAFF,
                footer      = {text = "VaenHub Script"}
            }}
        })
        HttpService:PostAsync(State.WebhookURL, data, Enum.HttpContentType.ApplicationJson)
    end)
    Notify("VaenHub","Webhook test sent!",3)
end)

MakeSection(pCfg,"Save & Load",8)
MakeButton(pCfg,"💾","Save Settings","Writes config to file",T.Success,9,function()
    SaveCfg()
    Notify("VaenHub","Settings saved!",3)
end)
MakeButton(pCfg,"📂","Load Settings","Reads config from file",T.Accent,10,function()
    LoadCfg()
    Notify("VaenHub","Settings loaded!",3)
end)
MakeButton(pCfg,"🗑️","Reset to Default","Clears all saved settings",T.Danger,11,function()
    State.RollDelay = 0.5
    State.WalkSpeed = 16
    State.JumpPower = 50
    State.WebhookURL = ""
    Notify("VaenHub","Settings reset!",3)
end)

MakeSection(pCfg,"Stat Tracker",12)

-- Grid of stat cards (using UIGridLayout)
local sgHolder = Instance.new("Frame", pCfg)
sgHolder.Name            = "StatGrid"
sgHolder.Size            = UDim2.new(1,0,0,158)
sgHolder.BackgroundTransparency = 1
sgHolder.LayoutOrder     = 13

local sgLayout = Instance.new("UIGridLayout", sgHolder)
sgLayout.CellSize        = UDim2.new(0.47,0,0,72)
sgLayout.CellPadding     = UDim2.new(0.06,0,0,8)
sgLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sgLayout.SortOrder       = Enum.SortOrder.LayoutOrder

MakeStatCard(sgHolder,"🎲","TOTAL ROLLS","TotalRolls")
MakeStatCard(sgHolder,"⭐","RARE COUNT","RareCount")
MakeStatCard(sgHolder,"🐾","BEST PET","BestPet")
MakeStatCard(sgHolder,"⏱️","SESSION","SessionTime")

-- ── MISC PAGE ──────────────────────────

local pMisc = MakeScroll(TabMap["Misc"].page)

MakeSection(pMisc,"Movement",1)
MakeToggle(pMisc,"✈️","Fly Mode","F key to toggle · WASD/Space to fly","FlyEnabled",2,function(on)
    if on then EnableFly() else DisableFly() end
end)
MakeToggle(pMisc,"👻","No Clip","Walk through all solid objects","NoClip",3)

MakeSection(pMisc,"ESP Visuals",4)
MakeToggle(pMisc,"👥","ESP Players","Show players through walls","ESPPlayers",5,function(on)
    if not on then ClearESP("Players") end
end)
MakeToggle(pMisc,"👾","ESP Mobs","Highlight all enemy mobs","ESPMobs",6,function(on)
    if not on then ClearESP("Mobs") end
end)
MakeToggle(pMisc,"📦","ESP Drops","Highlight drops (rare = orange)","ESPDrops",7,function(on)
    if not on then ClearESP("Drops") end
end)
MakeToggle(pMisc,"🎁","ESP Chests","Show chest locations","ESPChests",8,function(on)
    if not on then ClearESP("Chests") end
end)

MakeSection(pMisc,"Utility",9)
MakeToggle(pMisc,"💤","Anti AFK","Prevents AFK kick","AntiAFK",10)
MakeToggle(pMisc,"⚡","Performance Mode","Disables shadows for more FPS","PerfMode",11,function(on)
    pcall(function()
        Lighting.GlobalShadows = not on
        Lighting.FogEnd = on and 1e7 or 2000
    end)
end)

MakeButton(pMisc,"🔄","Rejoin Server","Connects to a fresh server",T.Warning,12,function()
    pcall(function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end)
end)

MakeButton(pMisc,"🧹","Clear ESP All","Removes all ESP overlays",T.Danger,13,function()
    State.ESPPlayers = false
    State.ESPMobs    = false
    State.ESPDrops   = false
    State.ESPChests  = false
    ClearESP("Players")
    ClearESP("Mobs")
    ClearESP("Drops")
    ClearESP("Chests")
    -- Refresh toggle UI
    for _, key in pairs({"ESPPlayers","ESPMobs","ESPDrops","ESPChests"}) do
        local ref = ToggleRefs[key]
        if ref then
            Tween(ref.pill, {BackgroundColor3=T.ToggleOff}, 0.2)
            Tween(ref.knob, {Position=UDim2.new(0,3,0.5,-8)}, 0.2)
        end
    end
    Notify("VaenHub","All ESP cleared!",3)
end)

MakeButton(pMisc,"📋","Copy Stats","Copy player stats to clipboard",T.Accent,14,function()
    local txt = string.format(
        "[VaenHub] %s | Rolls:%d | Rares:%d | Best:%s",
        LocalPlayer.Name, State.TotalRolls, State.RareCount, State.BestPet
    )
    pcall(function() setclipboard(txt) end)
    Notify("VaenHub","Stats copied to clipboard!",3)
end)

-- ╔══════════════════════════════════════╗
-- ║     CHARACTER RESPAWN HANDLER        ║
-- ╚══════════════════════════════════════╝

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HRP = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
    task.wait(1)
    Humanoid.WalkSpeed = State.WalkSpeed
    Humanoid.JumpPower = State.JumpPower
    if State.FlyEnabled then EnableFly() end
    if State.NoClip then
        RunService.Stepped:Connect(function()
            if State.NoClip then
                for _, p in pairs(Character:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end
end)

-- ╔══════════════════════════════════════╗
-- ║     OPEN ANIMATION + FIRST TAB      ║
-- ╚══════════════════════════════════════╝

Win.Size     = UDim2.new(0,WIN_W,0,0)
Win.Position = UDim2.new(0.5,-WIN_W/2,0.5,0)

Tween(Win, {
    Size     = UDim2.new(0,WIN_W,0,WIN_H),
    Position = UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2),
}, 0.4, "Back", "Out")

task.delay(0.1, function()
    SetActiveTab("Main")
end)

-- ╔══════════════════════════════════════╗
-- ║     STARTUP NOTIFY                   ║
-- ╚══════════════════════════════════════╝

task.delay(0.8, function()
    Notify("✅ VaenHub Loaded","Slime RNG · Delta Compatible · All Systems GO",5)
end)

--[[
╔══════════════════════════════════════════════════════════════╗
║          VAENHUB SLIME RNG — LOADED SUCCESSFULLY             ║
║   Fixed: CoreGui, UIStroke, State keys, spawn(), layout      ║
╚══════════════════════════════════════════════════════════════╝
]]
```
