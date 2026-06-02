# Talk Eligibility
**A typed library that checks which players can chat with one another based on ROBLOX chat permissions.**

> [!NOTE]
> ***You must have the new Luau type solver enabled in `Workspace` in order to receive proper types.***

## Installation
*You may get the `.rbxm` file directly from [Codeberg Releases](https://codeberg.org/project-roadwork/talk-eligibility/releases), or *install via Wally or Pesde*:**

**Install via pesde:**
```bash
pesde add project_roadwork/light_reflector@version
pesde install
```
*Replace version with the current version of the package.*

**Or install via Wally:**
Add this to your `wally.toml` file:

```toml [wally.toml]
[dependencies]
lightreflector = "illinois-roadbuff/light-reflector@version"
```
*Replace version with the current version of the package.*

Then, type this into your terminal and press enter:
```bash
wally install
```

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
local BASE_CONFIG = {

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
**Licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0) WITH the [LLVM exception](https://spdx.org/licenses/LLVM-exception.html).**
