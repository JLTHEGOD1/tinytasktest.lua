local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local player = Players.LocalPlayer
local mouse = player:GetMouse()

local recording, replaying = false, false
local clicks, startTime = {}, 0
local savedMacros = {}
local replaySpeed = 1
local loopCount = 0
local currentLoop = 0
local ClickRemote = ReplicatedStorage:FindFirstChild("ClickRemote")
local statusLabel

local function ShowNotification(text)
    if statusLabel then
        statusLabel.Text = "Status: " .. text
    end
end

local function recordAction(actionType, data)
    table.insert(clicks, {
        time = os.clock() - startTime,
        type = actionType,
        data = data
    })
end

local function toggleRecording()
    if recording then
        recording = false
        ShowNotification("Idle (Recorded " .. #clicks .. " actions)")
    else
        clicks = {}
        recording = true
        startTime = os.clock()
        ShowNotification("Recording")
    end
end

local function replayMacro()
    if replaying or #clicks == 0 then return end
    replaying = true
    currentLoop = 0
    task.spawn(function()
        repeat
            currentLoop += 1
            ShowNotification("Replaying (Loop " .. currentLoop .. (loopCount == 0 and "/∞)" or "/" .. loopCount .. ")"))
            local lastTime = 0
            for _, action in ipairs(clicks) do
                if not replaying then break end
                local waitTime = (action.time - lastTime) / replaySpeed
                if waitTime > 0 then
                    local waited = task.wait(waitTime)
                    if not replaying then break end
                end
                lastTime = action.time
                if action.type == "Click" and ClickRemote then
                    if action.data and action.data.Parent then
                        pcall(function() ClickRemote:FireServer(action.data) end)
                    end
                elseif action.type == "Key" then
                end
            end
        until not replaying or (loopCount > 0 and currentLoop >= loopCount)
        replaying = false
        ShowNotification("Idle (Replay finished)")
    end)
end

local function cancelReplay()
    if replaying then
        replaying = false
        ShowNotification("Idle (Replay canceled)")
    end
end

local function saveMacro(slot)
    if #clicks == 0 then
        ShowNotification("No macro to save")
        return
    end
    savedMacros[slot] = table.clone(clicks)
    ShowNotification("Saved slot " .. slot)
end

local function loadMacro(slot)
    if not savedMacros[slot] then
        ShowNotification("No macro in slot " .. slot)
        return
    end
    clicks = table.clone(savedMacros[slot])
    ShowNotification("Loaded slot " .. slot .. " (" .. #clicks .. " actions)")
end

local function clearMacro()
    clicks = {}
    ShowNotification("Idle (Macro cleared)")
end

local function setReplaySpeed(speed)
    replaySpeed = speed
    ShowNotification("Replay speed x" .. speed)
end

task.spawn(function()
    while task.wait(60) do
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

mouse.Button1Down:Connect(function()
    if recording then
        local target = mouse.Target
        recordAction("Click", target)
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if recording and not processed then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            recordAction("Key", input.KeyCode)
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            recordAction("Click", nil)
        end
    end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
pcall(function()
    screenGui.Parent = player:WaitForChild("PlayerGui")
end)
if not screenGui.Parent then
    screenGui.Parent = game:GetService("CoreGui")
end

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 420, 0, 330)
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -165)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", mainFrame)
stroke.Color = Color3.fromRGB(100, 100, 100)
stroke.Thickness = 1.5

local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local titleText = Instance.new("TextLabel", titleBar)
titleText.Size = UDim2.new(1, -60, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Macro Recorder Pro"
titleText.TextColor3 = Color3.new(1, 1, 1)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 16
titleText.TextXAlignment = Enum.TextXAlignment.Left

statusLabel = Instance.new("TextLabel", mainFrame)
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 1, -25)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left

local closeButton = Instance.new("TextButton", titleBar)
closeButton.Size = UDim2.new(0, 30, 1, 0)
closeButton.Position = UDim2.new(1, -30, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 8)
closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

local minimizeButton = Instance.new("TextButton", titleBar)
minimizeButton.Size = UDim2.new(0, 30, 1, 0)
minimizeButton.Position = UDim2.new(1, -65, 0, 0)
minimizeButton.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
minimizeButton.Text = "_"
minimizeButton.TextColor3 = Color3.new(1, 1, 1)
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.TextSize = 14
Instance.new("UICorner", minimizeButton).CornerRadius = UDim.new(0, 8)
local minimized = false
minimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    mainFrame.Size = minimized and UDim2.new(0, 420, 0, 40) or UDim2.new(0, 420, 0, 330)
end)

local container = Instance.new("Frame", mainFrame)
container.Size = UDim2.new(0.5, -15, 1, -60)
container.Position = UDim2.new(0, 10, 0, 40)
container.BackgroundTransparency = 1
local uiList = Instance.new("UIListLayout", container)
uiList.Padding = UDim.new(0, 6)
uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiList.VerticalAlignment = Enum.VerticalAlignment.Top

local function createButton(name, color, callback)
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = color
    btn.Text = name
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

createButton("Start/Stop Recording", Color3.fromRGB(40, 120, 200), toggleRecording)
createButton("Replay Macro", Color3.fromRGB(60, 180, 75), replayMacro)
createButton("Cancel Replay", Color3.fromRGB(200, 100, 60), cancelReplay)
createButton("Clear Macro", Color3.fromRGB(200, 60, 60), clearMacro)

for i = 1, 3 do
    createButton("Save Slot " .. i, Color3.fromRGB(90, 90, 200), function() saveMacro(i) end)
    createButton("Load Slot " .. i, Color3.fromRGB(120, 120, 220), function() loadMacro(i) end)
end

createButton("Speed x0.5", Color3.fromRGB(100, 160, 200), function() setReplaySpeed(0.5) end)
createButton("Speed x1", Color3.fromRGB(100, 200, 100), function() setReplaySpeed(1) end)
createButton("Speed x2", Color3.fromRGB(200, 160, 100), function() setReplaySpeed(2) end)
