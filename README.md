starsync.sh
-----------
Run `starsync.sh` to sync your GitHub stars locally.
It'll prompt for your GitHub username, first guessing
based on your *nix username.

Usage
-----

    starsync.sh [options]
    Options:
        --no-clones           Do not clone new stars
        -h | --help           Show this help message
        -u | --user           Set your username. If unset, you will be prompted for it
        -s | --shallow        Perform a shallow clone of new repositories
        -m | --max-repo-size  Set the maximum allowable repository size, in kilobytes.
                              Repositories over this limit will not be cloned.
                              Defaults to 50 megabytes


Dependencies
------------
- `curl`
- `jq`
- `zsh`
- `git`

Probably Zsh isn't actually required, but `starsync.sh`
explicitly calls it out in the shebang line. It's not
tested with any other shell.

Example
-------
[![asciicast](https://asciinema.org/a/60quj6v5uvvagd7ijv0tx1glx.png)](https://asciinema.org/a/60quj6v5uvvagd7ijv0tx1glx)
