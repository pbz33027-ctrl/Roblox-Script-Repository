local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "飞行控制台",
    LoadingTitle = "加载中...",
    LoadingSubtitle = "请稍等",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "FlyScript",
        FileName = "FlySettings"
    },
    KeySystem = false,
})

local FlyTab = Window:CreateTab("飞行控制", nil)
local PlayerESPTab = Window:CreateTab("玩家ESP", nil)
local TornadoESPTab = Window:CreateTab("龙卷风ESP", nil)
local FarmTab = Window:CreateTab("自动农场", nil)
local ToolsTab = Window:CreateTab("工具", nil)
local SettingsTab = Window:CreateTab("设置", nil)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local FLYING_SPEED = 50
local VERTICAL_SPEED = 25

local HIGHLIGHT_COLOR = Color3.fromRGB(0, 255, 255)
local HIGHLIGHT_TRANSPARENCY = 0.5
local currentHighlight = nil

local isFlying = false
local moveDirection = Vector3.new(0, 0, 0)
local verticalMove = 0

local PlayerESPEnabled = false
local NameESPEnabled = false
local HealthESPEnabled = false
local DistanceESPEnabled = false
local BoxESPEnabled = false
local playerEspList = {}

local TornadoESPEnabled = false
local tornadoEspList = {}
local tornadoObjects = {}

local FarmEnabled = false
local FarmMode = isMobile and "Touch" or "Keyboard"
local FarmKey = Enum.KeyCode.E
local FarmTouchX = 0.5
local FarmTouchY = 0.5
local FarmInterval = 1.0
local FarmRandomDelay = 0.2
local farmConnection = nil

local activeTouch = nil
local touchStartPos = nil
local touchCurrentDir = Vector3.new(0, 0, 0)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FlyMobileControls"
screenGui.Parent = player:WaitForChild("PlayerGui")

local touchAreaHint = Instance.new("Frame")
touchAreaHint.Size = UDim2.new(0, 200, 0, 200)
touchAreaHint.Position = UDim2.new(0, 10, 1, -210)
touchAreaHint.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
touchAreaHint.BackgroundTransparency = 0.7
touchAreaHint.BorderSizePixel = 0
touchAreaHint.Visible = isMobile
touchAreaHint.Parent = screenGui

local touchHintText = Instance.new("TextLabel")
touchHintText.Size = UDim2.new(1, 0, 1, 0)
touchHintText.BackgroundTransparency = 1
touchHintText.Text = "← 拖拽滑动 →"
touchHintText.TextColor3 = Color3.fromRGB(255, 255, 255)
touchHintText.TextScaled = true
touchHintText.Font = Enum.Font.Gothom
touchHintText.Parent = touchAreaHint

local upButton = Instance.new("TextButton")
upButton.Size = UDim2.new(0, 80, 0, 80)
upButton.Position = UDim2.new(1, -190, 1, -210)
upButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
upButton.BackgroundTransparency = 0.3
upButton.Text = "⬆"
upButton.TextColor3 = Color3.fromRGB(255, 255, 255)
upButton.TextScaled = true
upButton.Font = Enum.Font.GothomBold
upButton.BorderSizePixel = 0
upButton.Visible = isMobile
upButton.Parent = screenGui

local downButton = Instance.new("TextButton")
downButton.Size = UDim2.new(0, 80, 0, 80)
downButton.Position = UDim2.new(1, -100, 1, -210)
downButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
downButton.BackgroundTransparency = 0.3
downButton.Text = "⬇"
downButton.TextColor3 = Color3.fromRGB(255, 255, 255)
downButton.TextScaled = true
downButton.Font = Enum.Font.GothomBold
downButton.BorderSizePixel = 0
downButton.Visible = isMobile
downButton.Parent = screenGui

local function getCharacter()
    local char = player.Character
    if not char then return nil, nil, nil end
    return char, char:FindFirstChild("Humanoid"), char:FindFirstChild("HumanoidRootPart")
end

local function notify(title, content)
    Rayfield:Notify({
        Title = title,
        Content = content,
        Duration = 3,
    })
