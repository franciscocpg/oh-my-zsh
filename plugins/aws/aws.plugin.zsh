_homebrew-installed() {
  type brew &> /dev/null
  _xit=$?
  if [ $_xit -eq 0 ];then
        # ok , we have brew installed
        # speculatively we check default brew prefix
        if [ -h  /usr/local/opt/awscli ];then
                _brew_prefix="/usr/local/opt/awscli"
        else
                # ok , it is not default prefix
                # this call to brew is expensive ( about 400 ms ), so at least let's make it only once
                _brew_prefix=$(brew --prefix awscli)
        fi
        return 0
   else
        return $_xit
   fi
}

_awscli-homebrew-installed() {
  [ -r $_brew_prefix/libexec/bin/aws_zsh_completer.sh ] &> /dev/null
}

export AWS_HOME=~/.aws

function agp {
  echo $AWS_DEFAULT_PROFILE
}

function asp {
  local rprompt=${RPROMPT/<aws:$(agp)>/}

  export AWS_DEFAULT_PROFILE=$1
  export AWS_PROFILE=$1

  export RPROMPT="<aws:$AWS_DEFAULT_PROFILE>$rprompt"
}

function aws_profiles {
  reply=($(grep profile $AWS_HOME/config|sed -e 's/.*profile \([a-zA-Z0-9_\.-]*\).*/\1/'))
}
compctl -K aws_profiles asp

if which aws_zsh_completer.sh &>/dev/null; then
  _aws_zsh_completer_path=$(which aws_zsh_completer.sh 2>/dev/null)
elif _homebrew-installed && _awscli-homebrew-installed; then
  _aws_zsh_completer_path=$_brew_prefix/libexec/bin/aws_zsh_completer.sh
fi

[ -n "$_aws_zsh_completer_path" ] && [ -x $_aws_zsh_completer_path ] && source $_aws_zsh_completer_path
unset _aws_zsh_completer_path

function aws-ec2-desc-instances {
  local instance_id="$1"

  if [ -n "$instance_id" ]; then
    local instance_ids=(--instance-ids $instance_id)
  fi

  aws ec2 describe-instances $instance_ids | \
  jq '.Reservations[].Instances[] | {InstanceId: .InstanceId, Status: .State.Name, Ip: .NetworkInterfaces[0].Association.PublicIp}'
}

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

  local IP="${3:-$(curl -s https://httpbin.org/ip | jq -r .origin)}"
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

  local IP="${3:-$(curl -s https://httpbin.org/ip | jq -r .origin)}"
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

  local IP="${3:-$(curl -s https://httpbin.org/ip | jq -r .origin)}"

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

  local IP="${3:-$(curl -s https://httpbin.org/ip | jq -r .origin)}"

  aws ec2 revoke-security-group-ingress \
  --group-id "$group_id" \
  --ip-permissions '[{"IpProtocol": "tcp", "FromPort": '$from_port', "ToPort": '$to_port', "IpRanges": [{"CidrIp": "'$IP'/32"}]}]'
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
  local IP="${1:-$(curl -s https://httpbin.org/ip | jq -r .origin)}"

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
'| .IpRanges[] | select(.Description=="'$description'")'\
'| [$p.Id + " (" + $p.Name + ")", .CidrIp, $r.PortRange, .Description] | join("\t")' \
  | sort -u)
  
  echo "$header\n$result" | column -t -s $'\t'
}

function aws-workspace-status() {
  local workspace_id="${1:-ws-j8w1k9l32}"

  aws workspaces describe-workspaces --workspace-ids $workspace_id | jq -r .Workspaces[0].State
}

function aws-workspace-start() {
  local workspace_id="${1:-ws-j8w1k9l32}"

  local result_status=$(aws workspaces describe-workspaces --workspace-ids $workspace_id | jq -r .Workspaces[0].State)

  if [ $result_status == "null" ]
  then
    echo "Workspace $workspace_id not found"
    return 1
  fi

  if [ $result_status == "AVAILABLE" ]
  then
    echo "Workspace $workspace_id already started"
    return 1
  fi

  if [ $result_status != "STOPPED" ]
  then
    echo "Workspace $workspace_id cannot be started because its status is $result_status"
    return 1
  fi

  local result=$(aws workspaces start-workspaces --start-workspace-requests WorkspaceId=$workspace_id)
  
  local failed_requests=$(echo "$result" | jq .FailedRequests) 

  if [ $failed_requests != "[]" ]
  then
    echo "Fail to start workspace $workspace_id. Response: "
    echo "$result"
    return 1
  fi

  while :
  do 
    local result_status=$(aws workspaces describe-workspaces --workspace-ids $workspace_id | jq -r .Workspaces[0].State)
    echo "$(date +%T) $result_status" 

    if [ $result_status == "AVAILABLE" ]
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

  local result_status=$(aws workspaces describe-workspaces --workspace-ids $workspace_id | jq -r .Workspaces[0].State)

  if [ $result_status == "null" ]
  then
    echo "Workspace $workspace_id not found"
    return 1
  fi

  if [ $result_status == "STOPPED" ]
  then
    echo "Workspace $workspace_id already stopped"
    return 1
  fi

  if [ $result_status != "AVAILABLE" ]
  then
    echo "Workspace $workspace_id cannot be stopped because its status is $result_status"
    return 1
  fi

  local result=$(aws workspaces stop-workspaces --stop-workspace-requests WorkspaceId=$workspace_id)
  
  local failed_requests=$(echo "$result" | jq .FailedRequests)

  if [ $failed_requests != "[]" ]
  then
    echo "Fail to stop workspace $workspace_id. Response: "
    echo "$result"
    return 1
  fi

  while :
  do 
    local result_status=$(aws workspaces describe-workspaces --workspace-ids $workspace_id | jq -r .Workspaces[0].State)
    echo "$(date +%T) $result_status" 

    if [ $result_status == "STOPPED" ]
    then
      notify-send -u critical -i ok "Workspace $workspace_id is stopped"
      break
    else
      sleep 10
    fi
  done
}