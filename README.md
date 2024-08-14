# Kali Setup Script

## Description

This Bash script automates the setup and installation of essential tools and utilities on a Kali Linux system. It categorizes tools into various groups, such as basic utilities, network tools, web tools, Active Directory tools, pwn/reverse engineering tools, wordlists, and Firefox extensions. The script provides options to selectively install specific categories or all tools at once. Additionally, users can list the tools in each category before installation.

### Key Features:
- **Category-based Installation**: Install tools grouped by functionality, such as basic tools, network tools, etc.
- **Custom Installation Handling**: Supports custom installation methods, including GitHub releases, pip packages, and direct downloads.
- **Automatic Cleanup**: Temporary files created during installation are automatically removed.
- **User Feedback**: The script provides detailed feedback on the tools being installed and the installation status.

## Prerequisites

Before running this script, ensure the following dependencies are installed:
- **Bash**: The script is written in Bash and is intended for use on Linux systems.
- **sudo**: Some commands require root privileges.
- **curl**: Used for downloading files from URLs.
- **wget**: Required for downloading files from the web.
- **firefox**: Necessary for installing Firefox extensions.

## Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/your-username/kali-setup-script.git
   cd kali-setup-script
   ```

2. **Make the Script Executable**:
   ```bash
   chmod +x kali-setup.sh
   ```

3. **Run the Script**:
   ```bash
   ./kali-setup.sh [options]
   ```

## Usage

Run the script with the appropriate options to install specific categories of tools. You can also list the tools in each category without installing them.

### Options:
- `-h, --help` : Display the help message.
- `--all` : Enable and install all categories.
- `--basic` : Install basic tools.
- `--network` : Install network and pivoting tools.
- `--web` : Install web tools.
- `--extension` : Install Firefox extensions.
- `--ad` : Install Active Directory tools.
- `--pwn` : Install pwn/reverse engineering tools.
- `--wordlist` : Download and install wordlists.

### Examples:

- **Install All Tools**:
  ```bash
  ./kali-setup.sh --all
  ```

- **Install Only Basic and Network Tools**:
  ```bash
  ./kali-setup.sh --basic --network
  ```

- **List Tools in the Web Category**:
  ```bash
  ./kali-setup.sh --web
  ```

## Options

The following options can be passed to the script:

- **Basic Tools**:
  - p7zip-full (via apt)
  - python3-pip (via apt)
  - VSCodium (via custom GitHub release)
  - linpeas (via custom download)

- **Network Tools**:
  - nmap (via apt)
  - proxychains4 (via apt)
  - ngrok (via custom download and installation)

- **Web Tools**:
  - ffuf (via apt)
  - wfuzz (via apt)
  - gobuster (via apt)
  - hashid (via apt)
  - hash-identifier (via apt)
  - hashcat (via apt)
  - hydra (via apt)

- **Active Directory Tools**:
  - rdesktop (via apt)
  - impacket-scripts (via apt)
  - neo4j (via apt)
  - bloodhound (via apt)
  - evil-winrm (via apt)
  - pkexec (via apt)
  - freerdp2-x11 (via apt)

- **Pwn/Reverse Engineering Tools**:
  - ghidra (via apt)
  - gdb (via apt)
  - radare2 (via apt)
  - checksec (via apt)
  - Pwntools (via pip)

- **Wordlists**:
  - seclists (via apt)
  - rockyou.txt (via custom download)

- **Firefox Extensions**:
  - Ghostery
  - Bitwarden
  - FoxyProxy
  - Wappalyzer
  - User-Agent Switcher

## Contributing

Contributions are welcome! If you find bugs, have feature requests, or want to contribute to the codebase, please create an issue or submit a pull request on GitHub.

## License

This script is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

## Author Information

- **Author**: bipbipboup
- **GitHub**: [your-username](https://github.com/bipbipboup)

## To do
- [x] Change the path of clean.sh and proxychains.conf to find to be the path of the kali-setup.sh file.
- [ ] Create requirements.txt file.
- [ ] Loop on all the categories to not have to modify it if we add a category.
- [ ] Be able to create a really custom function so that the custom installation go take that function (for ngrok for example). -> Enables to remove it from the case.
- [ ] Create one function for the github download. Be able to precise what we are looking for (.deb, linpeas.sh, etc.). Maybe support regex.
- [ ] Create a function to list the categories.
- [x] Do a generic function to install tools
- [x] Create a list tools function