end

local function applyHighlight(character)
    if currentHighlight then currentHighlight:Destroy() end
    local highlight = Instance.new("Highlight")
    highlight.FillColor = HIGHLIGHT_COLOR
    highlight.FillTransparency = HIGHLIGHT_TRANSPARENCY
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.OutlineTransparency = 0.3
    highlight.Parent = character
    currentHighlight = highlight
end

local function removeHighlight()
    if currentHighlight then
        currentHighlight:Destroy()
        currentHighlight = nil
    end
end

local function killCharacter()
    local char = player.Character
    if char then
        char:BreakJoints()
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Health = 0
        end
        notify("⚠️ 自杀", "角色已死亡，即将重生")
    else
        notify("错误", "没有找到当前角色")
    end
end

local function simulateKeyPress(keyCode)
    VirtualInputManager:SendKeyEvent(true, keyCode, false, nil)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, keyCode, false, nil)
end

local function simulateTouchPress(xPercent, yPercent)
    local viewportSize = camera.ViewportSize
    local x = viewportSize.X * xPercent
    local y = viewportSize.Y * yPercent
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, Enum.UserInputType.Touch, nil, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, Enum.UserInputType.Touch, nil, 0)
end

local function startFarm()
    if farmConnection then
        farmConnection:Disconnect()
        farmConnection = nil
    end
    if not FarmEnabled then return end

    local lastTime = tick()
    farmConnection = RunService.Stepped:Connect(function()
        if not FarmEnabled then return end
        local now = tick()
        local intervalWithRandom = FarmInterval + (math.random() * 2 - 1) * FarmRandomDelay
        if intervalWithRandom < 0.1 then intervalWithRandom = 0.1 end
        if now - lastTime >= intervalWithRandom then
            lastTime = now
            if FarmMode == "Keyboard" then
                simulateKeyPress(FarmKey)
            else
                simulateTouchPress(FarmTouchX, FarmTouchY)
            end
        end
    end)
end

local function stopFarm()
    if farmConnection then
        farmConnection:Disconnect()
        farmConnection = nil
    end
end

local function restartFarm()
    if FarmEnabled then
        startFarm()
    else
        stopFarm()
    end
end

