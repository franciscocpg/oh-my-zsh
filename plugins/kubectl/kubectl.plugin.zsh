# Autocompletion for kubectl, the command line interface for Kubernetes
#
# Author: https://github.com/pstadler

alias k8s='kubectl'
if [ $commands[kubectl] ]; then
  source <(kubectl completion zsh)

  k8s-dash() {
	RED='\033[0;31m'
	GREEN='\033[0;32m'
	NC='\033[0m' # No Color

  	NS=$1
	SELECTOR=$2
	CUTOFF_SECONDS=${3:-1800}

	NOW=$(date +%s)
	CUTOFF_TIMESTAMP=$(($NOW - $CUTOFF_SECONDS))

	echo "namespace=${NS:-default} selector=${SELECTOR:-none}"

	PODS_JSON="${PODS_JSON:-$(kubectl -n "$NS" get pod --selector "$SELECTOR" -o json)}"
	PODS="$(echo -E "$PODS_JSON" | jq '[.items[] | {status: .status.phase, ready: .status.containerStatuses[0].ready, timestamp: .metadata.creationTimestamp | fromdate}'])"
	OLD_PODS=$(echo "$PODS" | jq "[.[] | select(.timestamp <= $CUTOFF_TIMESTAMP)]")
	NEW_PODS=$(echo "$PODS" | jq "[.[] | select(.timestamp > $CUTOFF_TIMESTAMP)]")

	echo "===================================================="
	echo "new pods"
	echo "===================================================="

	NEW_PODS_STATUSES=$(echo "$NEW_PODS" | jq -r '[.[].status+"="+(.[].ready | tostring)] | unique | .[]')
	if [ -n "$NEW_PODS_STATUSES" ]
	then
		while read -r status_ready; do
			array=($(echo "$status_ready" | tr '=' ' '))
			st="${array[1]}"
			ready="${array[2]}"

			if [ "$ready" == "null" ]
			then
				ready=false
			fi

			ready_string=$($ready && echo "and ready" || echo "not ready")
			color="$($ready && echo $GREEN || echo $RED)"
			len=$(echo "$NEW_PODS" | jq "[.[] | select(.ready == $ready and .status == \"$st\")] | length")
			echo -e "${color}$st $ready_string: $len${NC}"
		done <<< "$NEW_PODS_STATUSES"
	else
		echo "No results"
	fi

	echo ""
	echo "===================================================="
	echo "old pods"
	echo "===================================================="

	OLD_PODS_STATUSES=$(echo "$OLD_PODS" | jq -r '[.[].status+"="+(.[].ready | tostring)] | unique | .[]')
	if [ -n "$OLD_PODS_STATUSES" ]
	then
		while read -r status_ready; do
			array=($(echo "$status_ready" | tr '=' ' '))
			st="${array[1]}"
			ready="${array[2]}"
			ready_string=$($ready && echo "and ready" || echo "not ready")
			color="$($ready && echo $GREEN || echo $RED)"
			len=$(echo "$OLD_PODS" | jq "[.[] | select(.ready == $ready and .status == \"$st\")] | length")
			echo "${color}$st $ready_string: $len${nc}"
		done <<< "$OLD_PODS_STATUSES"
	else
		echo "No results"
	fi
  }

  k8s-dash-watch() {
  	NS=$1
	SELECTOR=$2
	CUTOFF_SECONDS=$3
	INTERVAL=${4:-10}
	watch --color -n $INTERVAL "zsh -i -c 'k8s-dash $NS \"$SELECTOR\" $CUTOFF_SECONDS'"
  }
fi

# This command is used a LOT both below and in daily life
alias k=kubectl

# Apply a YML file
alias kaf='kubectl apply -f'

# Drop into an interactive terminal on a container
alias keti='kubectl exec -ti'

# Manage configuration quickly to switch contexts between local, dev ad staging.
alias kcuc='kubectl config use-context'
alias kcsc='kubectl config set-context'
alias kcdc='kubectl config delete-context'
alias kccc='kubectl config current-context'

# Pod management.
alias kgp='kubectl get pods'
alias kep='kubectl edit pods'
alias kdp='kubectl describe pods'
alias kdelp='kubectl delete pods'

# Service management.
alias kgs='kubectl get svc'
alias kes='kubectl edit svc'
alias kds='kubectl describe svc'
alias kdels='kubectl delete svc'

# Ingress management
alias kgi='kubectl get ingress'
alias kei='kubectl edit ingress'
alias kdi='kubectl describe ingress'
alias kdeli='kubectl delete ingress'

# Secret management
alias kgsec='kubectl get secret'
alias kdsec='kubectl describe secret'
alias kdelsec='kubectl delete secret'

# Deployment management.
alias kgd='kubectl get deployment'
alias ked='kubectl edit deployment'
alias kdd='kubectl describe deployment'
alias kdeld='kubectl delete deployment'
alias ksd='kubectl scale deployment'
alias krsd='kubectl rollout status deployment'

# Rollout management.
alias kgrs='kubectl get rs'
alias krh='kubectl rollout history'
alias kru='kubectl rollout undo'

# Logs
alias kl='kubectl logs'
alias klf='kubectl logs -f'
