#!/usr/bin/env bash

set -euo pipefail

CONF_URL="https://bootstrap.llaun.ch/legacy/bootstrap.json"
MANIFEST_TEMPLATE="manifest.yaml.in"
MANIFEST_OUTPUT="manifest.yaml"

for cmd in jq wget sha256sum sed curl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: Required command '$cmd' is not installed." >&2
    exit 1
  fi
done

if [[ ! -f "$MANIFEST_TEMPLATE" ]]; then
  echo "Error: Template file '$MANIFEST_TEMPLATE' not found." >&2
  exit 1
fi

echo "Fetching TL team configuration..."
CONFIG_DATA=$(curl -sSL "$CONF_URL")

URL=$(echo "$CONFIG_DATA" | jq -r '.bootstrap_java.url[0]')
VER=$(echo "$CONFIG_DATA" | jq -r '.bootstrap_java.version | split("+")[0]')


echo "Version: $VER"

# Check if the manifest file needs to be regenerated
NEED_MANIFEST_GEN=true
if [[ -f "$MANIFEST_OUTPUT" ]]; then
  EXISTING_URL=$(grep -A 5 "x86_64:" "$MANIFEST_OUTPUT" | grep "url:" | sed -E 's/.*url:[[:space:]]*"([^"]*)".*/\1/')

  if [[ "$EXISTING_URL" == "$URL" ]]; then
    echo "Manifest $MANIFEST_OUTPUT is already up to date."
    NEED_MANIFEST_GEN=false
  fi
fi

# Generate the manifest file if needed
if [[ "$NEED_MANIFEST_GEN" == true ]]; then
  echo "Generating new $MANIFEST_OUTPUT..."
  rm -f "$MANIFEST_OUTPUT"

  # Process AMD64 package
  BOOTSTRAP="tmp_bootstrap.jar"
  for host in llaun.ch eu1.llaun.ch lln4.ru ru1.lln4.ru; do
	    if wget --timeout=15 --tries=2 "https://$host/jar" -O "$BOOTSTRAP"; then
	        BOOTSTRAP_SUCCESS=true
	        break
	    fi
	done
  SHA256=$(sha256sum "$BOOTSTRAP" | awk '{print $1}')
  SIZE=$(stat -c%s "$BOOTSTRAP")
  rm -f "$BOOTSTRAP"


  # Generate the manifest file by replacing placeholders in the template
  sed \
    -e "s|@TL_VERSION_AMD64@|${VER}|g" \
    -e "s|@TL_URL_AMD64@|${URL}|g" \
    -e "s|@TL_SHA256_AMD64@|${SHA256}|g" \
    -e "s|\"@TL_SIZE_AMD64@\"|${SIZE}|g" \
    "$MANIFEST_TEMPLATE" > "$MANIFEST_OUTPUT"

  echo "Successfully generated $MANIFEST_OUTPUT!"
fi