local function createPlayerESP(targetPlayer)
    if targetPlayer == player then return end
    local character = targetPlayer.Character
    if not character then return end
    local head = character:FindFirstChild("Head")
    if not head then return end

    if playerEspList[targetPlayer] then
        playerEspList[targetPlayer]:Destroy()
        playerEspList[targetPlayer] = nil
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlayerESP"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = billboard

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = targetPlayer.DisplayName
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothomBold
    nameLabel.Parent = mainFrame

    local healthLabel = Instance.new("TextLabel")
    healthLabel.Name = "HealthLabel"
    healthLabel.Size = UDim2.new(1, 0, 0.3, 0)
    healthLabel.Position = UDim2.new(0, 0, 0.4, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    healthLabel.TextScaled = true
    healthLabel.Font = Enum.Font.Gothom
    healthLabel.Parent = mainFrame

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.Size = UDim2.new(1, 0, 0.3, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.7, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    distanceLabel.TextScaled = true
    distanceLabel.Font = Enum.Font.Gothom
    distanceLabel.Parent = mainFrame

    local boxFrame = Instance.new("Frame")
    boxFrame.Name = "BoxFrame"
    boxFrame.Size = UDim2.new(1, 0, 1, 0)
    boxFrame.BackgroundTransparency = 0.8
    boxFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    boxFrame.BorderSizePixel = 2
    boxFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
    boxFrame.Visible = false
    boxFrame.Parent = mainFrame

    playerEspList[targetPlayer] = billboard

    local function updateHealth()
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            local health = math.floor(humanoid.Health)
            local maxHealth = humanoid.MaxHealth
            local healthPercent = health / maxHealth
            local healthColor = Color3.fromRGB(255 - (255 * healthPercent), 255 * healthPercent, 0)
            healthLabel.TextColor3 = healthColor
            healthLabel.Text = "❤️ " .. health .. "/" .. maxHealth
        else
            healthLabel.Text = "❤️ 已死亡"
        end
    end

    local function updateDistance()
        local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local targetRootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart and targetRootPart then
            local distance = (rootPart.Position - targetRootPart.Position).Magnitude
            distanceLabel.Text = "📏 " .. math.floor(distance) .. " studs"
        else
            distanceLabel.Text = "📏 -- studs"
        end
    end

    local function updateVisibility()
        nameLabel.Visible = NameESPEnabled
        healthLabel.Visible = HealthESPEnabled
        distanceLabel.Visible = DistanceESPEnabled
        boxFrame.Visible = BoxESPEnabled
        billboard.Enabled = PlayerESPEnabled
    end

    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.HealthChanged:Connect(updateHealth)
    end
    character:WaitForChild("Humanoid").HealthChanged:Connect(updateHealth)

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not billboard.Parent then
            connection:Disconnect()
            return
        end
        if PlayerESPEnabled then
            updateDistance()
            updateVisibility()
        else
            billboard.Enabled = false
        end
    end)

    updateHealth()
    updateDistance()
    updateVisibility()
end

local function refreshPlayerESP()
    for targetPlayer, gui in pairs(playerEspList) do
        if gui and gui.Parent then
            gui:Destroy()
        end
    end
    playerEspList = {}
    if not PlayerESPEnabled then return end
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= player then
            if targetPlayer.Character then
                createPlayerESP(targetPlayer)
            end
            targetPlayer.CharacterAdded:Connect(function()
                createPlayerESP(targetPlayer)
            end)
        end
    end
end

Players.PlayerAdded:Connect(function(newPlayer)
    if newPlayer ~= player then
        newPlayer.CharacterAdded:Connect(function()
            createPlayerESP(newPlayer)
        end)
    end
end)

local function isTornadoObject(obj)
    if not obj then return false end
    local nameLower = obj.Name:lower()
    if nameLower:find("tornado") or nameLower:find("storm") or nameLower:find("twister") or nameLower:find("龙卷风") then
        return true
    end
    if obj.Parent and obj.Parent.Name:lower():find("tornado") then
        return true
    end
    return false
end

local function getTornadoAttachPart(tornadoObj)
    if tornadoObj:IsA("BasePart") then
        return tornadoObj
    elseif tornadoObj:IsA("Model") then
        return tornadoObj.PrimaryPart or tornadoObj:FindFirstChild("HumanoidRootPart") or tornadoObj:FindFirstChild("Head") or tornadoObj:FindFirstChildWhichIsA("BasePart")
    end
    return nil
end

local function createTornadoESP(tornadoObj)
    local attachPart = getTornadoAttachPart(tornadoObj)
    if not attachPart then return nil end

    if tornadoEspList[tornadoObj] then
        tornadoEspList[tornadoObj].billboard:Destroy()
        tornadoEspList[tornadoObj] = nil
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TornadoESP"
    billboard.Adornee = attachPart
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = attachPart

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = billboard

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "🌪️ 龙卷风"
    nameLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothomBold
    nameLabel.Parent = mainFrame

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceLabel.TextScaled = true
    distanceLabel.Font = Enum.Font.Gothom
    distanceLabel.Parent = mainFrame

    local espData = {billboard = billboard, distanceLabel = distanceLabel, attachPart = attachPart}
    tornadoEspList[tornadoObj] = espData
    return espData
end

local function scanAndCreateTornadoESP()
    for obj, data in pairs(tornadoEspList) do
        if data.billboard then
            data.billboard:Destroy()
        end
    end
    tornadoEspList = {}
    tornadoObjects = {}

    if not TornadoESPEnabled then return end

    local function search(container)
        for _, obj in ipairs(container:GetChildren()) do
            if isTornadoObject(obj) then
                if not tornadoObjects[obj] then
                    tornadoObjects[obj] = true
                    createTornadoESP(obj)
                end
            elseif obj:IsA("Model") or obj:IsA("Folder") then
                search(obj)
            end
        end
    end
    search(workspace)
end

local function updateTornadoESP()
    if not TornadoESPEnabled then return end
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    for obj, data in pairs(tornadoEspList) do
        if data.billboard and data.billboard.Parent and data.distanceLabel then
            local attachPart = data.attachPart
            if attachPart and attachPart.Parent then
                local distance = (rootPart.Position - attachPart.Position).Magnitude
                data.distanceLabel.Text = string.format("📏 %.1f studs", distance)
                if distance < 50 then
                    data.distanceLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                elseif distance < 100 then
                    data.distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                else
                    data.distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            else
                data.billboard:Destroy()
                tornadoEspList[obj] = nil
            end
        end
    end
end

local function startTornadoScanner()
    while true do
        task.wait(5)
        if TornadoESPEnabled then
            scanAndCreateTornadoESP()
        end
    end
end
task.spawn(startTornadoScanner)

local function startFlight()
    local char, humanoid, rootPart = getCharacter()
    if not (char and humanoid and rootPart) then return end
    humanoid.PlatformStand = true
    isFlying = true
    applyHighlight(char)
    notify("飞行模式", "已开启")
end

local function stopFlight()
    local char, humanoid, rootPart = getCharacter()
    if char and humanoid then
        humanoid.PlatformStand = false
    end
    moveDirection = Vector3.new(0, 0, 0)
    verticalMove = 0
    touchCurrentDir = Vector3.new(0, 0, 0)
    isFlying = false
    removeHighlight()
    notify("飞行模式", "已关闭")
end

local function onInputBegan(input, gameProcessed)
    if gameProcessed or not isFlying or isMobile then return end
    local key = input.KeyCode
    if key == Enum.KeyCode.W then
        moveDirection = moveDirection + Vector3.new(0, 0, -1)
    elseif key == Enum.KeyCode.S then
        moveDirection = moveDirection + Vector3.new(0, 0, 1)
    elseif key == Enum.KeyCode.A then
        moveDirection = moveDirection + Vector3.new(-1, 0, 0)
    elseif key == Enum.KeyCode.D then
        moveDirection = moveDirection + Vector3.new(1, 0, 0)
    elseif key == Enum.KeyCode.Space then
        verticalMove = verticalMove + 1
    elseif key == Enum.KeyCode.LeftControl then
        verticalMove = verticalMove - 1
    end
end

local function onInputEnded(input)
    if not isFlying or isMobile then return end
    local key = input.KeyCode
    if key == Enum.KeyCode.W then
        moveDirection = moveDirection - Vector3.new(0, 0, -1)
    elseif key == Enum.KeyCode.S then
        moveDirection = moveDirection - Vector3.new(0, 0, 1)
    elseif key == Enum.KeyCode.A then
        moveDirection = moveDirection - Vector3.new(-1, 0, 0)
    elseif key == Enum.KeyCode.D then
        moveDirection = moveDirection - Vector3.new(1, 0, 0)
    elseif key == Enum.KeyCode.Space then
        verticalMove = verticalMove - 1
    elseif key == Enum.KeyCode.LeftControl then
        verticalMove = verticalMove + 1
    end
end

local function handleTouchBegan(input, gameProcessed)
    if gameProcessed or not isFlying or not isMobile then return end
    if input.UserInputType == Enum.UserInputType.Touch then
        local touchPos = input.Position
        if touchPos.X < camera.ViewportSize.X / 2 then
            if activeTouch == nil then
                activeTouch = input
                touchStartPos = touchPos
                touchCurrentDir = Vector3.new(0, 0, 0)
            end
        end
    end
end

local function handleTouchMoved(input, gameProcessed)
    if gameProcessed or not isFlying or not isMobile then return end
    if input.UserInputType == Enum.UserInputType.Touch and activeTouch == input then
        local currentPos = input.Position
        local delta = currentPos - touchStartPos
        local maxDelta = 150
        local dirX = math.clamp(delta.X / maxDelta, -1, 1)
        local dirZ = math.clamp(delta.Y / maxDelta, -1, 1)
        touchCurrentDir = Vector3.new(dirX, 0, -dirZ)
        local intensity = math.max(math.abs(dirX), math.abs(dirZ))
        touchAreaHint.BackgroundTransparency = 0.7 - intensity * 0.4
    end
end

local function handleTouchEnded(input, gameProcessed)
    if gameProcessed or not isFlying or not isMobile then return end
    if input.UserInputType == Enum.UserInputType.Touch and activeTouch == input then
        activeTouch = nil
        touchStartPos = nil
        touchCurrentDir = Vector3.new(0, 0, 0)
        touchAreaHint.BackgroundTransparency = 0.7
    end
end

local verticalHold = 0
upButton.MouseButton1Down:Connect(function()
    if not isFlying then return end
    verticalHold = 1
end)
upButton.MouseButton1Up:Connect(function()
    if verticalHold == 1 then verticalHold = 0 end
end)
downButton.MouseButton1Down:Connect(function()
    if not isFlying then return end
    verticalHold = -1
end)
downButton.MouseButton1Up:Connect(function()
    if verticalHold == -1 then verticalHold = 0 end
end)

local function updateFlight()
    if not isFlying then return end
    local char, humanoid, rootPart = getCharacter()
    if not (char and humanoid and rootPart) then return end
    local cam = workspace.CurrentCamera
    local camCFrame = cam.CFrame
    local move = Vector3.new(0, 0, 0)
    if isMobile then
        move = camCFrame:VectorToWorldSpace(touchCurrentDir) * FLYING_SPEED
        move = move + Vector3.new(0, verticalHold * VERTICAL_SPEED, 0)
    else
        move = camCFrame:VectorToWorldSpace(moveDirection) * FLYING_SPEED
        move = move + Vector3.new(0, verticalMove * VERTICAL_SPEED, 0)
    end
    rootPart.AssemblyLinearVelocity = move
end

UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)
UserInputService.InputBegan:Connect(handleTouchBegan)
UserInputService.InputChanged:Connect(handleTouchMoved)
UserInputService.InputEnded:Connect(handleTouchEnded)
RunService.RenderStepped:Connect(updateFlight)
RunService.RenderStepped:Connect(updateTornadoESP)

