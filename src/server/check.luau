--[[

    SPDX-FileCopyrightText:   Copyright 2026 Illinois_Roadbuff (Rogue Jr) <illinois_roadbuff@proton.me>
	SPDX-FileCopyrightText:   Copyright 2026 Project Roadwork and Contributors

	SPDX-License-Identifier:   BSD-2-Clause-Patent

]]

--!native
--!strict

-- Services
local EncodingService = game:GetService("EncodingService")
local TextChatService: TextChatService = game:GetService("TextChatService")
local Players: Players = game:GetService("Players")

-- Modules
local QuickNet = require("../shared/net/QuickNet")
local config = require("../shared/config")

-- Variables
local BASE_CONFIG = config.getConfig()
local version: string = BASE_CONFIG._VERSION

-- QuickNet Variables
local data = QuickNet.Data
local checkNewPlayer = QuickNet:register(
	"checkNewPlayer",
	data.optional(data.union(data.Boolean, data.String)),
	data.optional(data.Player)
)
local getTalkablePlayers = QuickNet:register("getTalkablePlayers", data.optional({ [data.Player] = data.Boolean }))

local function _canUsersChat(userIdFrom: number, userIdTo: number): boolean | string
	local success: boolean, result: boolean | string | nil =
		pcall(TextChatService.CanUsersChatAsync, TextChatService, userIdFrom, userIdTo)

	if success then
		return result == true -- added `== true` for typing reasons
	else
		local message: string =
			`[Talk Eligibility {version}] An error occured while calling TextChatService.CanUsersChatAsync: {result}`
		warn(message)
		return message
	end
end

local function _getTalkablePlayersfromPlayer(fromPlayer: Player): { [Player]: boolean }
	local allowedPlayers: { [Player]: boolean } = {}

	for _: number, existingPlayer: Player in Players:GetPlayers() do
		local result = _canUsersChat(fromPlayer.UserId, existingPlayer.UserId)

		if typeof(result) == "string" then
			result = false -- a returned string means that the request failed
		end

		allowedPlayers[existingPlayer] = result :: boolean
	end

	return allowedPlayers
end

local function _onPlayerAdded(newPlayer: Player): ()
	for _, existingPlayer: Player in Players:GetPlayers() do
		checkNewPlayer:FireClient(existingPlayer, _canUsersChat(existingPlayer.UserId, newPlayer.UserId))
	end
end

local function init(): () end

local function start(): ()
	getTalkablePlayers.OnServerEvent:Connect(function(player: Player)
		getTalkablePlayers:FireClient(player, _getTalkablePlayersfromPlayer(player))
	end)

	Players.PlayerAdded:Connect(_onPlayerAdded)
end

return {
	name = "check",
	init = init,
	start = start,
}
