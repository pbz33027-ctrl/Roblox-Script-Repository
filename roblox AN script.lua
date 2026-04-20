local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Translations = {
    ["zh"] = {
        windowTitle = "RAKE 游戏助手",
        loadingTitle = "脚本加载中...",
        mainTab = "玩家增强",
        visualsTab = "视觉辅助",
        settingsTab = "设置",
        infiniteJump = "开启无限跳跃",
        speedToggle = "开启速度调整",
        infiniteStamina = "无限耐力",
        godMode = "锁血模式",
        speedSlider = "移动速度",
        jumpSlider = "跳跃力量",
        fullBright = "游戏全亮",
        noFog = "无雾模式",
        playerESP = "显示玩家位置",
        rakeESP = "显示RAKE位置",
        flareESP = "显示信号枪位置",
        lootboxESP = "显示战利品箱位置",
        languageSetting = "语言",
        scriptBy = "脚本作者: CN_154LH"
    },
    ["en"] = {
        windowTitle = "RAKE Game Assistant",
        loadingTitle = "Script Loading...",
        mainTab = "Player Enhancements",
        visualsTab = "Visual Aids",
        settingsTab = "Settings",
        infiniteJump = "Enable Infinite Jump",
        speedToggle = "Enable Speed Adjustment",
        infiniteStamina = "Infinite Stamina",
        godMode = "God Mode",
        speedSlider = "Movement Speed",
        jumpSlider = "Jump Power",
        fullBright = "Full Bright",
        noFog = "No Fog Mode",
        playerESP = "Show Player Positions",
        rakeESP = "Show RAKE Position",
        flareESP = "Show Flare Gun Positions",
        lootboxESP = "Show Lootbox Positions",
        languageSetting = "Language",
        scriptBy = "Script by: CN_154LH"
    }
}

local currentLanguage = "zh"

local function switchLanguage(lang)
    if Translations[lang] then
        currentLanguage = lang
        return true
    end
    return false
end

local function T(key)
    return Translations[currentLanguage][key] or key
end

