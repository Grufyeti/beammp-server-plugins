local json = require("dkjson")
local carrespawn = true

-- JSON data helpers
local function saveData(filename, data)
	if type(data) ~= "table" then
		print("saveData ERROR: data must be a table, got", type(data))
		return
	end

	local encoded = json.encode(data, { indent = true })
	if not encoded or type(encoded) ~= "string" then
		print("saveData ERROR: json.encode failed, got", type(encoded), encoded)
		return
	end

	local file, err = io.open(filename, "w")
	if not file then
		print("saveData ERROR: could not open file:", err)
		return
	end

	file:write(encoded)
	file:close()
end

local function loadData(filename)
	local file = io.open(filename, "r")
	if not file then
		return {} -- empty if file doesn’t exist
	end

	local contents = file:read("*a")
	file:close()

	local data, pos, err = json.decode(contents)
	if err then
		print("Error decoding JSON in", filename, ":", err)
		return {}
	end

	return data or {}
end

-- Load existing data
local playerData = loadData("carsspawned.json")
local connectionData = loadData("playersjoined.json")

-- Increment vehicle count or add new player
function AddVehicle(playerName)
	if not playerName then
		return
	end

	if playerData[playerName] then
		playerData[playerName] = playerData[playerName] + 1
	else
		playerData[playerName] = 1
	end

	saveData("carsspawned.json", playerData)
	print("[INFO] Updated vehicles for", playerName, ":", playerData[playerName])
end

-- Save connections (BeamMP example, adjust as needed)
function AddConnection(playerName, playerId)
	if not playerName or not playerId then
		return
	end

	-- Save SteamID/unique identifiers if needed
	connectionData[playerName] = MP.GetPlayerIdentifiers(playerId)

	saveData("playersjoined.json", connectionData)
	print("[INFO] Player joined:", playerName)
end

function AddGamemode(flipvar)
	carrespawn = flipvar
	MP.SendChatMessage(-1, "Respawning cars in now disabled")
end

function Wait(seconds)
	local start = os.time()
	repeat
	until os.time() > start + seconds
end

function Countdown_print(sender_name)
	local i = 5
	MP.SendChatMessage(-1, sender_name .. " has started a countdown")
	Wait(1)
	repeat
		MP.SendChatMessage(-1, "Countdown: " .. i)
		Wait(1)
		i = i - 1
	until i == 0
	MP.SendChatMessage(-1, "Start!!!")
	return 1
end

function Playerkicker(message)
	local cmd, player = message:match("^(%S+)%s+(.*)$")
	if player then
		MP.SendChatMessage(-1, "Trying to kick player " .. player)
	end
	if cmd == "kick" then
		local PlayerAmount = MP.GetPLayerCount()
		local i = 0
		repeat
			if MP.GetPlayerName(i) == player then
				MP.DropPlayer(i, "")
			end
		until i > PlayerAmount
	end
	return 1
end

function CommandHandeler(sender_name, msg)
	if
		sender_name == "Grufyeti"
		or sender_name == "I_eat_toast"
		or sender_name == "Ph1llplayz"
		or sender_name == "Schwedenbomber"
	then
		if msg == msg:match("^kick") then
			Playerkicker(msg)
		end
		if msg == "disable respawn" then
			AddGamemode(false)
		elseif msg == "enable respawn" then
			AddGamemode(true)
		end
	end
	if msg == "countdown" then
		Countdown_print(sender_name)
	end
	return 1
end

function CarAmountupdate(player_id)
	local playername = MP.GetPlayerName(player_id)
	AddVehicle(playername)
end

function PlayerConnected(player_id)
	local player = MP.GetPlayerName(player_id)
	AddConnection(player, player_id)
end

function Noresetgameevent(respawners_id)
	if carrespawn == true then
		return 0
	elseif carrespawn == false then
		MP.SendChatMessage(
			-1,
			"Player " .. MP.GetPlayerName(respawners_id) .. "respawned his vehicle while in a non respawn gamemode!"
		)
	end
end

MP.RegisterEvent("onChatMessage", "CommandHandeler")
MP.RegisterEvent("onVehicleSpawn", "CarAmountupdate")
MP.RegisterEvent("onPlayerConnecting", "PlayerConnected")
MP.RegisterEvent("onVehicleReset", "Noresetgameevent")
