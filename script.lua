-- Anon UI Macro Suite (Dark Mode, Pink/Red Theme)
-- Requires: Ronix executor (supports writefile, readfile, listfiles, keypress, mouse1click, mousemoveabs)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

--== ScreenGui ==--
local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
screenGui.Name = "MacroSuite"

--== Main Frame ==--
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 500, 0, 300)
mainFrame.Position = UDim2.new(0.2, 0, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0

--== Draggable + Close ==--
local dragging, dragInput, dragStart, startPos
mainFrame.Active = true
mainFrame.Draggable = true

local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 30)
topBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)

local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(1, -30, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.Text = "ACC Macro System"
title.TextColor3 = Color3.fromRGB(255, 100, 150)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, 30, 1, 0)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
closeBtn.BackgroundTransparency = 1
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 20
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

--== Sidebar ==--
local sidebar = Instance.new("Frame", mainFrame)
sidebar.Size = UDim2.new(0, 120, 1, -30)
sidebar.Position = UDim2.new(0, 0, 0, 30)
sidebar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

local tabs = {"🎮 Macros", "📂 Saved Files", "⚙️ Settings", "⭐ Credits"}
local tabButtons, currentTab = {}, nil

local contentFrame = Instance.new("Frame", mainFrame)
contentFrame.Size = UDim2.new(1, -120, 1, -30)
contentFrame.Position = UDim2.new(0, 120, 0, 30)
contentFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)

--== Notifications (centered) ==--
local notifFrame = Instance.new("Frame", screenGui)
notifFrame.Size = UDim2.new(1, 0, 0, 50)
notifFrame.Position = UDim2.new(0, 0, 0, 10)
notifFrame.BackgroundTransparency = 1

local function ShowNotif(msg, dur)
    dur = dur or 2.5
    local notif = Instance.new("TextLabel", notifFrame)
    notif.Size = UDim2.new(0, 400, 0, 40)
    notif.Position = UDim2.new(0.5, -200, 0, 0)
    notif.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    notif.BorderSizePixel = 0
    notif.TextColor3 = Color3.fromRGB(255, 100, 150)
    notif.Font = Enum.Font.SourceSansBold
    notif.TextSize = 20
    notif.Text = msg
    notif.TextTransparency = 1
    notif.BackgroundTransparency = 0.2

    -- fade in
    for i = 1, 10 do
        notif.TextTransparency = 1 - (i * 0.1)
        task.wait(0.05)
    end

    task.delay(dur, function()
        for i = 1, 10 do
            notif.TextTransparency = i * 0.1
            task.wait(0.05)
        end
        notif:Destroy()
    end)
end

--== Macro System ==--
local recording, playing, loopPlayback = false, false, false
local macroName, macroData = "Untitled", {}

