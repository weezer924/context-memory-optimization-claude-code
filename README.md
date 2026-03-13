# Context & Memory Optimization with Claude Code

A real-world case study on managing a **55,000-line knowledge base** with an LLM — without hallucinating, without forgetting, and without blowing up the context window.

---

## What problem were we targeting?

How do you make an LLM reliably operate on a large, interconnected knowledge base — **254 files, ~55K lines** of rules, state data, session history, profiles, and world data across 7 domains?

The naive approach — dump everything into context — fails immediately. Token limits, lost-in-the-middle effects, and skyrocketing costs. The other extreme — give the model nothing — produces hallucinated data and inconsistent state.

**The challenge: find the sweet spot between "too much context" and "not enough."**

---

## What did we build?

A **layered context architecture** with three tiers:

### Tier 1: Always-loaded core (~800 lines)

| File | Lines | Purpose |
|------|-------|---------|
| `CLAUDE.md` | 245 | Operational rulebook — priority hierarchy, decision procedures, validation requirements |
| `state.yaml` | 211 | Single source of truth for all mutable data |
| Latest session log | ~200 | Immediate working memory |
| Working notes | 193 | Active flags, pending events, tracker |

This is the "working memory." Always in context. Enough to operate, not enough to hallucinate from.

### Tier 2: On-demand loading protocol (12,000+ lines available)

- A **lookup table in CLAUDE.md** maps 20+ trigger conditions to specific files
- The model **must read before answering** — enforced as the #1 operational rule
- Shell tools extract just the relevant section instead of loading full files

Example: instead of loading a 6,105-line reference document, a lookup script returns 8 lines + a line number. **95% context reduction** for common lookups.

### Tier 3: Persistent memory system

- Claude Code's `/memory/` directory stores cross-session knowledge
- User preferences, past mistakes, architectural decisions carry forward automatically
- `MEMORY.md` serves as an indexed, typed catalog (user/feedback/project/reference)
- Prevents re-learning the same lessons every session

### Key Optimizations

| Optimization | Impact |
|-------------|--------|
| **Single source of truth** — one YAML file for all mutable numbers, validated by a lint script | Zero data duplication, zero sync conflicts |
| **Shell tool abstraction** — lookup scripts extract 8 lines from 6,000-line files | **95% context reduction** for lookups |
| **Checkpoint system** — auto-detects state drift every 3 major events, forces full sync | Prevents accumulated errors |
| **Layered file architecture** — 7 region directories, identical structure, only active region loaded | **~85% of world data stays unloaded** |
| **Memory decay management** — tracks what's been communicated vs. what's hidden | Prevents accidental information leaks |
| **Domain logic refactor** — deleted ~500 lines across 3 files, consolidated into 1 (162 lines) | **68% reduction** while adding features |

---

## Milestones: From Zero to Production

### Phase 0 — Cold Start (Commits 1–10)
> *"Just throw everything in CLAUDE.md and hope for the best"*

- One giant instruction file, no state management, no tools
- Claude hallucinated outputs, forgot entity names between sessions, invented data that didn't exist
- Session logs were the only persistence — no structured data at all
- **Pain point**: Every new conversation was amnesia. Claude re-learned the domain from scratch each time

### Phase 1 — Structured State (Commits 11–30)
> *"If it's not in a file, it doesn't exist"*

- Introduced `state.yaml` as single source of truth for all mutable data (metrics, resources, inventory, calendar)
- Split domain data into regional directories with consistent file structures
- Created entity profile files with structured sections (attributes, history, relationships)
- Added shared state files and task tracking logs
- **Result**: Claude stopped inventing data — but still loaded too much context per turn

### Phase 2 — Tool Augmentation (Commits 31–60)
> *"Don't memorize the library — build a card catalog"*

- Built **randomization scripts** — deterministic random outputs, eliminating hallucinated results
- Built **calculation engine** — math-heavy operations offloaded to shell commands
- Built **domain-specific generators** — region-aware content generation (9 region variants)
- Built **targeted lookup scripts** — extract 8 lines from 6,000-line reference files
- Added **lint/validation script** — cross-file consistency checks (entity data vs state.yaml)
- Added **checkpoint script** — periodic state sync with drift detection
- Added **session archiver** — full state snapshot with calculation and data validation
- **Result**: Common lookups went from loading entire reference files to ~8-line extractions. **95% context reduction** for reference queries

### Phase 3 — On-Demand Loading Protocol (Commits 60–90)
> *"Read before you answer — no exceptions"*

- Created the **trigger-action table** in CLAUDE.md: 20+ conditions mapped to specific files
- Established "read before write" as the **#1 operational rule** — Claude must load the file before making any ruling
- Reduced startup from 16 files to 4 core files + on-demand loading for everything else (~34% token reduction)
- Moved `SKILL.md` to on-demand (saved ~500 tokens per session)
- Built `MEMORY.md` as a persistent cross-session index — preferences, past mistakes, key decisions survive between conversations
- **Result**: Startup cost dropped from ~2,500 lines to ~800 lines. Factual errors dropped ~90%

