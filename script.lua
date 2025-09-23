Roblox Macro Suite w/ Notification System + File Browser Controls
Note: Requires executor APIs for file handling & input simulation

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
screenGui.Name = "MacroSuite"

local notifFrame = Instance.new("Frame", screenGui)
notifFrame.Size = UDim2.new(0, 300, 0, 200)
notifFrame.Position = UDim2.new(1, -310, 0, 20)
notifFrame.BackgroundTransparency = 1
notifFrame.ClipsDescendants = true

local notifQueue = {}
local notifBusy = false

local function ShowNotif(msg, dur)
    dur = dur or 3
    table.insert(notifQueue, {msg = msg, dur = dur})
    if not notifBusy then
        notifBusy = true
        while #notifQueue > 0 do
            local data = table.remove(notifQueue, 1)
            local notif = Instance.new("TextLabel", notifFrame)
            notif.Size = UDim2.new(1, 0, 0, 30)
            notif.Position = UDim2.new(1, 0, 0, (#notifFrame:GetChildren() - 1) * 35)
            notif.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            notif.TextColor3 = Color3.new(1,1,1)
            notif.Font = Enum.Font.SourceSansBold
            notif.TextSize = 18
            notif.Text = data.msg
            notif.BackgroundTransparency = 0.1

            notif:TweenPosition(UDim2.new(0, 0, notif.Position.Y.Scale, notif.Position.Y.Offset), "Out", "Quad", 0.5, true)

            task.delay(data.dur, function()
                notif:TweenPosition(UDim2.new(-1, 0, notif.Position.Y.Scale, notif.Position.Y.Offset), "In", "Quad", 0.5, true)
                game:GetService("Debris"):AddItem(notif, 0.6)
            end)

            task.wait(data.dur + 0.5)
        end
        notifBusy = false
    end
end

local recording = false
local playing = false
local loopPlayback = false
local macroName = "Untitled"
local macroData = {}

local controlPanel = Instance.new("Frame", screenGui)
controlPanel.Size = UDim2.new(0, 300, 0, 200)
controlPanel.Position = UDim2.new(0.05, 0, 0.05, 0)
controlPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local title1 = Instance.new("TextLabel", controlPanel)
title1.Size = UDim2.new(1, 0, 0, 30)
title1.Text = "Macro Controls"
title1.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
title1.TextColor3 = Color3.new(1,1,1)
title1.Font = Enum.Font.SourceSansBold
title1.TextSize = 18

local nameBox = Instance.new("TextBox", controlPanel)
nameBox.Size = UDim2.new(1, -20, 0, 30)
nameBox.Position = UDim2.new(0, 10, 0, 40)
nameBox.PlaceholderText = "Macro Name"
nameBox.Text = macroName

local recordBtn = Instance.new("TextButton", controlPanel)
recordBtn.Size = UDim2.new(1, -20, 0, 30)
recordBtn.Position = UDim2.new(0, 10, 0, 80)
recordBtn.Text = "Start Recording"

recordBtn.MouseButton1Click:Connect(function()
    if not recording then
        macroData = {}
        recording = true
        ShowNotif("Recording started!", 3)
        recordBtn.Text = "Stop Recording"
    else
        recording = false
        ShowNotif("Recording stopped!", 3)
        recordBtn.Text = "Start Recording"
    end
end)

local playBtn = Instance.new("TextButton", controlPanel)
playBtn.Size = UDim2.new(1, -20, 0, 30)
playBtn.Position = UDim2.new(0, 10, 0, 120)
playBtn.Text = "Play Macro"

playBtn.MouseButton1Click:Connect(function()
    if playing or #macroData == 0 then return end
    ShowNotif("Macro playback started!", 3)
    playing = true
    spawn(function()
        repeat
            for _, step in ipairs(macroData) do
                if step.inputType == "MouseClick" then
                    mousemoveabs(step.x, step.y)
                    mouse1click()
                elseif step.inputType == "KeyPress" then
                    keypress(step.keyCode)
                    keyrelease(step.keyCode)
                end
                wait(step.delay)
            end
        until not loopPlayback
        playing = false
        ShowNotif("Macro playback finished!", 3)
    end)
end)

local saveBtn = Instance.new("TextButton", controlPanel)
saveBtn.Size = UDim2.new(1, -20, 0, 30)
saveBtn.Position = UDim2.new(0, 10, 0, 160)
saveBtn.Text = "Save Macro"

saveBtn.MouseButton1Click:Connect(function()
    macroName = nameBox.Text
    writefile(macroName..".macro", HttpService:JSONEncode(macroData))
    refreshFileList()
    ShowNotif("Macro saved: "..macroName, 3)
end)

local filePanel = Instance.new("Frame", screenGui)
filePanel.Size = UDim2.new(0, 300, 0, 200)
filePanel.Position = UDim2.new(0.05, 0, 0.35, 0)
filePanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local title2 = Instance.new("TextLabel", filePanel)
title2.Size = UDim2.new(1, 0, 0, 30)
title2.Text = "Saved Macros"
title2.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
title2.TextColor3 = Color3.new(1,1,1)
title2.Font = Enum.Font.SourceSansBold
title2.TextSize = 18

local macroList = Instance.new("ScrollingFrame", filePanel)
macroList.Size = UDim2.new(1, -10, 0, 160)
macroList.Position = UDim2.new(0, 5, 0, 35)
macroList.BackgroundTransparency = 1
macroList.CanvasSize = UDim2.new(0, 0, 0, 0)

function refreshFileList()
    macroList:ClearAllChildren()
    local y = 0
    for _, file in ipairs(listfiles("")) do
        if file:match("%.macro$") then
            local fileName = file:match("([^/\\]+)%.macro$")
            local btn = Instance.new("TextButton", macroList)
            btn.Size = UDim2.new(1, -10, 0, 30)
            btn.Position = UDim2.new(0, 5, 0, y)
            btn.Text = fileName
            btn.MouseButton1Click:Connect(function()
                macroName = fileName
                macroData = HttpService:JSONDecode(readfile(file))
                ShowNotif("Loaded macro: "..macroName, 3)
            end)
            y = y + 35
        end
    end
    macroList.CanvasSize = UDim2.new(0, 0, 0, y)
end
refreshFileList()

local lastTime = tick()
UIS.InputBegan:Connect(function(input, processed)
    if recording and not processed then
        local step = {delay = 0}
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            step.inputType = "MouseClick"
            step.x, step.y = math.floor(input.Position.X), math.floor(input.Position.Y)
        elseif input.UserInputType == Enum.UserInputType.Keyboard then
            step.inputType = "KeyPress"
            step.keyCode = input.KeyCode.Value
        end
        step.delay = tick() - lastTime
        lastTime = tick()
        table.insert(macroData, step)
    end
end)
