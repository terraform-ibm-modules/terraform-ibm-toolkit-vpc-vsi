#!/usr/bin/env bash

NETWORK_ACL="$1"
REGION="$2"
RESOURCE_GROUP="$3"
TARGET_IP_RANGE="$4"

if [[ -n "${BIN_DIR}" ]]; then
  export PATH="${BIN_DIR}:${PATH}"
fi

if [[ -z "${TARGET_IP_RANGE}" ]]; then
  TARGET_IP_RANGE="0.0.0.0/0"
fi

if [[ -z "${NETWORK_ACL}" ]] || [[ -z "${REGION}" ]] || [[ -z "${RESOURCE_GROUP}" ]]; then
  echo "Usage: open-acl-rules.sh NETWORK_ACL REGION RESOURCE_GROUP"
  exit 1
fi

if [[ -z "${IBMCLOUD_API_KEY}" ]]; then
  echo "IBMCLOUD_API_KEY environment variable must be set"
  exit 1
fi

if [[ -z "${ACL_RULES}" ]] || [[ -z "${SG_RULES}" ]]; then
  echo "ACL_RULES or SG_RULES environment variable must be set"
  exit 0
fi

SEMAPHORE="acl_rules.semaphore"

while true; do
  echo "Checking for semaphore"
  if [[ ! -f "${SEMAPHORE}" ]]; then
    echo -n "${NETWORK_ACL}" > "${SEMAPHORE}"

    if [[ $(cat ${SEMAPHORE}) == "${NETWORK_ACL}" ]]; then
      echo "Got the semaphore. Creating acl rules"
      break
    fi
  fi

  SLEEP_TIME=$((1 + $RANDOM % 10))
  echo "  Waiting $SLEEP_TIME seconds for semaphore"
  sleep $SLEEP_TIME
done

function finish {
  rm "${SEMAPHORE}"
}

trap finish EXIT

# Install jq if not available

