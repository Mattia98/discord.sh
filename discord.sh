#!/bin/bash
set -e

echo "discord.sh version 1.1"

# Check dependencies
if ! hash jq ; then
	echo "jq is missing. Please install jq bevore proceeding"
	exit 10
fi
if ! hash curl ; then
	echo "curl is missing. Please install curl bevore proceeding"
	exit 11
fi

function main() {
	# Check wether Discord is already installed
	if [ -d ~/.local/share/Discord/ ]; then
		# Get latest version number
		LAST_VER=$(curl 'https://discord.com/api/download?platform=linux' -si | grep -oP 'location: \K.*' | cut -d '/' -f 6)
		echo "Latest version is $LAST_VER"
		# Get installed version number
		CURR_VER=$(jq .version -r ~/.local/share/Discord/resources/build_info.json)
		echo "Current version is $CURR_VER"
		# Compare version
		if [ $(version $CURR_VER) -lt $(version $LAST_VER) ]; then 
			# We are outdated, need to update
			msg "Updating Discord"
			update_discord;
		else
			msg "No update necessary"
		fi
	else
		msg "Installing Discord for the first time"
		install_discord;
	fi
	# Ready to go, start Discord
	msg "Starting Discord"
	start_discord;
}

function update_discord() {
	# Create temporary directory for downloading Discord and download into it
	TMP_DIR=$(mktemp -d)
	curl -L -o "$TMP_DIR/discord.tgz" "https://discord.com/api/download?platform=linux&format=tar.gz"
	# Extract Discord into its new home
	tar --overwrite -xf "$TMP_DIR/discord.tgz" --directory ~/.local/share/
}

function install_discord() {
	# Make sure our directory exists
	mkdir -p ~/.local/share/Discord/
	# Update Discord to install it :/
	update_discord;
	# Create a desktop file for this
	mkdir -p ~/.local/share/applications/
	cat > ~/.local/share/applications/Discord.desktop <<\EOF
[Desktop Entry]
Name=Discord
StartupWMClass=discord
Comment=All-in-one voice and text chat for gamers that's free, secure, and works on both your desktop and phone.
GenericName=Internet Messenger
Exec=bash -c '~/.local/share/Discord/discord.sh'
Icon=discord
Type=Application
Categories=Network;InstantMessaging;
EOF
	chmod +x ~/.local/share/applications/Discord.desktop
	cp $0 ~/.local/share/Discord/discord.sh
	chmod +x ~/.local/share/Discord/discord.sh
}

function start_discord() {
	~/.local/share/Discord/Discord
}

function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

function msg() {
	if hash notify-send ; then
		notify-send -i discord "discord.sh" "$1"
	else
		echo "$1"
	fi
}

main;
