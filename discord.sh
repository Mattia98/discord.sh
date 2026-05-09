#!/bin/bash
set -e

echo "discord.sh version 1.2"

# Check dependencies
if ! hash curl ; then
	echo "curl is missing. Please install curl bevore proceeding"
	exit 11
fi

# Check if we are being run through a pipe
# The way this is checked is by checking if argument0 is a readable file
# If the script is run as a file, argument0 is the script itself, resulting in true
# If the script is run through a pipe, argument0 is the shell command (e.g. bash), resulting in false
# This is not fail-safe, because if the the shell command used is an absolute path the result would be true
if [ ! -r "$0" ] ; then
	echo "script is running from a pipe. Please download the script and run it from terminal"
	exit 12
fi

function main() {
	# Get latest version number
	LAST_VER=$(curl 'https://discord.com/api/download?platform=linux' -si | grep -oP 'location: \K.*' | cut -d '/' -f 6)

	# Check wether Discord is already installed
	if [ -d ~/.local/opt/Discord/ ]; then
		msg "Checking for updates"
		echo "Latest version is $LAST_VER"
		# Get installed version number
		CURR_VER=$(cat ~/.local/opt/Discord/DISCORD_SH_INSTALLED_VERSION || echo '0.0.0')
		echo "Current version is $CURR_VER"
		# Compare version
		if [ $(version $CURR_VER) -lt $(version $LAST_VER) ]; then 
			# We are outdated, need to update
			msg "Updating Discord"
			update_discord $CURR_VER;
			cleanup_cache;
		else
			msg "No update necessary"
		fi
	else
		msg "Installing Discord for the first time"
		install_discord $LAST_VER;
	fi
	# Ready to go, start Discord
	msg "Starting Discord"
	start_discord;
}

function update_discord() {
	# Create temporary directory for downloading Discord and download into it
	msg "Downloading Discord"
	TMP_DIR=$(mktemp -d)
	curl -L -o "$TMP_DIR/discord.tgz" "https://discord.com/api/download?platform=linux&format=tar.gz"

	# Extract Discord into its new home
	msg "Extracting Discord"
	tar --overwrite -xf "$TMP_DIR/discord.tgz" --directory ~/.local/opt/
	echo $1 > ~/.local/opt/Discord/DISCORD_SH_INSTALLED_VERSION
}

function install_discord() {
	# Make sure our directory exists
	mkdir -p ~/.local/opt/Discord/
	# Update Discord to install it :/
	update_discord $1;
	# Create a desktop file for this
	mkdir -p ~/.local/share/applications/
	cat > ~/.local/share/applications/Discord.desktop <<EOF
[Desktop Entry]
Name=Discord
StartupWMClass=discord
Comment=All-in-one voice and text chat for gamers that's free, secure, and works on both your desktop and phone.
GenericName=Internet Messenger
Exec=$HOME/.local/bin/discord.sh
Icon=$HOME/.local/opt/Discord/discord.png
Type=Application
Categories=Network;InstantMessaging;
EOF
	chmod +x ~/.local/share/applications/Discord.desktop
	# Install our script
	mkdir -p ~/.local/bin/
	cp $0 ~/.local/bin/discord.sh
	chmod +x ~/.local/bin/discord.sh
}

function start_discord() {
	~/.local/opt/Discord/discord
}

function cleanup_cache() {
	rm -rf ~/.config/discord/Cache
	rm -rf ~/.config/discord/GPUCache
}

function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

function msg() {
	# Output message as blue text always
	echo -e "\e[1;34m$1\e[0m"

	if hash notify-send ; then
		if [ -r ~/.local/opt/Discord/discord.png ]; then
			notify-send -i ~/.local/opt/Discord/discord.png "discord.sh" "$1"
		else
			notify-send -i emblem-downloads "discord.sh" "$1"
		fi
	fi
}

main;
