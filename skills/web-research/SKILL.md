---
name: web-research
description: Research a question across several independent web sources and synthesize the findings into one cited report. Use when asked to look something up online, find current information, compare options, investigate a topic from multiple angles, or produce a research report with sources.
license: MIT
compatibility: Requires web search and page-fetch access plus read/write access to the working directory. Delegation is optional; without it, run the subtopics sequentially.
metadata:
  author: jope35
  version: "1.0.0"
  source: https://github.com/langchain-ai/deepagents/tree/main/libs/code/examples/skills/web-research
  upstream_sha: 2ac7d4153398889100d5fd163ab4a122633862b5
---

# Web Research

Answer a research question from several independent web sources and synthesize the results into one cited report. Findings live in files on disk, so each subtopic stays isolated and the final synthesis reads evidence instead of memory.

This portable skill follows the web research example in [langchain-ai/deepagents `libs/code`](https://github.com/langchain-ai/deepagents/tree/main/libs/code/examples/skills/web-research). The process is unchanged; harness-specific tool names are mapped to generic capabilities and the output contract is made explicit.

## When to use

- The answer depends on information outside the repository and outside training data: current releases, prices, policies, benchmarks, market or vendor comparisons.
- The user asks for a research report, a sourced comparison, or a survey of what different sources say.
- A single search is unlikely to be enough because the question has separable parts.

Do not use for a single lookup that one search answers, for questions the repository already answers, or when the user asked for an opinion rather than evidence. Say so and answer directly.

## Harness-agnostic capabilities

Map these intents to the tools available in the current harness:

| Intent | Typical capability |
| --- | --- |
| Search the web | web search tool, search API, or search MCP server |
| Read a page | URL fetch, browser, or content extraction tool |
| Write and read working files | write, edit, read, list, or shell equivalents |
| Delegate a subtopic | subagent, child task, or task tool with a fresh context |

If search or fetch access is unavailable, stop and report the limitation instead of answering from memory as if it were researched. If delegation is unavailable, do the subtopics yourself in sequence and keep the same file layout.

## Workflow

### 1. Plan before searching

1. **Analyze the question.** Break it into 2-5 distinct, non-overlapping subtopics.
2. **Create a research folder** in the working directory: `research_[topic_name]/`. Keep every working file inside it so the repository root stays clean.
3. **Write `research_[topic_name]/research_plan.md`** containing:
   - the main research question, in one sentence;
   - the subtopics, in investigation order;
   - what evidence each subtopic must produce;
   - how the findings will be combined into an answer.

Size the plan to the question: 1-2 subtopics for a simple fact check, one per comparison element (max 3) for a comparison, 3-5 for a broad investigation. A plan that mirrors the user's sentence back without splitting it is not a plan.

### 2. Delegate or run each subtopic

For each subtopic, give the researcher a self-contained brief:

- a specific question with no unresolved acronyms;
- the output file path, `research_[topic_name]/findings_[subtopic].md`;
- a budget of 3-5 searches;
- the instruction to record facts, short quotes, dates, and source URLs, and to note what could not be confirmed.

Use this template:

```
Research [SPECIFIC TOPIC]. Search the web and read the most authoritative pages
you find. Save your findings to research_[topic_name]/findings_[subtopic].md,
including key facts, short supporting quotes, publication dates, and source URLs.
Flag anything you could not confirm. Use at most 5 searches.
```

Run up to 3 researchers in parallel when the harness supports it. Do not give two researchers the same scope; duplicated evidence wastes budget and hides gaps.

### 3. Synthesize from the files

1. **List the research folder** to confirm which findings files exist.
2. **Read each findings file** before writing anything. Read from local paths, not from URLs; use the fetch capability for pages, never a local file reader.
3. **Reconcile the evidence.** Where sources disagree, report the disagreement and which source is stronger, rather than picking one silently. Where a subtopic came back thin, say so.
4. **Answer the original question directly**, then support it with the integrated findings and cited sources.
5. **Write `research_[topic_name]/research_report.md`** only when the user asked for a report or the answer is too long for the chat response.

Stop when the plan's questions are answered. Additional searches beyond the budget need a named gap they close.

## Evidence and citation rules

- Cite each important claim with a URL plus the page title or section. A bare domain is not a citation.
- Prefer primary sources: official documentation, release notes, filings, standards, first-party announcements. Treat aggregators and SEO summaries as leads, not evidence.
- Record publication or last-updated dates and state the as-of date when freshness changes the answer.
- Quote sparingly and exactly; never paraphrase a quote into quotation marks.
- Never invent a URL, statistic, quote, or source. If it was not in a findings file or a page you fetched, it does not go in the answer.
- Name the limits: missing data, paywalled sources, single-source claims, and questions the evidence cannot settle.

## Required output

The final response contains, in this order:

1. **Answer** — the direct answer to the main question in the first paragraph.
2. **Findings** — the integrated evidence, grouped by subtopic, with citations.
3. **Conflicts and gaps** — disagreements between sources and what remains unknown.
4. **Sources** — the cited URLs with titles.

Keep the report free of process narration; the plan and findings files are the audit trail.

## Common mistakes

- Searching before writing the plan, then retrofitting subtopics to whatever was found.
- Overlapping subtopics that return the same three pages.
- Letting researchers return prose in the conversation instead of writing findings files.
- Trusting a finding file without opening the cited URL when the claim is load-bearing.
- Presenting a synthesis of one source as a multi-source survey.
- Researching past the point of diminishing returns; 3-5 searches per subtopic is usually enough.

## Pre-completion checklist

- [ ] `research_[topic_name]/research_plan.md` exists and names non-overlapping subtopics.
- [ ] Every planned subtopic has a findings file, or its absence is explained.
- [ ] Each findings file records sources with URLs and dates.
- [ ] The answer opens with the direct answer, not with the method.
- [ ] Every load-bearing claim carries a citation that was actually read.
- [ ] Conflicting evidence and gaps are reported, not smoothed over.
- [ ] `research_report.md` exists only if the user asked for one or the answer outgrew the chat.
- [ ] No invented URLs, numbers, or quotes anywhere in the output.
