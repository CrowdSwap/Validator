#!/usr/bin/env bash
# shellcheck disable=SC2034

set -Eeuo pipefail
trap failure SIGINT SIGTERM ERR
trap cleanup EXIT

cleanup() {
    trap - EXIT
    msg
    msg "script cleanup running"
    # script cleanup here
}

failure() {
    trap - SIGINT SIGTERM ERR

    msg "FAILED to run the last command"
    cleanup

    exit 1
}

setup_colors() {
    if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
        NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
    else
        NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
    fi
}

msg() {
    echo >&2 -e "${1-}"
}

die() {
    local msg=$1
    local code=${2-1} # default exit status 1
    msg "FAILED: $msg"
    exit "$code"
}

verify() {
    msg "Please VERIFY that the above parameters are correct.  Continue? [y/n]"
    read -r value
    if [[ "$value" != "y" ]]; then
        msg "You did not type 'y'. Exiting..."
        exit 1
    fi
    msg "\n"
}

copy_configuration_files() {
    if [ ! -f "${config_directory}/genesis.json" ]; then
        msg "Copying genesis file to the config directory"
        cp "${resources}/genesis.json" "${config_directory}/genesis.json"
    else
        msg "genesis file already exists"
    fi

    if [ ! -f "${config_directory}/seeds.toml" ]; then
        msg "Copying seeds.toml to the config directory"
        cp "${resources}/seeds.toml" "${config_directory}/seeds.toml"
    else
        msg "seeds.toml file already exists"
    fi


    if [ ! -f "${config_directory}/config.toml" ]; then
        msg "Importing seeds from seeds.toml into config.toml, copying config.toml to the config directory"
        cp "${git_root}/configuration/config.toml" "${config_directory}/config.toml"
        # We build the line in the expected format,a comma separated list of seed nodes
        SEEDS=$(grep address "${config_directory}/seeds.toml" | awk '{print $3}' | tr -d '\n' | sed 's/""/,/g' | sed 's/^/seeds = /')
        # We inject it in config.toml 
        sed -i.bak "s/seeds = \"\"/$SEEDS/" "${config_directory}/config.toml"
        # We remove the config.toml.bak (created because on Mac you have to create backup file with sed)
        rm "${config_directory}/config.toml.bak"

        sed -i.bak 's/external_address = \"\"/external_address = \"'"$(curl -4 -s https://ipinfo.io/ip)"':26656\"/g' "${config_directory}/config.toml"
        rm "${config_directory}/config.toml.bak"

    else
        msg "config.toml file already exists"
    fi

    if [ ! -f "${config_directory}/app.toml" ]; then
        msg "Copying app.toml to the config directory"
        cp "${git_root}/configuration/app.toml" "${config_directory}/app.toml"
    else
        msg "app.toml file already exists"
    fi

    policy=$(cat "${config_directory}/app.toml" | grep 'pruning = ')
    msg "Pruning policy is set to"
    msg "${policy}"
    if [ "$policy" = 'pruning = "everything"' ]; then
        msg "NOTE: If you're running an RPC node, then you may want to set it to 'default'"
    fi
}

ask_for_sudo() {
    if ! groups "$USER" | grep -q '\bsudo\b'; then
        die "Error: User $USER is not a member of the sudo group. Please add the user to the sudo group and try again."
    fi

    echo "Enter $USER password if requested"
    sudo echo "======================================="
    sudo echo -e "${GREEN}Running in sudo mode${NOFORMAT}"
}

check_sudo_group() {    
    if ! groups $USER | grep &>/dev/null "\bsudo\b"; then
        die "User $USER must be a member of sudo group."
    fi
}

check_dependency() {
    local dependencies=("tar" "git" "curl")
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: $cmd is not installed. Please install $cmd and try again."
            exit 1
        fi
    done
}

generate_password() {
    local password_length=16
    local password=""
    local chars="a-zA-Z0-9!@#^+*_-"
    local first_char=""

    # Ensure password meets complexity requirements
    while [[ ! ($password =~ [a-z] && $password =~ [A-Z] && $password =~ [0-9] && $password =~ [!@#^+*_-]) ]]; do
        password=$(</dev/urandom tr -dc 'a-zA-Z0-9!@#^+*_-' | head -c $((password_length - 1)))
    done

    # Add a lowercase character to the beginning
    first_char=$(</dev/urandom tr -dc 'a-z' | head -c 1)
    password="${first_char}${password}"

    echo "$password"
}