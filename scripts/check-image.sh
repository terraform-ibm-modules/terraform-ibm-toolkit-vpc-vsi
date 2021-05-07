#!/usr/bin/env bash

STATUS="$1"
NAME="$2"

RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

if [[ "${STATUS}" == "deprecated" ]]; then
  echo -e "${YELLOW}Warning:${NC} ${NAME} image is deprecated"
fi
