-- Reproduce la animación en loop sobre todos los Rig de workspace cuando un jugador se une

local ANIMATION_SPEED = 1 -- 1 = velocidad normal, 2 = doble, 0.5 = mitad

local Players = game:GetService("Players")

local animation = Instance.new("Animation")
animation.AnimationId = "rbxassetid://88624107471799"

local function getRigs()
	local rigs = {}
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA("Humanoid") then
			local model = descendant.Parent
			if model and model:IsA("Model") and not Players:GetPlayerFromCharacter(model) then
				table.insert(rigs, model)
			end
		end
	end
	return rigs
end

local function playAnimationOnRig(rig)
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if humanoid then
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

-- Ejecutar cuando un jugador se une
Players.PlayerAdded:Connect(playAnimationOnAllRigs)

-- Ejecutar si ya hay jugadores (por si el script carga tarde, ej. en Studio)
if #Players:GetPlayers() > 0 then
	playAnimationOnAllRigs()
end
