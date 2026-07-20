---
name: validate-plan
description: Adversarially validate plans, specs, RFCs, architecture proposals, migration designs, and other design documents. Use when asked to stress-test assumptions, verify a plan against official docs or code evidence, identify design risks, or produce concrete plan changes that increase robustness.
license: Apache-2.0
compatibility: Requires read access to the target document and repository context. Benefits from web/MCP access such as Exa, Context7, Ref, or direct documentation fetches, especially for vendor APIs and current platform behavior.
metadata:
  author: jope35
  version: "1.0.0"
---

# Validate Plan

Adversarially validate a plan, spec, RFC, architecture proposal, migration plan, or other design document. The goal is not to approve the document; the goal is to find the assumptions most likely to break and return a comprehensive change set that makes the design more robust.

## When to use

- A user asks to validate, review, stress-test, challenge, harden, or de-risk a plan or spec.
- A design depends on external systems, frameworks, SDKs, cloud services, APIs, compliance rules, scaling assumptions, or operational procedures.
- A document contains implementation strategy, architecture, rollout/migration steps, data model changes, security posture, performance claims, or dependency assumptions.
- A user wants a stronger plan, not just a summary.

Do not use this skill for ordinary code review unless the code review is specifically about validating a written design or rollout plan.

## Operating stance

Act like a skeptical principal engineer validating the design before it becomes expensive to change.

1. **Extract assumptions before judging.** Identify explicit claims and hidden premises in the document.
2. **Seek disconfirming evidence.** Try to nullify risky assumptions, not merely support them.
3. **Ground findings in evidence.** Use source code, local docs, official documentation, standards, release notes, and vendor references. Avoid uncited claims for external behavior.
4. **Return changes, not vibes.** Every material risk should become a concrete edit, test, mitigation, invariant, rollback step, or open decision in the plan.
5. **Prefer small but meaningful changes.** Improve the plan with the smallest edits that materially reduce risk, clarify ownership, or make validation possible. Avoid broad rewrites, new architecture, or process ceremony unless the evidence shows they are necessary.
6. **Separate certainty from suspicion.** Label unsupported concerns as hypotheses and explain what evidence would resolve them.

## Evidence sources and tool mapping

Use the best evidence available in the current harness. Map these intents to local tools:

| Intent | Preferred sources |
|--------|-------------------|
| Validate repository-specific behavior | Source search, tests, schemas, config, migrations, existing docs, git history |
| Validate library or framework APIs | Context7, Ref, official docs, typed definitions, release notes |
| Validate current vendor/platform behavior | Exa search/fetch, official docs, product release notes, API references |
| Validate a specific URL | Fetch the URL directly, then follow relevant official links |
| Validate an `llms.txt`-aware documentation site | Fetch `/llms.txt`, use it as the docs index, then fetch the linked markdown pages most relevant to the assumptions |
| Validate standards or protocols | Standards documents, official specs, maintainers' references |

### MCP and external documentation discipline

Before validating external assumptions, discover which documentation and research tools are available in the current harness. Use any relevant MCP or web/documentation fetcher, such as Exa, Context7, Ref, direct URL fetch, or vendor-specific docs tools.

- Prefer Context7, Ref, typed definitions, or official API references for library and framework behavior.
- Prefer Exa, direct fetch, official product docs, release notes, and `llms.txt` indexes for current vendor/platform behavior.
- Match docs to the plan's stated version, cloud, region, deployment model, and product tier when those details matter.
- If a tool, URL, or documentation source is unavailable, blocked, or inconclusive, flag the affected assumptions as evidence gaps. Do not silently skip external validation.
- Fetch full source pages for decisive claims. Search snippets can identify leads, but they are not enough for final evidence.

### `llms.txt` documentation workflow

When a plan depends on documentation hosted on a known domain, first try the LLM-friendly index if the site may support it:

1. Derive the documentation origin from the plan, for example `https://docs.databricks.com`.
2. Fetch `https://<docs-host>/llms.txt`.
3. Treat the returned markdown as an index, not as complete proof. Identify links whose titles/descriptions match the assumption.
4. Fetch the most relevant linked pages, preferably markdown variants when offered.
5. Cite the exact fetched page, section/title, and what it proves or disproves.
6. If `/llms.txt` is unavailable or incomplete, fall back to official docs search, Context7, Ref, Exa, or direct known URLs.

