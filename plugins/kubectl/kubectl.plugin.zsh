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
	OLD_BEFORE_SECONDS=${3:-1800}
	NEW_AFTER_SECONDS=${4:-600}
	BEFORE=$(($NOW - $OLD_BEFORE_SECONDS))
	AFTER=$(($NOW - $NEW_AFTER_SECONDS))

	echo "namespace=${NS:-default} selector=${SELECTOR:-none}"
	echo "===================================================="

	PODS=$(kubectl -n "$NS" get pod --selector "$SELECTOR" -o json | jq '[.items[] | {status: .status.phase, ready: .status.containerStatuses[0].ready, timestamp: .metadata.creationTimestamp | fromdate}'])
	OLD_PODS=$(echo "$PODS" | jq "[.[] | select(.timestamp <= $BEFORE)]")
	NEW_PODS=$(echo "$PODS" | jq "[.[] | select(.timestamp >= $AFTER)]")

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
	INTERVAL=${3:-10}
  	watch -n $INTERVAL "zsh -i -c 'k8s-dash $NS $SELECTOR'"
  }
fi
