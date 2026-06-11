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
local data = QuickNet.Data

local checkNewPlayer: QuickNet.NetworkEvent<(boolean | string)?, Player?> = QuickNet:register(
	"checkNewPlayer",
	data.optional(data.union(data.Boolean, data.String)),
	data.optional(data.Player)
)

local getTalkablePlayers: QuickNet.NetworkEvent<{ [Player]: boolean }?> =
	QuickNet:register("getTalkablePlayers", data.optional({ [data.Player] = data.Boolean }))

-- Variables
local BASE_CONFIG: types.BaseConfig = config.getConfig()
local chatCache: { [vector]: boolean } = {}
local talkableCache: { [Player]: { [Player]: boolean } } = {}

--[=[
	Private: Gets the key for chatChache
	@private
]=]
local function _getCacheKey(userId1: number, userId2: number): vector
	if userId1 > userId2 then
		userId1, userId2 = userId2, userId1
	end

	return vector.create(userId1, userId2)
end

--[=[
	Private: Checks if the local player already has no restrictions, like being the creator
	@private
]=]
local function _canUsersChat(userIdFrom: number, userIdTo: number): boolean | string
	local key: vector = _getCacheKey(userIdFrom, userIdTo)

	local cached: boolean? = chatCache[key]
	if cached ~= nil then
		return cached
	end

	local success: boolean, result: boolean | string | nil =
		pcall(TextChatService.CanUsersChatAsync, TextChatService, userIdFrom, userIdTo)

	if success then
		local value: boolean = (result == true)
		chatCache[key] = value
		return value
	else
		local message: string = `An error occured while calling TextChatService.CanUsersChatAsync: {result}.`
		utils.wrappedWarn(message)
		return message
	end
end

--[=[
	Private: Builds a dictionary of players that a certain player can talk to
	@private
]=]
local function _buildPlayerCache(newPlayer: Player): ()
	talkableCache[newPlayer] = {}

	for _, existingPlayer: Player in Players:GetPlayers() do
		if existingPlayer ~= newPlayer then
			local canChat: boolean | string = _canUsersChat(newPlayer.UserId, existingPlayer.UserId)

			if typeof(canChat) == "string" then
				canChat = false
			end

			local result: boolean = canChat :: boolean

			talkableCache[newPlayer][existingPlayer] = result

			talkableCache[existingPlayer] = talkableCache[existingPlayer] or {}
			talkableCache[existingPlayer][newPlayer] = result
		end
	end
end

--[=[
	Private: Fires all clients whether they can chat with an added player or not
	@private
]=]
local function _onPlayerAdded(newPlayer: Player): ()
	if BASE_CONFIG.CanCheckOnNewPlayerJoin == false then
		return
	end

	task.wait(2)

	if newPlayer == nil or newPlayer:IsDescendantOf(game) == false then
		return
	end

	_buildPlayerCache(newPlayer)

	for _: number, existingPlayer: Player in Players:GetPlayers() do
		if existingPlayer ~= newPlayer then
			local canChat: boolean | string = _canUsersChat(existingPlayer.UserId, newPlayer.UserId)
			checkNewPlayer:FireClient(existingPlayer, canChat, newPlayer)
		end
	end
end

--[=[
	Private: Cleans up caches from player
	@private
]=]
local function _onPlayerRemoving(player: Player): ()
	talkableCache[player] = nil

	for _: number, playerTable: { [Player]: boolean } in talkableCache do
		playerTable[player] = nil
	end

	local userId: number = player.UserId

	for key: vector, _: boolean in chatCache do
		if key.x == userId or key.y == userId then
			chatCache[key] = nil
		end
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
		getTalkablePlayers:FireClient(player, talkableCache[player] or {})
	end)

	Players.PlayerAdded:Connect(_onPlayerAdded)
	Players.PlayerRemoving:Connect(_onPlayerRemoving)
end

-- Return public variables and API
return {
	name = "check",
	init = init,
	start = start,
}