Prefer official docs over blogs, generated summaries, forum posts, or marketing pages. For high-risk assumptions, seek at least two independent official or source-backed references when feasible.

## Validation workflow

### 1. Identify the target and scope

Find the document or text to validate. If multiple documents apply, validate the highest-level plan first and inspect supporting docs only as needed. Capture:

- Document path or title
- Intended outcome
- Systems and teams touched
- Versions, environments, vendors, APIs, and deployment targets mentioned
- Any constraints the author assumes, such as timelines, compatibility, cost, latency, permissions, or compliance requirements

If the target document is missing or ambiguous, ask for it before performing a full validation.

### 2. Build an assumption ledger

Read the document and extract assumptions into a ledger. Include both explicit and implicit assumptions.

Classify each assumption by type:

- **API/platform:** supported operations, version behavior, quotas, lifecycle, deprecations
- **Data:** schemas, volume, quality, retention, ordering, idempotency, consistency
- **Architecture:** boundaries, ownership, coupling, extension points, compatibility
- **Security/privacy/compliance:** auth, permissions, secret handling, isolation, auditability, data residency
- **Operations:** deployability, rollback, monitoring, alerting, incident response, support load
- **Migration/rollout:** backfills, dual writes, compatibility windows, reversibility, feature flags
- **Performance/cost:** latency, throughput, capacity, caching, billing, resource ceilings
- **Product/user behavior:** workflow assumptions, adoption, failure modes, edge cases

Prioritize assumptions by blast radius and uncertainty. Validate the riskiest claims first, but do not stop after finding one issue.

### 3. Gather evidence adversarially

For each high- or medium-risk assumption:

1. Search local source, tests, schemas, and docs for existing contracts or contradictions.
2. Use Context7, Ref, Exa, direct vendor docs, or `llms.txt` indexes to verify external API/platform claims.
3. Check version-specific behavior. Do not assume latest docs apply if the plan names an older version.
4. Look for hard constraints: unsupported operations, quotas, consistency guarantees, auth requirements, regional availability, pricing boundaries, deprecations, and migration limitations.
5. Record whether evidence verifies, weakens, nullifies, or fails to address the assumption.
6. Track blocked checks separately from validated assumptions so the final report clearly shows what could not be verified.

Do not overfit to snippets. Fetch the full relevant page or source file when a snippet determines a finding.

### 4. Attack the design

Stress the plan from multiple angles:

- What must be true for this plan to work, and where is that not proven?
- Which dependency could make the design invalid if a vendor/API behaves differently?
- Which step is irreversible, hard to roll back, or unsafe under partial failure?
- What happens during retries, duplicate events, out-of-order data, stale caches, timeouts, rate limits, or regional outages?
- What data can be lost, leaked, corrupted, double-processed, or made inconsistent?
- What security boundary, permission model, or audit requirement is underspecified?
- What operational signal would show the rollout is failing before users report it?
- What invariant should be continuously checked?
- Which plan section would mislead an implementer or reviewer?

### 5. Convert findings into plan changes

Every significant finding should become one or more actionable changes:

- Replace an invalid assumption with evidence-backed wording.
- Add missing constraints, version requirements, or compatibility notes.
- Add preflight checks, proof-of-concept tasks, or spike questions.
- Add rollout gates, feature flags, rollback procedures, and kill switches.
- Add data migration safeguards, idempotency requirements, replay strategy, and validation queries.
- Add observability: metrics, logs, traces, dashboards, alerts, SLOs, and success/failure thresholds.
- Add security/privacy/compliance controls and explicit ownership.
- Add test coverage: unit, integration, migration, load, chaos/failure, permission, or end-to-end tests.
- Split an oversized or coupled design into smaller phases when that reduces risk.

Keep changes small but meaningful:

- Prefer inserting a missing invariant, test, rollout gate, or version constraint over rewriting an entire section.
- Preserve the author's intent and terminology when they are sound.
- Combine related edits only when they address the same failure mode.
- Do not add speculative safeguards that have no clear risk, owner, or verification path.
- If a large redesign appears necessary, explain the minimum evidence-backed reason and identify the smallest viable rework.

### 6. Require a verification and validation section

The target plan should include a dedicated section named **Verification and validation**, **Testing and validation**, or an equivalent heading. If the plan lacks one, add it to the change set. If it has one, validate that it is specific enough to prove the plan's output works.

