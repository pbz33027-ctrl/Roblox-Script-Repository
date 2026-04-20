local players = game:GetService("Players")
local run_service = game:GetService("RunService")
local user_input_service = game:GetService("UserInputService")
local tween_service = game:GetService("TweenService")
local core_gui = game:GetService("CoreGui")

local KEY_URL = "https://raw.githubusercontent.com/pbz33027-ctrl/Roblox-Script-Repository/main/Zixy%20key.txt"
local FALLBACK_KEY = "zixy2024"

local login_gui = Instance.new("ScreenGui")
login_gui.Name = "LoginGUI"
login_gui.Parent = core_gui

local login_frame = Instance.new("Frame")
login_frame.Parent = login_gui
login_frame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
login_frame.BorderSizePixel = 0
login_frame.Position = UDim2.new(0.5, 0, 0.5, 0)
login_frame.Size = UDim2.new(0, 300, 0, 180)
login_frame.AnchorPoint = Vector2.new(0.5, 0.5)

local login_corner = Instance.new("UICorner", login_frame)
login_corner.CornerRadius = UDim.new(0, 8)

local login_stroke = Instance.new("UIStroke", login_frame)
login_stroke.Thickness = 2
login_stroke.Color = Color3.fromRGB(255, 255, 255)

local stroke_gradient = Instance.new("UIGradient", login_stroke)
stroke_gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 181, 246)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(135, 206, 250))
})

local title_label = Instance.new("TextLabel")
title_label.Parent = login_frame
title_label.BackgroundTransparency = 1
title_label.Position = UDim2.new(0, 0, 0, 15)
title_label.Size = UDim2.new(1, 0, 0, 30)
title_label.Font = Enum.Font.RobotoMono
title_label.Text = "请输入卡密"
title_label.TextColor3 = Color3.fromRGB(255, 255, 255)
title_label.TextSize = 18
title_label.TextWrapped = true

local key_box = Instance.new("TextBox")
key_box.Parent = login_frame
key_box.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
key_box.BorderSizePixel = 0
key_box.Position = UDim2.new(0.1, 0, 0.35, 0)
key_box.Size = UDim2.new(0.8, 0, 0, 35)
key_box.Font = Enum.Font.RobotoMono
key_box.Text = ""
key_box.PlaceholderText = "输入卡密..."
key_box.TextColor3 = Color3.fromRGB(255, 255, 255)
key_box.TextSize = 14
local box_corner = Instance.new("UICorner", key_box)
box_corner.CornerRadius = UDim.new(0, 4)

local confirm_btn = Instance.new("TextButton")
confirm_btn.Parent = login_frame
confirm_btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
confirm_btn.BorderSizePixel = 0
confirm_btn.Position = UDim2.new(0.25, 0, 0.7, 0)
confirm_btn.Size = UDim2.new(0.5, 0, 0, 35)
confirm_btn.Font = Enum.Font.RobotoMono
confirm_btn.Text = "验证"
confirm_btn.TextColor3 = Color3.fromRGB(255, 255, 255)
confirm_btn.TextSize = 14
local btn_corner = Instance.new("UICorner", confirm_btn)
btn_corner.CornerRadius = UDim.new(0, 4)

local info_label = Instance.new("TextLabel")
info_label.Parent = login_frame
info_label.BackgroundTransparency = 1
info_label.Position = UDim2.new(0, 0, 0.85, 0)
info_label.Size = UDim2.new(1, 0, 0, 20)
info_label.Font = Enum.Font.RobotoMono
info_label.Text = ""
info_label.TextColor3 = Color3.fromRGB(255, 80, 80)
info_label.TextSize = 12
info_label.TextWrapped = true

local rotate_connection = run_service.Heartbeat:Connect(function()
    stroke_gradient.Rotation = (stroke_gradient.Rotation or 0) + 4
end)

local function verify_key(input_key)
    info_label.Text = "验证中，请稍候..."
    local success, remote_key = pcall(function()
        return game:HttpGet(KEY_URL, true)  -- 第二个参数 true 表示缓存
    end)
    
    local valid_key = FALLBACK_KEY
    if success and remote_key and remote_key ~= "" then
        valid_key = remote_key:gsub("\n", ""):gsub("\r", "")
        info_label.Text = ""
    else
        info_label.Text = "远程验证失败，使用本地密钥"
        wait(1)
        info_label.Text = ""
    end
    
    return input_key == valid_key
end

