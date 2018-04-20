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
  reply=($(grep profile $AWS_HOME/config|sed -e 's/.*profile \([a-zA-Z0-9_-]*\).*/\1/'))
}

compctl -K aws_profiles asp

if _homebrew-installed && _awscli-homebrew-installed ; then
  _aws_zsh_completer_path=$_brew_prefix/libexec/bin/aws_zsh_completer.sh
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

function aws-add-security-group-rule-descomplica {
  GROUP_NAME="$1"
  PORT="$2"
  IP="${3:-$(curl -s https://httpbin.org/ip | jq -r .origin)}"
  DESCRIPTION="${4:-francisco temp access}"

  aws ec2 authorize-security-group-ingress \
  --group-name "$GROUP_NAME" \
  --ip-permissions '[{"IpProtocol": "tcp", "FromPort": '$PORT', "ToPort": '$PORT', "IpRanges": [{"CidrIp": "'$IP'/32", "Description": "'$DESCRIPTION'"}]}]' \
  --region sa-east-1 --profile descomplica
}

function aws-revoke-security-group-ingress-descomplica {
  GROUP_NAME="$1"
  PORT="$2"
  IP="${3:-$(curl -s https://httpbin.org/ip | jq -r .origin)}"

  aws ec2 revoke-security-group-ingress \
  --group-name "$GROUP_NAME" \
  --ip-permissions '[{"IpProtocol": "tcp", "FromPort": '$PORT', "ToPort": '$PORT', "IpRanges": [{"CidrIp": "'$IP'/32"}]}]' \
  --region sa-east-1 --profile descomplica
}