player.CharacterAdded:Connect(function(newChar)
    if isFlying then
        task.wait(0.5)
        local humanoid = newChar:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = true
            applyHighlight(newChar)
            notify("飞行模式", "已重新激活")
        end
    end
end)

FlyTab:CreateToggle({
    Name = "飞行模式",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(value)
        if value then startFlight() else stopFlight() end
    end,
})
FlyTab:CreateSlider({
    Name = "飞行速度 (studs/秒)",
    Range = {10, 200},
    Increment = 5,
    Suffix = " studs/秒",
    CurrentValue = FLYING_SPEED,
    Flag = "FlySpeedSlider",
    Callback = function(value) FLYING_SPEED = value end,
})
FlyTab:CreateSlider({
    Name = "升降速度 (studs/秒)",
    Range = {5, 100},
    Increment = 5,
    Suffix = " studs/秒",
    CurrentValue = VERTICAL_SPEED,
    Flag = "VerticalSpeedSlider",
    Callback = function(value) VERTICAL_SPEED = value end,
})

PlayerESPTab:CreateToggle({
    Name = "玩家ESP 总开关",
    CurrentValue = false,
    Flag = "PlayerESPMain",
    Callback = function(value)
        PlayerESPEnabled = value
        refreshPlayerESP()
    end,
})
PlayerESPTab:CreateToggle({
    Name = "显示玩家名称",
    CurrentValue = false,
    Flag = "NameESP",
    Callback = function(value)
        NameESPEnabled = value
        for _, gui in pairs(playerEspList) do
            local nameLabel = gui and gui:FindFirstChild("MainFrame") and gui.MainFrame:FindFirstChild("NameLabel")
            if nameLabel then nameLabel.Visible = value end
        end
    end,
})
PlayerESPTab:CreateToggle({
    Name = "显示血量",
    CurrentValue = false,
    Flag = "HealthESP",
    Callback = function(value)
        HealthESPEnabled = value
        for _, gui in pairs(playerEspList) do
            local healthLabel = gui and gui:FindFirstChild("MainFrame") and gui.MainFrame:FindFirstChild("HealthLabel")
            if healthLabel then healthLabel.Visible = value end
        end
    end,
})
PlayerESPTab:CreateToggle({
    Name = "显示距离 (studs)",
    CurrentValue = false,
    Flag = "DistanceESP",
    Callback = function(value)
        DistanceESPEnabled = value
        for _, gui in pairs(playerEspList) do
            local distanceLabel = gui and gui:FindFirstChild("MainFrame") and gui.MainFrame:FindFirstChild("DistanceLabel")
            if distanceLabel then distanceLabel.Visible = value end
        end
    end,
})
PlayerESPTab:CreateToggle({
    Name = "显示盒子边框",
    CurrentValue = false,
    Flag = "BoxESP",
    Callback = function(value)
        BoxESPEnabled = value
        for _, gui in pairs(playerEspList) do
            local boxFrame = gui and gui:FindFirstChild("MainFrame") and gui.MainFrame:FindFirstChild("BoxFrame")
            if boxFrame then boxFrame.Visible = value end
        end
    end,
})

