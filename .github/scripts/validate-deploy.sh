#!/usr/bin/env bash


if [[ -f acl_rules.semaphore ]]; then
  echo "Semaphore file not cleaned up"
  exit 1
fi
