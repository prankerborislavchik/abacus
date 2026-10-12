# Task worktrees

For an independent code task, inspect `git status`, remotes, and existing worktrees first. Reuse the task's assigned worktree for follow-up work.

For a new task:

1. Identify the appropriate upstream remote and its actual default branch. Honor an explicit user-specified base.
2. Fetch that remote. If fetching fails, report the blocker before using a stale base.
3. Create the branch and worktree with Worktrunk:

   ```sh
   wt switch --create <branch> --base <remote>/<default-branch> --no-cd --format=json
   ```

4. Use the returned absolute path for all edits, checks, and commits.
5. Inspect project setup instructions and any Worktrunk hooks. Allow configured hooks to run, and verify setup succeeded before dependent work. For this project, install the pinned SDK and resolve the locked dependencies using the commands in `README.md`.

A dependent task starts from the relevant task or PR branch; fetch it when its intended base is remote. Keep pre-existing uncommitted work intact.

Use the primary checkout for code changes only when the user explicitly requests it or project instructions require it. If Worktrunk or isolation is unavailable, report the blocker before falling back to the primary checkout.

Keep environment setup in project configuration and scripts. Install project hooks only for a concrete need; avoid generic global setup hooks. Report setup failures and approval gates explicitly.

If multiple agents are explicitly authorized to write concurrently, assign each an exclusive worktree and branch with an absolute path. Read-only agents may share a checkout. Coordinate integration through one agent and preserve uncommitted or unmerged work during cleanup.
