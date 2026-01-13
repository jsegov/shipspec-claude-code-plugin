---
name: task-loop-verify
description: Verify the current task and output a completion marker. Use this to check if a task is complete and signal the stop hook to allow session exit.
version: 0.1.0
allowed-tools: Read, Glob, Grep, Bash(rm:*), Task
---

# Task Loop Verification

Verify the current task in the loop and output a completion marker if successful. This skill wraps task-verifier and outputs the marker that the stop hook looks for.

## When to Use

Use this skill when:
- You've finished implementing a task and want to verify it
- The stop hook has triggered another loop iteration
- You want to exit the task loop cleanly

## Process

### Step 1: Read Loop State

Read `.claude/shipspec-task-loop.local.md` to get current task information:

```bash
cat .claude/shipspec-task-loop.local.md 2>/dev/null || echo "NO_STATE_FILE"
```

**If NO_STATE_FILE:**
> "No active task loop. Run `/implement-task <feature> <task-id>` to start a task."
> Stop here.

**If found:**
Parse the YAML frontmatter to extract:
- `feature`: The feature directory name
- `task_id`: The task being implemented
- `iteration`: Current attempt number
- `max_iterations`: Maximum allowed attempts

### Step 2: Load Task Prompt

The task prompt is stored in the state file after the YAML frontmatter.

Extract the full task prompt content (everything after the `---` closing the frontmatter).

### Step 3: Run Verification

Delegate to the `task-verifier` agent with:
- The full task prompt (including acceptance criteria)
- The feature name
- The task ID

### Step 4: Handle Result

Based on task-verifier result:

#### VERIFIED

All acceptance criteria passed.

1. Clean up state file:
   ```bash
   rm -f .claude/shipspec-task-loop.local.md
   ```

2. Update TASKS.md: Change `[~]` to `[x]` for the task

3. Log completion to `.claude/shipspec-debug.log`:
   ```
   $(date -u +%Y-%m-%dT%H:%M:%SZ) | [task_id] | LOOP_END | VERIFIED after [iteration] attempts
   ```

4. **Output the completion marker:**
   `<task-loop-complete>VERIFIED</task-loop-complete>`

5. Tell user: "Task [task_id] verified! All acceptance criteria passed."

#### INCOMPLETE

Some criteria failed. Manual intervention required.

1. Clean up state file:
   ```bash
   rm -f .claude/shipspec-task-loop.local.md
   ```

2. Log the failure to `.claude/shipspec-debug.log`:
   ```
   $(date -u +%Y-%m-%dT%H:%M:%SZ) | [task_id] | LOOP_END | INCOMPLETE | [brief failure reason]
   ```

3. **Output the incomplete marker:**
   `<task-loop-complete>INCOMPLETE</task-loop-complete>`

4. Show the user what failed:
   > "## Verification Failed
   >
   > The following criteria are not met:
   > - [List failed criteria]
   >
   > Please fix these issues and run `/implement-task [feature]` again."

#### BLOCKED

Cannot verify due to infrastructure issues.

1. Clean up state file:
   ```bash
   rm -f .claude/shipspec-task-loop.local.md
   ```

2. Log to `.claude/shipspec-debug.log`:
   ```
   $(date -u +%Y-%m-%dT%H:%M:%SZ) | [task_id] | LOOP_END | BLOCKED | [reason]
   ```

3. **Output the blocked marker:**
   `<task-loop-complete>BLOCKED</task-loop-complete>`

4. Tell user: "Task verification is blocked: [reason]. Manual intervention required."

## Important Notes

1. **Completion markers are critical** - the stop hook looks for these to decide whether to allow session exit
2. **All results output markers** - VERIFIED, INCOMPLETE, and BLOCKED all output completion markers to exit the loop
3. **INCOMPLETE requires manual fix** - user must address issues and re-run `/implement-task`
4. **BLOCKED needs investigation** - tasks that can't be verified need manual attention
5. **State file cleanup** - always remove on any completion (VERIFIED, INCOMPLETE, or BLOCKED) to prevent stale loops
