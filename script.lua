local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local recording = false
local replaying = false
local clicks = {}
local loopReplay = false
local startTime = 0

local ClickRemote = ReplicatedStorage:FindFirstChild("ClickRemote")

local ScreenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 200, 0, 120)
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
ReplayBtn.Text = "Replay"
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

mouse.Button1Down:Connect(function()
	if recording then
		local target = mouse.Target
		local guiTarget = mouse.Target and mouse.Target:FindFirstAncestorWhichIsA("GuiButton")
		table.insert(clicks, {
			time = tick(),
			gui = guiTarget,
			part = target
		})
		if guiTarget then
			print("Recorded GUI click:", guiTarget.Name)
		elseif target then
			print("Recorded 3D click on:", target.Name)
		else
			print("Recorded click on empty space")
		end
	end
end)

local function ToggleRecording()
	if recording then
		recording = false
		RecordBtn.Text = "Start Recording"
		print("Stopped recording. Total clicks:", #clicks)
	else
		clicks = {}
		recording = true
		startTime = tick()
		RecordBtn.Text = "Stop Recording"
		print("Recording started...")
	end
end

local function Replay(loop)
	if replaying or #clicks == 0 then return end
	replaying = true
	loopReplay = loop or false
	print("Replaying clicks...")
	local function playOnce()
		for i, click in ipairs(clicks) do
			local delayTime = click.time - clicks[1].time
			task.delay(delayTime, function()
				if click.gui then
					print("[Replay] Pressing GUI:", click.gui.Name)
					pcall(function() click.gui:Activate() end)
				elseif click.part then
					print("[Replay] Clicking part:", click.part.Name)
					if ClickRemote then
						pcall(function()
							ClickRemote:FireServer(click.part)
						end)
					end
				else
					print("[Replay] Empty click")
				end
			end)
		end
		task.delay(clicks[#clicks].time - clicks[1].time + 0.5, function()
			if loopReplay then
				playOnce()
			else
				replaying = false
				print("Replay finished.")
			end
		end)
	end
	playOnce()
end

local function StopReplay()
	loopReplay = false
	replaying = false
	print("Replay stopped.")
end

RunService.RenderStepped:Connect(function()
	if recording then
		local elapsed = math.floor(tick() - startTime)
		TimerLabel.Text = "Timer: " .. elapsed .. "s"
	else
		TimerLabel.Text = "Timer: 0s"
	end
end)

RecordBtn.MouseButton1Click:Connect(ToggleRecording)
ReplayBtn.MouseButton1Click:Connect(function() Replay(true) end)
StopBtn.MouseButton1Click:Connect(StopReplay)
