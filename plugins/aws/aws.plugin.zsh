function agp() {
  echo $AWS_PROFILE
}

# AWS profile selection
function asp() {
  if [[ -z "$1" ]]; then
    unset AWS_DEFAULT_PROFILE AWS_PROFILE AWS_EB_PROFILE
    echo AWS profile cleared.
    return
  fi

  local -a available_profiles
  available_profiles=($(aws_profiles))
  if [[ -z "${available_profiles[(r)$1]}" ]]; then
    echo "${fg[red]}Profile '$1' not found in '${AWS_CONFIG_FILE:-$HOME/.aws/config}'" >&2
    echo "Available profiles: ${(j:, :)available_profiles:-no profiles found}${reset_color}" >&2
    return 1
  fi

  export AWS_DEFAULT_PROFILE=$1
  export AWS_PROFILE=$1
  export AWS_EB_PROFILE=$1
}

function aws_change_access_key() {
  if [[ -z "$1" ]]; then
    echo "usage: $0 <profile>"
    return 1
  fi

  echo Insert the credentials when asked.
  asp "$1" || return 1
  AWS_PAGER="" aws iam create-access-key
  AWS_PAGER="" aws configure --profile "$1"

  echo You can now safely delete the old access key running \`aws iam delete-access-key --access-key-id ID\`
  echo Your current keys are:
  AWS_PAGER="" aws iam list-access-keys
}

function aws_profiles() {
  [[ -r "${AWS_CONFIG_FILE:-$HOME/.aws/config}" ]] || return 1
  grep '\[profile' "${AWS_CONFIG_FILE:-$HOME/.aws/config}"|sed -e 's/.*profile \([a-zA-Z0-9@_\.-]*\).*/\1/'
}

function _aws_profiles() {
  reply=($(aws_profiles))
}
compctl -K _aws_profiles asp aws_change_access_key
compctl -K _aws_profiles acp aws_change_access_key

# AWS prompt
function aws_prompt_info() {
  [[ -z $AWS_PROFILE ]] && return
  echo "${ZSH_THEME_AWS_PREFIX:=<aws:}${AWS_PROFILE}${ZSH_THEME_AWS_SUFFIX:=>}"
}

if [ "$SHOW_AWS_PROMPT" != false ]; then
  RPROMPT='$(aws_prompt_info)'"$RPROMPT"
fi


# Load awscli completions

# AWS CLI v2 comes with its own autocompletion. Check if that is there, otherwise fall back
if command -v aws_completer &> /dev/null; then
  autoload -Uz bashcompinit && bashcompinit
  complete -C aws_completer aws
else
  function _awscli-homebrew-installed() {
    # check if Homebrew is installed
    (( $+commands[brew] )) || return 1

    # speculatively check default brew prefix
    if [ -h /usr/local/opt/awscli ]; then
      _brew_prefix=/usr/local/opt/awscli
    else
      # ok, it is not in the default prefix
      # this call to brew is expensive (about 400 ms), so at least let's make it only once
      _brew_prefix=$(brew --prefix awscli)
    fi
  }

  # get aws_zsh_completer.sh location from $PATH
  _aws_zsh_completer_path="$commands[aws_zsh_completer.sh]"

  # otherwise check common locations
  if [[ -z $_aws_zsh_completer_path ]]; then
    # Homebrew
    if _awscli-homebrew-installed; then
      _aws_zsh_completer_path=$_brew_prefix/libexec/bin/aws_zsh_completer.sh
    # Ubuntu
    elif [[ -e /usr/share/zsh/vendor-completions/_awscli ]]; then
      _aws_zsh_completer_path=/usr/share/zsh/vendor-completions/_awscli
    # NixOS
    elif [[ -e "${commands[aws]:P:h:h}/share/zsh/site-functions/aws_zsh_completer.sh" ]]; then
      _aws_zsh_completer_path="${commands[aws]:P:h:h}/share/zsh/site-functions/aws_zsh_completer.sh"
    # RPM
    else
      _aws_zsh_completer_path=/usr/share/zsh/site-functions/aws_zsh_completer.sh
    fi
  fi

  [[ -r $_aws_zsh_completer_path ]] && source $_aws_zsh_completer_path
  unset _aws_zsh_completer_path _brew_prefix
fi

function aws-ec2-start-instances {
  local instance_id="$1"
  aws ec2 start-instances --instance-ids $instance_id | jq .
}

function aws-ec2-stop-instances {
  local instance_id="$1"
  aws ec2 stop-instances --instance-ids $instance_id | jq .
}

function aws-authorize-security-group-ingress-by-name {
  local group_name="$1"

  local port="$2"
  local port_range=($(echo "${port//-/ }"))
  local from_port="$port_range[1]"
  local to_port="${port_range[2]:-$from_port}"

  local IP="${3:-$(curl -s https://ipecho.net/plain)}"
  local description="${4:-$USERNAME temp access}"

  aws ec2 authorize-security-group-ingress \
  --group-name "$group_name" \
  --ip-permissions '[{"IpProtocol": "tcp", "FromPort": '$from_port', "ToPort": '$to_port', "IpRanges": [{"CidrIp": "'$IP'/32", "Description": "'$description'"}]}]'
}

function aws-authorize-security-group-ingress-by-id {
  local group_id="$1"

  local port="$2"
  local port_range=($(echo "${port//-/ }"))
  local from_port="$port_range[1]"
  local to_port="${port_range[2]:-$from_port}"

  local IP="${3:-$(curl -s https://ipecho.net/plain)}"
  local description="${4:-$USERNAME temp access}"

  aws ec2 authorize-security-group-ingress \
  --group-id "$group_id" \
  --ip-permissions '[{"IpProtocol": "tcp", "FromPort": '$from_port', "ToPort": '$to_port', "IpRanges": [{"CidrIp": "'$IP'/32", "Description": "'$description'"}]}]'
}

function aws-revoke-security-group-ingress-by-name {
  local group_name="$1"

  local port="$2"
  local port_range=($(echo "${port//-/ }"))
  local from_port="$port_range[1]"
  local to_port="${port_range[2]:-$from_port}"

  local IP="${3:-$(curl -s https://ipecho.net/plain)}"

  aws ec2 revoke-security-group-ingress \
  --group-name "$group_name" \
  --ip-permissions '[{"IpProtocol": "tcp", "FromPort": '$from_port', "ToPort": '$to_port', "IpRanges": [{"CidrIp": "'$IP'/32"}]}]'
}

function aws-revoke-security-group-ingress-by-id {
  local group_id="$1"

  local port="$2"
  local port_range=($(echo "${port//-/ }"))
  local from_port="$port_range[1]"
  local to_port="${port_range[2]:-$from_port}"

  local IP="${3:-$(curl -s https://ipecho.net/plain)}"

  aws ec2 revoke-security-group-ingress \
  --group-id "$group_id" \
  --ip-permissions '[{"IpProtocol": "tcp", "FromPort": '$from_port', "ToPort": '$to_port', "IpRanges": [{"CidrIp": "'$IP'/32"}]}]'
}

function aws-revoke-security-group-ingress-by-description {
  local description="${1:-$USERNAME temp access}"

  local result=($(aws ec2 describe-security-groups \
  | jq -r '.SecurityGroups[]'\
'| {Name: .GroupName, Id: .GroupId, IpPermissions: .IpPermissions} as $p'\
'| .IpPermissions[] | {PortRange: [.FromPort, .ToPort|tostring] | join("|"), IpRanges: .IpRanges[]} as $r'\
'| .IpRanges[] | select(.Description=="'$description'")'\
'| [$p.Id, $p.Name, .CidrIp, $r.PortRange] | join("|")' \
| sort -u | sed ':a;N;$!ba;s/\n/ /g'))

  for var in ${result[*]}
  do
    local arr=($(echo $var | tr '|' "\n" ))

    local group_id="${arr[1]}"
    local IP="${arr[3]}"
    local from_port="${arr[4]}"
    local to_port="${arr[5]}"

    echo "Removing $var"
    
    aws ec2 revoke-security-group-ingress \
    --group-id "$group_id" \
    --ip-permissions '[{"IpProtocol": "tcp", "FromPort": '$from_port', "ToPort": '$to_port', "IpRanges": [{"CidrIp": "'$IP'"}]}]'
  done
}

function aws-list-security-group-ingress-by-name {
  local header="************************************************\t***************\t********************\t********************
Security Group\tIP\tPort Range\tDescription
************************************************\t***************\t********************\t********************"

  local result=$(aws ec2 describe-security-groups \
  --group-names "$1" \
  | jq -r '.SecurityGroups[]'\
'| {Name: .GroupName, Id: .GroupId, IpPermissions: .IpPermissions} as $p'\
'| .IpPermissions[] | {PortRange: [.FromPort, .ToPort|tostring] | join("-"), IpRanges: .IpRanges[]} as $r'\
'| .IpRanges[]'\
'| [$p.Id + " (" + $p.Name + ")", .CidrIp, $r.PortRange, .Description] | join("\t")' \
  | sort -u)

  echo "$header\n$result" | column -t -s $'\t'
}

function aws-list-security-group-ingress-by-id {
  local header="************************************************\t***************\t********************\t********************
Security Group\tIP\tPort Range\tDescription
************************************************\t***************\t********************\t********************"

  local result=$(aws ec2 describe-security-groups \
  --group-ids "$1" \
  | jq -r '.SecurityGroups[]'\
'| {Name: .GroupName, Id: .GroupId, IpPermissions: .IpPermissions} as $p'\
'| .IpPermissions[] | {PortRange: [.FromPort, .ToPort|tostring] | join("-"), IpRanges: .IpRanges[]} as $r'\
'| .IpRanges[]'\
'| [$p.Id + " (" + $p.Name + ")", .CidrIp, $r.PortRange, .Description] | join("\t")' \
  | sort -u)

  echo "$header\n$result" | column -t -s $'\t'
}

function aws-list-authorized-security-group-ingress-by-ip {
  local IP="${1:-$(curl -s https://ipecho.net/plain)}"

  local header="************************************************\t***************\t********************\t********************
Security Group\tIP\tPort Range\tDescription
************************************************\t***************\t********************\t********************"

  local result=$(aws ec2 describe-security-groups \
  --filters Name=ip-permission.cidr,Values="$IP/32" \
  | jq -r '.SecurityGroups[]'\
'| {Name: .GroupName, Id: .GroupId, IpPermissions: .IpPermissions} as $p'\
'| .IpPermissions[] | {PortRange: [.FromPort, .ToPort|tostring] | join("-"), IpRanges: .IpRanges[]} as $r'\
'| .IpRanges[] | select(.CidrIp=="'$IP'/32") '\
'| [$p.Id + " (" + $p.Name + ")", .CidrIp, $r.PortRange, .Description] | join("\t")' \
  | sort -u)

  echo "$header\n$result" | column -t -s $'\t'
}

function aws-list-authorized-security-group-ingress-by-description {
  local description="${1:-$USERNAME temp access}"

  local header="************************************************\t***************\t********************\t********************
Security Group\tIP\tPort Range\tDescription
************************************************\t***************\t********************\t********************"

  local result=$(aws ec2 describe-security-groups \
  | jq -r '.SecurityGroups[]'\
'| {Name: .GroupName, Id: .GroupId, IpPermissions: .IpPermissions} as $p'\
'| .IpPermissions[] | {PortRange: [.FromPort, .ToPort|tostring] | join("-"), IpRanges: .IpRanges[]} as $r'\
'| .IpRanges[] | select(.Description != null) | select(.Description | match("'$description'"))'\
'| [$p.Id + " (" + $p.Name + ")", .CidrIp, $r.PortRange, .Description] | join("\t")' \
  | sort -u)
  
  echo "$header\n$result" | column -t -s $'\t'
}

function aws-workspace-status() {
  local workspace_id="${1:-ws-j8w1k9l32}"

  aws workspaces describe-workspaces --workspace-ids $workspace_id | jq -r '.Workspaces[0].State'
}

function aws-workspace-start() {
  local workspace_id="${1:-ws-j8w1k9l32}"
  
  local result_status=$(aws workspaces describe-workspaces --workspace-ids $workspace_id | jq -r '.Workspaces[0].State')
  
  if [[ $result_status == "null" ]]
  then
    echo "Workspace $workspace_id not found"
    return 1
  fi
  if [[ $result_status == "AVAILABLE" ]]
  then
    echo "Workspace $workspace_id already started"
    return 1
  fi

  if [[ $result_status != "STOPPED" ]]
  then
    echo "Workspace $workspace_id cannot be started because its status is $result_status"
    return 1
  fi

  local result=$(aws workspaces start-workspaces --start-workspace-requests WorkspaceId=$workspace_id)
  
  local failed_requests=$(echo "$result" | jq .FailedRequests) 

  if [[ $failed_requests != "[]" ]]
  then
    echo "Fail to start workspace $workspace_id. Response: "
    echo "$result"
    return 1
  fi

  while :
  do 
    local result_status=$(aws workspaces describe-workspaces --workspace-ids $workspace_id | jq -r '.Workspaces[0].State')
    echo "$(date +%T) $result_status" 

    if [[ $result_status == "AVAILABLE" ]]
    then
      notify-send -u critical -i ok "Workspace $workspace_id is available"
      break
    else
      sleep 10
    fi
  done
}


function aws-workspace-stop() {
  local workspace_id="${1:-ws-j8w1k9l32}"

  local result_status=$(aws workspaces describe-workspaces --workspace-ids $workspace_id | jq -r '.Workspaces[0].State')

  if [[ $result_status == "null" ]]
  then
    echo "Workspace $workspace_id not found"
    return 1
  fi

  if [[ $result_status == "STOPPED" ]]
  then
    echo "Workspace $workspace_id already stopped"
    return 1
  fi

  if [[ $result_status != "AVAILABLE" ]]
  then
    echo "Workspace $workspace_id cannot be stopped because its status is $result_status"
    return 1
  fi

  local result=$(aws workspaces stop-workspaces --stop-workspace-requests WorkspaceId=$workspace_id)
  
  local failed_requests=$(echo "$result" | jq .FailedRequests)

  if [[ $failed_requests != "[]" ]]
  then
    echo "Fail to stop workspace $workspace_id. Response: "
    echo "$result"
    return 1
  fi

  while :
  do 
    local result_status=$(aws workspaces describe-workspaces --workspace-ids $workspace_id | jq -r '.Workspaces[0].State')
    echo "$(date +%T) $result_status" 

    if [[ $result_status == "STOPPED" ]]
    then
      notify-send -u critical -i ok "Workspace $workspace_id is stopped"
      break
    else
      sleep 10
    fi
  done
}

function aws-list-cloudformation-stacks {
  aws cloudformation describe-stacks --output table --query 'Stacks[*].{Name:StackName,Status:StackStatus}'
}
