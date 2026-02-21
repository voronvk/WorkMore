-- Reproduce la animación en loop sobre todos los Rig de workspace cuando un jugador se une

local ANIMATION_SPEED = 1 -- 1 = velocidad normal, 2 = doble, 0.5 = mitad

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Animations = require(ReplicatedStorage.Shared.Animations)

local function getAnimationIdForRig(rig)
	if CollectionService:HasTag(rig, "Poor") then
		return Animations.PoorAnimation
	end
	if CollectionService:HasTag(rig, "Normal") then
		return Animations.NormalWorkerAnimation
	end
	return Animations.NormalWorkerAnimation
end

local processedRigs = {}

local function isRig(model)
	if not model or not model:IsA("Model") then
		return false
	end
	if Players:GetPlayerFromCharacter(model) then
		return false
	end
	-- Modelo con Humanoid (NPC) o con HumanoidRootPart (rig R6/R15)
	return model:FindFirstChildOfClass("Humanoid") or model:FindFirstChild("HumanoidRootPart")
end

local function getRigs()
	local rigs = {}
	local seen = {}
	for _, descendant in workspace:GetDescendants() do
		local model = nil
		if descendant:IsA("Humanoid") then
			model = descendant.Parent
		elseif descendant.Name == "HumanoidRootPart" and descendant:IsA("BasePart") then
			model = descendant.Parent
		end
		if model and isRig(model) and not seen[model] then
			seen[model] = true
			table.insert(rigs, model)
		end
	end
	return rigs
end

local function playAnimationOnRig(rig)
	if processedRigs[rig] then
		return
	end

	processedRigs[rig] = true

	rig.AncestryChanged:Connect(function()
		if not rig:IsDescendantOf(game) then
			processedRigs[rig] = nil
		end
	end)

	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local animation = Instance.new("Animation")
		animation.AnimationId = getAnimationIdForRig(rig)
		local track = humanoid:LoadAnimation(animation)
		track.Looped = true
		track:Play(nil, nil, ANIMATION_SPEED)
	end
end

local function playAnimationOnAllRigs()
	for _, rig in getRigs() do
		playAnimationOnRig(rig)
	end
end

local function tryProcessRig(instance)
	local model = nil
	if instance:IsA("Humanoid") then
		model = instance.Parent
	elseif instance.Name == "HumanoidRootPart" and instance:IsA("BasePart") then
		model = instance.Parent
	elseif instance:IsA("Model") and isRig(instance) then
		model = instance
	end
	if model and model:IsA("Model") then
		playAnimationOnRig(model)
	end
end

-- Detectar rigs que se añaden a workspace después
workspace.DescendantAdded:Connect(function(descendant)
	task.defer(function()
		tryProcessRig(descendant)
	end)
end)

-- Ejecutar cuando un jugador se une
Players.PlayerAdded:Connect(playAnimationOnAllRigs)

-- Ejecutar al iniciar: inmediato + con delay por si los rigs cargan después
playAnimationOnAllRigs()
task.defer(function()
	task.wait(1)
	playAnimationOnAllRigs()
end)
