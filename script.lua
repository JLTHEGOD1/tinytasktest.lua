local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local recording = false
local replaying = false
local actions = {}
local startTime = 0

-- Remote for 3D clicks
local ClickRemote = ReplicatedStorage:FindFirstChild("ClickRemote")
if not ClickRemote then
    ClickRemote = Instance.new("RemoteEvent")
    ClickRemote.Name = "ClickRemote"
    ClickRemote.Parent = ReplicatedStorage
end

-- GUI
local ScreenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 220, 0, 160)
Frame.Position = UDim2.new(0.05, 0, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(40,40,40)
Frame.Active = true
Frame.Draggable = true

local RecordBtn = Instance.new("TextButton", Frame)
RecordBtn.Size = UDim2.new(1, -10, 0, 30)
RecordBtn.Position = UDim2.new(0, 5, 0, 5)
RecordBtn.Text = "Start Recording"
RecordBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
RecordBtn.TextColor3 = Color3.new(1,1,1)

local ReplayBtn = Instance.new("TextButton", Frame)
ReplayBtn.Size = UDim2.new(1, -10, 0, 30)
ReplayBtn.Position = UDim2.new(0, 5, 0, 40)
ReplayBtn.Text = "Replay (Loop)"
ReplayBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
ReplayBtn.TextColor3 = Color3.new(1,1,1)

local StopBtn = Instance.new("TextButton", Frame)
StopBtn.Size = UDim2.new(1, -10, 0, 30)
StopBtn.Position = UDim2.new(0, 5, 0, 75)
StopBtn.Text = "Stop Replay"
StopBtn.BackgroundColor3 = Color3.fromRGB(150,50,50)
StopBtn.TextColor3 = Color3.new(1,1,1)

local TimerLabel = Instance.new("TextLabel", Frame)
TimerLabel.Size = UDim2.new(1, -10, 0, 20)
TimerLabel.Position = UDim2.new(0, 5, 1, -25)
TimerLabel.BackgroundTransparency = 1
TimerLabel.Text = "Timer: 0s"
TimerLabel.TextColor3 = Color3.new(1,1,1)

-- Fake cursors
local fakeCursor = Instance.new("Frame", ScreenGui)
fakeCursor.Size = UDim2.new(0, 8, 0, 8)
fakeCursor.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
fakeCursor.Visible = false

local fakeTouch = Instance.new("Frame", ScreenGui)
fakeTouch.Size = UDim2.new(0, 20, 0, 20)
fakeTouch.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
fakeTouch.BackgroundTransparency = 0.3
fakeTouch.Visible = false

-- Record mouse/touch moves
RunService.RenderStepped:Connect(function()
    if recording then
        local pos = UserInputService:GetMouseLocation()
        table.insert(actions, {time = tick(), type = "move", position = pos})
    end
end)

-- Record inputs
UserInputService.InputBegan:Connect(function(input, gp)
    if not recording then return end
    local pos = UserInputService:GetMouseLocation()

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        table.insert(actions, {time = tick(), type = "click", position = pos, part = mouse.Target})
    elseif input.UserInputType == Enum.UserInputType.Touch then
        table.insert(actions, {time = tick(), type = "touchStart", position = input.Position})
    elseif input.UserInputType == Enum.UserInputType.Keyboard then
        table.insert(actions, {time = tick(), type = "keyDown", key = input.KeyCode})
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if not recording then return end
    if input.UserInputType == Enum.UserInputType.Touch then
        table.insert(actions, {time = tick(), type = "touchEnd", position = input.Position})
    elseif input.UserInputType == Enum.UserInputType.Keyboard then
        table.insert(actions, {time = tick(), type = "keyUp", key = input.KeyCode})
    end
end)

-- Toggle Recording
local function ToggleRecording()
    if recording then
        recording = false
        RecordBtn.Text = "Start Recording"
        print("Stopped recording. Actions:", #actions)
    else
        actions = {}
        recording = true
        startTime = tick()
        RecordBtn.Text = "Stop Recording"
        print("Recording started...")
    end
end

-- Replay (infinite loop until stopped)
local function Replay()
    if replaying or #actions == 0 then return end
    replaying = true
    fakeCursor.Visible = true

    local function playOnce()
        for _, action in ipairs(actions) do
            local delayTime = action.time - actions[1].time
            task.delay(delayTime, function()
                if not replaying then return end

                if action.type == "move" then
                    fakeCursor.Position = UDim2.fromOffset(action.position.X, action.position.Y)
                elseif action.type == "click" then
                    fakeCursor.Position = UDim2.fromOffset(action.position.X, action.position.Y)
                    if action.part then
                        pcall(function() ClickRemote:FireServer(action.part) end)
                    end
                elseif action.type == "touchStart" then
                    fakeTouch.Visible = true
                    fakeTouch.Position = UDim2.fromOffset(action.position.X, action.position.Y)
                elseif action.type == "touchEnd" then
                    fakeTouch.Visible = false
                elseif action.type == "keyDown" then
                    print("[Replay] Key down:", action.key.Name)
                elseif action.type == "keyUp" then
                    print("[Replay] Key up:", action.key.Name)
                end
            end)
        end

        task.delay(actions[#actions].time - actions[1].time + 0.5, function()
            if replaying then
                playOnce() -- 🔁 loop forever
            end
        end)
    end

    playOnce()
end

-- Stop replay
local function StopReplay()
    replaying = false
    fakeCursor.Visible = false
    fakeTouch.Visible = false
    print("Replay stopped.")
end

-- Timer
RunService.RenderStepped:Connect(function()
    if recording then
        TimerLabel.Text = "Timer: " .. math.floor(tick() - startTime) .. "s"
    else
        TimerLabel.Text = "Timer: 0s"
    end
end)

-- Button events
RecordBtn.MouseButton1Click:Connect(ToggleRecording)
ReplayBtn.MouseButton1Click:Connect(Replay)
StopBtn.MouseButton1Click:Connect(StopReplay)

