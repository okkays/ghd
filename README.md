# Github Directory (ghd)

Utility to manage cloning and cd'ing to Github repos.

![Animated example of ghding a couple disparate repos](ghd.gif)

The idea behind this tool is to give an easy to access, centralized location for local clones of Github repositories.

## Installation

Put `ghd` somewhere in your `PATH`, then add:
```bash
alias ghd=". ghd"
```
to your bashrc.  (Sourcing the script allows it to change directory.)

## Usage

```bash
ghd <repo_name or repo url (with https://github.com or git@github.com:)>
ghd <already cloned user or organization>
ghd
```

For example, to clone and cd to this repo:

```bash
ghd okkays/ghd
```

If you've already checked out some of a user's repos, you can switch to that user's directory:

```bash
ghd okkays
```

Finally, to switch to the root of all of your cloned repos:

```bash
ghd
```

There, you can use directory-based tools like `find`, `ag`, etc to figure out where a piece of code is.

![Animated example of using ag with ghd](ghd_ag.gif)

## Configuration

ghd reads the following environment variables:

- `GHD_LOCATION`: The directory in which to store repos (`/tmp/ghd` by default).
- `GHD_USE_SSH`: Whether to clone via ssh (uses https by default).

To configure them, add (for example):

```bash
export GHD_LOCATION="$HOME/.ghd"
export GHD_USE_SSH=1
```

to `~/.bashrc`
