--[[

    SPDX-FileCopyrightText:   Copyright 2026 Illinois_Roadbuff (Rogue Jr) <illinois_roadbuff@proton.me>
	SPDX-FileCopyrightText:   Copyright 2026 Project Roadwork and Contributors

	SPDX-License-Identifier:   BSD-2-Clause-Patent

]]

--!native
--!strict

-- Services
local TextChatService: TextChatService | any = game:GetService("TextChatService")
local Players: Players = game:GetService("Players")

local QuickNet = require("../shared/net/QuickNet")
local config = require("../shared/config")

-- Variables
local BASE_CONFIG = config.getConfig()
local version: string = BASE_CONFIG._VERSION

local data = QuickNet.Data
local checkNewPlayer = QuickNet:register(
	"checkNewPlayer",
	data.optional(data.union(data.Boolean, data.String)),
	data.optional(data.Player)
)
local getTalkablePlayers = QuickNet:register("getTalkablePlayers", data.optional({ [data.Player] = data.Boolean }))

local LocalPlayer: Player = Players.LocalPlayer
local SystemChannel: TextChannel? = nil

local GameCreatorId: number = game.CreatorId

local function _createMultiplePlayerString(talkablePlayers: { [Player]: boolean }, getTalkable: boolean): string
	local players: { string } = {}

	for player: Player, canTalk: boolean in talkablePlayers do
		if canTalk == getTalkable then
			table.insert(players, player.DisplayName)
		end
	end

	local count: number = #players

	if count == 0 then
		return ""
	elseif count == 1 then
		return players[1]
	elseif count == 2 then
		return `{players[1]} and {players[2]}`
	end

	local lastPlayer: string? = table.remove(players)
	return `{table.concat(players, ", ")}, and {lastPlayer}`
end

local function _createMultiplePlayerStringWithOmit(
	talkablePlayers: { [Player]: boolean },
	getTalkable: boolean,
	maxNumber: number
): string
	local players: { string } = {}

	for player: Player, canTalk: boolean in talkablePlayers do
		if canTalk == getTalkable then
			table.insert(players, player.DisplayName)
		end
	end

	local count: number = #players

	if count == 0 then
		return ""
	end

	-- No omission needed
	if count <= maxNumber then
		if count == 1 then
			return players[1]
		elseif count == 2 then
			return `{players[1]} and {players[2]}`
		end

		local lastPlayer = table.remove(players)
		return `{table.concat(players, ", ")}, and {lastPlayer}`
	end

	-- Omission needed
	local shown: { string } = {}

	for i = 1, maxNumber do
		shown[i] = players[i]
	end

	local omitted = count - maxNumber

	return `{table.concat(shown, ", ")}, and {omitted} other{if omitted == 1 then "" else "s"}`
end

local function _checkIfPlayerHasNoRestrictions(player: Player): boolean
	-- Can be extended
	return player.UserId == GameCreatorId
end

local function _canLocalPlayerChat(): boolean
	local success: boolean, result: boolean | string | nil =
		pcall(TextChatService.CanUserChatAsync, TextChatService, LocalPlayer.UserId)

	if success then
		return result == true -- added `== true` for typing reasons
	else
		local message: string =
			`[Talk Eligibility {version}] An error occured while calling TextChatService.CanUserChatAsync: {result}`
		warn(message)
		return false
	end
end

local function _createSystemMessage(msgDict)
	return '<font color="#'
		.. msgDict["Color"]
		.. '"><font size="'
		.. msgDict["FontSize"]
		.. '"><font face="'
		.. msgDict["FontFace"]
		.. '">'
		.. msgDict["Text"]
		.. "</font></font></font>"
end

local function _displayCannotChatAtAll(DefinedSystemChannel: TextChannel): ()
	DefinedSystemChannel:DisplaySystemMessage(_createSystemMessage({
		Text = `{BASE_CONFIG.BeginningString}{BASE_CONFIG.CannotChatWithAllTemplate}`,
		FontFace = BASE_CONFIG.FontFace,
		Color = BASE_CONFIG.CannotChatColor3:ToHex(),
		FontSize = BASE_CONFIG.FontSize,
	}))
end

local function _displayCanChat(DefinedSystemChannel: TextChannel, template: string): ()
	DefinedSystemChannel:DisplaySystemMessage(_createSystemMessage({
		Text = `{BASE_CONFIG.BeginningString}{template}`,
		FontFace = BASE_CONFIG.FontFace,
		Color = BASE_CONFIG.CanChatColor3:ToHex(),
		FontSize = BASE_CONFIG.FontSize,
	}))
end

local function _displayCannotChat(DefinedSystemChannel: TextChannel, template: string): ()
	DefinedSystemChannel:DisplaySystemMessage(_createSystemMessage({
		Text = `{BASE_CONFIG.BeginningString}{template}`,
		FontFace = BASE_CONFIG.FontFace,
		Color = BASE_CONFIG.CannotChatColor3:ToHex(),
		FontSize = BASE_CONFIG.FontSize,
	}))
