#!/usr/bin/env bash
# gen-sbi-certs.sh: test PKI for the SBI TLS and OAuth2 of feature 05
# (rc-02 wave, Lane 3, decision L3-D12/D13: openssl script for compose and
# the lab; cert-manager does this on Helm).
#
# Makes, in OUT_DIR:
#   ca.crt, ca.key                 internal CA (EC P-256)
#   <nf>.crt, <nf>.key             one certificate per NF, signed by the CA,
#                                  serverAuth + clientAuth (the NF is server
#                                  and client on the SBI, mTLS)
#   nrf-oauth2-signing.key         NRF access token signing key (ES256, EC
#                                  P-256), for nrf.oauth2_signing_key_path
#   nrf-oauth2-signing.pub         its public key, for oauth2.nrf_public_key_path
#                                  in every NF
#
# The NF config keys: tls.cert_certificate_path = <nf>.crt,
# tls.cert_key_path = <nf>.key, tls.ca_path = ca.crt (cs L3-05-1).
#
# SANs per NF: DNS:<nf>, DNS:<nf>.<domain> (when -d is given), and each -i
# address. Run it again with -f to replace existing files.
#
# Not for production: the CA key sits beside the certificates.
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 [-o OUT_DIR] [-n "amf smf ..."] [-d DOMAIN] [-i IP]... [-t DAYS] [-f]
  -o  output directory (default ./sbi-certs)
  -n  NF names (default: amf smf upf ausf udm udr pcf nrf nssf nef eir udsf)
  -d  DNS suffix added as a second SAN, e.g. firecell-core.svc.cluster.local
  -i  IP address SAN added to every NF certificate (repeatable)
  -t  validity in days (default 365)
  -f  overwrite existing files
EOF
}

OUT_DIR=./sbi-certs
NFS="amf smf upf ausf udm udr pcf nrf nssf nef eir udsf"
DOMAIN=""
IPS=()
DAYS=365
FORCE=0
while getopts "o:n:d:i:t:fh" opt; do
  case "$opt" in
    o) OUT_DIR=$OPTARG ;;
    n) NFS=$OPTARG ;;
    d) DOMAIN=$OPTARG ;;
    i) IPS+=("$OPTARG") ;;
    t) DAYS=$OPTARG ;;
    f) FORCE=1 ;;
    h) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done

command -v openssl >/dev/null || { echo "openssl not found" >&2; exit 1; }
[[ $DAYS =~ ^[0-9]+$ ]] || { echo "-t: days must be a number" >&2; exit 2; }
for n in $NFS; do
  [[ $n =~ ^[a-z0-9-]+$ ]] || { echo "bad NF name: $n" >&2; exit 2; }
done

mkdir -p "$OUT_DIR"
umask 077

if [[ -e $OUT_DIR/ca.key && $FORCE -eq 0 ]]; then
  echo "$OUT_DIR/ca.key exists; use -f to replace the PKI" >&2
  exit 1
fi

# Internal CA
openssl ecparam -name prime256v1 -genkey -noout -out "$OUT_DIR/ca.key"
openssl req -x509 -new -key "$OUT_DIR/ca.key" -sha256 -days "$DAYS" \
  -subj "/O=Firecell 5GC test/CN=sbi-ca" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,keyCertSign,cRLSign" \
  -out "$OUT_DIR/ca.crt"

# One certificate per NF
for nf in $NFS; do
  san="DNS:$nf"
  [[ -n $DOMAIN ]] && san="$san,DNS:$nf.$DOMAIN"
  for ip in "${IPS[@]}"; do san="$san,IP:$ip"; done
  ext=$(mktemp)
  cat >"$ext" <<EOF
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyAgreement
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=$san
EOF
  openssl ecparam -name prime256v1 -genkey -noout -out "$OUT_DIR/$nf.key"
  openssl req -new -key "$OUT_DIR/$nf.key" -subj "/O=Firecell 5GC test/CN=$nf" \
    -out "$OUT_DIR/$nf.csr"
  openssl x509 -req -in "$OUT_DIR/$nf.csr" -CA "$OUT_DIR/ca.crt" \
    -CAkey "$OUT_DIR/ca.key" -CAcreateserial -sha256 -days "$DAYS" \
    -extfile "$ext" -out "$OUT_DIR/$nf.crt" 2>/dev/null
  rm -f "$ext" "$OUT_DIR/$nf.csr"
  openssl verify -CAfile "$OUT_DIR/ca.crt" "$OUT_DIR/$nf.crt" >/dev/null
  echo "$nf: $san"
done
rm -f "$OUT_DIR/ca.srl"

# NRF OAuth2 signing key (ES256, L3-05-10) and the public key for the NFs
# (cs access_token_validator, L3-05-7). PKCS#8 PEM; the NRF loader takes it.
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 \
  -out "$OUT_DIR/nrf-oauth2-signing.key"
openssl pkey -in "$OUT_DIR/nrf-oauth2-signing.key" -pubout \
  -out "$OUT_DIR/nrf-oauth2-signing.pub"

# Certificates and public keys are readable; private keys stay 0600
chmod 0644 "$OUT_DIR"/*.crt "$OUT_DIR/nrf-oauth2-signing.pub"
echo "Written to $OUT_DIR"
