#!/bin/bash

set -ue

e=""
readonly CURRENT_DIR_PATH=$(dirname "$0")
readonly HTTPSHD_DIR_PATH=$(cd "${CURRENT_DIR_PATH}"; cd ../; pwd)
cd "${HTTPSHD_DIR_PATH}"
echo pwd; pwd
echo "${HTTPSHD_DIR_PATH}/main.go"

readonly remove_past_binary=$(\
  find \
    -mindepth 1 \
    -maxdepth 1 \
    -type f \
    | grep "/httpshd-"\
    | awk '{
      if(!$0) next
      print "rm \x22"$0"\x22"
    }'
)
echo "${remove_past_binary}"
case "${remove_past_binary}" in
  "") ;;
  *) bash -c "${remove_past_binary}" ;;
esac

readonly VERSION="0.0.1"

readonly binary_name_amd64="httpshd-${VERSION}-amd64"
go build -o \
  "${binary_name_amd64}" \
  main.go | pv
chmod +x "${binary_name_amd64}"

binary_name_arm64="httpshd-${VERSION}-arm64"
GOOS=linux \
GOARCH=arm64 \
CGO_ENABLED=1 \
CC=aarch64-linux-gnu-gcc \
	go build -o \
	  "${binary_name_arm64}" \
	  main.go | pv
chmod +x "${binary_name_arm64}"

gh release delete -y "${VERSION}" \
  || e=$?
sleep 1
gh release create "${VERSION}" \
  --title "httpshd-${VERSION}" \
  --latest \
  --notes "update release" \
  "${binary_name_arm64}" \
  "${binary_name_amd64}"