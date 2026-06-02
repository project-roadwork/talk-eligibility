--[[

    SPDX-FileCopyrightText:   Copyright 2026 Illinois_Roadbuff (Rogue Jr) <illinois_roadbuff@proton.me>
	SPDX-FileCopyrightText:   Copyright 2026 Project Roadwork and Contributors

	SPDX-License-Identifier:   Apache-2.0 WITH LLVM-exception

]]

--!native
--!strict

local config = require("./config")

export type ShowModule = {
	read name: string,
	read init: () -> (),
	read start: () -> (),
}

export type CheckModule = {
	read name: string,
	read init: () -> (),
	read start: () -> (),
}

export type ConfigModule = typeof(config)
export type BaseConfig = typeof(config.getConfig())

export type createSystemMessage = (DefinedSystemChannel: TextChannel, msgDict: { [string]: any }) -> ()
export type createMultiplePlayerString = (talkablePlayers: { [Player]: boolean }, getTalkable: boolean) -> string
export type createMultiplePlayerStringWithOmit = (
	talkablePlayers: { [Player]: boolean },
	getTalkable: boolean,
	maxNumber: number
) -> string

export type Utils = {
	read name: string,
	read wrappedWarn: (string) -> (),
	read wrappedPrint: (string) -> (),
	read versionToString: (Version) -> string,
	read createSystemMessage: createSystemMessage,
	read createMultiplePlayerString: createMultiplePlayerString,
	read createMultiplePlayerStringWithOmit: createMultiplePlayerStringWithOmit,
}

export type Version = {
	read major: number,
	read minor: number,
	read patch: number,
	read pre_release: string,
	read build: number,
	read metadata: string,
}

return {}
