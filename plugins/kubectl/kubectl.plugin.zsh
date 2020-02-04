# Autocompletion for kubectl, the command line interface for Kubernetes
#
# Author: https://github.com/pstadler

alias k8s='/usr/bin/kubectl'
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

# Execute a kubectl command against all namespaces
alias kca='f(){ kubectl "$@" --all-namespaces;  unset -f f; }; f'

# Apply a YML file
alias kaf='kubectl apply -f'

# Drop into an interactive terminal on a container
alias keti='kubectl exec -ti'

# Manage configuration quickly to switch contexts between local, dev ad staging.
alias kcuc='kubectl config use-context'
alias kcsc='kubectl config set-context'
alias kcdc='kubectl config delete-context'
alias kccc='kubectl config current-context'

# List all contexts
alias kcgc='kubectl config get-contexts'

# General aliases
alias kdel='kubectl delete'
alias kdelf='kubectl delete -f'

# Pod management.
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods --all-namespaces'
alias kgpw='kgp --watch'
alias kgpwide='kgp -o wide'
alias kep='kubectl edit pods'
alias kdp='kubectl describe pods'
alias kdelp='kubectl delete pods'

# get pod by label: kgpl "app=myapp" -n myns
alias kgpl='kgp -l'

# Service management.
alias kgs='kubectl get svc'
alias kgsa='kubectl get svc --all-namespaces'
alias kgsw='kgs --watch'
alias kgswide='kgs -o wide'
alias kes='kubectl edit svc'
alias kds='kubectl describe svc'
alias kdels='kubectl delete svc'

# Ingress management
alias kgi='kubectl get ingress'
alias kgia='kubectl get ingress --all-namespaces'
alias kei='kubectl edit ingress'
alias kdi='kubectl describe ingress'
alias kdeli='kubectl delete ingress'

# Namespace management
alias kgns='kubectl get namespaces'
alias kens='kubectl edit namespace'
alias kdns='kubectl describe namespace'
alias kdelns='kubectl delete namespace'
alias kcn='kubectl config set-context $(kubectl config current-context) --namespace'

# ConfigMap management
alias kgcm='kubectl get configmaps'
alias kgcma='kubectl get configmaps --all-namespaces'
alias kecm='kubectl edit configmap'
alias kdcm='kubectl describe configmap'
alias kdelcm='kubectl delete configmap'

# Secret management
alias kgsec='kubectl get secret'
alias kgseca='kubectl get secret --all-namespaces'
alias kdsec='kubectl describe secret'
alias kdelsec='kubectl delete secret'

# Deployment management.
alias kgd='kubectl get deployment'
alias kgda='kubectl get deployment --all-namespaces'
alias kgdw='kgd --watch'
alias kgdwide='kgd -o wide'
alias ked='kubectl edit deployment'
alias kdd='kubectl describe deployment'
alias kdeld='kubectl delete deployment'
alias ksd='kubectl scale deployment'
alias krsd='kubectl rollout status deployment'
kres(){
    kubectl set env $@ REFRESHED_AT=$(date +%Y%m%d%H%M%S)
}

# Rollout management.
alias kgrs='kubectl get rs'
alias krh='kubectl rollout history'
alias kru='kubectl rollout undo'

# Statefulset management.
alias kgss='kubectl get statefulset'
alias kgssa='kubectl get statefulset --all-namespaces'
alias kgssw='kgss --watch'
alias kgsswide='kgss -o wide'
alias kess='kubectl edit statefulset'
alias kdss='kubectl describe statefulset'
alias kdelss='kubectl delete statefulset'
alias ksss='kubectl scale statefulset'
alias krsss='kubectl rollout status statefulset'

# Port forwarding
alias kpf="kubectl port-forward"

# Tools for accessing all information
alias kga='kubectl get all'
alias kgaa='kubectl get all --all-namespaces'

# Logs
alias kl='kubectl logs'
alias kl1h='kubectl logs --since 1h'
alias kl1m='kubectl logs --since 1m'
alias kl1s='kubectl logs --since 1s'
alias klf='kubectl logs -f'
alias klf1h='kubectl logs --since 1h -f'
alias klf1m='kubectl logs --since 1m -f'
alias klf1s='kubectl logs --since 1s -f'

# File copy
alias kcp='kubectl cp'

# Node Management
alias kgno='kubectl get nodes'
alias keno='kubectl edit node'
alias kdno='kubectl describe node'
alias kdelno='kubectl delete node'

# PVC management.
alias kgpvc='kubectl get pvc'
alias kgpvca='kubectl get pvc --all-namespaces'
alias kgpvcw='kgpvc --watch'
alias kepvc='kubectl edit pvc'
alias kdpvc='kubectl describe pvc'
alias kdelpvc='kubectl delete pvc'

