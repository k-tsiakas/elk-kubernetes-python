

## wait for elastisearch to be ready

#!/bin/bash

# Namespace where Elasticsearch is deployed
NAMESPACE="logging"
# Label to identify the Elasticsearch pod (adjust as needed)
LABEL_SELECTOR="app=elasticsearch-master"
# Max wait time in seconds
TIMEOUT=300
# Wait interval in seconds
SLEEP=5

# 1. Install elasticsearch
helm install elk-elasticsearch elastic/elasticsearch -f src/k8s/elasticsearch-values.yaml --namespace "$NAMESPACE" --create-namespace
ELASTIC_PASSWORD=$(kubectl get secrets --namespace="$NAMESPACE" elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d)
echo "$ELASTIC_PASSWORD"
echo "Waiting for Elasticsearch pod to become ready..."

SECONDS_WAITED=0
while true; do
  # Get the name of the first matching pod
  POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l "$LABEL_SELECTOR" -o jsonpath="{.items[0].metadata.name}")

  if [[ -z "$POD_NAME" ]]; then
    echo "No Elasticsearch pod found with label: $LABEL_SELECTOR"
  else
    # Check if the pod is Ready
    READY=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath="{.status.containerStatuses[0].ready}")
    if [[ "$READY" == "true" ]]; then
      echo "Elasticsearch pod '$POD_NAME' is ready."
      
      # Optional: Check if Elasticsearch is responsive via its REST API
      echo "Probing Elasticsearch REST API..."
      kubectl port-forward svc/elasticsearch-master 9200:9200 -n "$NAMESPACE" > /dev/null 2>&1 &
      PORT_FORWARD_PID=$!
      sleep 2
      if curl -k -s -u elastic:$ELASTIC_PASSWORD http://localhost:9200/_cluster/health | jq ".status"; then
        echo "Elasticsearch REST API is responsive."
        kill $PORT_FORWARD_PID
        break
      else
        echo "Elasticsearch API not responding yet..."
        kill $PORT_FORWARD_PID
      fi
    else
      echo "Pod '$POD_NAME' is not ready yet..."
    fi
  fi

  sleep $SLEEP
  SECONDS_WAITED=$((SECONDS_WAITED + SLEEP))
  if [[ $SECONDS_WAITED -ge $TIMEOUT ]]; then
    echo "Timed out waiting for Elasticsearch to become ready."
    exit 1
  fi
done

# 2. Install kibana
helm install elk-kibana elastic/kibana -f src/k8s/kibana-values.yaml --namespace "$NAMESPACE"

# 3. Install logstash
helm install elk-logstash elastic/logstash -f src/k8s/logstash-values.yaml --namespace "$NAMESPACE"

# 4. Install filebeat
helm install elk-filebeat elastic/filebeat -f src/k8s/filebeat-values.yaml --namespace "$NAMESPACE"