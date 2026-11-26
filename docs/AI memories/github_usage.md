Classic squash-merge side effect. Here's the mechanism:

When you squash-and-merge a PR on GitHub, it creates a brand-new commit on origin/main that bundles all your PR's commits into one, with a new SHA. It is not the same commits you had locally — it's a repack of their content into a single new commit.

If your local main branch still has the original, individual commits from before the merge (e.g. you committed work directly on main, or merged your feature branch into local main before the GitHub merge happened), git now sees two different, unrelated-looking commit sequences that both claim to extend the same point in history:

origin/main: ...→ (old shared commit) → [new squashed commit A] → [new squashed commit B]
local main: ...→ (old shared commit) → [your original commit 1] → [commit 2] → [commit 3]
Same net content, different SHAs, no common lineage after the shared point — hence "diverged." git pull would try to merge these two different histories together, which usually leaves you with duplicate-looking changes or a conflict, even though nothing is actually in conflict content-wise.

Fix, since your working tree is clean and those 3 local commits are presumably already fully represented in what got merged:


git reset --hard origin/main
This discards your 3 local commits and makes local main exactly match origin/main. It's a destructive command (rewrites local history), and the right move here only if those 3 local commits contain nothing beyond what was already in the merged PR — worth a quick git log origin/main..main first to see exactly what you'd be discarding, if you want to double check before running it.

To stop this recurring: avoid committing directly to local main at all. Keep doing your work on a feature branch (like 50-drop-down-selector), and once GitHub squash-merges the PR, switch to main and run git fetch origin && git reset --hard origin/main (or just delete and recheck out main tracking origin) instead of ever advancing local main with your own commits. Local main then only ever moves by fast-forwarding to match origin — never diverges.