local function CreateTab(name)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1, -10, 0, 40)
    btn.Position = UDim2.new(0, 5, 0, (#tabButtons) * 45 + 5)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 100, 150)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16

    tabButtons[#tabButtons+1] = btn

    btn.MouseButton1Click:Connect(function()
        for _, c in pairs(contentFrame:GetChildren()) do
            c:Destroy()
        end
        currentTab = name

        --== Macros Tab ==--
        if name == "🎮 Macros" then
            local nameBox = Instance.new("TextBox", contentFrame)
            nameBox.Size = UDim2.new(1, -20, 0, 30)
            nameBox.Position = UDim2.new(0, 10, 0, 10)
            nameBox.PlaceholderText = "Macro Name"
            nameBox.Text = macroName
            nameBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            nameBox.TextColor3 = Color3.fromRGB(255, 150, 200)

            local recordBtn = Instance.new("TextButton", contentFrame)
            recordBtn.Size = UDim2.new(1, -20, 0, 30)
            recordBtn.Position = UDim2.new(0, 10, 0, 50)
            recordBtn.Text = "Start Recording"
            recordBtn.BackgroundColor3 = Color3.fromRGB(60, 0, 20)
            recordBtn.TextColor3 = Color3.fromRGB(255, 150, 200)

            recordBtn.MouseButton1Click:Connect(function()
                if not recording then
                    macroData = {}
                    recording = true
                    ShowNotif("Recording started!", 2)
                    recordBtn.Text = "Stop Recording"
                else
                    recording = false
                    ShowNotif("Recording stopped!", 2)
                    recordBtn.Text = "Start Recording"
                end
            end)

            local playBtn = Instance.new("TextButton", contentFrame)
            playBtn.Size = UDim2.new(1, -20, 0, 30)
            playBtn.Position = UDim2.new(0, 10, 0, 90)
            playBtn.Text = "Play Macro"
            playBtn.BackgroundColor3 = Color3.fromRGB(60, 0, 20)
            playBtn.TextColor3 = Color3.fromRGB(255, 150, 200)

            playBtn.MouseButton1Click:Connect(function()
                if playing or #macroData == 0 then return end
                ShowNotif("Macro playback started!", 2)
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
                    ShowNotif("Macro playback finished!", 2)
                end)
            end)

            local loopBtn = Instance.new("TextButton", contentFrame)
            loopBtn.Size = UDim2.new(1, -20, 0, 30)
            loopBtn.Position = UDim2.new(0, 10, 0, 130)
            loopBtn.Text = "Loop: OFF"
            loopBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            loopBtn.TextColor3 = Color3.fromRGB(255, 150, 200)

            loopBtn.MouseButton1Click:Connect(function()
                loopPlayback = not loopPlayback
                loopBtn.Text = "Loop: " .. (loopPlayback and "ON" or "OFF")
                ShowNotif("Loop " .. (loopPlayback and "enabled" or "disabled"), 2)
            end)

            local saveBtn = Instance.new("TextButton", contentFrame)
            saveBtn.Size = UDim2.new(1, -20, 0, 30)
            saveBtn.Position = UDim2.new(0, 10, 0, 170)
            saveBtn.Text = "Save Macro"
            saveBtn.BackgroundColor3 = Color3.fromRGB(60, 0, 20)
            saveBtn.TextColor3 = Color3.fromRGB(255, 150, 200)

            saveBtn.MouseButton1Click:Connect(function()
                macroName = nameBox.Text
                writefile(macroName..".macro", HttpService:JSONEncode(macroData))
                ShowNotif("Macro saved: "..macroName, 2)
            end)

        --== Saved Files Tab ==--
        elseif name == "📂 Saved Files" then
            local list = Instance.new("ScrollingFrame", contentFrame)
            list.Size = UDim2.new(1, -10, 1, -10)
            list.Position = UDim2.new(0, 5, 0, 5)
            list.CanvasSize = UDim2.new(0, 0, 0, 0)
            list.BackgroundTransparency = 1

            local y = 0
            for _, file in ipairs(listfiles("")) do
                if file:match("%.macro$") then
                    local fname = file:match("([^/\\]+)%.macro$")
                    local btn = Instance.new("TextButton", list)
                    btn.Size = UDim2.new(1, -10, 0, 30)
                    btn.Position = UDim2.new(0, 5, 0, y)
                    btn.Text = fname
                    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                    btn.TextColor3 = Color3.fromRGB(255, 150, 200)

                    btn.MouseButton1Click:Connect(function()
                        macroName = fname
                        macroData = HttpService:JSONDecode(readfile(file))
                        ShowNotif("Loaded macro: "..macroName, 2)
                    end)
                    y = y + 35
                end
            end
            list.CanvasSize = UDim2.new(0, 0, 0, y)

        --== Settings Tab ==--
        elseif name == "⚙️ Settings" then
            local lbl = Instance.new("TextLabel", contentFrame)
            lbl.Size = UDim2.new(1, -20, 0, 30)
            lbl.Position = UDim2.new(0, 10, 0, 10)
            lbl.Text = "Settings (placeholder)"
            lbl.TextColor3 = Color3.fromRGB(255, 150, 200)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.SourceSansBold
            lbl.TextSize = 18

        --== Credits Tab ==--
        elseif name == "⭐ Credits" then
            local lbl = Instance.new("TextLabel", contentFrame)
            lbl.Size = UDim2.new(1, -20, 0, 30)
            lbl.Position = UDim2.new(0, 10, 0, 10)
            lbl.Text = "Credits - Edit this yourself"
            lbl.TextColor3 = Color3.fromRGB(255, 150, 200)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.SourceSansBold
            lbl.TextSize = 18
        end
    end)
end

-- build sidebar
for _, tabName in ipairs(tabs) do
    CreateTab(tabName)
end

-- auto-open Macros first
tabButtons[1]:MouseButton1Click()

--== Input Capture ==--
local lastTime = tick()
UIS.InputBegan:Connect(function(input, processed)
    if recording and not processed then
        local step = {delay = tick() - lastTime}
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            step.inputType = "MouseClick"
            step.x, step.y = math.floor(input.Position.X), math.floor(input.Position.Y)
        elseif input.UserInputType == Enum.UserInputType.Keyboard then
            step.inputType = "KeyPress"
            step.keyCode = input.KeyCode.Value
        end
        lastTime = tick()
        table.insert(macroData, step)
    end
end)
