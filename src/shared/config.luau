--[[

    SPDX-FileCopyrightText:   Copyright 2026 Illinois_Roadbuff (Rogue Jr) <illinois_roadbuff@proton.me>
	SPDX-FileCopyrightText:   Copyright 2026 Project Roadwork and Contributors

	SPDX-License-Identifier:   Apache-2.0 WITH LLVM-exception

]]

--!native
--!strict

-- Variables
local version: Version = table.freeze({major = 1, minor = 0, patch = 0, pre_release = "alpha", build = 3, metadata = ""})

--[=[
	Private: Converts version to string
	@private
]=]
local function _versionToString(v: Version): string
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

-- Base Config
local BASE_CONFIG = {
    LOCKED = false,
    _VERSION = _versionToString(version),

    -- Repositories
    CODEBERG = "https://codeberg.org/project-roadwork/talk-eligibility.git",
	GITHUB = "https://github.com/project-roadwork/talk-eligibility.git",

	CodebergTags = "https://codeberg.org/api/v1/repos/project-roadwork/light-reflector/tags",

	CheckForUpdates = true,
	ShowPrints = true,
	ShowWarns = true,

    TextChatService = game:GetService("TextChatService"),
    --^ Change this if you are using something like OpenTextChatService

    --BeginningString = `<b><font color="#{Color3.fromRGB(210, 210, 210):ToHex()}">[Talk Eligibility]</font></b> `,
    BeginningString = ``,
    CanChatTemplate = "🔊 %s joined. You are able to talk with this player.",
    CannotChatTemplate = "🔇 %s joined. You are not able to talk with this player.",
    NotDeterminedTemplate = "❔%s joined. You may or may not be able to talk with this player.",
    NoRestrictionsTemplate = "🔊 You can talk to everyone in this server.",
    RestrictedTemplate = "🔇 You cannot talk to anyone in this server.",
    CanChatWithAllTemplate = "🔊 You can currently talk to everyone in this server.",
    CannotChatWithAllTemplate = "🔇 You currently cannot talk to anyone in this server.",
    OnlyOneTemplate = "🔇 You are the only person in this server.",

    CanChatWithMultiple = "🔊 You can talk with the following players: %s.",
    CannotChatWithMultiple = "🔇 However, you cannot talk with the following players: %s.",

    ShowTalkablePlayers = true,
    ShowNonTalkablePlayers = true,

    CanDoSecondTests = false,
    -- ^ This may not be neccesary, but it checks the other way around.
    --   e.g., if (player1 and player2) *AND* (player2 and player1)

    CanCheckOnNewPlayerJoin = true,
    -- ^ Check if the existing players can chat with any new player.
    --   May spam the chat with servers which has high capacity

    -- Max amount shown until cutoff (e.g., plr1, plr2, and 2 others)
    MaxTalkablePlayersShown = 5,
    MaxNonTalkablePlayersShown = 5,

    -- Preview
    FontSize = 13,
    FontFace = "Gotham",
    CanChatColor3 = Color3.fromRGB(198, 255, 192),
    CannotChatColor3 = Color3.fromRGB(255, 142, 142),
    NotDeterminedColor3 = Color3.fromRGB(210, 210, 210),
}

-- Flags
const FLAGS = {
	["SHOW_NO_RESTRICTION"] = false,
	-- ^ Displays no restriction messages like if the player is the creator. This may be inaccurate.
}

--[=[
	Public: Returns the entire config
]=]
const function getConfig(): BASE_CONFIG
	return BASE_CONFIG
end

--[=[
	Public: Deep merges two dictionaries
]=]
const function _deepMerge(defaults: Dict, overrides: Dict, path: string?): ()
	path = path or ""

	for key, value in next, overrides do
		if typeof(key) ~= "string" then
			continue
		end

		const fullPath: string = if path ~= "" then `{path}.{key}` else tostring(key)

		if defaults[key] == nil then
			warn(`[Talk Eligibility {BASE_CONFIG._VERSION}] Unknown configuration key: -> {fullPath} <-; are you sure it is spelled or capitalized correctly?`)
			continue
		end

		if typeof(value) == "table" and typeof(defaults[key]) == "table" then
			_deepMerge(defaults[key] :: Dict, value :: Dict, fullPath)
		else
			defaults[key] = value
		end
	end
end

--[=[
	Public: Assigns config via deep merge
]=]
const function applyOverrides(userConfig: any): BASE_CONFIG
	if typeof(userConfig) ~= "table" then
		return BASE_CONFIG
	end

	_deepMerge(BASE_CONFIG :: Dict, userConfig :: Dict)

	return BASE_CONFIG
end

-- Returns
local configReturns = table.freeze({
	name = "config",
	FLAGS = FLAGS,
	getConfig = getConfig,
	applyOverrides = applyOverrides
})

-- Types
export type BASE_CONFIG = typeof(BASE_CONFIG)
export type Dict = { [string | number]: any }

export type Version = {
	read major: number,
	read minor: number,
	read patch: number,
	read pre_release: string,
	read build: number,
	read metadata: string,
}

-- Return public variables and API
return configReturns
