--[[
    SPDX-FileCopyrightText:   Copyright 2026 Illinois_Roadbuff (Rogue Jr) <illinois_roadbuff@proton.me>
	SPDX-FileCopyrightText:   Copyright 2026 Project Roadwork and Contributors

	SPDX-License-Identifier:   Apache-2.0 WITH LLVM-exception

	VIEW README FILE FOR MORE INFORMATION LOCATED AT:
		GIT: ./README.md

	GIT REPOSITORIES:
		Codeberg / Forgejo (main): https://codeberg.org/project-roadwork/talk-eligibility.git
		GitHub (mirror): https://github.com/project-roadwork/talk-eligibility.git
]]

-- Services
local RunService: RunService = game:GetService("RunService")
const HttpService: HttpService = game:GetService("HttpService")

-- Modules
local types: {} = require("@self/shared/types")
local config: types.ConfigModule = require("@self/shared/config")
local utils: types.Utils = require("@self/shared/utils")

-- Variables
local BASE_CONFIG: types.BaseConfig = config.getConfig()
local version: string = BASE_CONFIG._VERSION
local IS_SERVER: boolean = RunService:IsServer()
local CodebergTags: string = BASE_CONFIG.CodebergTags

--[=[
	Private: Checks if the local player already has no restrictions, like being the creator
	@private
]=]
local function checkVersion(): ()
	if IS_SERVER == false then
		utils.wrappedWarn(`You must run checkVersion() from the server! Aborting...`)
		return
	end

	if BASE_CONFIG.CheckForUpdates == false then
        return
	end

	local function fetch(url: string)
		local success: boolean, result: string = pcall(HttpService.GetAsync, HttpService, url)

		if not success then
			return nil
		end

		local ok: boolean, data: any? = pcall(HttpService.JSONDecode, HttpService, result)

		return ok and data or nil
	end

	local function normalizeVersion(v: string): string
		v = string.gsub(v, "^%s+", "")
		v = string.gsub(v, "%s+$", "")

		if string.match(v, "^[vV]%d") then
			v = string.sub(v, 2)
		end

		return v
	end

	task.defer(function()
		const tags: {any}? = fetch(CodebergTags)
		if not tags or not tags[1] then
			return
		end

		const rawLatest: any = tags[1].name
		if typeof(rawLatest) ~= "string" then
			return
		end

		const latestVersion: string = normalizeVersion(rawLatest)
		const currentVersion: string = normalizeVersion(utils.versionToString(version))

		if latestVersion ~= currentVersion then
			print(`[Light Reflector] New version available! Current: {currentVersion} | Latest: {latestVersion}`)
			--^ not using wrapped since it has to print anyway
		end
	end)
end

return {
	name = "init",
	init = function()
		if IS_SERVER then
			require("@self/server/check").init()
		else
			require("@self/client/show").init()
		end
	end,
	start = function()
		if IS_SERVER then
			require("@self/server/check").start()
		else
			require("@self/client/show").start()
		end
	end,
	config = config,
	checkVersion = checkVersion
}
