# Talk Eligibility
**A typed library that checks which players can chat with one another based on ROBLOX chat permissions.**

## Installation

## Quick Start
```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TalkEligibility = require(ReplicatedStorage.Packages["talk-eligibility"])

task.wait(5) -- Make sure to wait for a few seconds

TalkEligibility.init()
TalkEligibility.start()
```

## Configuration
```luau
const BASE_CONFIG = {

	  CheckForUpdates = true,
	  ShowPrints = true,
	  ShowWarns = true,

    TextChatService = game:GetService("TextChatService"),
    --^ Change this if you are using something like OpenTextChatService

    BeginningString = `<b><font color="#{Color3.fromRGB(210, 210, 210):ToHex()}">[Talk Eligibility]</font></b> `,
    CanChatTemplate = "🔊 %s joined. You are able to talk with this player.",
    CannotChatTemplate = "🔇 %s joined. You are not able to talk with this player.",
    NotDeterminedTemplate = "❔%s joined. You may or may not be able to talk with this player.",
    NoRestrictionsTemplate = "🔊 You can talk to everyone in this server.",
    CannotChatWithAllTemplate = "🔇 You cannot talk to anyone in this server.",
    OnlyOneTemplate = "🔇 You are the only person in this server.",

    CanChatWithMultiple = "🔊 You can talk with the following players: %s.",
    CannotChatWithMultiple = "🔇 However, you cannot talk with the following players: %s.",

    ShowTalkablePlayers = true,
    ShowNonTalkablePlayers = true,

    -- Max amount shown until cutoff (e.g., plr1, plr2, and 2 others)
    MaxTalkablePlayersShown = 10,
    MaxNonTalkablePlayersShown = 10,

    FontSize = 15,
    FontFace = "Gotham",
    CanChatColor3 = Color3.fromRGB(198, 255, 192),
    CannotChatColor3 = Color3.fromRGB(255, 142, 142),
    NotDeterminedColor3 = Color3.fromRGB(210, 210, 210),
}
```

## License
**Licensed under the Apache License 2.0 WITH the LLVM exception.**
