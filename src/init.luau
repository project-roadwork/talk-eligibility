--[[
    SPDX-FileCopyrightText:   Copyright 2026 Illinois_Roadbuff (Rogue Jr) <illinois_roadbuff@proton.me>
	SPDX-FileCopyrightText:   Copyright 2026 Project Roadwork and Contributors

	SPDX-License-Identifier:   BSD-2-Clause-Patent

	VIEW README FILE FOR MORE INFORMATION LOCATED AT:
		GIT: ./README.md

	GIT REPOSITORIES:
		Codeberg / Forgejo (main): https://codeberg.org/project-roadwork/talk-eligibility.git
		GitHub (mirror): https://github.com/project-roadwork/talk-eligibility.git
]]

local RunService: RunService = game:GetService("RunService")
local IS_SERVER: boolean = RunService:IsServer()
local config = require("@self/shared/config")

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
}