local function create_main_gui()
    if rotate_connection then rotate_connection:Disconnect() end
    
    local games = {
        { name = "Arsenal", link = "https://raw.githubusercontent.com/zixypy/zixyx/main/mobile.txt" },
        { name = "Twisted", link = "https://raw.githubusercontent.com/zixypy/zixyx/main/twisted.txt" },
    }
    
    local holder_stroke = Instance.new("UIStroke")
    holder_stroke.Color = Color3.fromRGB(24, 24, 24)
    holder_stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    
    do
        local dragging = false
        local mouse_start = nil
        local frame_start = nil
        
        local main = Instance.new("Frame", core_gui)
        main.Name = "MainGUI"
        main.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
        main.BorderColor3 = Color3.fromRGB(0, 0, 0)
        main.BorderSizePixel = 0
        main.Position = UDim2.new(0.427201211, 0, 0.393133998, 0)
        main.Size = UDim2.new(0.145, 0, 0.267, 0)
        
        local title = Instance.new("TextLabel", main)
        title.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
        title.BorderColor3 = Color3.fromRGB(0, 0, 0)
        title.BorderSizePixel = 0
        title.Position = UDim2.new(0.0361463465, 0, 0.0199999996, 0)
        title.Size = UDim2.new(0.926784515, 0, 0.112490386, 0)
        title.Font = Enum.Font.RobotoMono
        title.Text = "Zixy X (all keys are 6h btw)"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextStrokeTransparency = 0.000
        title.TextWrapped = true
        title.TextSize = 18
        
        title.InputBegan:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                dragging = true
                mouse_start = user_input_service:GetMouseLocation()
                frame_start = main.Position
            end
        end)
    
        user_input_service.InputChanged:Connect(function(input)
            if (dragging and input.UserInputType == Enum.UserInputType.MouseMovement) then
                local delta = user_input_service:GetMouseLocation() - mouse_start
                tween_service:Create(main, TweenInfo.new(0.1), {Position = UDim2.new(frame_start.X.Scale, frame_start.X.Offset + delta.X, frame_start.Y.Scale, frame_start.Y.Offset + delta.Y)}):Play()
            end
        end)
        
        user_input_service.InputEnded:Connect(function(input)
            if (dragging) then
                dragging = false
            end
        end)
        
        local ui_stroke = Instance.new("UIStroke", main)
        ui_stroke.Thickness = 2
        ui_stroke.Color = Color3.fromRGB(255, 255, 255)
        
        local ui_gradient = Instance.new("UIGradient", ui_stroke)
        ui_gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 181, 246)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(135, 206, 250))
        })
    
        local ui_corner = Instance.new("UICorner", title)
        ui_corner.CornerRadius = UDim.new(0, 2)
    
        local holder = Instance.new("Frame", main)
        holder.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
        holder.BorderColor3 = Color3.fromRGB(0, 0, 0)
        holder.BorderSizePixel = 0
        holder.Position = UDim2.new(0.0361457169, 0, 0.167407826, 0)
        holder.Size = UDim2.new(0.926784515, 0, 0.781875908, 0)
        
        local stroke = holder_stroke:Clone()
        stroke.Parent = holder
    
        local ui_corner_2 = Instance.new("UICorner", holder)
        ui_corner_2.CornerRadius = UDim.new(0, 4)
    
        local scrolling_frame = Instance.new("ScrollingFrame", holder)
        scrolling_frame.Active = true
        scrolling_frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        scrolling_frame.BackgroundTransparency = 1.000
        scrolling_frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        scrolling_frame.BorderSizePixel = 0
        scrolling_frame.Position = UDim2.new(0, 0, 3.04931473e-06, 0)
        scrolling_frame.Size = UDim2.new(1, 0, 0.999999821, 0)
        scrolling_frame.CanvasSize = UDim2.new(0, 0, 5, 0)
    
        local ui_padding = Instance.new("UIPadding", scrolling_frame)
        ui_padding.PaddingTop = UDim.new(0, 10)
    
        local ui_grid_layout = Instance.new("UIGridLayout", scrolling_frame)
        ui_grid_layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        ui_grid_layout.SortOrder = Enum.SortOrder.LayoutOrder
        ui_grid_layout.CellPadding = UDim2.new(0, 10, 0, 10)
        ui_grid_layout.CellSize = UDim2.new(0, 165, 0, 25)
        
        local heartbeat = run_service.Heartbeat:Connect(function()
            ui_gradient.Rotation += 4
        end)
        
        for _, supported_game in ipairs(games) do
            local text_button = Instance.new("TextButton", scrolling_frame)
            text_button.Text = `Load {supported_game.name}`
            text_button.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
            text_button.BorderColor3 = Color3.fromRGB(0, 0, 0)
            text_button.BorderSizePixel = 0
            text_button.Size = UDim2.new(0.14958863, 0, 0.0553709865, 0)
            text_button.Font = Enum.Font.RobotoMono
            text_button.TextColor3 = Color3.fromRGB(255, 255, 255)
            text_button.TextSize = 12.000
            text_button.TextWrapped = true
            
            local stroke = holder_stroke:Clone()
            stroke.Parent = text_button
    
            local ui_corner_3 = Instance.new("UICorner", text_button)
            ui_corner_3.CornerRadius = UDim.new(0, 4)
            
            text_button.MouseButton1Click:Connect(function()
                local success, result = pcall(function()
                    login_gui:Destroy()
                    if main then main:Destroy() end
                    return loadstring(game:HttpGet(supported_game.link))()
                end)
                if not success then
                    warn("Failed to execute script for " .. supported_game.name .. ": " .. result)
                end
                heartbeat:Disconnect()
            end)
        end
    end
end

confirm_btn.MouseButton1Click:Connect(function()
    local input_key = key_box.Text
    if input_key == "" then
        info_label.Text = "卡密不能为空！"
        return
    end
    
    local is_valid = verify_key(input_key)
    if is_valid then
        login_gui:Destroy()
        if rotate_connection then rotate_connection:Disconnect() end
        create_main_gui()
    else
        info_label.Text = "卡密错误，请重试"
        key_box.Text = ""
    end
end)

key_box.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        confirm_btn.MouseButton1Click:Fire()
    end
end)