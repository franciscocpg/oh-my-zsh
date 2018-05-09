# Set up hub wrapper for git, if it is available; http://github.com/github/hub
if (( $+commands[hub] )); then
  alias git=hub
fi

# Functions #################################################################

# Based on https://github.com/dbb/githome/blob/master/.config/zsh/functions

# empty_gh <NAME_OF_REPO>
#
# Use this when creating a new repo from scratch.
# Creates a new repo with a blank README.md in it and pushes it up to GitHub.
empty_gh() { # [NAME_OF_REPO]
  emulate -L zsh
  local repo=$1

  mkdir "$repo"
  touch "$repo/README.md"
  new_gh "$repo"
}

# new_gh [DIRECTORY]
#
# Use this when you have a directory that is not yet set up for git.
# This function will add all non-hidden files to git.
new_gh() { # [DIRECTORY]
  emulate -L zsh
  local repo="$1"
  cd "$repo" \
    || return

  git init \
    || return
  # add all non-dot files
  print '.*'"\n"'*~' >> .gitignore
  git add [^.]* \
    || return
  git add .gitignore \
    || return
  git commit -m 'Initial commit.' \
    || return
  hub create \
    || return
  git push -u origin master \
    || return
}

# exist_gh [DIRECTORY]
#
# Use this when you have a git repo that's ready to go and you want to add it
# to your GitHub.
exist_gh() { # [DIRECTORY]
  emulate -L zsh
  local repo=$1
  cd "$repo"

  hub create \
    || return
  git push -u origin master
}

# git.io "GitHub URL"
#
# Shorten GitHub url, example:
#   https://github.com/nvogel/dotzsh    >   http://git.io/8nU25w  
# source: https://github.com/nvogel/dotzsh
# documentation: https://github.com/blog/985-git-io-github-url-shortener
#
git.io() {
  emulate -L zsh
  curl -i -s https://git.io -F "url=$1" | grep "Location" | cut -f 2 -d " "
}

github-release-repo() {
  LATEST_TAG=$(git describe --tags $(git rev-list --tags --max-count=1))
  echo "Latest tag: $LATEST_TAG"
  echo "Tag"
  read TAG
  which github-release > /dev/null || go get -v github.com/c4milo/github-release;
  project=$(basename $(dirname $PWD))/$(basename $PWD) &&
  latest_tag=$(git describe --tags `git rev-list --tags --max-count=1`) &&
  comparison="$latest_tag..HEAD" &&
  if [ -z "$latest_tag" ]; then comparison=""; fi &&
  changelog=$(git log $comparison --oneline --no-merges --reverse --no-color) &&
  echo "Releasing\nProject: $project\nTag: $TAG\nBranch: \"master\"\nChangelog: \"**Changelog**<br/>$changelog\""
  echo -n "Confirm (y/N)?"
  read CONFIRM
  if [ "$CONFIRM" = "y" ]; then
    github-release $project $TAG "master" "**Changelog**<br/>$changelog" '' &&
    git pull
  fi
}

# End Functions #############################################################