echo "Getting IBM Cloud API access_token"
TOKEN=$(curl -s -X POST "https://iam.cloud.ibm.com/identity/token" -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=${IBMCLOUD_API_KEY}" | jq -r '.access_token // empty')

if [[ -z "${TOKEN}" ]]; then
  echo "Error retrieving auth token"
  exit 1
fi

## TODO more sophisticated logic needed to 1) test for existing rules and 2) place this rule in the right order

VERSION="2021-06-30"

echo "Processing ACL_RULES"
echo "${ACL_RULES}" | jq -c '.[]' | \
  while read rule;
do
  name=$(echo "${rule}" | jq -r '.name')
  action=$(echo "${rule}" | jq -r '.action')
  direction=$(echo "${rule}" | jq -r '.direction')
  source=$(echo "${rule}" | jq -r '.source')
  destination=$(echo "${rule}" | jq -r '.destination')

  tcp=$(echo "${rule}" | jq -c '.tcp // empty')
  udp=$(echo "${rule}" | jq -c '.udp // empty')
  icmp=$(echo "${rule}" | jq -c '.icmp // empty')

  if [[ -n "${tcp}" ]] || [[ -n "${udp}" ]]; then
    if [[ -n "${tcp}" ]]; then
      type="tcp"
      config="${tcp}"
    else
      type="udp"
      config="${udp}"
    fi

    source_port_min=$(echo "${config}" | jq -r '.source_port_min')
    source_port_max=$(echo "${config}" | jq -r '.source_port_max')
    port_min=$(echo "${config}" | jq -r '.port_min')
    port_max=$(echo "${config}" | jq -r '.port_max')

    RULE=$(jq -c -n --arg action "${action}" \
      --arg direction "${direction}" \
      --arg protocol "${type}" \
      --arg source "${source}" \
      --arg destination "${destination}" \
      --arg name "${name}" \
      --argjson source_port_min "${source_port_min}" \
      --argjson source_port_max "${source_port_max}" \
      --argjson destination_port_min "${port_min}" \
      --argjson destination_port_max "${port_max}" \
      '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name, destination_port_min: $destination_port_min, destination_port_max: $destination_port_max, source_port_min: $source_port_min, source_port_max: $source_port_max}')
  elif [[ -n "${icmp}" ]]; then
    icmp_type=$(echo "${icmp}" | jq -r '.type // empty')
    icmp_code=$(echo "${icmp}" | jq -r '.code // empty')

    if [[ -n "${icmp_type}" ]] && [[ -n "${icmp_code}" ]]; then
      RULE=$(jq -c -n --arg action "${action}" \
        --arg direction "${direction}" \
        --arg protocol "icmp" \
        --arg source "${source}" \
        --arg destination "${destination}" \
        --arg name "${name}" \
        --argjson code "${icmp_code}" \
        --argjson type "${icmp_type}" \
        '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name, code: $code, type: $type}')
    elif [[ -n "${icmp_type}" ]]; then
      RULE=$(jq -c -n --arg action "${action}" \
        --arg direction "${direction}" \
        --arg protocol "icmp" \
        --arg source "${source}" \
        --arg destination "${destination}" \
        --arg name "${name}" \
        --argjson type "${icmp_type}" \
        '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name, type: $type}')
    else
      RULE=$(jq -c -n --arg action "${action}" \
        --arg direction "${direction}" \
        --arg protocol "icmp" \
        --arg source "${source}" \
        --arg destination "${destination}" \
        --arg name "${name}" \
        '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name}')
    fi
  else
    RULE=$(jq -c -n --arg action "${action}" \
      --arg direction "${direction}" \
      --arg protocol "all" \
      --arg source "${source}" \
      --arg destination "${destination}" \
      --arg name "${name}" \
      '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name}')
  fi

  echo "Creating rule: ${RULE}"

  RESULT=$(curl -s -H "Authorization: Bearer ${TOKEN}" \
    -X POST \
    "https://${REGION}.iaas.cloud.ibm.com/v1/network_acls/${NETWORK_ACL}/rules?version=${VERSION}&generation=2" \
    -d "${RULE}")

  ID=$(echo "${RESULT}" | jq -r '.id // empty')

  if [[ -z "${ID}" ]]; then
    echo "Error creating rule: ${rule}"
    echo "${RESULT}"
    exit 1
  fi
done

echo "Processing SG_RULES"
echo "${SG_RULES}" | jq -c '.[]' | \
  while read rule;
do
  name=$(echo "${rule}" | jq -r '.name')
  action="allow"
  direction=$(echo "${rule}" | jq -r '.direction')
  remote=$(echo "${rule}" | jq -r '.remote')

  if [[ "${direction}" == "inbound" ]]; then
    reverse_direction="outbound"
  else
    reverse_direction="inbound"
  fi
  reverse_name="$(echo "${name}" | sed -E "s/-${direction}//g" | sed -E "s/(.*)/\1-${reverse_direction}/g")"

  if [[ "${direction}" == "inbound" ]]; then
    source="${remote}"
    destination="${TARGET_IP_RANGE}"
  else
    destination="${remote}"
    source="${TARGET_IP_RANGE}"
  fi

  tcp=$(echo "${rule}" | jq -c '.tcp // empty')
  udp=$(echo "${rule}" | jq -c '.udp // empty')
  icmp=$(echo "${rule}" | jq -c '.icmp // empty')

  if [[ -n "${tcp}" ]] || [[ -n "${udp}" ]]; then
    if [[ -n "${tcp}" ]]; then
      type="tcp"
      config="${tcp}"
    else
      type="udp"
      config="${udp}"
    fi

    port_min=$(echo "${config}" | jq -r '.port_min')
    port_max=$(echo "${config}" | jq -r '.port_max')

    RULE=$(jq -c -n --arg action "${action}" \
      --arg direction "${direction}" \
      --arg protocol "${type}" \
      --arg source "${source}" \
      --arg destination "${destination}" \
      --arg name "${name}" \
      --argjson source_port_min "${port_min}" \
      --argjson source_port_max "${port_max}" \
      --argjson destination_port_min "${port_min}" \
      --argjson destination_port_max "${port_max}" \
      '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name, destination_port_min: $destination_port_min, destination_port_max: $destination_port_max, source_port_min: $source_port_min, source_port_max: $source_port_max}')
    REVERSE_RULE=$(jq -c -n --arg action "${action}" \
      --arg direction "${reverse_direction}" \
      --arg protocol "${type}" \
      --arg source "${destination}" \
      --arg destination "${source}" \
      --arg name "${reverse_name}" \
      --argjson source_port_min "${port_min}" \
      --argjson source_port_max "${port_max}" \
      --argjson destination_port_min "${port_min}" \
      --argjson destination_port_max "${port_max}" \
      '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name, destination_port_min: $destination_port_min, destination_port_max: $destination_port_max, source_port_min: $source_port_min, source_port_max: $source_port_max}')
  elif [[ -n "${icmp}" ]]; then
    icmp_type=$(echo "${icmp}" | jq -r '.type // empty')
    icmp_code=$(echo "${icmp}" | jq -r '.code // empty')

    if [[ -n "${icmp_type}" ]] && [[ -n "${icmp_code}" ]]; then
      RULE=$(jq -c -n --arg action "${action}" \
        --arg direction "${direction}" \
        --arg protocol "icmp" \
        --arg source "${source}" \
        --arg destination "${destination}" \
        --arg name "${name}" \
        --argjson code "${icmp_code}" \
        --argjson type "${icmp_type}" \
        '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name, code: $code, type: $type}')
      REVERSE_RULE=$(jq -c -n --arg action "${action}" \
        --arg direction "${reverse_direction}" \
        --arg protocol "icmp" \
        --arg source "${destination}" \
        --arg destination "${source}" \
        --arg name "${reverse_name}" \
        --argjson code "${icmp_code}" \
        --argjson type "${icmp_type}" \
        '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name, code: $code, type: $type}')
    elif [[ -n "${icmp_type}" ]]; then
      RULE=$(jq -c -n --arg action "${action}" \
        --arg direction "${direction}" \
        --arg protocol "icmp" \
        --arg source "${source}" \
        --arg destination "${destination}" \
        --arg name "${name}" \
        --argjson type "${icmp_type}" \
        '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name, type: $type}')
      REVERSE_RULE=$(jq -c -n --arg action "${action}" \
        --arg direction "${reverse_direction}" \
        --arg protocol "icmp" \
        --arg source "${destination}" \
        --arg destination "${source}" \
        --arg name "${reverse_name}" \
        --argjson type "${icmp_type}" \
        '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name, type: $type}')
    else
      RULE=$(jq -c -n --arg action "${action}" \
        --arg direction "${direction}" \
        --arg protocol "icmp" \
        --arg source "${source}" \
        --arg destination "${destination}" \
        --arg name "${name}" \
        '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name}')
      REVERSE_RULE=$(jq -c -n --arg action "${action}" \
        --arg direction "${reverse_direction}" \
        --arg protocol "icmp" \
        --arg source "${destination}" \
        --arg destination "${source}" \
        --arg name "${reverse_name}" \
        '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name}')
    fi
  else
    RULE=$(jq -c -n --arg action "${action}" \
      --arg direction "${direction}" \
      --arg protocol "all" \
      --arg source "${source}" \
      --arg destination "${destination}" \
      --arg name "${name}" \
      '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name}')
    REVERSE_RULE=$(jq -c -n --arg action "${action}" \
      --arg direction "${reverse_direction}" \
      --arg protocol "all" \
      --arg source "${destination}" \
      --arg destination "${source}" \
      --arg name "${reverse_name}" \
      '{action: $action, direction: $direction, protocol: $protocol, source: $source, destination: $destination, name: $name}')
  fi

  echo "Creating rule: ${RULE}"

  RESULT=$(curl -s -H "Authorization: Bearer ${TOKEN}" \
    -X POST \
    "https://${REGION}.iaas.cloud.ibm.com/v1/network_acls/${NETWORK_ACL}/rules?version=${VERSION}&generation=2" \
    -d "${RULE}")

  REVERSE_RESULT=$(curl -s -H "Authorization: Bearer ${TOKEN}" \
    -X POST \
    "https://${REGION}.iaas.cloud.ibm.com/v1/network_acls/${NETWORK_ACL}/rules?version=${VERSION}&generation=2" \
    -d "${REVERSE_RULE}")

  ID=$(echo "${RESULT}" | jq -r '.id // empty')

  if [[ -z "${ID}" ]]; then
    echo "Error creating rule: ${rule}"
    echo "${RESULT}"
    exit 1
  fi
done
