#!/bin/bash


# ====================
# Variables
# ====================

TOOL_FOLDER="$HOME/tools"
mkdir -p "$TOOL_FOLDER"

echo "$TOOL_FOLDER"

SCRIPT_FOLDER=$(dirname "$0")
echo "$SCRIPT_FOLDER"


# ====================
# Utility functions
# ====================


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
    printf "\e[4m%b\e[0m\n" "$1"  # Keep this without a newline, just underlining
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


install_packages() {
    sudo apt install -y "$@"
}


# ====================
# Generalized Functions
# ====================

# Function to fetch and download files from a GitHub release
download_github_release_file() {
    REPO="$1"      # GitHub repository in the format owner/repo
    PATTERN="$2"   # Pattern to match the desired file(s)

    # Extract repository name for folder creation
    repo_name=$(basename "$REPO")
    TARGET_DIR="$TOOL_FOLDER/$repo_name"

    # Fetch the latest release information from GitHub API
    latest_release=$(curl --silent "https://api.github.com/repos/$REPO/releases/latest")

    # Extract the download URLs for files matching the pattern
    download_urls=$(echo "$latest_release" | grep -oP '"browser_download_url": "\K.*?'"$PATTERN"'(?=")')

    if [ -z "$download_urls" ]; then
        error_echo "No files matching $PATTERN found in the latest release of $REPO."
        return 1
    fi

    # Create the target directory with the repo name if it does not exist
    mkdir -p "$TARGET_DIR"

    # Download each file
    for url in $download_urls; do
        filename=$(basename "$url")
        filepath="$TARGET_DIR/$filename"
        if ! curl --silent -L -o "$filepath" "${url}"; then
            error_echo "Failed to download $filename"
            return 1
        fi
        info_echo "Downloaded $filename to $TARGET_DIR"

        # Check if the file is a gzip archive and decompress it
        if [[ "$filepath" == *.gz ]]; then
            info_echo "Decompressing $filename..."
            if ! gzip -d -f "$filepath"; then
                error_echo "Failed to decompress $filename"
                return 1
            fi
            info_echo "Decompressed $filename"
        fi
    done
}