TornadoESPTab:CreateToggle({
    Name = "龙卷风ESP 开关",
    CurrentValue = false,
    Flag = "TornadoESP",
    Callback = function(value)
        TornadoESPEnabled = value
        if value then
            scanAndCreateTornadoESP()
        else
            for _, data in pairs(tornadoEspList) do
                if data.billboard then data.billboard:Destroy() end
            end
            tornadoEspList = {}
            tornadoObjects = {}
        end
    end,
})
TornadoESPTab:CreateParagraph({
    Title = "龙卷风识别说明",
    Content = "脚本会自动识别名称中包含 tornado、storm、twister、龙卷风 的对象。\n如果游戏中的龙卷风使用其他名称，可以手动修改脚本中的 isTornadoObject 函数。",
})

local modeOptions = {"键盘模式", "触摸模式"}
FarmTab:CreateDropdown({
    Name = "输入模式",
    Options = modeOptions,
    CurrentOption = (FarmMode == "Keyboard") and "键盘模式" or "触摸模式",
    Flag = "FarmMode",
    Callback = function(option)
        FarmMode = (option == "键盘模式") and "Keyboard" or "Touch"
        if FarmEnabled then
            restartFarm()
        end
        notify("自动农场", "已切换至 " .. option)
    end,
})

local keyOptions = {"E", "F", "G", "R", "T", "Q", "LeftMouse", "RightMouse", "Space", "LeftControl"}
local keyMap = {
    E = Enum.KeyCode.E,
    F = Enum.KeyCode.F,
    G = Enum.KeyCode.G,
    R = Enum.KeyCode.R,
    T = Enum.KeyCode.T,
    Q = Enum.KeyCode.Q,
    LeftMouse = Enum.KeyCode.ButtonL,
    RightMouse = Enum.KeyCode.ButtonR,
    Space = Enum.KeyCode.Space,
    LeftControl = Enum.KeyCode.LeftControl,
}
FarmTab:CreateDropdown({
    Name = "键盘按键",
    Options = keyOptions,
    CurrentOption = "E",
    Flag = "FarmKeyDropdown",
    Callback = function(option)
        FarmKey = keyMap[option] or Enum.KeyCode.E
        if FarmEnabled and FarmMode == "Keyboard" then
            restartFarm()
            notify("自动农场", "按键已改为 " .. option)
        end
    end,
})

