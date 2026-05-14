
You are going to create a persistent AI handoff and project continuity system for this repository.

Your goal is to make this project fully survivable across:

* multiple AI sessions,
* different accounts,
* context loss,
* model changes,
* interrupted work,
* and long development cycles.

Create a `/project_docs` folder at the project root.

Inside it create the following files:

* DIRECTIVES.md
* ARCHITECTURE.md
* CURRENT_TASK.md
* SESSION_LOG.md
* STYLE_GUIDE.md
* TODO_GLOBAL.md
* KNOWN_BUGS.md
* PROJECT_OVERVIEW.md

Your first task is to fully initialize those files with useful structure and initial content based on the current project.

IMPORTANT:
The system must be designed so ANY future AI agent can immediately continue development with minimal confusion.

# DIRECTIVES.md

This file is the highest priority file.

It must contain strict operational rules for all future AI agents.

Include rules similar to:

1. Always read:

   * PROJECT_OVERVIEW.md
   * ARCHITECTURE.md
   * CURRENT_TASK.md
   * STYLE_GUIDE.md
     before making changes.

2. When starting a task:

   * immediately document it inside CURRENT_TASK.md.

3. When finishing a task:

   * update CURRENT_TASK.md,
   * update SESSION_LOG.md,
   * and document architectural changes if needed.

4. Never silently refactor unrelated systems.

5. Never rewrite architecture without explicit justification.

6. Keep files modular and small.

7. Prefer many small readable files over giant files.

8. If a task is large:

   * first create a detailed implementation plan,
   * then divide it into smaller subtasks.

9. Always document:

   * important decisions,
   * assumptions,
   * temporary hacks,
   * technical debt,
   * and unfinished work.

10. Never delete project knowledge from markdown files unless obsolete.

11. Keep continuity between sessions as a top priority.

12. Before ending a session:

* summarize completed work,
* summarize pending work,
* and leave the repository in a resumable state.

13. Minimize token usage:

* avoid rereading unnecessary files,
* avoid giant outputs,
* avoid unnecessary explanations.

14. Do not overengineer solutions.

15. Preserve consistency with existing architecture and code style.

# CURRENT_TASK.md

This file should always contain:

* active task,
* current progress,
* next steps,
* affected files,
* warnings,
* blockers,
* and completion state.

# SESSION_LOG.md

Append chronological development logs.

Each session entry should include:

* date/session,
* completed work,
* architectural decisions,
* discovered issues,
* pending follow-ups.

# STYLE_GUIDE.md

Define:

* code organization,
* naming conventions,
* file size philosophy,
* modularity rules,
* architecture preferences,
* forbidden patterns,
* formatting expectations.

Strongly emphasize:

* small readable files,
* modular systems,
* maintainability,
* avoiding monolithic files.

# ARCHITECTURE.md

Document:

* system relationships,
* core architecture,
* important services,
* dependency flow,
* communication patterns,
* major design decisions.

# PROJECT_OVERVIEW.md

Create a concise but high quality overview of:

* project goals,
* gameplay/app purpose,
* current systems,
* development status,
* major priorities.

# TODO_GLOBAL.md

Maintain a global prioritized task list.

# KNOWN_BUGS.md

Track:

* active bugs,
* suspected causes,
* reproduction steps,
* temporary workarounds,
* affected systems.

IMPORTANT:
The markdown system itself must become part of the development workflow.

Future agents should continuously maintain and update these files as development progresses.

After creating the system:

1. Populate all files with meaningful initial content.
2. Analyze the repository structure.
3. Infer architecture where possible.
4. Leave the project in a fully resumable state for future AI sessions.
