# Load support for __git_ps1
GIT_SH_PROMPT=/usr/lib/git-core/git-sh-prompt

if [ -f "$GIT_SH_PROMPT" ]; then
  . "$GIT_SH_PROMPT"
else
  echo "ERROR: git-sh-prompt is missing"
fi

# Shows * if there are unstaged (modified) changes and + if there are staged changes.
export GIT_PS1_SHOWDIRTYSTATE=""
# Shows $ if there are entries in the stash.
export GIT_PS1_SHOWSTASHSTATE=""
# Shows % if there are untracked files.
export GIT_PS1_SHOWUNTRACKEDFILES=""
# Shows remote tracking status: 0 (don't show), 1/git (simple), verbose (numbers and names), name
export GIT_PS1_SHOWUPSTREAM=""
# Shows when there are conflicts during Merge, Interactive Rebase, Manual Rebase, Rebase, Cherry-pick, Revert, or Bisect.
export GIT_PS1_SHOWCONFLICTSTATE=""
# Hides Git info if the current directory is ignored by .gitignore.
export GIT_PS1_HIDE_IF_PWD_IGNORED=""
# Shows colors (requires PS1 to support ANSI escape sequences).
export GIT_PS1_SHOWCOLORHINTS=""
# Changes how the reference name is displayed (): contains, branch, describe, default, ""
export GIT_PS1_DESCRIBE_STYLE=""
# Changes the separator between the branch name and state indicators.
export GIT_PS1_STATESEPARATOR="" # →
# Changes the default symbol ↑ when ahead of the remote.
export GIT_PS1_SYMBOLS_AHEAD=""
# Changes the default symbol ↓ when behind the remote.
export GIT_PS1_SYMBOLS_BEHIND=""
# Text to display when there is no remote branch configured.
export GIT_PS1_SYMBOLS_NO_REMOTE_TRACKING=""

# Show emoji status indicators for Git state
git_state_emoji() {
    # Exit if not inside a Git repository
    git rev-parse --is-inside-work-tree &>/dev/null || return

    local emojis=""
    local git_status
    git_status=$(git status --porcelain 2>/dev/null)

    # Untracked files
    [[ "$git_status" == *"??"* ]] && emojis+="🆕"

    # Modified files (not staged)
    [[ "$git_status" == *" M"* || "$git_status" == "M "* ]] && emojis+="⚡"

    # Staged files
    ! git diff --cached --quiet 2>/dev/null && emojis+="🔄"

    # Stashed changes
    [[ -n "$(git stash list 2>/dev/null)" ]] && emojis+="💾"

    # Rebase in progress
    [[ -d .git/rebase-apply || -d .git/rebase-merge ]] && emojis+="⏳"

    # Merge in progress
    [[ -f .git/MERGE_HEAD ]] && emojis+="🚧"

    # Revert in progress
    [[ -f .git/REVERT_HEAD ]] && emojis+="🔁"

    # Cherry-pick in progress
    [[ -f .git/CHERRY_PICK_HEAD ]] && emojis+="🍒"

    # Detached HEAD state
    if ! git symbolic-ref -q HEAD &>/dev/null; then
        emojis+="🚫"
    fi

    # Stash exists but working tree is clean
    if [[ -n "$(git stash list)" && -z "$git_status" ]]; then
        emojis+="💥"
    fi

    # Remote tracking status
    local upstream ahead behind
    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
    if [[ -n "$upstream" ]]; then
        ahead=$(git rev-list --count HEAD.."$upstream" 2>/dev/null)
        behind=$(git rev-list --count "$upstream"..HEAD 2>/dev/null)
        if [[ "$ahead" -gt 0 && "$behind" -gt 0 ]]; then
            emojis+="↕️"  # Both ahead and behind
        elif [[ "$ahead" -gt 0 ]]; then
            emojis+="⬆️"  # Ahead of remote
        elif [[ "$behind" -gt 0 ]]; then
            emojis+="⬇️"  # Behind remote
        fi
    fi

    # If no state indicators were added, show a check mark
    [[ -z "$emojis" ]] && emojis="✅"

    # Output emojis in purple color
    echo -e "\e[35m${emojis}\e[0m"
}

update_prompt_colors() {
    if [[ $? -eq 0 ]]; then
        export USER_HOST_COLOR="\e[32m$(whoami)@$(hostname -s)\e[0m"
    else
        export USER_HOST_COLOR="\e[31m$(whoami)@$(hostname -s)\e[0m"
    fi
}

PROMPT_COMMAND=update_prompt_colors

export PS1='$(git rev-parse --is-inside-work-tree &>/dev/null && \
  echo -e "\n💙 \[\e[33m\e[1m\]$(__git_ps1 "%s")\[\e[0m\] \[\e[35m\]$(git_state_emoji)\[\e[0m\] ⏳\t\n${USER_HOST_COLOR}:\[\e[36m\]\w\[\e[0m\] \$ " || \
  echo -e "\n😎 ⏳\t\n${USER_HOST_COLOR}:\[\e[36m\]\w\[\e[0m\] \$ ")'
