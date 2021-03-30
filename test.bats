#!/usr/bin/env bats
ghd_base="$BATS_TMPDIR/ghd_test"

setup() {
  GHD_LOCATION="$ghd_base/$BATS_TEST_NUMBER"
  GHD_USE_SSH=0
  logged_out=1
  rm -rf "$GHD_LOCATION"
  repo_name="ghd"
  repo_owner="okkays"
  repo="$repo_owner/$repo_name"

  __fzfcmd() {
    echo 'fzf'
  }

  fzf() {
    stdin="$(cat)"
    echo "fzf_called with $stdin"
  }

  git() {
    echo "MOCK: git $@"
  }

  cd() {
    echo "MOCK: cd $@"
  }

  gh() {
    if [[ "$@" == "auth status" ]]; then
      return $logged_out
    fi

    if [[ $logged_out -eq 1 ]]; then
      echo 'Github CLI invoked improperly.  Check `gh auth status` first.'
      return 0
    fi

    if [[ "$@" == "repo list --limit 10000" ]]; then
      echo "$repo_owner/gh_$repo_name"
      return 0
    fi

    echo "Unexpected gh command: $@"
    exit 1
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
  logged_out=0
  mkdir -p "$GHD_LOCATION/$repo"

  run . ./ghd ""

  [[ "$output" == *"MOCK: cd $GHD_LOCATION/fzf_called with "*"okkays"*"okkays/gh_ghd"*"okkays/ghd" ]]
  [[ "${#lines[@]}" -eq 3 ]]
  [[ "$status" -eq 0 ]]
}

@test "calls fzf for ambiguous repo" {
  mkdir -p "$GHD_LOCATION/$repo"
  mkdir -p "$GHD_LOCATION/$repo_name"
  run . ./ghd $repo_name
  [[ "$output" == *"MOCK: cd $GHD_LOCATION/fzf_called with "*"$GHD_LOCATION/ghd"*"$GHD_LOCATION/okkays/ghd" ]]
  [[ "${#lines[@]}" -eq 2 ]]
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

@test "exits gracefully when no matches" {
  run . ./ghd $repo_name
  [[ "$output" == *"No cloned repository, user, or organization found for: $repo_name"* ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 1 ]]
}

@test "exits gracefully when no matches and no fzf" {
  unset -f __fzfcmd
  run . ./ghd $repo_name
  [[ "$output" == *"No cloned repository, user, or organization found for: $repo_name"* ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 1 ]]
}

@test "calls fzf when called bare" {
  mkdir -p "$GHD_LOCATION/$repo"
  mkdir -p "$GHD_LOCATION/$repo_name"
  run . ./ghd ""
  [[ "$output" == *"MOCK: cd $GHD_LOCATION/fzf_called with ghd"*"okkays"*"okkays/ghd" ]]
  [[ "${#lines[@]}" -eq 3 ]]
  [[ "$status" -eq 0 ]]
}

@test "ignores fzf if fzf exits abnormally" {
  mkdir -p "$GHD_LOCATION/$repo"
  mkdir -p "$GHD_LOCATION/$repo_name"
  fzf() {
    return 130
  }
  run . ./ghd ""
  [[ "${#lines[@]}" -eq 0 ]]
  [[ "$status" -eq 130 ]]
}

@test "obeys PAGER for fzf" {
  mkdir -p "$GHD_LOCATION/$repo"
  mkdir -p "$GHD_LOCATION/$repo_name"
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
