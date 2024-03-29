#!/usr/bin/env bats
ghd_base="$BATS_TMPDIR/ghd_test"

setup() {
  GHD_LOCATION="$ghd_base/$BATS_TEST_NUMBER"
  GHD_USE_SSH=0
  gh_logged_out=1
  remote_exists=0
  gh_fail_create=0
  rm -rf "$GHD_LOCATION"
  fake_repo_name="ghd"
  fake_repo_owner="okkays"
  fake_repo="$fake_repo_owner/$fake_repo_name"
  fake_gh_repo_1="$fake_repo_owner/gh_$fake_repo_name"
  fake_gh_repo_2="$fake_repo_owner/gh_2_$fake_repo_name"

  __fzfcmd() {
    echo 'fzf'
  }

  fzf() {
    stdin="$(cat)"
    echo "fzf_called with $(echo $stdin | tr -d '\n' | tr '/' '_')"
  }

  git() {
    if [[ "$@" == "ls-remote"* ]]; then
      if [[ $remote_exists -eq 0 ]]; then
        return 1
      else
        return 0
      fi
    fi

    echo "MOCK: git $@"
  }

  rm() {
    echo "MOCK: rm $@"
  }

  cd() {
    echo "MOCK: cd $@"
  }

  gh() {
    if [[ "$@" == "auth status" ]]; then
      return $gh_logged_out
    fi

    if [[ $gh_logged_out -eq 1 ]]; then
      echo 'Github CLI invoked improperly.  Check `gh auth status` first.'
      return 0
    fi

    if [[ "$@" == "repo list org"* ]]; then
      echo "org/gh_repo_1"
      echo "org/gh_repo_2"
      return 0
    fi

    if [[ "$@" == "repo list "* ]]; then
      echo "$fake_repo_owner/gh_$fake_repo_name"
      echo "$fake_repo_owner/gh_2_$fake_repo_name"
      return 0
    fi

    if [[ "$@" == "repo create "* ]]; then
      if [[ $gh_fail_create -eq 1 ]]; then
        return 1
      fi
      echo "MOCK: gh $@"
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
  [[ "$output" == *"MOCK: git clone"*"git@github.com:$fake_repo "* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "clones https repo name" {
  GHD_USE_SSH=0
  run . ./ghd $fake_repo
  [[ "$output" == *"MOCK: git clone"*"https://github.com/$fake_repo"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "clones ssh given https" {
  GHD_USE_SSH=1
  run . ./ghd https://github.com/$fake_repo
  [[ "$output" == *"MOCK: git clone"*"git@github.com:$fake_repo"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "clones https given git" {
  GHD_USE_SSH=0
  run . ./ghd git@github.com:$fake_repo
  [[ "$output" == *"MOCK: git clone"*"https://github.com/$fake_repo"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "clones and switches to branch with @" {
  GHD_USE_SSH=1
  run . ./ghd git@github.com:$fake_repo@fake_branch
  [[ "$output" == *"MOCK: git clone --branch \"fake_branch\" -- git@github.com:$fake_repo $GHD_LOCATION/$fake_repo"* ]]

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

@test "goes to branch if @ is used" {
  mkdir -p "$GHD_LOCATION/$fake_repo"
  run . ./ghd $fake_repo@fake_branch
  [[ "$output" == *"MOCK: git -C $GHD_LOCATION/$fake_repo checkout fake_branch"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "goes to and pulls branch if bare @ is used" {
  mkdir -p "$GHD_LOCATION/$fake_repo"
  run . ./ghd @fake_branch!
  [[ "$output" == *"MOCK: git checkout fake_branch"* ]]
  [[ "$output" == *"MOCK: git pull" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "goes to new branch if @b? is used" {
  mkdir -p "$GHD_LOCATION/$fake_repo"
  run . ./ghd $fake_repo@fake_branch?
  [[ "$output" == *"MOCK: git -C $GHD_LOCATION/$fake_repo checkout -b fake_branch"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "goes to branch if @ is used without repo" {
  run . ./ghd @fake_branch
  [[ "$output" == *"MOCK: git checkout fake_branch"* ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}

@test "goes to new branch if @b? is used without repo" {
  run . ./ghd @fake_branch?
  [[ "$output" == *"MOCK: git checkout -b fake_branch"* ]]
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

@test "pulls cloned repo and then switches to branch if repo@branch! is used" {
  mkdir -p "$GHD_LOCATION/$fake_repo/.git"
  run . ./ghd $fake_repo@fake_branch!
  [[ "$output" == *"MOCK: git -C $GHD_LOCATION/$fake_repo pull --all"* ]]
  [[ "$output" == *"MOCK: git -C $GHD_LOCATION/$fake_repo checkout fake_branch"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo" ]]
  [[ "${#lines[@]}" -eq 3 ]]
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

@test "clones all repos for org by org name if * used and gh available" {
  gh_logged_out=0
  GHD_USE_SSH=1
  mkdir -p "$GHD_LOCATION/$fake_gh_repo_2"
  run . ./ghd $fake_repo_owner'*'
  [[ "$output" == *"MOCK: git clone "*"git@github.com:$fake_gh_repo_1"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo_owner" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "lists repos from gh for current user if auth enabled" {
  gh_logged_out=0

  run . ./ghd gh_2_ghd

  [[ "$output" == *"MOCK: git clone"*"github.com/$fake_repo_owner/gh_2_ghd "* ]]
  [[ "$output" == *"MOCK: cd $GHD_LOCATION/$fake_repo_owner/gh_2_ghd" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "lists repos from gh for an org if auth enabled and + used" {
  gh_logged_out=0
  mkdir -p "$GHD_LOCATION/org/gh_repo_1"

  run . ./ghd org+

  [[ "$output" == *"MOCK: git clone"*"github.com/fzf_called "* ]]
  [[ "$output" == *"MOCK: cd $GHD_LOCATION/fzf_called with "*"org"*"org_gh_repo_1"*"org_gh_repo_2" ]]
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "$status" -eq 0 ]]
}

@test "calls fzf for ambiguous repo" {
  mkdir -p "$GHD_LOCATION/$fake_repo"
  mkdir -p "$GHD_LOCATION/$fake_repo_name/.git"
  run . ./ghd $fake_repo_name
  [[ "$output" == *"MOCK: git clone"*"github.com/fzf_called "* ]]
  [[ "$output" == *"MOCK: cd $GHD_LOCATION/fzf_called with "*"ghd"*"okkays_ghd" ]]
  [[ "${#lines[@]}" -eq 2 ]]
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
  [[ "$output" == *"MOCK: git clone"*"github.com/fzf_called "* ]]
  [[ "$output" == *"MOCK: cd $GHD_LOCATION/fzf_called with ghd"*"okkays"*"okkays_ghd" ]]
  [[ "${#lines[@]}" -eq 2 ]]
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
  [[ "$output" == *"mockPager"* ]]
  [[ "$status" -eq 0 ]]
}

@test "goes to root given /" {
  run . ./ghd /
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/" ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}

@test "prints dir instead of cding given ?" {
  mkdir -p "$GHD_LOCATION/$fake_repo/.git"
  run . ./ghd /?
  [[ "$output" != *"MOCK: cd "*"$GHD_LOCATION/" ]]
  [[ "$output" == *"$GHD_LOCATION/"* ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 0 ]]
}

@test "creates new repo given + if gh unavailable" {
  GHD_USE_SSH=1
  gh_logged_out=1
  run . ./ghd $fake_repo+
  echo "$output"
  [[ "$output" == *"MOCK: git init $GHD_LOCATION/$fake_repo"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo"* ]]
  [[ "$output" == *"MOCK: git remote add origin git@github.com:$fake_repo"* ]]
  [[ "${#lines[@]}" -eq 3 ]]
  [[ "$status" -eq 0 ]]
}

@test "creates new repo given + with gh available" {
  GHD_USE_SSH=1
  gh_logged_out=0
  run . ./ghd $fake_repo+
  echo "$output"
  [[ "$output" == *"MOCK: git init $GHD_LOCATION/$fake_repo"* ]]
  [[ "$output" == *"MOCK: cd "*"$GHD_LOCATION/$fake_repo"* ]]
  [[ "$output" == *"MOCK: gh repo create $fake_repo --private --source ."* ]]
  [[ "${#lines[@]}" -eq 3 ]]
  [[ "$status" -eq 0 ]]
}

@test "cleans up a failed gh create" {
  GHD_USE_SSH=1
  gh_logged_out=0
  gh_fail_create=1
  run . ./ghd $fake_repo+
  [[ "$output" == *"MOCK: rm -rf $GHD_LOCATION/$fake_repo"* ]]
  [[ "${#lines[@]}" -eq 4 ]]
  [[ "$status" -eq 3 ]]
}

@test "fails to create new repo given + if it exists" {
  remote_exists=1
  run . ./ghd $fake_repo+
  [[ "$output" == *"exists on github: $fake_repo"* ]]
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "$status" -eq 2 ]]
}
