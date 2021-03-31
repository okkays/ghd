#!/usr/bin/env bats
ghd_base="$BATS_TMPDIR/ghd_test"

setup() {
  GHD_LOCATION="$ghd_base/$BATS_TEST_NUMBER"
  GHD_USE_SSH=0
  logged_out=1
  rm -rf "$GHD_LOCATION"
  fake_repo_name="ghd"
  fake_repo_owner="okkays"
  fake_repo="$fake_repo_owner/$fake_repo_name"

  __fzfcmd() {
    echo 'fzf'
  }

  fzf() {
    stdin="$(cat)"
    echo "fzf_called with $(echo $stdin | tr -d '\n' | tr '/' '_')"
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
      echo "$fake_repo_owner/gh_$fake_repo_name"
      return 0
    fi

    echo "Unexpected gh command: $@"
    exit 1
  }
  printf "\n\nStart test $BATS_TEST_NUMBER: $BATS_TEST_DESCRIPTION\n\n" >> /tmp/bats
}

teardown() {
  printf "\n$output\n" >> /tmp/bats
  printf "\n\nEnd test $BATS_TEST_NUMBER\n\n" >> /tmp/bats
}

@test "clones ssh repo name" {
  GHD_USE_SSH=1
  run . ./ghd $fake_repo
  [[ "$output" == *"MOCK: git "*"git@github.com:$fake_repo "* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "clones https repo name" {
  GHD_USE_SSH=0
  run . ./ghd $fake_repo
  [[ "$output" == *"MOCK: git "*"https://github.com/$fake_repo"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "clones https when given https" {
  run . ./ghd https://github.com/$fake_repo
  [[ "$output" == *"MOCK: git "*"https://github.com/$fake_repo"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "clones git when given git" {
  run . ./ghd git@github.com:$fake_repo
  [[ "$output" == *"MOCK: git "*"git@github.com:$fake_repo"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "exits abnormally when git fails" {
  git() {
    return 1
  }
  run . ./ghd git@github.com:$fake_repo
  [[ "${#lines[@]}" -eq 0 ]]
  [[ "$status" -eq 1 ]]
}

@test "goes to cloned repo by ssh url" {
  mkdir -p "$GHD_LOCATION/$fake_repo"
  run . ./ghd git@github.com:$fake_repo
  [[ "$output" != *"MOCK: git "*"git@github.com:$fake_repo"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo" ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}

@test "goes to cloned repo by https url" {
  mkdir -p "$GHD_LOCATION/$fake_repo"
  run . ./ghd https://github.com/$fake_repo
  [[ "$output" != *"MOCK: git "*"https://github.com/$fake_repo"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo" ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}

@test "goes to cloned repo by name" {
  mkdir -p "$GHD_LOCATION/$fake_repo"
  run . ./ghd $fake_repo
  [[ "$output" != *"MOCK: git "*"git@github.com:$fake_repo"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo" ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}

@test "goes to cloned repo by repo name" {
  mkdir -p "$GHD_LOCATION/$fake_repo"
  run . ./ghd $fake_repo_name
  [[ "$output" != *"MOCK: git "*"git@github.com:$fake_repo"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo" ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}

@test "pulls cloned repo if repo_name! is used" {
  mkdir -p "$GHD_LOCATION/$fake_repo/.git"
  run . ./ghd $fake_repo_name!
  [[ "$output" == *"MOCK: git -C $GHD_LOCATION/$fake_repo pull --all"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "pulls cloned repo if repo! is used" {
  mkdir -p "$GHD_LOCATION/$fake_repo/.git"
  run . ./ghd $fake_repo!
  [[ "$output" == *"MOCK: git -C $GHD_LOCATION/$fake_repo pull --all"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "pulls cloned repo if url! is used" {
  mkdir -p "$GHD_LOCATION/$fake_repo/.git"
  run . ./ghd git@github.com:$fake_repo!
  [[ "$output" == *"MOCK: git -C $GHD_LOCATION/$fake_repo pull --all"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "doesn't pull orgs" {
  mkdir -p "$GHD_LOCATION/$fake_repo/.git"
  run . ./ghd $fake_repo_owner!
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo_owner" ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}

@test "goes to cloned org by org name" {
  mkdir -p "$GHD_LOCATION/$fake_repo"
  run . ./ghd $fake_repo_owner
  [[ "$output" != *"MOCK: git "*"git@github.com:$fake_repo"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo_owner" ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}

@test "lists orgs from gh if auth enabled" {
  logged_out=0
  mkdir -p "$GHD_LOCATION/$fake_repo"

  run . ./ghd ""

  [[ "$output" == *"MOCK: cd $GHD_LOCATION/fzf_called with "*"okkays"*"okkays_gh_ghd"*"okkays_ghd" ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}

@test "calls fzf for ambiguous repo" {
  mkdir -p "$GHD_LOCATION/$fake_repo"
  mkdir -p "$GHD_LOCATION/$fake_repo_name/.git"
  run . ./ghd $fake_repo_name
  [[ "$output" == *"MOCK: cd $GHD_LOCATION/fzf_called with "*"ghd"*"okkays_ghd" ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}

@test "exits gracefully when ambiguous with no fzf" {
  mkdir -p "$GHD_LOCATION/$fake_repo"
  mkdir -p "$GHD_LOCATION/$fake_repo_name"
  unset -f __fzfcmd
  run . ./ghd $fake_repo_name
  [[ "$output" == *"Found multiple matches for $fake_repo_name:"* ]]
  [[ "${#lines[@]}" -eq 3 ]]
  [[ "$status" -eq 1 ]]
}

@test "exits gracefully when no matches" {
  run . ./ghd $fake_repo_name
  [[ "$output" == *"No cloned repository, user, or organization found for: $fake_repo_name"* ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 1 ]]
}

@test "exits gracefully when no matches and no fzf" {
  unset -f __fzfcmd
  run . ./ghd $fake_repo_name
  [[ "$output" == *"No cloned repository, user, or organization found for: $fake_repo_name"* ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 1 ]]
}

@test "calls fzf when called bare" {
  mkdir -p "$GHD_LOCATION/$fake_repo"
  mkdir -p "$GHD_LOCATION/$fake_repo_name"
  run . ./ghd ""
  [[ "$output" == *"MOCK: cd $GHD_LOCATION/fzf_called with ghd"*"okkays"*"okkays_ghd" ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}

@test "ignores fzf if fzf exits abnormally" {
  mkdir -p "$GHD_LOCATION/$fake_repo"
  mkdir -p "$GHD_LOCATION/$fake_repo_name"
  fzf() {
    return 130
  }
  run . ./ghd ""
  [[ "${#lines[@]}" -eq 0 ]]
  [[ "$status" -eq 130 ]]
}

@test "obeys PAGER for fzf" {
  mkdir -p "$GHD_LOCATION/$fake_repo/.git"
  mkdir -p "$GHD_LOCATION/$fake_repo_name/.git"
  PAGER="mockPager"
  fzf() {
    echo "$@" | tr '\n' ' '
  }
  run . ./ghd ""
  [[ "$output" == *"mockPager '$GHD_LOCATION/{}/README.md'"* ]]
  [[ "$status" -eq 0 ]]
}

@test "goes to root given /" {
  run . ./ghd /
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/" ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}
