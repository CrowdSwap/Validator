#!/usr/bin/env bash
# shellcheck disable=SC2034

set -Eeuo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# shellcheck disable=SC1091
. "${script_dir}/utils.sh"

crowdswapd_binary="crowdswapd"

setPath(){
    current_link=$(which $crowdswapd_binary)
    resolved_file=$(resolve_link "$current_link")
    directory_path=$(dirname "$resolved_file")
}

resolve_link() {    
    local file="$1"
    while [ -L "$file" ]; do        
        file=$(readlink "$file")     
    done
    echo "$file"                     
}
 

download_latest(){
    crowdswap_version=$(curl -s "https://api.github.com/repos/CrowdSwap/Validator/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
    crowdswapd_binary_path=$directory_path/$crowdswapd_binary-$crowdswap_version
    crowdswapd_binary_symlink=$directory_path/$crowdswapd_binary

     msg "\ndownloading required dependencies"
    
    # Define the artifact name to download
    crowdswapd_artifact="crowdswap_linux_amd64.tar.gz"
    msg "downloading $crowdswapd_binary binary $crowdswap_version"
    local crowdswapd_binary_url
    crowdswapd_binary_url="https://github.com/CrowdSwap/Validator/releases/download/${crowdswap_version}/${crowdswapd_artifact}"
    curl -sL --fail "${crowdswapd_binary_url}" -o "${crowdswapd_artifact}" 
    tar -xzvf "${crowdswapd_artifact}" -C "."
    mv "${crowdswapd_binary}" "${crowdswapd_binary_path}"
    chmod +x "${crowdswapd_binary_path}"
    rm -f "${crowdswapd_artifact}"

    msg "symlinking crowdswapd binary"
    rm -f "${crowdswapd_binary_symlink}"
    ln -s "${crowdswapd_binary_path}" "${crowdswapd_binary_symlink}"
}

check_binary_installed() {
  if ! which "$crowdswapd_binary" > /dev/null 2>&1; then
      die "Error: $crowdswapd_binary is not installed. Please install it and try again."
  fi
}

stop_service(){
    sudo systemctl stop vald
    sudo systemctl stop crowdswapd
}
start_service(){
    sudo systemctl start crowdswapd
    sudo systemctl start vald
}

setup_colors
check_sudo_group
ask_for_sudo

stop_service
check_binary_installed
setPath
download_latest
start_service