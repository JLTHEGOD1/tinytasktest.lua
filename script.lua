local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local recording, replaying, loopReplay = false, false, false
local clicks, startTime = {}, 0
local savedMacros = {}

local ClickRemote = ReplicatedStorage:FindFirstChild("ClickRemote")
if not ClickRemote then
    warn("ClickRemote not found in ReplicatedStorage")
end

local isMinimized, isFullscreen = false, false
local normalSize = UDim2.new(0,220,0,160)
local normalPos = UDim2.new(0.05,0,0.2,0)

local ScreenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
ScreenGui.Name = "MacroGui"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = normalSize
Frame.Position = normalPos
Frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
Frame.Active = true
Frame.Draggable = true
Frame.BorderSizePixel = 0

local TopBar = Instance.new("Frame", Frame)
TopBar.Size = UDim2.new(1,0,0,25)
TopBar.Position = UDim2.new(0,0,0,0)
TopBar.BackgroundColor3 = Color3.fromRGB(50,50,50)

local TitleLabel = Instance.new("TextLabel", TopBar)
TitleLabel.Size = UDim2.new(0.6,0,1,0)
TitleLabel.Position = UDim2.new(0,5,0,0)
TitleLabel.Text = "Macro Recorder"
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.new(1,1,1)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local function makeControlBtn(symbol,posScale)
    local btn = Instance.new("TextButton", TopBar)
    btn.Size = UDim2.new(0,25,1,0)
    btn.Position = UDim2.new(posScale,0,0,0)
    btn.Text = symbol
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.new(1,1,1)
    btn.BackgroundColor3 = Color3.fromRGB(150,150,150)
    return btn
end

local MinBtn = makeControlBtn("–",0.7)
local FullBtn = makeControlBtn("⛶",0.8)
local CloseBtn = makeControlBtn("✕",0.9)

local ContentFrame = Instance.new("Frame", Frame)
ContentFrame.Size = UDim2.new(1,0,1,-25)
ContentFrame.Position = UDim2.new(0,0,0,25)
ContentFrame.BackgroundTransparency = 1

local function makeBtn(text,y,color)
    local btn = Instance.new("TextButton", ContentFrame)
    btn.Size = UDim2.new(1,-10,0,28)
    btn.Position = UDim2.new(0,5,0,y)
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    return btn
end

local RecordBtn = makeBtn("Start Recording",5, Color3.fromRGB(80,80,80))
local ReplayBtn = makeBtn("Replay",40, Color3.fromRGB(80,80,80))
local StopBtn = makeBtn("Stop Replay",75, Color3.fromRGB(150,50,50))
local SaveBtn = makeBtn("Save Macro",110, Color3.fromRGB(60,120,60))

local TimerLabel = Instance.new("TextLabel", ContentFrame)
TimerLabel.Size = UDim2.new(1,-10,0,20)
TimerLabel.Position = UDim2.new(0,5,1,-25)
TimerLabel.BackgroundTransparency = 1
TimerLabel.Text = "Timer: 0s"
TimerLabel.TextColor3 = Color3.new(1,1,1)

local NotifFrame = Instance.new("Frame", ScreenGui)
NotifFrame.Size = UDim2.new(0,300,0,60)
NotifFrame.Position = UDim2.new(0.7,0,0.1,0)
NotifFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
NotifFrame.Visible = false
NotifFrame.BorderSizePixel = 0

local NotifLabel = Instance.new("TextLabel", NotifFrame)
NotifLabel.Size = UDim2.new(1,-10,1,-10)
NotifLabel.Position = UDim2.new(0,5,0,5)
NotifLabel.BackgroundTransparency = 1
NotifLabel.TextColor3 = Color3.new(1,1,1)
NotifLabel.TextWrapped = true
NotifLabel.Text = "..."

local function ShowNotification(text)
    NotifLabel.Text = text
    NotifFrame.Visible = true
    task.delay(2,function() NotifFrame.Visible = false end)
end

local PreviewGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
PreviewGui.Name = "MacroPreview"

