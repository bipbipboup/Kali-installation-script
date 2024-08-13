#!/bin/bash

# Ensure sudo access is available and refreshed
sudo -v


cleanup() {
    # Remove any temporary files here
    [ -f addon.xpi ] && rm -f addon.xpi
    [ -f latest_release.deb ] && rm -f latest_release.deb
    # Add other temporary files as needed
}

# Trap to ensure cleanup is called on exit
trap cleanup EXIT INT


# Functions for styled output
underline_echo() {
    printf "\e[4m%s\e[0m\n" "$1"  # Keep this without a newline, just underlining
}

info_echo() {
    printf "\e[32m%b\e[0m\n" "$1"  # Use %b to interpret \n, and ensure color codes are handled
}

error_echo() {
    printf "\e[31m%b\e[0m\n" "$1"  # Same for error_echo, with color red
}


# Display a dynamically generated usage/help message
usage() {
    echo "Usage: $0 [-h] [$(printf -- '--%s ' "${!option_descriptions[@]}")]"
    echo
    echo "Options:"
    echo "  -h           Display this help message"
    for key in "${!option_descriptions[@]}"; do
        printf "  --%-10s %s\n" "$key" "${option_descriptions[$key]}"
    done
    exit 1
}


# Function to install a Firefox extension
install_extension() {
    wget "$1" -O addon.xpi  # Download the extension
    firefox addon.xpi     # Install the extension in Firefox
    rm addon.xpi          # Clean up the downloaded file
}


# Function to download and install the latest .deb package from a GitHub repository
install_github_deb() {
    REPO=$1  # Define the repository in the format owner/repo

    # Fetch the latest release information from GitHub API
    latest_release=$(curl --silent "https://api.github.com/repos/$REPO/releases/latest")

    # Extract the download URL for the .deb asset
    download_url=$(echo "$latest_release" | grep -oP '"browser_download_url": "\K.*?amd64\.deb(?=")')

    if [ -z "$download_url" ]; then  # Check if a .deb file was found
        error_echo "No .deb file found in the latest release of $REPO."
        cleanup
        return 1  # Exit the function with an error code
    fi

    # Download the .deb package
    if ! curl -L -o latest_release.deb "${download_url}"; then
        error_echo "Failed to download $REPO"
        cleanup
        return 1  # Exit the function with an error code
    fi

     # Install the .deb package
    if ! sudo apt install ./latest_release.deb -y; then
        error_echo "Failed to install the .deb package for $REPO"
        cleanup
        return 1  # Exit the function with an error code
    fi

    # Clean up the downloaded .deb file
    rm -rf latest_release.deb
}


install_packages() {
    sudo apt install -y "$@"
}


# Function to download the latest linpeas.sh script
download_linpeas() {
    latest_release=$(curl --silent "https://api.github.com/repos/peass-ng/PEASS-ng/releases/latest")

    # Extract the download URL for linpeas.sh
    download_url=$(echo "$latest_release" | grep -oP '"browser_download_url": "\K.*?linpeas.sh(?=")')

    if [ -z "$download_url" ]; then  # Check if the linpeas.sh file was found
        error_echo "Could not find linpeas.sh file"
        return 1  # Exit the function with an error code
    fi

    # Download linpeas.sh to the home directory
    if ! curl -L -o ~/linpeas.sh "${download_url}"; then
        error_echo "Failed to download linpeas.sh"
        return 1  # Exit the function with an error code
    fi

    info_echo "Downloaded linpeas.sh to ~/linpeas.sh"
}


# Declare associative arrays to manage option states and descriptions
declare -A option_states=(
    ["all"]=0
    ["basic"]=0
    ["network"]=0
    ["web"]=0
    ["extension"]=0
    ["ad"]=0
    ["pwn"]=0
    ["wordlist"]=0
)

# Declare an associative array to hold the option descriptions
declare -A option_descriptions=(
    ["all"]="Enable all modes"
    ["basic"]="Install basic tools"
    ["network"]="Install network and pivoting tools"
    ["web"]="Install the web tools"
    ["extension"]="Install the firefox extensions"
    ["ad"]="Install the Active Directory tools"
    ["pwn"]="Install the pwn/reverse tools"
    ["wordlist"]="Download wordlists"  
)


# ====================
# Option Parsing
# ====================


