# skills

A collection of portable [Agent Skills](https://agentskills.io) for any harness.

[![skills.sh](https://skills.sh/b/jope35/skills)](https://skills.sh/jope35/skills)

## Skills

| Skill | What it does | Use it for |
| --- | --- | --- |
| [validate-plan](./skills/validate-plan/SKILL.md) | Adversarially validates plans, specs, and design documents, then edits them to reduce risk. | Stress-testing a spec, de-risking an RFC, checking assumptions against code and docs. |
| [web-research](./skills/web-research/SKILL.md) | Researches a question across several web sources and synthesizes one cited report. | Finding current information, comparing options, surveying what sources say. |

Both are harness- and model-agnostic: they map intents to whatever search, fetch, file, and delegation capabilities the current harness provides.

## Install

```bash
# Interactive: pick the skills and the agents
npx skills add jope35/skills

# One skill, every agent you use
npx skills add jope35/skills --skill web-research

# Everything, no prompts (CI friendly)
npx skills add jope35/skills --all

# Browse without installing
npx skills add jope35/skills --list

# Run without installing (pipe into an agent)
npx skills use jope35/skills --skill web-research
```

Installs to the current project by default; add `-g` for every project. Compatible with [skills.sh](https://skills.sh) and 70+ agents (Cursor, Claude Code, Codex, OpenCode, Windsurf, and others).

## Web Research

[`skills/web-research/SKILL.md`](./skills/web-research/SKILL.md) — Research a question across several web sources, synthesize the findings, and produce one cited report.

Adapted from the web research example in [langchain-ai/deepagents `libs/code`](https://github.com/langchain-ai/deepagents/tree/main/libs/code/examples/skills/web-research) at [`2ac7d41`](https://github.com/langchain-ai/deepagents/commit/2ac7d4153398889100d5fd163ab4a122633862b5). Harness- and model-agnostic. Licensed under [MIT](skills/web-research/LICENSE), consistent with upstream.

**Triggers:** research a topic online, find current information, compare options across sources, survey what several sources say, produce a cited research report.

**Process:** write `research_[topic_name]/research_plan.md`, run 2-5 non-overlapping subtopics as delegated researchers (up to 3 in parallel) that save findings to files, then synthesize from those files into a cited answer.

**Output:** a direct answer first, then integrated findings with citations, conflicting evidence and gaps, and a source list.

## Validate Plan

[`skills/validate-plan/SKILL.md`](./skills/validate-plan/SKILL.md) — Adversarially validate plans, specs, RFCs, and design documents, then edit them so that a wrong assumption fails visibly.

**Triggers:** validate a plan, stress-test a spec, challenge design assumptions, de-risk an RFC, verify architecture or rollout assumptions against code and official docs.

**Evidence sources:** local source/docs, Exa, Context7, Ref, official documentation, standards, and `llms.txt` documentation indexes where available. Blocked or unavailable evidence checks are flagged instead of silently skipped.

**Output:** the edited document, including a verification and validation section that explains how to test the plan's output. The chat gets a four-line status: verdict, file and change counts, top risk, and the action the user must take. A full report with the change set and evidence ledger is written next to the document only when asked.

## Layout

([Agent Skills specification](https://agentskills.io/specification))

```
skills/
├── validate-plan/     # SKILL.md
└── web-research/      # SKILL.md, LICENSE
```

Validate every skill in the collection:

```bash
npx --yes skills-ref validate ./skills/validate-plan
npx --yes skills-ref validate ./skills/web-research
```

## License

The collection is [Apache-2.0](LICENSE). `web-research` carries its upstream MIT license in [skills/web-research/LICENSE](skills/web-research/LICENSE).