local Window = Rayfield:CreateWindow({
    Name = T("windowTitle"),
    LoadingTitle = T("loadingTitle"),
    LoadingSubtitle = "by 助手",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

local MainTab = Window:CreateTab(T("mainTab"), nil)
local VisualsTab = Window:CreateTab(T("visualsTab"), nil)
local SettingsTab = Window:CreateTab(T("settingsTab"), nil)

local InfiniteJumpEnabled = false
local SpeedEnabled = false
local InfiniteStaminaEnabled = false
local GodModeEnabled = false
local PlayerESPEnabled = false
local RakeESPEnabled = false
local FlareGunESPEnabled = false
local LootboxESPEnabled = false
local FullBrightEnabled = false
local NoFogEnabled = false

local PlayerESPObjects = {}
local ItemESPObjects = {}
local RakeESPObjects = {}
local FullBrightConnection
local OriginalFogStart
local OriginalFogEnd
local OriginalFogColor
local StaminaConnection
local GodModeConnection

local currentWalkSpeed = 50
local currentJumpPower = 100

local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local runService = game:GetService("RunService")

local lighting = game:GetService("Lighting")
OriginalFogStart = lighting.FogStart
OriginalFogEnd = lighting.FogEnd
OriginalFogColor = lighting.FogColor

local function applyCharacterSettings(character)
    local humanoid = character:WaitForChild("Humanoid")
    if SpeedEnabled then
        humanoid.WalkSpeed = currentWalkSpeed
    else
        humanoid.WalkSpeed = 16
    end
    humanoid.JumpPower = currentJumpPower
end

localPlayer.CharacterAdded:Connect(function(character)
    applyCharacterSettings(character)
end)

if localPlayer.Character then
    applyCharacterSettings(localPlayer.Character)
end

game:GetService("UserInputService").JumpRequest:Connect(function()
    if InfiniteJumpEnabled then
        local player = game:GetService("Players").LocalPlayer
        if player and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:ChangeState("Jumping")
            end
        end
    end
end)

MainTab:CreateToggle({
    Name = T("infiniteJump"),
    CurrentValue = false,
    Callback = function(Value)
        InfiniteJumpEnabled = Value
    end,
})

MainTab:CreateToggle({
    Name = T("speedToggle"),
    CurrentValue = false,
    Callback = function(Value)
        SpeedEnabled = Value
        local player = game:GetService("Players").LocalPlayer
        if player and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if Value then
                    humanoid.WalkSpeed = currentWalkSpeed
                else
                    humanoid.WalkSpeed = 16
                end
            end
        end
    end,
})

MainTab:CreateToggle({
    Name = T("infiniteStamina"),
    CurrentValue = false,
    Callback = function(Value)
        InfiniteStaminaEnabled = Value
        if Value then
            StaminaConnection = runService.Heartbeat:Connect(function()
                if not InfiniteStaminaEnabled then
                    StaminaConnection:Disconnect()
                    return
                end
                
                local player = game:GetService("Players").LocalPlayer
                if player and player.Character then
                    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        if humanoid:GetAttribute("Stamina") then
                            humanoid:SetAttribute("Stamina", 100)
                        end
                        
                        if humanoid:GetAttribute("Energy") then
                            humanoid:SetAttribute("Energy", 100)
                        end
                        
                        if humanoid:GetAttribute("Exhausted") then
                            humanoid:SetAttribute("Exhausted", false)
                        end
                    end
                    
                    for _, script in pairs(player.Character:GetDescendants()) do
                        if script:IsA("Script") or script:IsA("LocalScript") then
                            if string.find(string.lower(script.Name), "stamina") or 
                               string.find(string.lower(script.Name), "energy") or
                               string.find(string.lower(script.Name), "exhaust") then
                                if script:FindFirstChild("Value") then
                                    local value = script:FindFirstChild("Value")
                                    if value:IsA("NumberValue") or value:IsA("IntValue") then
                                        value.Value = 100
                                    elseif value:IsA("BoolValue") then
                                        value.Value = false
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        else
            if StaminaConnection then
                StaminaConnection:Disconnect()
            end
        end
    end,
})

MainTab:CreateToggle({
    Name = T("godMode"),
    CurrentValue = false,
    Callback = function(Value)
        GodModeEnabled = Value
        if Value then
            GodModeConnection = runService.Heartbeat:Connect(function()
                if not GodModeEnabled then
                    GodModeConnection:Disconnect()
                    return
                end
                
                local player = game:GetService("Players").LocalPlayer
                if player and player.Character then
                    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid.Health = humanoid.MaxHealth
                    end
                end
            end)
        else
            if GodModeConnection then
                GodModeConnection:Disconnect()
            end
        end
    end,
})

MainTab:CreateSlider({
    Name = T("speedSlider"),
    Range = {16, 100},
    Increment = 1,
    Suffix = "速度",
    CurrentValue = currentWalkSpeed,
    Callback = function(Value)
        currentWalkSpeed = Value
        if SpeedEnabled then
            local player = game:GetService("Players").LocalPlayer
            if player and player.Character then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = Value
                end
            end
        end
    end,
})

MainTab:CreateSlider({
    Name = T("jumpSlider"),
    Range = {50, 200},
    Increment = 1,
    Suffix = "力量",
    CurrentValue = currentJumpPower,
    Callback = function(Value)
        currentJumpPower = Value
        local player = game:GetService("Players").LocalPlayer
        if player and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.JumpPower = Value
            end
        end
    end,
})

VisualsTab:CreateToggle({
    Name = T("fullBright"),
    CurrentValue = false,
    Callback = function(Value)
        FullBrightEnabled = Value
        if Value then
            FullBrightConnection = runService.RenderStepped:Connect(function()
                if not FullBrightEnabled then
                    FullBrightConnection:Disconnect()
                    return
                end
                
                local lighting = game:GetService("Lighting")
                lighting.Ambient = Color3.new(1, 1, 1)
                lighting.Brightness = 2
                lighting.GlobalShadows = false
                lighting.OutdoorAmbient = Color3.new(1, 1, 1)
                
                for _, obj in pairs(lighting:GetChildren()) do
                    if obj:IsA("Sky") then
                        obj:Destroy()
                    end
                end
            end)
        else
            if FullBrightConnection then
                FullBrightConnection:Disconnect()
            end
            local lighting = game:GetService("Lighting")
            lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
            lighting.Brightness = 1
            lighting.GlobalShadows = true
            lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
        end
    end,
})

VisualsTab:CreateToggle({
    Name = T("noFog"),
    CurrentValue = false,
    Callback = function(Value)
        NoFogEnabled = Value
        local lighting = game:GetService("Lighting")
        
        if Value then
            lighting.FogStart = 0
            lighting.FogEnd = 0
        else
            lighting.FogStart = OriginalFogStart
            lighting.FogEnd = OriginalFogEnd
            lighting.FogColor = OriginalFogColor
        end
    end,
})

local function createBillboardGUI(adornee, text, color)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.Adornee = adornee
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 500
    billboard.Parent = game.CoreGui
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = color
    textLabel.TextSize = 12
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.Parent = billboard
    
    return {Billboard = billboard, TextLabel = textLabel}
end

local function updateDistance(espObject, targetPart, name)
    if not espObject or not espObject.TextLabel then return end
    
    local localPlayer = game:GetService("Players").LocalPlayer
    if not localPlayer or not localPlayer.Character then return end
    
    local localRoot = localPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetPart
    
    if not localRoot or not targetRoot then return end
    
    local distance = (localRoot.Position - targetRoot.Position).Magnitude
    espObject.TextLabel.Text = string.format("%s\n%d studs", name, math.floor(distance))
end

local function createPlayerESP(player)
    if player == localPlayer then return end
    if not player or PlayerESPObjects[player] then return end

    local function setupCharacter(character)
        if not character then return end
        
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
        if not humanoidRootPart then return end
        
        local highlight = Instance.new("Highlight")
        highlight.Name = "PlayerESP"
        highlight.Adornee = character
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.3
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = game.CoreGui
        
        local billboard = createBillboardGUI(humanoidRootPart, player.Name, Color3.fromRGB(255, 0, 0))
        
        PlayerESPObjects[player] = {
            Highlight = highlight,
            Billboard = billboard.Billboard,
            TextLabel = billboard.TextLabel,
            Character = character
        }
        
        coroutine.wrap(function()
            while PlayerESPObjects[player] and character and character.Parent do
                updateDistance(billboard, humanoidRootPart, player.Name)
                wait(0.2)
            end
        end)()
    end

    if player.Character then
        setupCharacter(player.Character)
    end
    
    player.CharacterAdded:Connect(setupCharacter)
end

local function removePlayerESP(player)
    local espObject = PlayerESPObjects[player]
    if espObject then
        if espObject.Highlight then espObject.Highlight:Destroy() end
        if espObject.Billboard then espObject.Billboard:Destroy() end
        PlayerESPObjects[player] = nil
    end
end

local function togglePlayerESP(enable)
    PlayerESPEnabled = enable
    if enable then
        for _, player in ipairs(players:GetPlayers()) do
            createPlayerESP(player)
        end
        players.PlayerAdded:Connect(createPlayerESP)
    else
        for player, _ in pairs(PlayerESPObjects) do
            removePlayerESP(player)
        end
    end
end

VisualsTab:CreateToggle({
    Name = T("playerESP"),
    CurrentValue = false,
    Callback = function(Value)
        togglePlayerESP(Value)
    end,
})

VisualsTab:CreateToggle({
    Name = T("rakeESP"),
    CurrentValue = false,
    Callback = function(Value)
        RakeESPEnabled = Value
        if Value then
            scanForRakes()
        else
            removeRakeESP()
        end
    end,
})

VisualsTab:CreateToggle({
    Name = T("flareESP"),
    CurrentValue = false,
    Callback = function(Value)
        FlareGunESPEnabled = Value
        if Value then
            scanForFlareGuns()
        else
            removeESPByType("FlareGun")
        end
    end,
})

VisualsTab:CreateToggle({
    Name = T("lootboxESP"),
    CurrentValue = false,
    Callback = function(Value)
        LootboxESPEnabled = Value
        if Value then
            scanForLootboxes()
        else
            removeESPByType("Lootbox")
        end
    end,
})

function scanForRakes()
    if not RakeESPEnabled then return end
    
    for _, npc in pairs(workspace:GetChildren()) do
        if npc:IsA("Model") and (string.find(string.lower(npc.Name), "rake")) then
            addRakeESP(npc)
        end
    end
end

function addRakeESP(rakeModel)
    if RakeESPObjects[rakeModel] then return end

    local primaryPart = rakeModel.PrimaryPart or rakeModel:FindFirstChild("HumanoidRootPart")
    if not primaryPart then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "RakeESP"
    highlight.Adornee = rakeModel
    highlight.FillColor = Color3.fromRGB(139, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.3
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = game.CoreGui

    local billboard = createBillboardGUI(primaryPart, "RAKE", Color3.fromRGB(255, 0, 0))
    
    RakeESPObjects[rakeModel] = {
        Highlight = highlight,
        Billboard = billboard.Billboard,
        TextLabel = billboard.TextLabel,
        Model = rakeModel
    }
    
    coroutine.wrap(function()
        while RakeESPObjects[rakeModel] and rakeModel.Parent do
            updateDistance(billboard, primaryPart, "RAKE")
            wait(0.2)
        end
    end)()
end

function removeRakeESP()
    for rakeModel, espObject in pairs(RakeESPObjects) do
        if espObject.Highlight then espObject.Highlight:Destroy() end
        if espObject.Billboard then espObject.Billboard:Destroy() end
        RakeESPObjects[rakeModel] = nil
    end
end

function scanForFlareGuns()
    if not FlareGunESPEnabled then return end
    
    for _, item in pairs(workspace:GetChildren()) do
        if item:IsA("Model") and (string.find(string.lower(item.Name), "flare") or string.find(string.lower(item.Name), "signal")) then
            addItemESP(item, "信号枪", Color3.fromRGB(255, 255, 0))
        end
    end
end

function scanForLootboxes()
    if not LootboxESPEnabled then return end
    
    for _, item in pairs(workspace:GetChildren()) do
        if item:IsA("Model") and (string.find(string.lower(item.Name), "lootbox") or string.find(string.lower(item.Name), "loot") or string.find(string.lower(item.Name), "crate")) then
            addItemESP(item, "战利品箱", Color3.fromRGB(0, 255, 0))
        end
    end
end

function addItemESP(itemModel, itemType, color)
    if ItemESPObjects[itemModel] then return end

    local primaryPart = itemModel.PrimaryPart or itemModel:FindFirstChild("Handle") or itemModel:FindFirstChildWhichIsA("BasePart")
    if not primaryPart then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = itemType .. "ESP"
    highlight.Adornee = itemModel
    highlight.FillColor = color
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.3
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = game.CoreGui

    local billboard = createBillboardGUI(primaryPart, itemType, color)
    
    ItemESPObjects[itemModel] = {
        Highlight = highlight,
        Billboard = billboard.Billboard,
        TextLabel = billboard.TextLabel,
        Type = itemType,
        Model = itemModel
    }
    
    coroutine.wrap(function()
        while ItemESPObjects[itemModel] and itemModel.Parent do
            updateDistance(billboard, primaryPart, itemType)
            wait(0.2)
        end
    end)()
end

function removeItemESP(itemModel)
    local espObject = ItemESPObjects[itemModel]
    if espObject then
        if espObject.Highlight then espObject.Highlight:Destroy() end
        if espObject.Billboard then espObject.Billboard:Destroy() end
        ItemESPObjects[itemModel] = nil
    end
end

function removeESPByType(itemType)
    for itemModel, espObject in pairs(ItemESPObjects) do
        if espObject.Type == itemType then
            removeItemESP(itemModel)
        end
    end
end

players.PlayerRemoving:Connect(function(player)
    removePlayerESP(player)
end)

game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(character)
    character:WaitForChild("Humanoid")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if SpeedEnabled then
            humanoid.WalkSpeed = currentWalkSpeed
        else
            humanoid.WalkSpeed = 16
        end
        humanoid.JumpPower = currentJumpPower
    end
end)

local player = game:GetService("Players").LocalPlayer
if player and player.Character then
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if SpeedEnabled then
            humanoid.WalkSpeed = currentWalkSpeed
        else
            humanoid.WalkSpeed = 16
        end
        humanoid.JumpPower = currentJumpPower
    end
end

runService.Heartbeat:Connect(function()
    if RakeESPEnabled then
        scanForRakes()
    end
    if FlareGunESPEnabled then
        scanForFlareGuns()
    end
    if LootboxESPEnabled then
        scanForLootboxes()
    end
end)

SettingsTab:CreateDropdown({
    Name = T("languageSetting"),
    Options = {"中文", "English"},
    CurrentOption = "中文",
    Callback = function(Option)
        if Option == "English" then
            switchLanguage("en")
            Rayfield:Notify({
                Title = "Language Changed",
                Content = "Language set to English",
                Duration = 3
            })
        else
            switchLanguage("zh")
            Rayfield:Notify({
                Title = "语言已更改",
                Content = "语言已设置为中文",
                Duration = 3
            })
        end
    end,
})

VisualsTab:CreateSection("备注")
VisualsTab:CreateParagraph({Title = "", Content = T("scriptBy")})

Rayfield:Notify({
    Title = "脚本加载成功",
    Content = "请根据需要开启功能",
    Duration = 5,
})