parse_options() {
    while getopts ":h-:" opt; do
        case ${opt} in
            -)
                case "${OPTARG}" in
                    help)
                        usage  # Display the help message
                        ;;
                    all)
                        option_states["all"]=1
                        for key in "${!option_states[@]}"; do
                            option_states[$key]=1
                        done
                        ;;
                    *)
                        # Check if the option is valid in the associative array
                        if [[ -n "${option_states[${OPTARG}]}" ]]; then
                            option_states["${OPTARG}"]=1
                        else
                            echo "Unknown option --${OPTARG}" >&2
                            usage
                        fi
                        ;;
                esac
                ;;
            h)
                usage  # Display the help message
                ;;
            \?)
                echo "Invalid option: -${OPTARG}" >&2
                usage
                ;;
            :)
                echo "Option -${OPTARG} requires an argument." >&2
                usage
                ;;
        esac
    done
    shift $((OPTIND -1))
}

# Call the option parsing function
parse_options "$@"


# ====================
# Main Script Execution
# ====================


# Provide feedback to the user on the selected options
underline_echo "Selected options:"
echo  # Add an empty line for better readability

for key in "${!option_states[@]}"; do
    # Check if the option is enabled
    if [ "${option_states[$key]}" -eq 1 ]; then
        status="Enabled"
        echo "${key^} mode: $(info_echo $status)"
    else
        status="Disabled"
        echo "${key^} mode: $(error_echo $status)"
    fi
done


# ====================
# Installation Functions
# ====================


install_basic_tools() {
    info_echo "\nInstalling basic tools"
    install_packages p7zip-full python3-pip
    
    info_echo "\nInstalling VSCodium..."
    install_github_deb "VSCodium/vscodium"
    
    info_echo "\nDownloading Linpeas in home folder"
    download_linpeas
}

install_network_tools() {
    info_echo "\nInstalling Network tools"

    # Install ngrok
    if ! curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && \
       echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list && \
       sudo apt update && sudo apt install ngrok; then
        error_echo "Failed to install ngrok"
        return 1
    fi
    
    install_packages nmap proxychains4
    
    info_echo "\nCopying proxychains configuration file"
    sudo cp ~/proxychains.conf /etc/proxychains.conf
}

install_web_tools() {
    info_echo "\nInstalling Web tools"
    install_packages ffuf wfuzz gobuster hashid hash-identifier hashcat hydra
}

install_ad_tools() {
    info_echo "\nInstalling Active Directory tools"
    install_packages rdesktop impacket-scripts neo4j bloodhound evil-winrm pkexec freerdp2-x11
}

install_pwn_tools() {
    info_echo "\nInstalling Pwn/Reverse tools"
    install_packages ghidra gdb radare2

    info_echo "\nInstalling Pwntools"
    pip install pwntools
}

install_wordlists() {
    info_echo "\nInstalling some wordlists"
    install_packages seclists
    
    info_echo "\nDownloading rockyou.txt in home folder"
    if ! wget https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt -O ~/rockyou.txt; then
        error_echo "Failed to download rockyou.txt"
        return 1
    fi
}

install_firefox_extensions() {
    info_echo "\nInstalling Firefox extensions"
    install_extension "https://addons.mozilla.org/firefox/downloads/file/4142024/ghostery-8.11.1.xpi"
    install_extension "https://addons.mozilla.org/firefox/downloads/file/4205620/bitwarden_password_manager-2023.12.0.xpi"
    install_extension "https://addons.mozilla.org/firefox/downloads/file/4207660/foxyproxy_standard-8.6.xpi"
    install_extension "https://addons.mozilla.org/firefox/downloads/file/4189626/wappalyzer-6.10.67.xpi"
    install_extension "https://addons.mozilla.org/firefox/downloads/file/4098688/user_agent_string_switcher-0.5.0.xpi"
}

# ====================
# Main Script Execution
# ====================

# Call the appropriate functions based on the selected options
if [ "${option_states["basic"]}" -eq 1 ] ; then
    install_basic_tools
fi

if [ "${option_states["network"]}" -eq 1 ] ; then
    install_network_tools
fi

if [ "${option_states["web"]}" -eq 1 ] ; then
    install_web_tools
fi

if [ "${option_states["ad"]}" -eq 1 ] ; then
    install_ad_tools
fi

if [ "${option_states["pwn"]}" -eq 1 ] ; then
    install_pwn_tools
fi

if [ "${option_states["wordlist"]}" -eq 1 ] ; then
    install_wordlists
fi

if [ "${option_states["extension"]}" -eq 1 ] ; then
    install_firefox_extensions
fi

# Final system update and cleanup
info_echo "\nUpdating the machine, just in case. Finishing setting up"
~/clean.sh