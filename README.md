starsync.sh
-----------
Run `starsync.sh` to sync your GitHub stars locally.
It'll prompt for your GitHub username, first guessing
based on your *nix username.

Dependencies
------------
- `curl`
- `jq`
- `zsh`
- `git`

Probably Zsh isn't actually required, but `starsync.sh`
explicitly calls it out in the shebang line. It's not
tested with any other shell.
