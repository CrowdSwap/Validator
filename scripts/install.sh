#!/usr/bin/env bash
# shellcheck disable=SC2034

set -Eeuo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# shellcheck disable=SC1091
. "${script_dir}/utils.sh"

usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-r] arg1 [arg2...]

Set up configs and download binaries for vald and tofnd.

Available options:

-h, --help                    Print this help and exit
-v, --verbose                 Print script debug info
-d, --root-directory          Directory for data. [default: $HOME/.crowdswap]
-e, --environment             Environment to run in [host only]
EOF
    exit
}

parse_params() {
    # default values of variables set from params
    crowdswap_version=""
    tofnd_version=""
    chain_id="crowdswap-1"
    root_directory="$HOME/.crowdswap"
    git_root="$(git rev-parse --show-toplevel)"
    environment='host'
    skip_download=false

    while :; do
        case "${1-}" in
        -h | --help) usage ;;
        -v | --verbose) set -x ;;
        --no-color) NO_COLOR=1 ;;
        -c | --crowdswap-version)
            crowdswap_version="${2-}"
            shift
            ;;
        -t | -q | --tofnd-version)
            tofnd_version="${2-}"
            shift
            ;;
        -d | --root-directory)
            root_directory="${2-}"
            shift
            ;;
        -?*) die "Unknown option: $1" ;;
        *) break ;;
        esac
        shift
    done

    args=("$@")

    if [ -z "${crowdswap_version}" ]; then
        # Fetch the latest release tag
        crowdswap_version=$(curl -s "https://api.github.com/repos/CrowdSwap/Validator/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
    fi

    if [ -z "${tofnd_version}" ]; then
        tofnd_version=$(curl -s "https://api.github.com/repos/CrowdSwap/Validator/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
    fi

    # check required params and arguments
    [[ -z "${root_directory-}" ]] && die "Missing required parameter: root-directory"
    
    vald_directory="${root_directory}/vald"
    tofnd_directory="${root_directory}/tofnd"
    bin_directory="$root_directory/bin"
    logs_directory="$root_directory/logs"
    config_directory="$root_directory/config"
    resources="${git_root}/configuration"
    crowdswapd_binary="crowdswapd"
    crowdswapd_binary_signature_path="$bin_directory/crowdswapd-${crowdswap_version}.asc"
    crowdswapd_binary_path="$bin_directory/crowdswapd-${crowdswap_version}"
    crowdswapd_binary_symlink="$bin_directory/crowdswapd"
    tofnd_binary_path="$bin_directory/tofnd-${tofnd_version}"
    tofnd_binary_signature_path="$bin_directory/tofnd-${tofnd_version}.asc"
    tofnd_binary_symlink="$bin_directory/tofnd"
    os="$(uname | awk '{print tolower($0)}')"
    arch="$(uname -m)"

    if [[ "${arch}" != "x86_64" ]]; then
        die "crowdswapd is only available for amd64 arch."
    fi

    return 0
}

print_crowdhub() {
    msg "
  ${GREEN}
  ██████  ██████   ██████  ██     ██ ██████  ██   ██ ██    ██ ██████   
  ██  ██  ██   ██ ██    ██ ██     ██ ██   ██ ██   ██ ██    ██ ██   ██  
  ██      ██████  ██    ██ ██  █  ██ ██   ██ ███████ ██    ██ ██████   
  ██  ██  ██   ██ ██    ██ ██ ███ ██ ██   ██ ██   ██ ██    ██ ██   ██  
  ██████  ██   ██  ██████   ███ ███  ██████  ██   ██  ██████  ██████   
  ${NOFORMAT}
  "
}


create_directories() {
    msg "creating required directories"
    if [[ ! -d "$root_directory" ]]; then mkdir -p "$root_directory"; fi
    if [[ ! -d "$vald_directory" ]]; then mkdir -p "$vald_directory"; fi
    if [[ ! -d "$tofnd_directory" ]]; then mkdir -p "$tofnd_directory"; fi
    if [[ ! -d "$config_directory" ]]; then mkdir -p "$config_directory"; fi
    if [[ ! -d "$bin_directory" ]]; then mkdir -p "$bin_directory"; fi
}

download_dependencies() {

    msg "\ndownloading required dependencies"
    
    # Define the artifact name to download
    crowdswapd_artifact="crowdswap_linux_amd64.tar.gz"
    msg "downloading $crowdswapd_binary binary $crowdswap_version"
    if [[ ! -f "${crowdswapd_binary_path}" ]]; then
        local crowdswapd_binary_url
        crowdswapd_binary_url="https://github.com/CrowdSwap/Validator/releases/download/${crowdswap_version}/${crowdswapd_artifact}"

        curl -sL --fail "${crowdswapd_binary_url}" -o "${crowdswapd_artifact}" 

        tar -xzvf "${crowdswapd_artifact}" -C "."
        mv "${crowdswapd_binary}" "${crowdswapd_binary_path}"
        chmod +x "${crowdswapd_binary_path}"
        rm -f "${crowdswapd_artifact}"
    else
        msg "binary already downloaded"
    fi

    msg "symlinking crowdswapd binary"
    rm -f "${crowdswapd_binary_symlink}"
    ln -s "${crowdswapd_binary_path}" "${crowdswapd_binary_symlink}"

    local tofnd_binary
    tofnd_binary="tofnd_${os}_${arch}.1"    

    msg "downloading tofnd binary $tofnd_binary"
    if [[ ! -f "${tofnd_binary_path}" ]]; then
        local tofnd_binary_url
        tofnd_binary_url="https://github.com/CrowdSwap/Validator/releases/download/${tofnd_version}/${tofnd_binary}"
        echo $tofnd_binary_url
        curl -sL --fail "${tofnd_binary_url}" -o "${tofnd_binary_path}" && chmod +x "${tofnd_binary_path}"

    else
        msg "binary already downloaded"
    fi

    msg "symlinking tofnd binary"
    rm -f "${tofnd_binary_symlink}"
    ln -s "${tofnd_binary_path}" "${tofnd_binary_symlink}"
}

addlinks() { 
    # Remove existing symlinks if they exist
    [ -L /usr/local/bin/crowdswapd ] && sudo rm /usr/local/bin/crowdswapd
    [ -L /usr/local/bin/tofnd ] && sudo rm /usr/local/bin/tofnd

    sudo ln -s $crowdswapd_binary_symlink /usr/local/bin/crowdswapd 
    sudo ln -s $tofnd_binary_symlink /usr/local/bin/tofnd
}

check_environment() {
    if [ "$(pgrep -f "${tofnd_binary_path}")" != "" ]; then
        # shellcheck disable=SC2016
        die 'tofnd already running. Run "pkill -f tofnd" to kill tofnd.'
    fi

    if [ "$(pgrep -f "${crowdswapd_binary} vald-start")" != "" ]; then
        # shellcheck disable=SC2016
        die 'vald already running. Run "pkill -f vald" to kill vald.'
    fi
}

post_run_message() {
    msg "vald/tofnd setup completed"
    msg
    msg "SUCCESS"
    msg
}

parse_params "$@"
setup_colors

check_sudo_group
check_dependency
check_environment

print_crowdhub

# Print params
msg "${RED}Read parameters:${NOFORMAT}"
msg "- root-directory: ${root_directory}"
msg "- script_dir: ${script_dir}"
msg "\n"


verify

# Create all required directories common to docker and host mode
create_directories

# Configuration files
copy_configuration_files

download_dependencies # download dependencies specific to mode

ask_for_sudo

addlinks

post_run_message # print message post run
