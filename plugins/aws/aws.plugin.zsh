_homebrew-installed() {
  type brew &> /dev/null
}

_awscli-homebrew-installed() {
  brew list awscli &> /dev/null
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
  reply=($(grep profile $AWS_HOME/config|sed -e 's/.*profile \([a-zA-Z0-9_-]*\).*/\1/'))
}

compctl -K aws_profiles asp

if _homebrew-installed && _awscli-homebrew-installed ; then
  _aws_zsh_completer_path=$(brew --prefix awscli)/libexec/bin/aws_zsh_completer.sh
else
  _aws_zsh_completer_path=$(which aws_zsh_completer.sh)
fi

[ -x $_aws_zsh_completer_path ] && source $_aws_zsh_completer_path
unset _aws_zsh_completer_path

function aws-ec2-desc-instances {
  INSTANCE_ID="$1"
  if [ -n "$INSTANCE_ID" ]; then
    INSTANCE_IDS=(--instance-ids $INSTANCE_ID)
  fi
  aws ec2 describe-instances $INSTANCE_IDS | \
  jq '.Reservations[].Instances[] | {InstanceId: .InstanceId, Status: .State.Name, Ip: .NetworkInterfaces[0].Association.PublicIp}'
}

function aws-ec2-start-instances {
  INSTANCE_ID="$1"
  aws ec2 start-instances --instance-ids $INSTANCE_ID | jq .
}

function aws-ec2-stop-instances {
  INSTANCE_ID="$1"
  aws ec2 stop-instances --instance-ids $INSTANCE_ID | jq .
}