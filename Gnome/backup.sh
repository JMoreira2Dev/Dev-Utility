#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${YELLOW}Creating backup directory...${NC}"
mkdir -p gnome-backup/extensions

echo -e "${YELLOW}Saving enabled extensions list...${NC}"
gsettings get org.gnome.shell enabled-extensions > gnome-backup/enabled-extensions.txt

echo -e "${YELLOW}Saving GNOME Shell extension configuration...${NC}"
dconf dump /org/gnome/shell/extensions/ > gnome-backup/extensions-config.conf

echo -e "${YELLOW}Copying installed extensions...${NC}"
if [ -d ~/.local/share/gnome-shell/extensions/ ]; then
    cp -r ~/.local/share/gnome-shell/extensions/* gnome-backup/extensions/
fi
if [ -d /usr/share/gnome-shell/extensions/ ]; then
    cp -r /usr/share/gnome-shell/extensions/* gnome-backup/extensions/ 2>/dev/null
fi

echo -e "${GREEN}Backup complete.${NC}"
echo -e "${YELLOW}Backup saved in gnome-backup/${NC}"
