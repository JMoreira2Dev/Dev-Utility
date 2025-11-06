#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'


read -sp ">Github username: " username
echo

if command -v gh &> /dev/null; then
    echo -e "${GREEN} gh is available!${NC}"
else
    echo -e "${RED} gh is not installed!${NC}"
    echo -e "${GREEN} Installing now...${NC}"

    echo -e "   ==> ${YELLOW}Detecting package manager...${NC}"

    if command -v apt >/dev/null 2>&1; then
        PKG="apt"
    elif command -v dnf >/dev/null 2>&1; then
        PKG="dnf"
    elif command -v yum >/dev/null 2>&1; then
        PKG="yum"
    elif command -v pacman >/dev/null 2>&1; then
        PKG="pacman"
    else
        echo -e "${RED}No supported package manager found${NC} (apt, dnf, yum, pacman)."
        exit 1
    fi

    echo -e "${YELLOW}[Package manager]${NC}: $PKG"
    echo -e "  ==> ${YELLOW}Proceeding to installation...${NC}"
    echo

    case $PKG in

        apt)
            echo "- Configuring GitHub CLI repository..."
            sudo apt-key --keyring /usr/share/keyrings/githubcli-archive-keyring.gpg adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/github-cli2.list > /dev/null
            sudo apt update
            sudo apt install gh
            ;;

        dnf)
            echo "Adding RPM repo and installing..."
            sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
            sudo dnf install -y gh
            ;;

        yum)
            echo "Adding RPM repo and installing..."
            sudo yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
            sudo yum install -y gh
            ;;

        pacman)
            echo "Installing via the official Arch repository..."
            sudo pacman -Sy --noconfirm github-cli
            ;;

    esac

    echo
    echo -e "${GREEN}Installation complete!${NC}"

fi

echo
read -p "Do you want to authenticate with GitHub CLI? (y/n): " auth_choice
auth_choice=$(echo "$auth_choice" | tr '[:upper:]' '[:lower:]')

if [ "$auth_choice" = "y" ] || [ "$auth_choice" = "yes" ]; then
    echo
    echo "Starting GitHub authentication..."
    gh auth login

    echo
    echo "Cloning repositories using GitHub CLI (authenticated)..."
    gh repo list "$username" --limit 1000 --json nameWithOwner -q '.[] .nameWithOwner' \
        | xargs -n1 -I{} gh repo clone {}
else
    echo
    echo "Skipping authentication."
    echo -e "${YELLOW}Only public repositories will be cloned.${NC}"
    echo

    echo "Cloning public repositories via curl + git clone..."
    curl -s "https://api.github.com/users/$username/repos?per_page=1000" \
        | jq -r '.[].clone_url' \
        | xargs -n1 git clone
fi

echo
echo -e "${GREEN}Done.${NC}"
echo
