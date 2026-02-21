-- Al tocar Workers.(folder).Activation: escala el modelo 1 → 1.2 → 1
-- y anima el Highlight (FillTransparency y OutlineTransparency 1 → 0.7 → 1)

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local WORKERS_FOLDER_NAME = "Workers"
local SCALE_PEAK = 1.2
local HIGHLIGHT_TRANSPARENCY_PEAK = 0.5
local TWEEN_DURATION = 0.15
local TWEEN_STYLE = Enum.EasingStyle.Quad
local TOUCH_COOLDOWN = 1 -- segundos antes de poder activar de nuevo

local function setupWorkerFolder(folder: Folder)
	if not folder:IsA("Folder") then
		return
	end

	local model = folder:FindFirstChildOfClass("Model")
	local activationPart = folder:FindFirstChild("Activation")

	if not model or not activationPart or not activationPart:IsA("BasePart") then
		return
	end

	local highlight = model:FindFirstChildOfClass("Highlight")
	if not highlight then
		return
	end

	local scaleHelper = Instance.new("NumberValue")
	scaleHelper.Name = "WorkerTouchScaleHelper"
	scaleHelper.Value = 1
	scaleHelper.Parent = model

	scaleHelper.Changed:Connect(function()
		if model.Parent and model:IsDescendantOf(game) then
			pcall(function()
				model:ScaleTo(scaleHelper.Value)
			end)
		end
	end)

	local isAnimating = false
	local cooldownUntil = 0
	local currentScaleTween = nil
	local currentHighlightTween = nil

	local function cancelTweens()
		if currentScaleTween then
			currentScaleTween:Cancel()
			currentScaleTween = nil
		end
		if currentHighlightTween then
			currentHighlightTween:Cancel()
			currentHighlightTween = nil
		end
	end

	local function playTouchAnimation()
		if isAnimating or tick() < cooldownUntil then
			return
		end

		isAnimating = true
		cooldownUntil = tick() + TOUCH_COOLDOWN
		cancelTweens()

		local tweenInfo = TweenInfo.new(
			TWEEN_DURATION,
			TWEEN_STYLE,
			Enum.EasingDirection.Out
		)

		local tweenInfoBack = TweenInfo.new(
			TWEEN_DURATION,
			TWEEN_STYLE,
			Enum.EasingDirection.In
		)

		-- Scale: 1 → 1.2
		scaleHelper.Value = 1
		local scaleUp = TweenService:Create(scaleHelper, tweenInfo, { Value = SCALE_PEAK })
		scaleUp.Completed:Connect(function()
			if scaleHelper.Parent then
				local scaleDown = TweenService:Create(scaleHelper, tweenInfoBack, { Value = 1 })
				scaleDown.Completed:Connect(function()
					isAnimating = false
				end)
				scaleDown:Play()
				currentScaleTween = scaleDown
			else
				isAnimating = false
			end
		end)

		scaleUp:Play()
		currentScaleTween = scaleUp

		-- Highlight: 1 → 0.7 → 1
		highlight.FillTransparency = 1
		highlight.OutlineTransparency = 1

		local highlightToPeak = TweenService:Create(highlight, tweenInfo, {
			FillTransparency = HIGHLIGHT_TRANSPARENCY_PEAK,
			OutlineTransparency = HIGHLIGHT_TRANSPARENCY_PEAK,
		})

		highlightToPeak.Completed:Connect(function()
			if highlight.Parent then
				local highlightBack = TweenService:Create(highlight, tweenInfoBack, {
					FillTransparency = 1,
					OutlineTransparency = 1,
				})
				highlightBack:Play()
				currentHighlightTween = highlightBack
			end
		end)

		highlightToPeak:Play()
		currentHighlightTween = highlightToPeak
	end

	activationPart.Touched:Connect(function()
		playTouchAnimation()
	end)

	-- También soportar folders que se añadan después
	folder.AncestryChanged:Connect(function()
		if not folder:IsDescendantOf(game) then
			cancelTweens()
			if scaleHelper and scaleHelper.Parent then
				scaleHelper:Destroy()
			end
		end
	end)
end

local function init()
	local workers = Workspace:WaitForChild(WORKERS_FOLDER_NAME, 10)
	if not workers then
		warn("[WorkerTouchAnimation] No se encontró la carpeta 'Workers' en Workspace")
		return
	end

	for _, child in workers:GetChildren() do
		if child:IsA("Folder") then
			setupWorkerFolder(child :: Folder)
		end
	end

	workers.ChildAdded:Connect(function(child)
		if child:IsA("Folder") then
			task.defer(function()
				setupWorkerFolder(child :: Folder)
			end)
		end
	end)
end

init()