That section should answer "How do we test this?" with concrete checks, not generic confidence statements:

- **Success criteria:** observable outcomes, acceptance criteria, SLOs, data-quality thresholds, or user-visible behavior that define done.
- **Automated tests:** unit, integration, contract, migration, end-to-end, permission, regression, and performance tests as appropriate.
- **Manual or exploratory validation:** realistic scenarios, edge cases, admin/operator workflows, and negative tests.
- **Data validation:** before/after counts, reconciliation queries, invariants, sampling, backfill validation, idempotency checks, and corruption/loss detection.
- **Operational validation:** metrics, logs, traces, dashboards, alerts, synthetic checks, load tests, failure injection, and rollback drills.
- **Security/compliance validation:** authorization tests, audit log checks, secret handling, data residency, privacy review, and abuse cases where relevant.
- **Rollout gates:** preflight checks, canary criteria, feature-flag checks, hold points, abort thresholds, and rollback verification.
- **Ownership:** who runs each check, where results are recorded, and which failures block launch.

If the user asked you to edit the document, apply the changes after validating. Otherwise, output a comprehensive change set the author can apply.

## Finding statuses

Use precise status labels:

- **Verified:** Evidence supports the assumption as written.
- **Nullified:** Evidence contradicts the assumption.
- **Overbroad:** The assumption is sometimes true but needs narrower conditions.
- **Underspecified:** The assumption may be true, but the plan omits required details.
- **Unsupported:** No sufficient evidence was found.
- **Conflicting evidence:** Credible sources disagree or version context is unclear.
- **Out of scope:** The assumption is not material to the requested validation.

## Required output format

Return a structured validation report with these sections:

1. **Verdict**
   - One of: `Accept with minor changes`, `Revise before implementation`, or `Rework required`.
   - A short explanation of the dominant risks.

2. **Highest-impact plan changes**
   - Bullet list of the most important edits, ordered by severity.

3. **Comprehensive change set**
   - For each change:
     - **Plan location:** heading, section, file path, or quoted text.
     - **Change to make:** exact replacement wording or a precise insertion.
     - **Why:** the assumption or failure mode addressed.
     - **Evidence:** local file references or external URLs/docs used to verify or nullify the assumption.
     - **Validation:** test, check, experiment, or rollout gate that proves the change works.
     - **Severity:** Critical, High, Medium, or Low.

4. **Required verification and validation section**
   - Provide exact wording to add to the plan, or precise edits to the existing testing/validation section.
   - Include success criteria, automated tests, manual validation, operational checks, rollout gates, and ownership.
   - Keep the section scoped to tests that prove the plan's intended output, not unrelated quality wishes.

5. **Assumption validation ledger**
   - Table with: assumption, status, evidence, risk if wrong, required plan update.

6. **Evidence coverage and blocked checks**
   - List unavailable MCPs, inaccessible URLs, missing docs, version ambiguity, or local evidence that could not be inspected.
   - For each gap, name the affected assumption and whether the gap blocks implementation or only reduces confidence.

7. **Open questions**
   - Only include questions that block confidence or meaningfully affect design robustness.

8. **Suggested robustness additions**
   - Tests, observability, rollout/rollback, security, data integrity, performance, and operational improvements that should be added even if no single assumption was nullified.

## Citation requirements

- Cite local evidence with file paths and line numbers when available.
- Cite external evidence with URL, page title or section, and the specific claim it supports.
- If an MCP or web tool is unavailable, say which evidence could not be checked and mark affected assumptions as `Unsupported` or `Conflicting evidence`.
- Do not cite search result snippets as final evidence when the full page is fetchable.

## Pre-completion checklist

- [ ] Target document and scope are clear.
- [ ] Explicit and implicit assumptions were extracted.
- [ ] High-risk assumptions were checked against source or official external evidence.
- [ ] `llms.txt` indexes were attempted for relevant documentation sites when appropriate.
- [ ] Relevant MCP/documentation tools were used when available, and blocked or unavailable checks were flagged.
- [ ] Findings distinguish verified, nullified, unsupported, and underspecified assumptions.
- [ ] Output includes concrete edits to the plan, not only observations.
- [ ] Changes are small enough to preserve sound plan intent while materially reducing risk.
- [ ] The plan includes a concrete verification/validation section that explains how to test the plan's output.
- [ ] Robustness additions cover rollout, rollback, tests, observability, security, and data integrity where relevant.
