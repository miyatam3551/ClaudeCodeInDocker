#!/bin/bash
docker scout cves claudecode-docker --exit-code --only-severity critical,high
if [ $? -ne 0 ]; then
  echo "Critical or High severity vulnerabilities detected. Aborting push."
  exit 1
fi
