# Yay! High voltage and arrows!

prompt_setup_pygmalion(){
  ZSH_THEME_GIT_PROMPT_PREFIX="%{$reset_color%}%{$fg[green]%}"
  ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
  ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[yellow]%}⚡%{$reset_color%}"
  ZSH_THEME_GIT_PROMPT_CLEAN=""
  pathname='if [ $(pwd) = "/" ]; then
              pathname="/"
            else
              num=`echo $(pwd) | awk '"'BEGIN{FS=\"/\"} {print NF?NF-1:0}'"'`
              if [ "$num" -eq "1" ]; then
                pathname="$(pwd)"
              else
                pathname=$(basename $(dirname `pwd`))/$(basename `pwd`)
              fi
            fi
            echo $pathname
            '
  base_prompt='%{$fg[magenta]%}%n%{$reset_color%}%{$fg[cyan]%}@%{$reset_color%}%{$fg[yellow]%}%m%{$reset_color%}%{$fg[red]%}:%{$reset_color%}%{$fg[cyan]%}%0 $(eval $pathname)%{$reset_color%}%{$fg[red]%}|%{$reset_color%}'
  post_prompt='%{$fg[cyan]%}⇒%{$reset_color%}  '

  base_prompt_nocolor=$(echo "$base_prompt" | perl -pe "s/%\{[^}]+\}//g")
  post_prompt_nocolor=$(echo "$post_prompt" | perl -pe "s/%\{[^}]+\}//g")

  precmd_functions+=(prompt_pygmalion_precmd)
}

prompt_pygmalion_precmd(){
  local gitupstream="$(command git rev-parse --abbrev-ref --symbolic-full-name @{u} 2> /dev/null)"
  local gitinfo="$(echo "$(git_prompt_info)" | xargs)"
  if [ -n "$gitupstream" ]; then
    gitinfo="$gitinfo..%{$fg[red]%}$gitupstream%{$reset_color%}"
  fi
  local gitinfo_nocolor=$(echo "$gitinfo" | perl -pe "s/%\{[^}]+\}//g")
  local exp_nocolor="$(print -P \"$base_prompt_nocolor$gitinfo_nocolor$post_prompt_nocolor\")"
  local prompt_length=${#exp_nocolor}

  local nl=""

  if [[ $prompt_length -gt 40 ]]; then
    nl=$'\n%{\r%}';
  fi

  if [[ -z "$(aws_prompt_info)" ]]; then
    PROMPT="$base_prompt$gitinfo $(emoji-clock) $(date)$nl$post_prompt"
  else
    PROMPT="$base_prompt$gitinfo $(aws_prompt_info) $(emoji-clock) $(date)$nl$post_prompt"
  fi
}

prompt_setup_pygmalion


