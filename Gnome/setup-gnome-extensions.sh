#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

if [ ! -f gnome-shell-config.conf ]; then
    echo -e "${RED}gnome-shell-config.conf not found${NC}"
    exit 1
fi

if ! command -v gnome-shell &> /dev/null; then
    echo -e "${RED}GNOME is not running on this system${NC}"
    exit 1
fi

if ! command -v gnome-extensions &> /dev/null; then
    echo -e "${YELLOW}Installing gnome-extensions CLI...${NC}"
    if command -v apt &> /dev/null; then sudo apt update && sudo apt install -y gnome-shell-extensions jq curl; fi
    if command -v dnf &> /dev/null; then sudo dnf install -y gnome-extensions-app jq curl; fi
    if command -v pacman &> /dev/null; then sudo pacman -Sy --noconfirm gnome-shell-extensions jq curl; fi
fi

if ! command -v jq &> /dev/null; then
    if command -v apt &> /dev/null; then sudo apt install -y jq; fi
    if command -v dnf &> /dev/null; then sudo dnf install -y jq; fi
    if command -v pacman &> /dev/null; then sudo pacman -Sy --noconfirm jq; fi
fi

shell_version=$(gnome-shell --version | awk '{print $3}' | cut -d'.' -f1)
enabled=$(grep '^enabled-extensions=' gnome-shell-config.conf | sed "s/enabled-extensions=\[//;s/\]//;s/'//g" | tr ',' '\n' | tr -d '[:space:]')

echo -e "${YELLOW}Install missing extensions? (y/n):${NC}"
read install_missing

install_missing=$(echo "$install_missing" | tr '[:upper:]' '[:lower:]')

for ext in $enabled; do
    if gnome-extensions info "$ext" &> /dev/null; then
        echo -e "${GREEN}Enabling: $ext${NC}"
        gnome-extensions enable "$ext"
    else
        if [ "$install_missing" = "y" ] || [ "$install_missing" = "yes" ]; then
            echo -e "${YELLOW}Installing: $ext${NC}"
            info=$(curl -s "https://extensions.gnome.org/extension-info/?uuid=$ext&shell_version=$shell_version")
            url=$(echo "$info" | jq -r '.download_url')
            name=$(echo "$info" | jq -r '.uuid')
            
            if [ "$url" != "null" ]; then
                curl -s -o /tmp/$name.zip "https://extensions.gnome.org$url"
                gnome-extensions install /tmp/$name.zip
                gnome-extensions enable "$name"
                
                echo -e "${GREEN}Installed: $name${NC}"
            else
                echo -e "${RED}Failed: $ext not available for this GNOME version${NC}"
            fi
        
        else
            echo -e "${YELLOW}Skipping missing extension: $ext${NC}"
        fi
    fi
done

echo -e "${YELLOW}Restore full GNOME desktop config? (y/n):${NC}"
read restore_full
restore_full=$(echo "$restore_full" | tr '[:upper:]' '[:lower:]')

if [ "$restore_full" = "y" ] || [ "$restore_full" = "yes" ]; then
    echo -e "${GREEN}Applying full GNOME system configuration...${NC}"
    dconf load / < gnome-shell-config.conf
else
    echo -e "${GREEN}Applying only extension configuration...${NC}"
    tmp=$(mktemp)
    awk '/^\[extensions\//,/^$/' gnome-shell-config.conf > $tmp
    dconf load /org/gnome/shell/extensions/ < $tmp
    rm $tmp
fi

echo -e "${GREEN}Done.${NC}"
echo -e "${YELLOW}Restart GNOME Shell to apply changes.${NC}"