FarmTab:CreateSlider({
    Name = "触摸 X 坐标 (%)",
    Range = {0, 100},
    Increment = 5,
    Suffix = "%",
    CurrentValue = FarmTouchX * 100,
    Flag = "FarmTouchX",
    Callback = function(value)
        FarmTouchX = value / 100
    end,
})

FarmTab:CreateSlider({
    Name = "触摸 Y 坐标 (%)",
    Range = {0, 100},
    Increment = 5,
    Suffix = "%",
    CurrentValue = FarmTouchY * 100,
    Flag = "FarmTouchY",
    Callback = function(value)
        FarmTouchY = value / 100
    end,
})

FarmTab:CreateSlider({
    Name = "点击间隔 (秒)",
    Range = {0.2, 5},
    Increment = 0.1,
    Suffix = " 秒",
    CurrentValue = FarmInterval,
    Flag = "FarmInterval",
    Callback = function(value)
        FarmInterval = value
        if FarmEnabled then
            restartFarm()
        end
    end,
})

FarmTab:CreateSlider({
    Name = "随机延迟 (±秒)",
    Range = {0, 0.5},
    Increment = 0.05,
    Suffix = " 秒",
    CurrentValue = FarmRandomDelay,
    Flag = "FarmRandomDelay",
    Callback = function(value)
        FarmRandomDelay = value
        if FarmEnabled then
            restartFarm()
        end
    end,
})

