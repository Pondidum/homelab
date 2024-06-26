#!/bin/sh

set -eu

password=$(op item get Honeycomb.io --fields piirakka-apikey)

nomad var put -force "nomad/jobs/otel-collector" \
  "honeycomb_apikey=${password}"