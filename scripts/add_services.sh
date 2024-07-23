#!/usr/bin/env bash
# shellcheck disable=SC2034

crowdswapd_binary="crowdswapd"
CHAIN_ID="crowdswap-1"
# Store the original user's username
ORIGINAL_USER=${USER}

check_binary_installed() {
  if ! which "$crowdswapd_binary" > /dev/null 2>&1; then
      die "Error: $crowdswapd_binary is not installed. Please install it and try again."
  fi
}

check_tofnd_installed() {
  if ! which tofnd > /dev/null 2>&1; then
      die "Error: tofnd is not installed. Please install it and try again."
  fi
}

check_binary_installed
check_tofnd_installed

if ! env | grep -q '^KEYRING_PASSWORD='; then
  die "Error: KEYRING_PASSWORD not found as environment variable."
fi

if ! env | grep -q '^TOFND_PASSWORD='; then
  die "Error: TOFND_PASSWORD not found as environment variable."
fi

if ! env | grep -q '^VALIDATOR_OPERATOR_ADDRESS='; then
  die "Error: VALIDATOR_OPERATOR_ADDRESS not found as environment variable."
fi


ask_for_sudo

sudo tee <<EOF >/dev/null /etc/systemd/system/crowdswapd.service
[Unit]
Description=CrowdSwap Cosmos daemon
After=network-online.target

[Service]
User=$ORIGINAL_USER
ExecStart=/usr/local/bin/${crowdswapd_binary} start
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

cat /etc/systemd/system/crowdswapd.service
sudo systemctl enable crowdswapd


sudo tee <<EOF >/dev/null /etc/systemd/system/tofnd.service
[Unit]
Description=Tofnd daemon
After=network-online.target

[Service]
User=$ORIGINAL_USER
Environment="TOFND_PASSWORD=$TOFND_PASSWORD"
ExecStart=/usr/bin/sh -c 'echo \$TOFND_PASSWORD | tofnd -m existing -d $HOME/.tofnd'
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

cat /etc/systemd/system/tofnd.service
sudo systemctl enable tofnd


sudo tee <<EOF >/dev/null /etc/systemd/system/vald.service
[Unit]
Description=Vald daemon
After=network-online.target tofnd.service
[Service]
User=$ORIGINAL_USER
Environment="KEYRING_PASSWORD=$KEYRING_PASSWORD"
Environment="CHAIN_ID=$CHAIN_ID"
Environment="VALIDATOR_OPERATOR_ADDRESS=$VALIDATOR_OPERATOR_ADDRESS"
ExecStart=/usr/bin/sh -c 'echo \$KEYRING_PASSWORD | /usr/local/bin/${crowdswapd_binary} vald-start --validator-addr \$VALIDATOR_OPERATOR_ADDRESS --log_level debug --chain-id \$CHAIN_ID --from broadcaster'
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

cat /etc/systemd/system/vald.service
sudo systemctl enable vald
sudo systemctl daemon-reload