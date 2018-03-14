# Autocompletion for kubectl, the command line interface for Kubernetes
#
# Author: https://github.com/pstadler

alias k8s='kubectl'
if [ $commands[kubectl] ]; then
  source <(kubectl completion zsh)

  k8s-dash() {
  	NS=$1
	SELECTOR=$2

	NOW=$(date +%s)
	TIMELINE_SECONDS=${3:-1800}
	TIMELINE_TIMESTAMP=$(($NOW - $TIMELINE_SECONDS))

	echo "namespace=${NS:-default} selector=${SELECTOR:-none}"
	echo "===================================================="

	PODS=$(kubectl -n "$NS" get pod --selector "$SELECTOR" -o json | jq '[.items[] | {status: .status.phase, ready: .status.containerStatuses[0].ready, timestamp: .metadata.creationTimestamp | fromdate}'])
	OLD_PODS=$(echo "$PODS" | jq "[.[] | select(.timestamp <= $TIMELINE_TIMESTAMP)]")
	NEW_PODS=$(echo "$PODS" | jq "[.[] | select(.timestamp > $TIMELINE_TIMESTAMP)]")

	NEW_RUNNING_READY=$(echo "$NEW_PODS" | jq '[.[] | select(.ready == true and .status == "Running")] | length')
	NEW_RUNNING_NOT_READY=$(echo "$NEW_PODS" | jq '[.[] | select(.ready == false and .status == "Running")] | length')

	OLD_RUNNING_READY=$(echo "$OLD_PODS" | jq '[.[] | select(.ready == true and .status == "Running")] | length')
	OLD_RUNNING_NOT_READY=$(echo "$OLD_PODS" | jq '[.[] | select(.ready == false and .status == "Running")] | length')

	echo "new pods"
	echo "===================================================="
	echo "Running and ready: $NEW_RUNNING_READY"
	echo "Running not ready (Creating): $NEW_RUNNING_NOT_READY"
	echo ""

	echo "===================================================="
	echo "old pods"
	echo "===================================================="
	echo "Running and ready: $OLD_RUNNING_READY"
	echo "Running not ready (Terminating): $OLD_RUNNING_NOT_READY"
  }

  k8s-dash-watch() {
  	NS=$1
	SELECTOR=$2
	TIMELINE_SECONDS=$3
	INTERVAL=${5:-10}
	watch -n $INTERVAL "zsh -i -c 'k8s-dash $NS \"$SELECTOR\" $TIMELINE_SECONDS'"
  }
fi

# This command is used ALOT both below and in daily life
alias k=kubectl

# Apply a YML file
alias kaf='k apply -f'

# Drop into an interactive terminal on a container
alias keti='k exec -ti'

# Manage configuration quickly to switch contexts between local, dev ad staging.
alias kcuc='k config use-context'
alias kcsc='k config set-context'
alias kcdc='k config delete-context'
alias kccc='k config current-context'

# Pod management.
alias kgp='k get pods'
alias kep='k edit pods'
alias kdp='k describe pods'
alias kdelp='k delete pods'

# Service management.
alias kgs='k get svc'
alias kes='k edit svc'
alias kds='k describe svc'
alias kdels='k delete svc'

# Secret management
alias kgsec='k get secret'
alias kdsec='k describe secret'
alias kdelsec='k delete secret'

# Deployment management.
alias kgd='k get deployment'
alias ked='k edit deployment'
alias kdd='k describe deployment'
alias kdeld='k delete deployment'
alias ksd='k scale deployment'
alias krsd='k rollout status deployment'

# Rollout management.
alias kgrs='k get rs'
alias krh='k rollout history'
alias kru='k rollout undo'

# Logs
alias kl='k logs'
alias klf='k logs -f'