FarmTab:CreateToggle({
    Name = "启用自动农场",
    CurrentValue = false,
    Flag = "FarmToggle",
    Callback = function(value)
        FarmEnabled = value
        if value then
            startFarm()
            local modeText = (FarmMode == "Keyboard") and "键盘按键" or "触摸屏幕"
            local detail = (FarmMode == "Keyboard") and tostring(FarmKey):gsub("Enum.KeyCode.", "") or string.format("(%.0f%%, %.0f%%)", FarmTouchX*100, FarmTouchY*100)
            notify("自动农场", string.format("已启用 (%s %s)，间隔 %.1f 秒", modeText, detail, FarmInterval))
        else
            stopFarm()
            notify("自动农场", "已禁用")
        end
    end,
})

FarmTab:CreateParagraph({
    Title = "📱 手机使用说明",
    Content = "• 键盘模式：模拟物理按键（需要蓝牙键盘或PC）\n• 触摸模式：自动点击屏幕指定位置（推荐手机使用）\n• 调整 X/Y 坐标可以点击游戏中的按钮区域\n• 建议先手动点击一下目标位置，记下大致百分比，再设置\n• 随机延迟可降低被检测风险",
})

ToolsTab:CreateButton({
    Name = "💀 自杀 / 死亡 💀",
    Callback = function()
        killCharacter()
    end,
})
ToolsTab:CreateParagraph({
    Title = "⚠️ 说明",
    Content = "当游戏禁用了角色重置功能时，可以使用此按钮强制自杀。\n点击后当前角色会立刻死亡并重生。",
})

SettingsTab:CreateColorPicker({
    Name = "高亮颜色",
    CurrentValue = HIGHLIGHT_COLOR,
    Flag = "HighlightColor",
    Callback = function(color)
        HIGHLIGHT_COLOR = color
        if isFlying and currentHighlight then currentHighlight.FillColor = color end
    end,
})
SettingsTab:CreateSlider({
    Name = "高亮透明度",
    Range = {0, 1},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = HIGHLIGHT_TRANSPARENCY,
    Flag = "HighlightTransparency",
    Callback = function(value)
        HIGHLIGHT_TRANSPARENCY = value
        if isFlying and currentHighlight then currentHighlight.FillTransparency = value end
    end,
})
SettingsTab:CreateParagraph({
    Title = "设备信息",
    Content = "当前设备：" .. (isMobile and "📱 手机/平板（触摸模式）" or "💻 PC（键盘模式）"),
})
local controlText = isMobile and 
    "左侧屏幕：拖拽滑动控制方向\n右侧↑/↓按钮：上升/下降\nK键：显示/隐藏此界面" or
    "W/A/S/D：水平移动\n空格：上升\n左 Ctrl：下降\nK键：显示/隐藏此界面"
SettingsTab:CreateParagraph({
    Title = "控制说明",
    Content = controlText,
})

notify("脚本已加载", "设备：" .. (isMobile and "📱 触摸模式" or "💻 键盘模式") .. "，按 K 键打开控制面板，自动农场已适配手机触摸")