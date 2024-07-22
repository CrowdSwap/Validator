# CrowdSwap Validator Setup Instructions


## General Information

Run all scripts as a non-root user who has sudo permissions. None of the scripts should be triggered with sudo directly. The `add_services.sh` script will prompt for your password if necessary.

## Step 1: Clone the Repository

First, clone the this repository:

```sh
git clone https://github.com/CrowdSwap/Validator
cd Validator/scripts
```

If the files inside scripts directory are not executable, you can make them executable with:

```bash
chmod +x install.sh add_services.sh add_validator.sh

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

## Step 4: Set Environment Variables

Run the script below and fill in the fields based on your own information:

```bash
echo export MONIKER=PUT_YOUR_MONIKER_HERE >> $HOME/.profile
echo export VALIDATOR_OPERATOR_ADDRESS=$(crowdswapd keys show validator --bech val | grep address | awk {'print $3'}) >> $HOME/.profile
echo export BROADCASTER_ADDRESS=$(crowdswapd keys show broadcaster | grep address | awk {'print $3'}) >> $HOME/.profile

# It's recommended to manually edit the file and add your keyring password
echo export KEYRING_PASSWORD=PUT_YOUR_KEYRING_PASSWORD_HERE >> $HOME/.profile

source $HOME/.profile

```


## Step 5: Add systemd Services by Script
Run the `add_services.sh` script without sudo:

```bash
./add_services.sh

```

## Step 6: Start Your Services
Finally, start your services with the following commands:

```bash
sudo systemctl restart crowdswapd
sudo systemctl restart tofnd
sudo systemctl restart vald
```

## Step 7: Contact us to verify the process
During this step, please provide detailed information about your setup process. Upon review, we will send you the requirements for staking and registering your validator.

Email: support@crowdswap.org

## Step 8: Add validator

Finally to register your validator run following script:

```bash
./add_validator.sh

```

### Summary of Instructions

1. **General Information**:
    - Use a non-root user with sudo permissions.
    - Avoid running scripts with sudo directly.
    - `add_services.sh` will prompt for your password if needed.

2. **Install Binaries**:
    - Run `install.sh` to install binaries and configure basic settings.

3. **Generate Keys**:
    - Use `crowdswapd` and `tofnd` commands to generate keys.
    - Store `KEYRING_PASSWORD` and account mnemonics securely.

4. **Set Environment Variables**:
    - Use provided script to set and export environment variables.
    - Manually add `KEYRING_PASSWORD` to `.profile`.
    - Reload environment variables with `source $HOME/.profile`.

5. **Add Systemd Services**:
    - Run `add_services.sh` without sudo.

6. **Start Services**:
    - Use `sudo systemctl restart` to start services.

