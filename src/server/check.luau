--[[

    SPDX-FileCopyrightText:   Copyright 2026 Illinois_Roadbuff (Rogue Jr) <illinois_roadbuff@proton.me>
	SPDX-FileCopyrightText:   Copyright 2026 Project Roadwork and Contributors

	SPDX-License-Identifier:   Apache-2.0 WITH LLVM-exception

]]

--!native
--!strict

-- Services
local TextChatService: TextChatService = game:GetService("TextChatService")
local Players: Players = game:GetService("Players")

-- Modules
local QuickNet: QuickNet.QuickNet = require("../shared/net/QuickNet")
local types: {} = require("../shared/types")
local config: types.ConfigModule = require("../shared/config")
local utils: types.Utils = require("../shared/utils")

-- Register Net Events
local data: QuickNet.DataTypes = QuickNet.Data

local checkNewPlayer: QuickNet.NetworkEvent<(boolean | string)?, Player?> = QuickNet:register(
	"checkNewPlayer",
	data.optional(data.union(data.Boolean, data.String)),
	data.optional(data.Player)
)

local getTalkablePlayers: QuickNet.NetworkEvent<{ [Player]: boolean }> =
	QuickNet:register("getTalkablePlayers", data.optional({ [data.Player] = data.Boolean }))

-- Variables
local BASE_CONFIG: types.BaseConfig = config.getConfig()

--[=[
	Private: Checks if the local player already has no restrictions, like being the creator
	@private
]=]
local function _canUsersChat(userIdFrom: number, userIdTo: number): boolean | string
	local success: boolean, result: boolean | string | nil =
		pcall(TextChatService.CanUsersChatAsync, TextChatService, userIdFrom, userIdTo)

	if success then
		return result == true -- added `== true` for typing reasons
	else
		local message: string = `An error occured while calling TextChatService.CanUsersChatAsync: {result}`
		utils.wrappedWarn(message)
		return message
	end
end

--[=[
	Private: Returns a dictionary of players that a certain player can talk to
	@private
]=]
local function _getTalkablePlayersfromPlayer(fromPlayer: Player): { [Player]: boolean }
	local talkablePlayers: { [Player]: boolean } = {}

	for _: number, existingPlayer: Player in Players:GetPlayers() do
		local result: boolean | string = _canUsersChat(fromPlayer.UserId, existingPlayer.UserId)

		if typeof(result) == "string" then
			result = false -- a returned string means that the request failed
		end

		talkablePlayers[existingPlayer] = result :: boolean
	end

	return talkablePlayers
end

--[=[
	Private: Fires all clients whether they can chat with an added player or not
	@private
]=]
local function _onPlayerAdded(newPlayer: Player): ()
	for _: number, existingPlayer: Player in Players:GetPlayers() do
		checkNewPlayer:FireClient(existingPlayer, _canUsersChat(existingPlayer.UserId, newPlayer.UserId), newPlayer)
	end
end

--[=[
	Public: Inits the server module
]=]
local function init(): ()
	if BASE_CONFIG.TextChatService ~= TextChatService then
		TextChatService = BASE_CONFIG.TextChatService
	end
end

--[=[
	Public: Starts the server module
]=]
local function start(): ()
	getTalkablePlayers.OnServerEvent:Connect(function(player: Player)
		getTalkablePlayers:FireClient(player, _getTalkablePlayersfromPlayer(player))
	end)

	Players.PlayerAdded:Connect(_onPlayerAdded)
end

-- Return public variables and API
return {
	name = "check",
	init = init,
	start = start,
}
