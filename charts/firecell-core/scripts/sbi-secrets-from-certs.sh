#!/usr/bin/env bash
# sbi-secrets-from-certs.sh: create the Secrets that global.sbi.tls (source: secrets) and
# global.sbi.oauth2 expect, from the files scripts/gen-sbi-certs.sh wrote.
#
#   scripts/gen-sbi-certs.sh -o ./sbi-certs -p oai- -a rx-n5-iwf=ims-rx-n5-iwf -d firecell-core.svc.cluster.local
#   (-p / -a: the Service names the NFs dial, oai-<nf> and ims-rx-n5-iwf, go into the SANs)
#   scripts/sbi-secrets-from-certs.sh -d ./sbi-certs -n firecell-core
#   helm upgrade --install ... --set global.sbi.tls.enabled=true --set global.sbi.oauth2.enabled=true
#
# Makes, in the namespace:
#   <prefix>-<nf>            keys tls.crt, tls.key, ca.crt   (one per NF found in the directory)
#   nrf-oauth2-signing-key   key signing-key.pem             (the NRF only)
#   nrf-oauth2-public-key    key public-key.pem              (mounted in every NF)
# The names are the chart defaults (global.sbi.tls.secretPrefix, global.sbi.oauth2.*Secret).
# Set KUBECTL=echo to print the commands instead of running them.
set -euo pipefail

DIR=./sbi-certs
NS=firecell-core
PREFIX=sbi-tls
SIGNING_SECRET=nrf-oauth2-signing-key
PUBLIC_SECRET=nrf-oauth2-public-key
KUBECTL=${KUBECTL:-kubectl}

usage() {
  cat <<USAGE
Usage: $0 [-d DIR] [-n NAMESPACE] [-p SECRET_PREFIX]
  -d  directory written by gen-sbi-certs.sh (default ./sbi-certs)
  -n  namespace (default firecell-core)
  -p  TLS Secret prefix (default sbi-tls)
USAGE
}

while getopts "d:n:p:h" opt; do
  case "$opt" in
    d) DIR=$OPTARG ;;
    n) NS=$OPTARG ;;
    p) PREFIX=$OPTARG ;;
    h) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done

[[ -f $DIR/ca.crt ]] || { echo "$DIR/ca.crt not found: run gen-sbi-certs.sh first" >&2; exit 1; }

apply() { # a Secret from --from-file arguments
  local name=$1; shift
  if [[ $KUBECTL == kubectl ]]; then
    kubectl -n "$NS" create secret generic "$name" "$@" --dry-run=client -o yaml | kubectl apply -f -
  else
    $KUBECTL -n "$NS" create secret generic "$name" "$@"
  fi
}

n=0
for crt in "$DIR"/*.crt; do
  nf=$(basename "$crt" .crt)
  [[ $nf == ca ]] && continue
  [[ -f $DIR/$nf.key ]] || { echo "$DIR/$nf.key missing" >&2; exit 1; }
  apply "$PREFIX-$nf" --from-file=tls.crt="$crt" --from-file=tls.key="$DIR/$nf.key" --from-file=ca.crt="$DIR/ca.crt"
  n=$((n + 1))
done
echo "TLS Secrets: $n"

if [[ -f $DIR/nrf-oauth2-signing.key && -f $DIR/nrf-oauth2-signing.pub ]]; then
  apply "$SIGNING_SECRET" --from-file=signing-key.pem="$DIR/nrf-oauth2-signing.key"
  apply "$PUBLIC_SECRET" --from-file=public-key.pem="$DIR/nrf-oauth2-signing.pub"
  echo "OAuth2 Secrets: $SIGNING_SECRET, $PUBLIC_SECRET"
fi