### Phase 4 — Full System Migration (Commits 90–140)
> *"Swap the engine while the car is moving"*

- Migrated the entire rule/reference system from legacy format to a new version at the Session 29 boundary
- Rewrote all 8 shell tools for the new system's mechanics
- Converted 12,000+ lines of reference documents to the new format
- Archived all legacy rules — CLAUDE.md explicitly forbids referencing them
- Rebuilt entity files, data tables, and domain logic for the new system
- Rebuilt web dashboard to match
- **Zero data loss** across the migration — all 29 sessions of history preserved

### Phase 5 — Context Optimization Sprints (Commits 140–180)
> *"Every token you load is a token you can't think with"*

- **Sprint 1**: Removed unused subsystems — deleted hundreds of lines Claude was loading but never using
- **Sprint 2**: Split inactive entities to a frozen state file — only active entities consume context
- **Sprint 3**: Extracted formatting rules and domain logic into standalone files, loaded only when needed
- **Sprint 4**: Merged 3 working notes files into 2, eliminating redundancy
- **Sprint 5**: Consolidated related rule files, deleted standalone duplicates
- **Sprint 6 (Domain logic refactor)**: Deleted ~500 lines across 3 files, rebuilt as 1 file (162 lines) with *more* features. **68% reduction**
- Replaced script-based scoring with direct ruling — deleted calculation script, simplified rules by ~40%
- **Result**: Total always-loaded context cut from ~2,500 lines to ~800 lines over 6 sprints. Same capabilities, 68% less context

### Phase 6 — Current State (230 commits, 42 sessions)
> *"The system runs itself — I just play"*

- **254 files, ~55K lines** of structured content across 7 world regions
- **8 shell tools** handling randomization, calculations, lookups, validation, and archiving
- **3-tier context architecture** fully operational (always-loaded / on-demand / persistent memory)
- **Self-correction loop**: lint script at startup catches drift before it compounds
- **Automated checkpoints**: state syncs every 3 major events without manual intervention
- **Web dashboard**: browser-based character sheet and state viewer
- Zero data loss across 42 sessions spanning months of real time

---

## How Claude is involved

Claude Code is the **execution engine**, not just a chat assistant.

### Structured operational rules

The 245-line `CLAUDE.md` isn't a prompt — it's a **runtime specification**:
- Priority hierarchy (which rules override which)
- Startup checklist (4 files to read before any output)
- Trigger-action table (20 conditions -> file loading requirements)
- Output format standards
- Validation requirements ("read file before answering" as a hard rule)

### Tool-augmented reasoning

8 shell scripts extend Claude's capabilities:

| Category | Purpose |
|----------|---------|
| **Randomization** | Deterministic random outputs (no hallucinated results) |
| **Calculation engine** | Math-heavy operations (ordering, resolution, coverage) |
| **Targeted lookups** (x2) | Extract 8 lines from 6,000-line reference files |
| **Lint / validation** | Self-verification (catches its own drift at startup) |
| **Checkpoint** | Periodic state persistence with drift detection |
| **Content generator** | Structured random generation with region awareness |
| **Session archiver** | Full state snapshot with cross-file validation |

### Cross-session memory

- 42 sessions across weeks of real time
- Without memory, each conversation starts from zero
- With memory: preferences, past mistakes, architectural decisions carry forward
- Memory is **indexed** and **typed** — the model knows *when* to access which memories

### Self-correction loop

A lint script catches inconsistencies between files at startup. This is **automated hallucination detection** — the system catches when the model wrote inconsistent data and forces resolution before proceeding.

---

## Takeaways

### 1. Context is architecture, not just a limit

Don't think "how do I fit more in the window" — think "what's the minimum the model needs right now, and where does it look up the rest?" The 3-tier pattern (always-loaded / on-demand / persistent memory) works for any large knowledge base.

### 2. Shell tools are underrated

A 10-line grep script that extracts 8 lines from a 6,000-line file saves more context than any prompt engineering trick. **Give the model tools to look things up, not documents to memorize.**

### 3. Enforce "read before write"

The single highest-impact rule: the model must read the relevant file before generating output that depends on it. This one rule — enforced in CLAUDE.md, validated by a lint script — eliminated ~90% of factual errors.

**Hallucination is a retrieval problem, not a generation problem.** If the model has the right data in context at decision time, it almost never makes things up.

### The numbers

- **55,000 lines** of content, **~800 lines** loaded per interaction
- **230 commits**, 42 sessions, zero data loss
- **8 shell tools**, 1 validation script
- 1 refactor cycle: **68% context reduction** while adding features

### The meta-lesson

Claude Code isn't just a coding assistant — it's a **stateful agent runtime**. `CLAUDE.md` is the program. Shell tools are the standard library. Memory is the database. The context window is RAM. Design accordingly.