end

local function _processAllTalkablePlayers(DefinedSystemChannel: TextChannel): ()
	getTalkablePlayers:FireServer()

	getTalkablePlayers.OnClientEvent:Connect(function(talkablePlayers: unknown | { [Player]: boolean })
		if typeof(talkablePlayers) ~= "table" then
			return
		end

		local totalPlayers = 0

		for _ in talkablePlayers do
			totalTalkablePlayers += 1
		end

		if #totalTalkablePlayers == 0 then
			_displayCannotChatAtAll(DefinedSystemChannel)
		elseif #totalTalkablePlayers <= 10 then
			if BASE_CONFIG.ShowTalkablePlayers then
				_displayCanChat(
					DefinedSystemChannel,
					string.format(BASE_CONFIG.CanChatWithMultiple, _createMultiplePlayerString(talkablePlayers, true))
				)
			end
			if BASE_CONFIG.ShowNonTalkablePlayers then
				_displayCanChat(
					DefinedSystemChannel,
					string.format(
						BASE_CONFIG.CannotChatWithMultiple,
						_createMultiplePlayerString(talkablePlayers, false)
					)
				)
			end
		else
			if BASE_CONFIG.ShowTalkablePlayers then
				_displayCanChat(
					DefinedSystemChannel,
					string.format(
						BASE_CONFIG.CanChatWithMultiple,
						_createMultiplePlayerStringWithOmit(talkablePlayers, true, BASE_CONFIG.MaxTalkablePlayersShown)
					)
				)
			end
			if BASE_CONFIG.ShowNonTalkablePlayers then
				_displayCanChat(
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

local function init()
	SystemChannel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXSystem")
end

local function start()
	if not SystemChannel then
		repeat
			task.wait()
		until SystemChannel
	end

	if not SystemChannel then
		return -- adding this because of types
	end

	local DefinedSystemChannel: TextChannel = SystemChannel -- adding this because of types again

	if _canLocalPlayerChat() == false then
		_displayCannotChatAtAll(DefinedSystemChannel)
		return
	end

	if _checkIfPlayerHasNoRestrictions(LocalPlayer) then
		DefinedSystemChannel:DisplaySystemMessage(_createSystemMessage({
			Text = `{BASE_CONFIG.BeginningString}{BASE_CONFIG.NoRestrictionsTemplate}`,
			FontFace = BASE_CONFIG.FontFace,
			Color = BASE_CONFIG.CanChatColor3:ToHex(),
			FontSize = BASE_CONFIG.FontSize,
		}))
		return
	end

	if #Players:GetPlayers() == 1 then
		print("g")
		DefinedSystemChannel:DisplaySystemMessage(_createSystemMessage({
			Text = `{BASE_CONFIG.BeginningString}{BASE_CONFIG.OnlyOneTemplate}`,
			FontFace = BASE_CONFIG.FontFace,
			Color = BASE_CONFIG.NotDeterminedColor3:ToHex(),
			FontSize = BASE_CONFIG.FontSize,
		}))
	else
		print("reach")
		checkNewPlayer.OnClientEvent:Connect(function(canChat: boolean? | string?, newPlayer: Player?)
			if not newPlayer then
				return
			end

			if canChat == true then
				DefinedSystemChannel:DisplaySystemMessage(_createSystemMessage({
					Text = `{BASE_CONFIG.BeginningString}{string.format(
						BASE_CONFIG.CanChatTemplate,
						newPlayer.DisplayName
					)}`,
					FontFace = BASE_CONFIG.FontFace,
					Color = BASE_CONFIG.CanChatColor3:ToHex(),
					FontSize = BASE_CONFIG.FontSize,
				}))
			elseif canChat == false then
				DefinedSystemChannel:DisplaySystemMessage(_createSystemMessage({
					Text = `{BASE_CONFIG.BeginningString}{string.format(
						BASE_CONFIG.CannotChatTemplate,
						newPlayer.DisplayName
					)}`,
					FontFace = BASE_CONFIG.FontFace,
					Color = BASE_CONFIG.CannotChatColor3:ToHex(),
					FontSize = BASE_CONFIG.FontSize,
				}))
			elseif typeof(canChat) == "string" then
				DefinedSystemChannel:DisplaySystemMessage(_createSystemMessage({
					Text = `{BASE_CONFIG.BeginningString}{string.format(
						BASE_CONFIG.NotDeterminedTemplate,
						newPlayer.DisplayName
					)}`,
					FontFace = BASE_CONFIG.FontFace,
					Color = BASE_CONFIG.NotDeterminedColor3:ToHex(),
					FontSize = BASE_CONFIG.FontSize,
				}))
			end
		end)
	end
end

return {
	name = "show",
	init = init,
	start = start,
}
