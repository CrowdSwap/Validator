#!/usr/bin/env bash
# shellcheck disable=SC2034

set -Eeuo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# shellcheck disable=SC1091
. "${script_dir}/utils.sh"

setup_colors

if ! env | grep -q '^KEYRING_PASSWORD='; then
  die "Error: KEYRING_PASSWORD not found as environment variable."
fi

if ! env | grep -q '^BROADCASTER_ADDRESS='; then
  die "Error: BROADCASTER_ADDRESS not found as environment variable."
fi

# Prompt the user for input
read -p "Enter the staking amount: " STAKING_AMOUNT
read -p "Enter your email address: " YOUR_EMAIL_ADDRESS
read -p "Enter your website: " YOUR_WEBSITE
read -p "Enter more details: " MORE_DETAIL

# Assign the input values to variables
AMOUNT=$STAKING_AMOUNT
EMAIL=$YOUR_EMAIL_ADDRESS
WEBSITE=$YOUR_WEBSITE
DETAILS=$MORE_DETAIL


JSON=$(cat <<EOF
{
  "AMOUNT": "$AMOUNT",
  "EMAIL": "$EMAIL",
  "WEBSITE": "$WEBSITE",
  "DETAILS": "$DETAILS"
}
EOF
)

# Output the JSON object (optional)
echo "$JSON"

verify

tee <<EOF >/dev/null $HOME/validator.json
{
  "pubkey": $(crowdswapd tendermint show-validator),
  "amount": "${AMOUNT}crowdhub",
  "moniker": "$MONIKER",
  "website": "$WEBSITE",
  "security": "$EMAIL",
  "details": "$DETAILS",
  "commission-rate": "0.1",
  "commission-max-rate": "0.2",
  "commission-max-change-rate": "0.01",
  "min-self-delegation": "1"
}
EOF

echo $KEYRING_PASSWORD | crowdswapd tx staking create-validator $HOME/validator.json --from validator --chain-id crowdswap-1 --fees 20crowdhub --yes
echo $KEYRING_PASSWORD | crowdswapd tx validator register-validator $BROADCASTER_ADDRESS --from validator --chain-id crowdswap-1 --fees 20crowdhub --yes