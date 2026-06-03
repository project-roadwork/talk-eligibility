--!native
--!optimize 2
--!strict

--[[

    SPDX-FileCopyrightText:   Copyright 2026 Illinois_Roadbuff (Rogue Jr) <illinois_roadbuff@proton.me>
	SPDX-FileCopyrightText:   Copyright 2026 Project Roadwork and Contributors

    Derived from: https://github.com/howmanysmall/thread-utilities.git

	SPDX-FileCopyrightText:   Copyright (c) 2024 Bura Games
	SPDX-License-Identifier:   MIT

]]

local freeThreads: { thread } = {}

-- Table variables
local insert: <T>({ T }, T) -> () = table.insert
local unpack: <V>({ V }, number?, number?) -> ...V = table.unpack

-- Coroutine variables
local create: ((...any) -> ()) -> thread = coroutine.create
local yield: (...any) -> ...any = coroutine.yield
local resume: (thread, ...any) -> (boolean, ...any) = coroutine.resume

-- Task variables
local defer: ((...any) -> () | thread, ...any) -> thread = task.defer

local function RunFunction<Arguments...>(callback: (Arguments...) -> (), thread: thread, ...: Arguments...): ()
	callback(...)
	insert(freeThreads, thread)
end

local function Yield(): ()
	while true do
		RunFunction(yield())
	end
end

local function FastDeferSafe<Arguments...>(callback: (Arguments...) -> (), ...: Arguments...): thread
	local thread: thread
	local freeAmount: number = #freeThreads

	if freeAmount > 0 then
		thread = freeThreads[freeAmount]
		freeThreads[freeAmount] = nil
	else
		thread = create(Yield)
		resume(thread)
	end

	local length: number = select("#", ...)
	if length == 0 then
		return defer(thread, callback, thread)
	end

	local arguments: { any } = { select(1, ...) }
	return defer(thread, function(): ()
		callback(unpack(arguments, 1, length))
	end, thread)
end

return FastDeferSafe
