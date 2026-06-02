--[[

    SPDX-FileCopyrightText:   Copyright 2026 Illinois_Roadbuff (Rogue Jr) <illinois_roadbuff@proton.me>
	SPDX-FileCopyrightText:   Copyright 2026 Project Roadwork and Contributors

	SPDX-License-Identifier:   BSD-2-Clause-Patent

]]

--!native
--!strict

-- Modules
local config: types.ConfigModule = require("./config")
local types: {} = require("./types")

-- Variables
local BASE_CONFIG: types.BaseConfig = config.getConfig()
local version: string = BASE_CONFIG._VERSION
local _luauwarn: (string) -> () = warn
local _luauprint: (string) -> () = print

--[=[
	Public: Creates a warn in the output
]=]
local function wrappedWarn(message: string)
	if BASE_CONFIG.ShowWarns then
		_luauwarn(`[Light Reflector {version}] {message}`)
	end
end

--[=[
	Public: Creates a print in the output
]=]
local function wrappedPrint(message: string)
	if BASE_CONFIG.ShowPrints then
		_luauprint(`[Light Reflector {version}] {message}`)
	end
end

--[=[
	Public: Converts version to string
]=]
const function versionToString(v: types.Version): string
	local str: string = `{v.major}.{v.minor}.{v.patch}`
	if v.pre_release and v.pre_release ~= "" then
		str = `{str}-{v.pre_release}`
	end
	if v.build and v.build >= 0 then
		str = `{str}.{v.build}`
	end
	if v.metadata and v.metadata ~= "" then
		str = `{str}+{v.metadata}`
	end
	return str
end

--[=[
	Public: Creates a system message
]=]
local function createSystemMessage(DefinedSystemChannel: TextChannel, msgDict: { [string]: any }): ()
	DefinedSystemChannel:DisplaySystemMessage(
		'<font color="#'
			.. msgDict["Color"]
			.. '"><font weight="SemiBold"><font size="'
			.. msgDict["FontSize"]
			.. '"><font face="'
			.. msgDict["FontFace"]
			.. '">'
			.. msgDict["Text"]
			.. "</font></font></font></font>"
	)
end

--[=[
	Public: Creates a multi-player string (e.g., pl1, plr2, and pl3)
]=]
local function createMultiplePlayerString(talkablePlayers: { [Player]: boolean }, getTalkable: boolean): string
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

--[=[
	Public: Creates a multi-player string with a cutoff (e.g., pl1, plr2, and 2 others.)
]=]
local function createMultiplePlayerStringWithOmit(
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

	if count <= maxNumber then
		if count == 1 then
			return players[1]
		elseif count == 2 then
			return `{players[1]} and {players[2]}`
		end

		local lastPlayer = table.remove(players)
		return `{table.concat(players, ", ")}, and {lastPlayer}`
	end

	local shown: { string } = {}

	for i: number = 1, maxNumber do
		shown[i] = players[i]
	end

	local omitted: number = count - maxNumber

	return `{table.concat(shown, ", ")}, and {omitted} other{if omitted == 1 then "" else "s"}`
end

-- Return public variables and API
return table.freeze({
	name = "utils",
	wrappedWarn = wrappedWarn,
	wrappedPrint = wrappedPrint,
	versionToString = versionToString,
	createSystemMessage = createSystemMessage,
	createMultiplePlayerString = createMultiplePlayerString,
	createMultiplePlayerStringWithOmit = createMultiplePlayerStringWithOmit,
})
