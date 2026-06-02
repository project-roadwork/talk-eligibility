/*
    SPDX-FileCopyrightText:   Copyright 2026 Illinois_Roadbuff (Rogue Jr) <illinois_roadbuff@proton.me>
	  SPDX-FileCopyrightText:   Copyright 2026 Project Roadwork and Contributors

	  SPDX-License-Identifier:   BSD-2-Clause-Patent

	  VIEW README FILE FOR MORE INFORMATION LOCATED AT:
		  GIT: ./README.md

	  GIT REPOSITORIES:
		  Codeberg / Forgejo (main): https://codeberg.org/project-roadwork/talk-eligibility.git
		  GitHub (mirror): https://github.com/project-roadwork/talk-eligibility.git
*/

declare const LightReflector: {
  name: "init";

  init(): void;
  start(): void;

  config: any; /* not listing every config type individually */

  checkVersion(): void;
};

export = LightReflector;
