---
name: web-research
description: Research a question across several independent web sources and synthesize the findings into one cited report. Use when asked to look something up online, find current information, compare options, investigate a topic from multiple angles, or produce a research report with sources.
license: MIT
compatibility: Requires web search and page-fetch access plus read/write access to the working directory. Delegation is optional. Without it, run the subtopics in sequence.
metadata:
  author: jope35
  version: "1.0.0"
  source: https://github.com/langchain-ai/deepagents/tree/main/libs/code/examples/skills/web-research
  upstream_sha: 2ac7d4153398889100d5fd163ab4a122633862b5
---

# Web Research

Answer a research question from several independent web sources. Synthesize the results into one report with citations. Findings live in files on disk. Each subtopic stays isolated, and the final synthesis reads evidence from disk instead of memory.

This portable skill follows the web research example in [langchain-ai/deepagents `libs/code`](https://github.com/langchain-ai/deepagents/tree/main/libs/code/examples/skills/web-research). The process is unchanged. Harness-specific tool names map to generic capabilities, and the output contract is explicit.

## When to use

- The answer depends on information outside the repository and outside training data. Examples are current releases, prices, policies, benchmarks, and vendor comparisons.
- The user asks for a research report, a comparison with sources, or a survey of what different sources say.
- A single search will not be enough because the question has separable parts.

Do not use this skill for a single lookup that one search answers. Do not use it for a question that the repository already answers. Do not use it when the user asks for an opinion, not evidence. In those cases, say so and answer directly.

## Harness-agnostic capabilities

Map these intents to the tools that the current harness provides:

| Intent | Typical capability |
| --- | --- |
| Search the web | web search tool, search API, or search MCP server |
| Read a page | URL fetch, browser, or content extraction tool |
| Write and read working files | write, edit, read, list, or shell equivalents |
| Delegate a subtopic | subagent, child task, or task tool with a fresh context |

If search or fetch access is unavailable, stop and report the limitation. Do not answer from memory as if you did the research. If delegation is unavailable, do the subtopics yourself in sequence and keep the same file layout.

## Workflow

### 1. Plan before searching

1. Analyze the question. Break it into 2-5 distinct subtopics that do not overlap.
2. Create a research folder in the working directory, named `research_[topic_name]/`. Keep every working file inside it. The repository root stays clean.
3. Write `research_[topic_name]/research_plan.md`. It contains:
   - The main research question, in one sentence.
   - The subtopics, in investigation order.
   - The evidence that each subtopic must produce.
   - The way that the findings will combine into an answer.

Size the plan to the question. Use 1-2 subtopics for a simple fact check. Use one subtopic for each comparison element, 3 at most. Use 3-5 subtopics for a broad investigation. A plan that repeats the user's sentence without splitting it is not a plan.

### 2. Delegate or run each subtopic

For each subtopic, give the researcher a brief that is complete on its own:

- A specific question with no unresolved acronyms.
- The output file path, `research_[topic_name]/findings_[subtopic].md`.
- A budget of 3-5 searches.
- The instruction to record facts, short quotes, dates, and source URLs, and to note what you cannot confirm.

Use this template:

```
Research [SPECIFIC TOPIC]. Search the web and read the most authoritative pages
you find. Save your findings to research_[topic_name]/findings_[subtopic].md.
Include key facts, short supporting quotes, publication dates, and source URLs.
Flag anything that you cannot confirm. Use at most 5 searches.
```

Run up to 3 researchers in parallel when the harness supports it. Do not give two researchers the same scope. Duplicated evidence wastes budget and hides gaps.

### 3. Synthesize from the files

1. List the research folder. Confirm which findings files exist.
2. Read each findings file before you write anything. Read from local paths, not from URLs. Use the fetch capability for pages. Never use a local file reader for a page.
3. Reconcile the evidence. When sources disagree, report the disagreement and the stronger source. Do not pick one source silently. When a subtopic came back thin, say so.
4. Answer the original question directly. Then support the answer with the integrated findings and the cited sources.
5. Write `research_[topic_name]/research_report.md` only when the user asked for a report, or when the answer is too long for the chat.

Stop when the plan's questions are answered. A search beyond the budget needs a named gap that it closes.

## Evidence and citation rules

- Cite each important claim with a URL and the page title or section. A bare domain is not a citation.
- Prefer primary sources: official documentation, release notes, filings, standards, first-party announcements. Treat aggregators and search engine summaries as leads, not evidence.
- Record publication or last-updated dates. State the as-of date when freshness changes the answer.
- Quote sparingly and exactly. Never paraphrase text and put it in quotation marks.
- Never invent a URL, statistic, quote, or source. If the claim was not in a findings file or on a page that you fetched, it does not go in the answer.
- Name the limits: missing data, paywalled sources, single-source claims, and questions that the evidence cannot settle.

## Required output

The final response contains these sections, in this order:

1. Answer: the direct answer to the main question, in the first paragraph.
2. Findings: the integrated evidence, grouped by subtopic, with citations.
3. Conflicts and gaps: disagreements between sources and what remains unknown.
4. Sources: the cited URLs with titles.

Keep the report free of process narration. The plan and findings files are the audit trail.

## Common mistakes

- Searching before you write the plan, then adding subtopics to match what you found.
- Overlapping subtopics that return the same three pages.
- Letting researchers return prose in the conversation instead of findings files.
- Trusting a finding file without opening the cited URL when the claim matters.
- Presenting the synthesis of one source as a survey of many sources.
- Researching past the point of diminishing returns. 3-5 searches per subtopic are usually enough.

## Pre-completion checklist

- [ ] `research_[topic_name]/research_plan.md` exists and names subtopics that do not overlap.
- [ ] Every planned subtopic has a findings file, or you explain why it does not.
- [ ] Each findings file records sources with URLs and dates.
- [ ] The answer opens with the direct answer, not with the method.
- [ ] Every claim that matters carries a citation that you read.
- [ ] You report conflicting evidence and gaps. You do not smooth them over.
- [ ] `research_report.md` exists only if the user asked for one or the answer outgrew the chat.
- [ ] No invented URLs, numbers, or quotes appear anywhere in the output.
