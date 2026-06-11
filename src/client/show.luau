--[[

    SPDX-FileCopyrightText:   Copyright 2026 Illinois_Roadbuff (Rogue Jr) <illinois_roadbuff@proton.me>
	SPDX-FileCopyrightText:   Copyright 2026 Project Roadwork and Contributors

	SPDX-License-Identifier:   Apache-2.0 WITH LLVM-exception

]]

--!native
--!strict

-- Services
local TextChatService: TextChatService | any = game:GetService("TextChatService")
local Players: Players = game:GetService("Players")

-- Modules
local QuickNet: QuickNet.QuickNet = require("../shared/net/QuickNet")
local types: {} = require("../shared/types")
local config: types.ConfigModule = require("../shared/config")
local utils: types.Utils = require("../shared/utils")
local defer: types.FastDeferSafe = require("../shared/defer")

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
local LocalPlayer: Player? = Players.LocalPlayer
local SystemChannel: TextChannel? = nil
local GameCreatorId: number = game.CreatorId

-- Utils Functions
local _createSystemMessage: types.createSystemMessage = utils.createSystemMessage
local _createMultiplePlayerString: types.createMultiplePlayerString = utils.createMultiplePlayerString
local _createMultiplePlayerStringWithOmit: types.createMultiplePlayerStringWithOmit =
	utils.createMultiplePlayerStringWithOmit

--[=[
	Private: Checks if the local player already has no restrictions, like being the creator
	@private
]=]
local function _checkIfPlayerHasNoRestrictions(player: Player): boolean
	-- Can be extended
	return player.UserId == GameCreatorId
end

--[=[
	Private: Checks if the local player can chat at all
	@private
]=]
local function _canLocalPlayerChat(LocalPlayer: Player): boolean
	local success: boolean, result: boolean | string | nil =
		pcall(TextChatService.CanUserChatAsync, TextChatService, LocalPlayer.UserId)

	if success then
		return result == true -- added `== true` for typing reasons
	else
		local message: string = `An error occured while calling TextChatService.CanUserChatAsync: {result}`
		utils.wrappedWarn(message)
		return false
	end
end

--[=[
	Private: Displays a `can chat` template
	@private
]=]
local function _displayCanChat(DefinedSystemChannel: TextChannel, template: string): ()
	_createSystemMessage(DefinedSystemChannel, {
		Text = `{BASE_CONFIG.BeginningString}{template}`,
		FontFace = BASE_CONFIG.FontFace,
		Color = BASE_CONFIG.CanChatColor3:ToHex(),
		FontSize = BASE_CONFIG.FontSize,
	})
end

--[=[
	Private: Displays a `cannot chat` template
	@private
]=]
local function _displayCannotChat(DefinedSystemChannel: TextChannel, template: string): ()
	_createSystemMessage(DefinedSystemChannel, {
		Text = `{BASE_CONFIG.BeginningString}{template}`,
		FontFace = BASE_CONFIG.FontFace,
		Color = BASE_CONFIG.CannotChatColor3:ToHex(),
		FontSize = BASE_CONFIG.FontSize,
	})
end

--[=[
	Private: Displays a `not determined` template
	@private
]=]
local function _displayNotDetermined(DefinedSystemChannel: TextChannel, template: string): ()
	_createSystemMessage(DefinedSystemChannel, {
		Text = `{BASE_CONFIG.BeginningString}{template}`,
		FontFace = BASE_CONFIG.FontFace,
		Color = BASE_CONFIG.NotDeterminedColor3:ToHex(),
		FontSize = BASE_CONFIG.FontSize,
	})
end

