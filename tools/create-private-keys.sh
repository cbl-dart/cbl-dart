#!/usr/bin/env bash

DART_FILE="packages/cbl_e2e_tests/lib/src/replication/private_keys.dart"
TMP_DIR="$(mktemp -d)"
PASSWORD="test"
CYPHER="aes256"

# Create key as PEM without password
openssl genrsa -out $TMP_DIR/private.pem 2048

# Create DER version of the same key
openssl rsa -in $TMP_DIR/private.pem -outform DER -out $TMP_DIR/private.der

# Encrypt the PEM key with a password
openssl rsa -traditional -in $TMP_DIR/private.pem -out $TMP_DIR/private_encrypted.pem "-${CYPHER}" -passout pass:$PASSWORD

# Encrypt the DER key with a password
openssl rsa -traditional -in $TMP_DIR/private.pem -outform DER -out $TMP_DIR/private_encrypted.der "-${CYPHER}" -passout pass:$PASSWORD

# Generate Dart file with the keys
mkdir -p "$(dirname "$DART_FILE")"

{
  echo "import 'dart:convert';"
  echo
  echo "import 'package:cbl/cbl.dart';"
  echo
  echo "const privateKeyPassword = '$PASSWORD';"
  echo
  echo "const privateKeyPem = PemData('''"
  cat $TMP_DIR/private.pem
  echo "''');"
  echo
  echo "final privateKeyDer = DerData(base64.decode('$(base64 -i $TMP_DIR/private.der)'));"
  echo
  echo "const privateKeyEncryptedPem = PemData('''"
  cat $TMP_DIR/private_encrypted.pem
  echo "''');"
  echo
  echo "final privateKeyEncryptedDer = DerData(base64.decode('$(base64 -i $TMP_DIR/private_encrypted.der)'));"
} >"$DART_FILE"

echo "Generated $DART_FILE"

rm -rf "$TMP_DIR"