#!/usr/bin/env bats
ghd_base="$BATS_TMPDIR/ghd_test"

setup() {
  GHD_LOCATION="$ghd_base/$BATS_TEST_NUMBER"
  GHD_USE_SSH=0
  rm -rf "$GHD_LOCATION"
  repo_name="ghd"
  repo_owner="okkays"
  repo="$repo_owner/$repo_name"

  __fzfcmd() {
    echo 'fzf'
  }

  fzf() {
    echo "fzf_called"
  }

  git() {
    echo "MOCK: git $@"
  }

  cd() {
    echo "MOCK: cd $@"
  }

  gh() {
    if [[ "$@" != "auth status" ]]; then
      echo 'Github CLI invoked improperly.  Check `gh auth status` first.'
      exit 1
    fi
    return 1
  }
}

@test "clones ssh repo name" {
  GHD_USE_SSH=1
  run . ./ghd $repo
  [[ "$output" == *"MOCK: git "*"git@github.com:$repo "* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$repo" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "clones https repo name" {
  GHD_USE_SSH=0
  run . ./ghd $repo
  [[ "$output" == *"MOCK: git "*"https://github.com/$repo"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$repo" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "clones https when given https" {
  run . ./ghd https://github.com/$repo
  [[ "$output" == *"MOCK: git "*"https://github.com/$repo"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$repo" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "clones git when given git" {
  run . ./ghd git@github.com:$repo
  [[ "$output" == *"MOCK: git "*"git@github.com:$repo"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$repo" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "exits abnormally when git fails" {
  git() {
    return 1
  }
  run . ./ghd git@github.com:$repo
  [[ "${#lines[@]}" -eq 0 ]]
  [[ "$status" -eq 1 ]]
}

@test "goes to cloned repo by ssh url" {
  mkdir -p "$GHD_LOCATION/$repo"
  run . ./ghd git@github.com:$repo
  [[ "$output" != *"MOCK: git "*"git@github.com:$repo"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$repo" ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}

@test "goes to cloned repo by https url" {
  mkdir -p "$GHD_LOCATION/$repo"
  run . ./ghd https://github.com/$repo
  [[ "$output" != *"MOCK: git "*"https://github.com/$repo"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$repo" ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}

@test "goes to cloned repo by name" {
  mkdir -p "$GHD_LOCATION/$repo"
  run . ./ghd $repo
  [[ "$output" != *"MOCK: git "*"git@github.com:$repo"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$repo" ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}

@test "goes to cloned repo by repo name" {
  mkdir -p "$GHD_LOCATION/$repo"
  run . ./ghd $repo_name
  [[ "$output" != *"MOCK: git "*"git@github.com:$repo"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$repo" ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}

@test "pulls cloned repo if repo_name! is used" {
  mkdir -p "$GHD_LOCATION/$repo/.git"
  run . ./ghd $repo_name!
  [[ "$output" == *"MOCK: git -C $GHD_LOCATION/$repo pull --all"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$repo" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "pulls cloned repo if repo! is used" {
  mkdir -p "$GHD_LOCATION/$repo/.git"
  run . ./ghd $repo!
  [[ "$output" == *"MOCK: git -C $GHD_LOCATION/$repo pull --all"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$repo" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "pulls cloned repo if url! is used" {
  mkdir -p "$GHD_LOCATION/$repo/.git"
  run . ./ghd git@github.com:$repo!
  [[ "$output" == *"MOCK: git -C $GHD_LOCATION/$repo pull --all"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$repo" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "doesn't pull orgs" {
  mkdir -p "$GHD_LOCATION/$repo/.git"
  run . ./ghd $repo_owner!
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$repo_owner" ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}

@test "goes to cloned org by org name" {
  mkdir -p "$GHD_LOCATION/$repo"
  run . ./ghd $repo_owner
  [[ "$output" != *"MOCK: git "*"git@github.com:$repo"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$repo_owner" ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}

@test "lists orgs from gh if auth enabled" {
  gh
}

@test "calls fzf for ambiguous repo" {
  mkdir -p "$GHD_LOCATION/$repo"
  mkdir -p "$GHD_LOCATION/$repo_name"
  run . ./ghd $repo_name
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/fzf_called" ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}

@test "exits gracefully when ambiguous with no fzf" {
  mkdir -p "$GHD_LOCATION/$repo"
  mkdir -p "$GHD_LOCATION/$repo_name"
  unset -f __fzfcmd
  run . ./ghd $repo_name
  [[ "$output" == *"Found multiple matches for $repo_name:"* ]]
  [[ "${#lines[@]}" -eq 3 ]]
  [[ "$status" -eq 1 ]]
}

@test "calls fzf for no matches" {
  run . ./ghd $repo_name
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/fzf_called" ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}

@test "exits gracefully when no matches and no fzf" {
  unset -f __fzfcmd
  run . ./ghd $repo_name
  [[ "$output" == *"No cloned repository, user, or organization found for: $repo_name"* ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 1 ]]
}

@test "calls fzf when called bare" {
  run . ./ghd ""
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/fzf_called" ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}

@test "ignores fzf if fzf exits abnormally" {
  fzf() {
    return 130
  }
  run . ./ghd ""
  echo "# $output" >&3
  [[ "${#lines[@]}" -eq 0 ]]
  [[ "$status" -eq 130 ]]
}

@test "obeys PAGER for fzf" {
  PAGER="wat"
  fzf() {
    echo "$@" | tr '\n' ' '
  }
  run . ./ghd ""
  [[ "$output" == *"wat '$GHD_LOCATION/{}/README.md'"* ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}

@test "goes to root given /" {
  run . ./ghd /
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION" ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}
