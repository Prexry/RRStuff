getgenv().SecureMode = true

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

local WDO = RS:WaitForChild("WDOReplicatedStorage")
local Events = WDO:WaitForChild("Events")
local EnemyDamage = Events:WaitForChild("enemyDamage")
local SetAFK = Events:WaitForChild("setAFK")
local MapVote = Events:WaitForChild("mapVote")
local CheckRemotes = Events:WaitForChild("checkRemotes")

local Window = Rayfield:CreateWindow({
    Name = "Overdrive! | Fierce",
    Icon = 0,
    LoadingTitle = "Omnidrive",
    LoadingSubtitle = "by fierce",
    ShowText = "Rayfield",
    Theme = "Default",
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "Overdrive",
        FileName = "Overdrive"
    },
    Discord = {
        Enabled = true,
        Invite = "2bmd2jym5p",
        RememberJoins = false
    },
    KeySystem = true,
    KeySettings = {
        Title = "Overdrive!",
        Subtitle = "Suggestions welcome",
        Note = "Join: discord.gg/2bmd2jym5p",
        FileName = "overdrive-key",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"4Nu6Bo2Ma4CboIlduGNGuD18ukKnBi"}
    }
})

local TabMain = Window:CreateTab("Main", 4483362458)
local TabPlayer = Window:CreateTab("Player", "user-round")
local TabMap = Window:CreateTab("Map", "map")

local godMode = false
local antiAFK = false
local antiAFKConn = nil
local lockInPlace = false
local autoVote = false
local bringEnemies = false
local bringConn = nil
local childConn = nil
local selectedMap = nil
local mapChosen = false

local DEFAULT_WALKSPEED = 16
local DEFAULT_JUMPPOWER = 50
local currentWalkSpeed = DEFAULT_WALKSPEED
local currentJumpPower = DEFAULT_JUMPPOWER

local function getCharacter()
    return LP.Character or LP.CharacterAdded:Wait()
end

local function getHRP()
    local char = getCharacter()
    return char:WaitForChild("HumanoidRootPart")
end

local function applyMovement()
    local char = getCharacter()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = currentWalkSpeed
        hum.JumpPower = currentJumpPower
    end
end

local function resetMovementToDefault()
    currentWalkSpeed = DEFAULT_WALKSPEED
    currentJumpPower = DEFAULT_JUMPPOWER
    applyMovement()
end

LP.CharacterAdded:Connect(function()
    task.wait(0.25)
    applyMovement()
    if lockInPlace then
        task.spawn(function()
            local char = getCharacter()
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.Anchored = true
                    p.CanCollide = false
                end
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.PlatformStand = true
            end
        end)
    end
end)

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if method == "FireServer" then
        if godMode and self == EnemyDamage then
            return
        end
        if antiAFK and self == SetAFK then
            args[1] = false
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end))

TabMain:CreateToggle({
    Name = "God Mode",
    CurrentValue = false,
    Flag = "GodMode",
    Callback = function(v)
        godMode = v
    end
})

TabMain:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(v)
        antiAFK = v
        if antiAFKConn then
            antiAFKConn:Disconnect()
            antiAFKConn = nil
        end
        if v then
            SetAFK:FireServer(false)
            local last = 0
            antiAFKConn = RunService.Heartbeat:Connect(function()
                local t = os.clock()
                if t - last >= 2 then
                    SetAFK:FireServer(false)
                    last = t
                end
            end)
        end
    end
})

local wsSlider = TabPlayer:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 500},
    Increment = 1,
    CurrentValue = DEFAULT_WALKSPEED,
    Flag = "WalkSpeed",
    Callback = function(val)
        currentWalkSpeed = math.clamp(val, 16, 500)
        applyMovement()
    end
})

local jpSlider = TabPlayer:CreateSlider({
    Name = "Jump Power",
    Range = {50, 1000},
    Increment = 1,
    CurrentValue = DEFAULT_JUMPPOWER,
    Flag = "JumpPower",
    Callback = function(val)
        currentJumpPower = math.clamp(val, 50, 1000)
        applyMovement()
    end
})