# Function to install .deb files
install_deb_files() {
    REPO="$1"  # Repository name (for folder matching)

    # Define the directory where the .deb files are expected
    TARGET_DIR="$TOOL_FOLDER/$(basename "$REPO")"

    # Find all .deb files in the target directory
    deb_files=$(find "$TARGET_DIR" -name "*.deb")

    if [ -z "$deb_files" ]; then
        error_echo "No .deb files found in $TARGET_DIR."
        return 1
    fi

    # Install each .deb file
    for deb_file in $deb_files; do
        if ! sudo apt install "$deb_file" -y; then
            error_echo "Failed to install $deb_file"
            return 1
        fi
        info_echo "Installed $deb_file"
    done
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


display_options() {
    # Provide feedback to the user on the selected options
    underline_echo "Selected options:"
    for key in "${!option_states[@]}"; do
        if [[ "${option_states[$key]}" -eq 1 ]]; then
            echo "${key^} mode: $(info_echo "Enabled")"
        else
            echo "${key^} mode: $(error_echo "Disabled")"
        fi
    done
    }


# Call the option parsing function
parse_options "$@"

display_options


# ====================
# Tool Lists with Installation Methods
# ====================

declare -A basic=(
    ["p7zip-full"]="apt"
    ["python3-pip"]="apt"
    ["VSCodium"]="custom github VSCodium/vscodium amd64.deb"
    ["linpeas"]="custom github peass-ng/PEASS-ng linpeas.sh"
    ["winpeas"]="custom github peass-ng/PEASS-ng winPEASany.exe"
)

declare -A network=(
    ["nmap"]="apt"
    ["proxychains4"]="apt"
    ["ngrok"]="custom ngrok"
    ["chisel"]="custom github jpillora/chisel amd64.gz"
)

declare -A web=(
    ["ffuf"]="apt"
    ["wfuzz"]="apt"
    ["gobuster"]="apt"
    ["hashid"]="apt"
    ["hash-identifier"]="apt"
    ["hashcat"]="apt"
    ["hydra"]="apt"
)

declare -A ad=(
    ["rdesktop"]="apt"
    ["impacket-scripts"]="apt"
    ["neo4j"]="apt"
    ["bloodhound"]="apt"
    ["evil-winrm"]="apt"
    ["pkexec"]="apt"
    ["freerdp2-x11"]="apt"
)

declare -A pwn=(
    ["ghidra"]="apt"
    ["gdb"]="apt"
    ["radare2"]="apt"
    ["checksec"]="apt"
    ["pwntools"]="pip"
)

declare -A wordlist=(
    ["seclists"]="apt"
    ["rockyou.txt"]="custom wget https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt $TOOL_FOLDER/rockyou.txt"
)

declare -A extension=(
    ["Ghostery"]="firefox https://addons.mozilla.org/firefox/downloads/file/4142024/ghostery-8.11.1.xpi"
    ["Bitwarden"]="firefox https://addons.mozilla.org/firefox/downloads/file/4205620/bitwarden_password_manager-2023.12.0.xpi"
    ["FoxyProxy"]="firefox https://addons.mozilla.org/firefox/downloads/file/4207660/foxyproxy_standard-8.6.xpi"
    ["Wappalyzer"]="firefox https://addons.mozilla.org/firefox/downloads/file/4189626/wappalyzer-6.10.67.xpi"
    ["User-Agent Switcher"]="firefox https://addons.mozilla.org/firefox/downloads/file/4098688/user_agent_string_switcher-0.5.0.xpi"
)


# ====================
# Listing and Installation Functions
# ====================

# List tools in a category
list_tools() {
    local -n tools="$1"
    underline_echo "\nTools in the '$1' category:"
    for tool in "${!tools[@]}"; do
        echo "$tool"
    done
}

# Install tools in a category
install_tools() {

    info_echo "\nIntalling $1 tools"

    local -n tools="$1"
    for tool in "${!tools[@]}"; do
        local command="${tools[$tool]}"
        if [[ "$command" == apt ]]; then
            info_echo "Installing $tool via apt..."
            install_packages "$tool"
        elif [[ "$command" == firefox* ]]; then
            IFS=' ' read -r method param1 param2 <<< "$command"
            install_extension "$param1"
        elif [[ "$command" == pip ]]; then
            info_echo "Installing $tool via pip..."
            pip install "$tool"
        elif [[ "$command" == custom* ]]; then
            # Extract the custom command without "custom" keyword
            command="${command#custom }"
            custom_install "$command"
        else
            error_echo "Unknown installation method for $tool"
        fi
    done
}

# Function to handle custom installations
custom_install() {
    IFS=' ' read -r method param1 param2 <<< "$1"
    case $method in
        github)
            download_github_release_file "$param1" "$param2"
            if [[ "$param2" == *"deb"* ]]; then
                install_deb_files "$param1"
            fi
            ;;
        linpeas)
            download_linpeas
            ;;
        chisel)
            download_chisel
            ;;
        wget)
            info_echo "Downloading from $param1"
            wget "$param1" -O "$param2"
            ;;
        ngrok)
            info_echo "Installing ngrok..."
            if ! curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && \
               echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list && \
               sudo apt update && sudo apt install ngrok; then
                error_echo "Failed to install ngrok"
                return 1
            fi
            ;;
        *)
            error_echo "Unknown custom installation method: $method"
            ;;
    esac
}

# ====================
# Main Script Execution
# ====================

info_echo "\nUpdating the machine"
"$SCRIPT_FOLDER/clean.sh"

# Example usage:
if [ "${option_states["basic"]}" -eq 1 ] ; then
    list_tools basic
    install_tools basic
fi

if [ "${option_states["network"]}" -eq 1 ] ; then
    list_tools network
    install_tools network
    sudo cp "$SCRIPT_FOLDER/proxychains.conf" /etc/proxychains.conf
fi

if [ "${option_states["web"]}" -eq 1 ] ; then
    list_tools web
    install_tools web
fi

if [ "${option_states["ad"]}" -eq 1 ] ; then
    list_tools ad
    install_tools ad
fi

if [ "${option_states["pwn"]}" -eq 1 ] ; then
    list_tools pwn
    install_tools pwn
fi

if [ "${option_states["wordlist"]}" -eq 1 ] ; then
    list_tools wordlist
    install_tools wordlist
fi

if [ "${option_states["extension"]}" -eq 1 ] ; then
    list_tools extension
    install_tools extension
fi

# Final system update and cleanup
info_echo "\nUpdating the machine, just in case. Finishing setting up"
"$SCRIPT_FOLDER/clean.sh"