--[=[
	Private: Processes all talkable players
	@private
]=]
local function _processAllTalkablePlayers(DefinedSystemChannel: TextChannel): ()
	task.wait(2)
	getTalkablePlayers:FireServer()

	getTalkablePlayers.OnClientEvent:Connect(function(talkablePlayers: { [Player]: boolean }?): ()
		if talkablePlayers == nil then
			return
		end

		local PlayersList = Players:GetPlayers()
		local totalTalkablePlayers: number = 0
		local totalNonTalkablePlayers: number = 0

		for _: Player, canChat: boolean in talkablePlayers do
			if canChat then
				totalTalkablePlayers += 1 -- making total count since table is a dictionary
			else
				totalNonTalkablePlayers += 1
			end
		end

		if totalTalkablePlayers == 0 then
			_displayCannotChat(DefinedSystemChannel, BASE_CONFIG.CannotChatWithAllTemplate)
		elseif totalTalkablePlayers >= #PlayersList - 1 then
			_displayCanChat(DefinedSystemChannel, BASE_CONFIG.CanChatWithAllTemplate)
		end

		if BASE_CONFIG.ShowTalkablePlayers and totalTalkablePlayers ~= 0 then
			if totalTalkablePlayers < BASE_CONFIG.MaxTalkablePlayersShown then
				_displayCanChat(
					DefinedSystemChannel,
					string.format(BASE_CONFIG.CanChatWithMultiple, _createMultiplePlayerString(talkablePlayers, true))
				)
			else
				_displayCanChat(
					DefinedSystemChannel,
					string.format(
						BASE_CONFIG.CanChatWithMultiple,
						_createMultiplePlayerStringWithOmit(talkablePlayers, true, BASE_CONFIG.MaxTalkablePlayersShown)
					)
				)
			end
		end

		if BASE_CONFIG.ShowNonTalkablePlayers and totalNonTalkablePlayers ~= 0 and totalTalkablePlayers ~= 0 then
			print(totalNonTalkablePlayers, totalTalkablePlayers)
			if totalNonTalkablePlayers < BASE_CONFIG.MaxTalkablePlayersShown then
				_displayCannotChat(
					DefinedSystemChannel,
					string.format(
						BASE_CONFIG.CannotChatWithMultiple,
						_createMultiplePlayerString(talkablePlayers, false)
					)
				)
			else
				_displayCannotChat(
					DefinedSystemChannel,
					string.format(
						BASE_CONFIG.CannotChatWithMultiple,
						_createMultiplePlayerStringWithOmit(
							talkablePlayers,
							false,
							BASE_CONFIG.MaxNonTalkablePlayersShown
						)
					)
				)
			end
		end
	end)
end

--[=[
	Public: Inits the client module
]=]
local function init(): ()
	if BASE_CONFIG.TextChatService ~= TextChatService then
		TextChatService = BASE_CONFIG.TextChatService
	end
end

--[=[
	Public: Starts the client module
]=]
local function start(): ()
	SystemChannel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXSystem")
	-- ^ Not moving this to init() since it yields

	if not SystemChannel then
		repeat
			task.wait()
		until SystemChannel
	end

	if not SystemChannel then
		return -- adding this because of types
	end

	if not LocalPlayer then
		return -- adding this because of types
	end

	local DefinedSystemChannel: TextChannel = SystemChannel -- adding this because of types again

	if _canLocalPlayerChat(LocalPlayer) == false then
		_displayCannotChat(DefinedSystemChannel, BASE_CONFIG.RestrictedTemplate)
		return
	end

	if #Players:GetPlayers() == 1 then
		_displayNotDetermined(DefinedSystemChannel, BASE_CONFIG.OnlyOneTemplate)
		-- not returning since more players may join later
	else
		defer(_processAllTalkablePlayers, DefinedSystemChannel)
	end

	if config.FLAGS.SHOW_NO_RESTRICTION == true then
		if _checkIfPlayerHasNoRestrictions(LocalPlayer) then
			_displayCanChat(DefinedSystemChannel, BASE_CONFIG.NoRestrictionsTemplate)
			return
		end
	end

	checkNewPlayer.OnClientEvent:Connect(function(canChat: boolean? | string?, newPlayer: Player?): ()
		if not newPlayer then
			return
		end

		print(`player {newPlayer.Name} can {canChat}`)
		print(tostring(canChat))
		if canChat == true then
			_displayCanChat(DefinedSystemChannel, string.format(BASE_CONFIG.CanChatTemplate, newPlayer.DisplayName))
		elseif canChat == false then
			_displayCannotChat(
				DefinedSystemChannel,
				string.format(BASE_CONFIG.CannotChatTemplate, newPlayer.DisplayName)
			)
		elseif typeof(canChat) == "string" then
			_displayNotDetermined(
				DefinedSystemChannel,
				string.format(BASE_CONFIG.NotDeterminedTemplate, newPlayer.DisplayName)
			)
		end
	end)
end

-- Return public variables and API
return table.freeze({
	name = "show",
	init = init,
	start = start,
})