TabPlayer:CreateButton({
    Name = "Reset LocalPlayer values",
    Callback = function()
        resetMovementToDefault()
        wsSlider:Set(DEFAULT_WALKSPEED)
        jpSlider:Set(DEFAULT_JUMPPOWER)
    end
})

TabPlayer:CreateButton({
    Name = "Reset Player",
    Callback = function()
        CheckRemotes:FireServer(true)
    end
})

TabPlayer:CreateToggle({
    Name = "Lock In Place",
    CurrentValue = false,
    Flag = "LockInPlace",
    Callback = function(v)
        lockInPlace = v
        if v then
            task.spawn(function()
                while lockInPlace do
                    local char = LP.Character
                    if char then
                        for _, p in ipairs(char:GetDescendants()) do
                            if p:IsA("BasePart") then
                                p.Anchored = true
                                p.CanCollide = false
                                p.AssemblyLinearVelocity = Vector3.zero
                                p.AssemblyAngularVelocity = Vector3.zero
                            end
                        end
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then
                            hum.PlatformStand = true
                            hum:ChangeState(Enum.HumanoidStateType.Physics)
                            hum.WalkSpeed = 0
                            hum.JumpPower = 0
                        end
                    end
                    RunService.Heartbeat:Wait()
                end
            end)
        else
            local char = LP.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.Anchored = false
                    end
                end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.PlatformStand = false
                    hum.WalkSpeed = currentWalkSpeed
                    hum.JumpPower = currentJumpPower
                end
            end
        end
    end
})

local maps = {
    "Belimir",
    "Slime Cave",
    "Bandit Hideout",
    "Mushroom Forest",
    "Courtyard",
    "Overgrown Cavern",
    "Lyseria Desert",
    "Frozen Lake",
    "Skycloud Islands",
    "Alstigar Darkswamp"
}

TabMap:CreateToggle({
    Name = "Auto Vote",
    CurrentValue = false,
    Flag = "AutoVote",
    Callback = function(v)
        autoVote = v
        if v then
            task.spawn(function()
                while autoVote do
                    if mapChosen and selectedMap then
                        MapVote:FireServer(selectedMap)
                    end
                    task.wait(3)
                end
            end)
        end
    end
})

TabMap:CreateDropdown({
    Name = "Map",
    Options = maps,
    CurrentOption = {maps[1]},
    MultipleOptions = false,
    Flag = "MapDropdown",
    Callback = function(Options)
        selectedMap = Options[1]
        mapChosen = true
    end
})

local function noCollide(model)
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            d.CanCollide = false
        end
    end
end

local function bringAllEnemies()
    local hrp = getHRP()
    local pos = hrp.CFrame
    local offsetIndex = 0
    local container = Workspace:FindFirstChild("SpawnedEnemies")
    if container then
        for _, m in ipairs(container:GetChildren()) do
            if m:IsA("Model") then
                noCollide(m)
                local off = CFrame.new((offsetIndex % 4) * 3, 0, math.floor(offsetIndex / 4) * 3)
                pcall(function()
                    m:PivotTo(pos * off)
                end)
                offsetIndex += 1
            end
        end
    end
end

TabMap:CreateToggle({
    Name = "Auto Bring Enemies",
    CurrentValue = false,
    Flag = "AutoBringEnemies",
    Callback = function(v)
        bringEnemies = v
        if bringConn then
            bringConn:Disconnect()
            bringConn = nil
        end
        if childConn then
            childConn:Disconnect()
            childConn = nil
        end
        if v then
            bringConn = RunService.Heartbeat:Connect(function()
                bringAllEnemies()
            end)
            local container = Workspace:FindFirstChild("SpawnedEnemies")
            if container then
                childConn = container.ChildAdded:Connect(function(ch)
                    if bringEnemies and ch:IsA("Model") then
                        noCollide(ch)
                        pcall(function()
                            ch:PivotTo(getHRP().CFrame)
                        end)
                    end
                end)
            end
        end
    end
})

Rayfield:LoadConfiguration()
