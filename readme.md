# CrowdSwap Validator Setup Instructions


## General Information

Run all scripts as a non-root user who has sudo permissions. None of the scripts should be triggered with sudo directly. The scripts will prompt for your password if necessary. 


To ensure proper functionality, it is essential that port `26656` on your machine is accessible from external networks. If you are utilizing a firewall, please take the necessary steps to unblock this port.

## Step 1: Clone the Repository

First, clone the this repository:

```sh
git clone https://github.com/CrowdSwap/Validator.git
cd Validator/scripts
```

If the files inside scripts directory are not executable, you can make them executable with:

```bash
chmod +x *.sh

```

## Step 2: Download and Install Binaries

To download and install the necessary binaries and configure basic settings, please run `install.sh` first, Ensure that `git` and `tar` are installed on your system before proceeding.

```bash
./install.sh
```

## Step 3: Generate Keys
After completing the first step, generate the keys using the commands below.

⚠️ **Warning:**  Keep your KEYRING_PASSWORD in a safe place along with each account mnemonic.

```bash
crowdswapd keys add broadcaster
crowdswapd keys add validator
tofnd -m create

```

```bash
cat $HOME/.tofnd/export
```
Keep this mnemonic in a safe place 

```bash
rm $HOME/.tofnd/export

```

## Step 4: Set Environment Variables

Run the script below and fill in the fields based on your own information:

```bash
echo export MONIKER=PUT_YOUR_MONIKER_HERE >> $HOME/.profile
echo export VALIDATOR_OPERATOR_ADDRESS=$(crowdswapd keys show validator --bech val | grep address | awk {'print $3'}) >> $HOME/.profile
echo export BROADCASTER_ADDRESS=$(crowdswapd keys show broadcaster | grep address | awk {'print $3'}) >> $HOME/.profile

# It's recommended to manually edit the file and add your keyring password
echo export KEYRING_PASSWORD=PUT_YOUR_KEYRING_PASSWORD_HERE >> $HOME/.profile
echo export TOFND_PASSWORD=PUT_YOUR_TOFND_PASSWORD_HERE >> $HOME/.profile

source $HOME/.profile

```


## Step 5: Add systemd Services by Script
Run the `add_services.sh` script without sudo:

```bash
./add_services.sh

```

## Step 6: Fill RPC URLS

```bash
nano ~/.crowdswap/config/config.toml
```
scroll down and fill the urls. For example:

```bash
[[native_bridge_evm]]
name = "137"
rpc_addr = "https://polygon-rpc.com/"
start-with-bridge = true
finality_override = "confirmation"


[[native_bridge_evm]]
name = "1130"
rpc_addr = "https://dmc.mydefichain.com/mainnet"
start-with-bridge = true
finality_override = "confirmation"
```

## Step 7: Start Your Services
Finally, start your services with the following commands:

```bash
sudo systemctl restart crowdswapd
sudo systemctl restart tofnd
sudo systemctl restart vald
```
Check your node with this code:

```bash
sudo journalctl -u crowdswapd -f
```

## Step 8: Contact us to verify the process
During this step, please provide detailed information about your setup process. Upon review, we will send you the requirements for staking and registering your validator.
Please provide us your `BROADCASTER_ADDRESS` and `VALIDATOR_OPERATOR_ADDRESS` which exist at the end of `$HOME/.profile` file as result of `Step 4`.
Email: support@crowdswap.org

## Step 9: Add validator

Finally to register your validator run following script:

```bash
./add_validator.sh
```
```bash
crowdswapd tx validator register-validator "$BROADCASTER_ADDRESS" --from validator --chain-id crowdswap-1 --fees 2crowdhub
```
```bash
crowdswapd tx network register-chain-maintainer "137","1130" --from broadcaster --chain-id crowdswap-1 --fees 2crowdhub
```

### Summary of Instructions

1. **General Information**:
    - Use a non-root user with sudo permissions.
    - Avoid running scripts with sudo directly.

2. **Install Binaries**:
    - Run `install.sh` to install binaries and configure basic settings.

3. **Generate Keys**:
    - Use `crowdswapd` and `tofnd` commands to generate keys.
    - Store `KEYRING_PASSWORD` and account mnemonics securely.
    - Store `TOFND_PASSWORD` and account mnemonics securely.

4. **Set Environment Variables**:
    - Use provided script to set and export environment variables.
    - Manually add `KEYRING_PASSWORD` to `.profile`.
    - Reload environment variables with `source $HOME/.profile`.

5. **Add Systemd Services**:
    - Run `add_services.sh` without sudo.

6. **Start Services**:
    - Use `sudo systemctl restart` to start services.