local PreviewFrame = Instance.new("ScrollingFrame", PreviewGui)
PreviewFrame.Size = UDim2.new(0,250,0,400)
PreviewFrame.Position = UDim2.new(0.75,0,0.05,0)
PreviewFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
PreviewFrame.CanvasSize = UDim2.new(0,0,0,0)
PreviewFrame.ScrollBarThickness = 8
PreviewFrame.Active = true
PreviewFrame.Draggable = true

local UIList = Instance.new("UIListLayout", PreviewFrame)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0,2)
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Left

local function AddPreviewAction(text)
    local label = Instance.new("TextLabel", PreviewFrame)
    label.Size = UDim2.new(1,-10,0,20)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.Text = text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = #PreviewFrame:GetChildren()
    PreviewFrame.CanvasSize = UDim2.new(0,0,0,UIList.AbsoluteContentSize.Y + 10)
    PreviewFrame.CanvasPosition = Vector2.new(0, UIList.AbsoluteContentSize.Y)
end

MinBtn.MouseButton1Click:Connect(function()
    if not isMinimized then
        Frame.Size = UDim2.new(0,200,0,25)
        ContentFrame.Visible = false
        isMinimized = true
    else
        Frame.Size = normalSize
        ContentFrame.Visible = true
        isMinimized = false
    end
end)

FullBtn.MouseButton1Click:Connect(function()
    if not isFullscreen then
        Frame.Position = UDim2.new(0,0,0,0)
        Frame.Size = UDim2.new(1,0,1,0)
        isFullscreen = true
    else
        Frame.Position = normalPos
        Frame.Size = normalSize
        isFullscreen = false
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    PreviewGui:Destroy()
end)

RunService.RenderStepped:Connect(function()
    if recording then
        TimerLabel.Text = "Timer: "..math.floor(tick()-startTime).."s"
    else
        TimerLabel.Text = "Timer: 0s"
    end
end)

local function recordAction(actionType, data)
    table.insert(clicks,{time=tick(), type=actionType, data=data})
    ShowNotification("Recorded: "..actionType..(data and (" "..tostring(data)) or ""))
    AddPreviewAction(string.format("[%.2fs] %s: %s", tick()-startTime, actionType, data or ""))
end

RecordBtn.MouseButton1Click:Connect(function()
    if recording then
        recording = false
        RecordBtn.Text = "Start Recording"
        ShowNotification("Recording stopped. Total actions: "..#clicks)
    else
        clicks = {}
        recording = true
        startTime = tick()
        RecordBtn.Text = "Stop Recording"
        ShowNotification("Recording started")
    end
end)

mouse.Button1Down:Connect(function()
    if recording and mouse then
        local target = mouse.Target
        if target then
            recordAction("Click", target.Name)
        else
            recordAction("Click", "Empty space")
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if recording and not processed then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            recordAction("Key", input.KeyCode.Name)
        elseif input.UserInputType == Enum.UserInputType.Touch then
            recordAction("TouchStart", "Position: "..tostring(input.Position))
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if recording and input.UserInputType == Enum.UserInputType.Touch then
        recordAction("Drag", "Position: "..tostring(input.Position))
    end
end)

ReplayBtn.MouseButton1Click:Connect(function()
    if #clicks == 0 then return end
    replaying = true
    loopReplay = true
    for _,action in ipairs(clicks) do
        if not replaying then break end
        if action.type=="Click" and ClickRemote then
            local part = workspace:FindFirstChild(action.data)
            if part then
                pcall(function() ClickRemote:FireServer(part) end)
            end
        end
        task.wait(0.1)
    end
end)

StopBtn.MouseButton1Click:Connect(function()
    loopReplay = false
    replaying = false
end)

SaveBtn.MouseButton1Click:Connect(function()
    if #clicks>0 then
        local name = "Macro_"..tostring(#savedMacros+1)
        savedMacros[name] = clicks
        ShowNotification("Macro saved: "..name)
    end
end)
