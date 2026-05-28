# 4NDR0DWL-INSTALLER.SH

Save the following as `4NDR0DWL-INSTALLER.SH` and execute to run:

```html
#!/bin/sh
# shellcheck disable=all
# 
#                    # === 4NDR0DWL-INSTALLER.SH === #
#
# Description: This script will install DWL for Wayland 
#              with my dotfiles and specs. - 4ndr0666 
# -----------------------------------------------------------

# CONSTANTS
dotfilesrepo="https://github.com/4ndr0666/dwl-dots.git"
progsfile="https://raw.githubusercontent.com/4ndr0666/4ndr0site/refs/heads/main/static/progs.csv"
aurhelper="yay"
repobranch="master"
export TERM=ansi
rssurls="https://xcandid.vip/feed/
https://forum.phun.org/forums/-/index.rss
https://celebhub.net/feed
https://simpcity.su/forums/youtube.13
https://simpcity.su/forums/instagram.12
https://simpcity.su/forums/celebrities.41
https://simpcity.su/forums/patreon.9
https://simpcity.su/forums/onlyfans.8
https://xstar.scandalshack.com/p/i/?a=rss
https://www.redditstatic.com/user/andr0666/saved.rss?feed=8138000bcda004509b631cd8c521ae8434701d49&user=andr0666"

# FUNCTIONS
installpkg() {
	pacman --noconfirm --needed -S "$1" >/dev/null 2>&1
}

error() {
	# Log to stderr and exit with failure.
	printf "%s\n" "$1" >&2
	exit 1
}

welcomemsg() {
	whiptail --title "4NDR0DWL-INSTALLER" \
		--msgbox "This will rice your machine to the 4ndr0666 Wayland specs for DWL.\\n\\nDWL will be registered as a tuigreet session alongside your existing WMs.\\n\\n-4ndr0666" 12 60

	whiptail --title "Important Note!" --yes-button "All ready!" \
		--no-button "Return..." \
		--yesno "Be sure the computer you are using has current pacman updates and refreshed Arch keyrings.\\n\\nIf it does not, the installation of some programs might fail." 8 70
}

getuserandpass() {
	# Prompts user for new username and password.
	name=$(whiptail --inputbox "First, please enter a name for the user account." 10 60 3>&1 1>&2 2>&3 3>&1) || exit 1
	while ! echo "$name" | grep -q "^[a-z_][a-z0-9_-]*$"; do
		name=$(whiptail --nocancel --inputbox "Username not valid. Give a username beginning with a letter, with only lowercase letters, - or _." 10 60 3>&1 1>&2 2>&3 3>&1)
	done
	pass1=$(whiptail --nocancel --passwordbox "Enter a password for that user." 10 60 3>&1 1>&2 2>&3 3>&1)
	pass2=$(whiptail --nocancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
	while ! [ "$pass1" = "$pass2" ]; do
		unset pass2
		pass1=$(whiptail --nocancel --passwordbox "Passwords do not match.\\n\\nEnter password again." 10 60 3>&1 1>&2 2>&3 3>&1)
		pass2=$(whiptail --nocancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
	done
}

usercheck() {
	! { id -u "$name" >/dev/null 2>&1; } ||
		whiptail --title "WARNING" --yes-button "CONTINUE" \
			--no-button "No wait..." \
			--yesno "The user \`$name\` already exists on this system. The script can install for a user already existing, but it will OVERWRITE any conflicting settings/dotfiles on the user account.\\n\\nThe ricer will NOT overwrite your user files, documents, videos, etc., but only click <CONTINUE> if you don't mind your settings being overwritten.\\n\\nNote also that the script will change $name's password to the one you just gave." 14 70
}

preinstallmsg() {
	whiptail --title "Let's get this party started!" --yes-button "Let's go!" \
		--no-button "No, nevermind!" \
		--yesno "The rest of the installation will now be totally automated, so you can sit back and relax.\\n\\nIt will take some time, but when done, you can relax even more with your complete system.\\n\\nNow just press <Let's go!> and the system will begin installation!" 13 60 || {
		clear
		exit 1
	}
}

adduserandpass() {
	# Adds user `$name` with password $pass1.
	whiptail --infobox "Adding user \"$name\"..." 7 50
	useradd -m -g wheel -s /bin/zsh "$name" >/dev/null 2>&1 ||
		usermod -a -G wheel "$name" && mkdir -p /home/"$name" && chown "$name":wheel /home/"$name"
	export repodir="/home/$name/.local/src"
	mkdir -p "$repodir"
	chown -R "$name":wheel "$(dirname "$repodir")"
	echo "$name:$pass1" | chpasswd
	unset pass1 pass2
}

# CHAOTIC AUR
refreshkeys() {
	case "$(readlink -f /sbin/init)" in
	*systemd*)
		whiptail --infobox "Refreshing Arch Keyring..." 7 40
		pacman --noconfirm -S archlinux-keyring >/dev/null 2>&1
		;;
	*)
		whiptail --infobox "Enabling Chaotic AUR..." 7 40
		pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com >/dev/null 2>&1
		pacman-key --lsign-key 3056513887B78AEB >/dev/null 2>&1
		whiptail --infobox "Installing Chaotic AUR keyring and mirrorlist..." 7 40
		pacman -U \
			'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
			'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' \
			>/dev/null 2>&1
		grep -q "^\[chaotic-aur\]" /etc/pacman.conf ||
			printf "\n[chaotic-aur]\nInclude = /etc/pacman.d/mirrorlist-arch\n" >>/etc/pacman.conf
		pacman -Sy --noconfirm >/dev/null 2>&1
		pacman-key --populate archlinux >/dev/null 2>&1
		;;
	esac
}

manualinstall() {
	# Installs $1 manually. Used only for AUR helper here.
	# Should be run after repodir is created and var is set.
	pacman -Qq "$1" && return 0
	whiptail --infobox "Installing \"$1\" manually." 7 50
	sudo -u "$name" mkdir -p "$repodir/$1"
	sudo -u "$name" git -C "$repodir" clone --depth 1 --single-branch \
		--no-tags -q "https://aur.archlinux.org/$1.git" "$repodir/$1" ||
		{
			cd "$repodir/$1" || return 1
			sudo -u "$name" git pull --force origin master
		}
	cd "$repodir/$1" || exit 1
	sudo -u "$name" \
		makepkg --noconfirm -si >/dev/null 2>&1 || return 1
}

maininstall() {
	whiptail --title "4NDR0DWL Installation" --infobox "Installing \`$1\` ($n of $total). $1 $2" 9 70
	installpkg "$1"
}

gitmakeinstall() {
	progname="${1##*/}"
	progname="${progname%.git}"
	dir="$repodir/$progname"
	whiptail --title "4NDR0DWL Installation" \
		--infobox "Installing \`$progname\` ($n of $total) via \`git\` and \`make\`. $(basename "$1") $2" 8 70
	sudo -u "$name" git -C "$repodir" clone --depth 1 --single-branch \
		--no-tags -q "$1" "$dir" ||
		{
			cd "$dir" || return 1
			sudo -u "$name" git pull --force origin master
		}
	cd "$dir" || exit 1
	make >/dev/null 2>&1
	make install >/dev/null 2>&1
	cd /tmp || return 1
}

aurinstall() {
	whiptail --title "4NDR0DWL Installation" \
		--infobox "Installing \`$1\` ($n of $total) from the AUR. $1 $2" 9 70
	echo "$aurinstalled" | grep -q "^$1$" && return 1
	sudo -u "$name" $aurhelper -S --noconfirm "$1" >/dev/null 2>&1
}

pipinstall() {
	whiptail --title "4NDR0DWL Installation" \
		--infobox "Installing the Python package \`$1\` ($n of $total). $1 $2" 9 70
	[ -x "$(command -v "pip")" ] || installpkg python-pip >/dev/null 2>&1
	yes | pip install "$1"
}

installationloop() {
	([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) ||
		curl -Ls "$progsfile" | sed '/^#/d' >/tmp/progs.csv
	total=$(wc -l </tmp/progs.csv)
	aurinstalled=$(pacman -Qqm)
	while IFS=, read -r tag program comment; do
		n=$((n + 1))
		echo "$comment" | grep -q "^\".*\"$" &&
			comment="$(echo "$comment" | sed -E "s/(^\"|\"$)//g")"
		case "$tag" in
		"A") aurinstall "$program" "$comment" ;;
		"G") gitmakeinstall "$program" "$comment" ;;
		"P") pipinstall "$program" "$comment" ;;
		*) maininstall "$program" "$comment" ;;
		esac
	done </tmp/progs.csv
}

putgitrepo() {
	# Downloads a gitrepo $1 and places the files in $2 only overwriting conflicts.
	whiptail --infobox "Downloading and installing config files..." 7 60
	[ -z "$3" ] && branch="master" || branch="$repobranch"
	dir=$(mktemp -d)
	[ ! -d "$2" ] && mkdir -p "$2"
	chown "$name":wheel "$dir" "$2"
	sudo -u "$name" git -C "$repodir" clone --depth 1 \
		--single-branch --no-tags -q --recursive -b "$branch" \
		--recurse-submodules "$1" "$dir"
	sudo -u "$name" cp -rfT "$dir" "$2"
}

vimplugininstall() {
	whiptail --infobox "Installing neovim plugins..." 7 60
	mkdir -p "/home/$name/.config/nvim/autoload"
	curl -Ls "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" \
		>"/home/$name/.config/nvim/autoload/plug.vim"
	chown -R "$name:wheel" "/home/$name/.config/nvim"
	sudo -u "$name" nvim -c "PlugInstall|q|q"
}

# Arken
makeuserjs() {
	arkenfox="$pdir/arkenfox.js"
	overrides="$pdir/user-overrides.js"
	userjs="$pdir/user.js"
	ln -fs "/home/$name/.config/firefox/4ndr0666.js" "$overrides"
	[ ! -f "$arkenfox" ] && curl -sL "https://raw.githubusercontent.com/arkenfox/user.js/master/user.js" >"$arkenfox"
	cat "$arkenfox" "$overrides" >"$userjs"
	chown "$name:wheel" "$arkenfox" "$userjs"
}

# DWL 
install_dwl() {
	local dwl_dir="$repodir/dwl"
	whiptail --infobox "Installing Wayland build stack for DWL..." 7 60
	for dep in wlroots wayland wayland-protocols libxkbcommon \
	            libinput pixman pkgconf; do
		installpkg "$dep"
	done

	whiptail --infobox "Cloning DWL (Wayland-native suckless window manager)..." 7 60
	sudo -u "$name" git -C "$repodir" clone --depth 1 --single-branch \
		--no-tags -q "https://github.com/djpohly/dwl.git" "$dwl_dir" ||
		{
			cd "$dwl_dir" || return 1
			sudo -u "$name" git pull --force origin main
		}
	cd "$dwl_dir" || return 1

	whiptail --infobox "Compiling DWL..." 7 60
	sudo -u "$name" make >/dev/null 2>&1
	make install >/dev/null 2>&1
	cd /tmp || return 1
}

# WAYLAND SESSION WRAPPER 
setup_wayland_env() {
	whiptail --infobox "Writing Wayland session wrapper ~/.local/bin/start-dwl..." 7 60
	sudo -u "$name" mkdir -p "/home/$name/.local/bin"

	cat >"/home/$name/.local/bin/start-dwl" <<'EOF'
#!/bin/sh
# ================================================================
# DWL WAYLAND SESSION WRAPPER — 4ndr0666 / theworkpc
# Invoked by: tuigreet → dwl.desktop
# NOT a .zprofile TTY intercept — tuigreet manages session dispatch.
# ================================================================

# --- XDG ---
export XDG_CURRENT_DESKTOP=dwl
export XDG_SESSION_DESKTOP=dwl
export XDG_SESSION_TYPE=wayland

# --- Toolkit backends ---
export GDK_BACKEND="wayland,x11,*"
export QT_QPA_PLATFORM="wayland;xcb"
export CLUTTER_BACKEND=wayland
export BEMENU_BACKEND=wayland
export WINIT_UNIX_BACKEND=wayland

# --- QT ---
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

# --- Java non-reparenting ---
export _JAVA_AWT_WM_NONREPARENTING=1

# --- Browser / Electron Wayland native ---
export MOZ_ENABLE_WAYLAND=1
export ELECTRON_OZONE_PLATFORM_HINT=auto

# ── DAEMONS (all guarded — safe on minimal installs) ──────────────

# Polkit agent (hyprpolkitagent → polkit-gnome → lxqt fallback)
if command -v hyprpolkitagent >/dev/null 2>&1; then
	hyprpolkitagent &
elif [ -f /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 ]; then
	/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
elif command -v lxqt-policykit-agent >/dev/null 2>&1; then
	lxqt-policykit-agent &
fi

# MAKO (dunst X11 fallback)
if command -v mako >/dev/null 2>&1; then
	mako &
elif command -v dunst >/dev/null 2>&1; then
	dunst &
fi

# NM
command -v nm-applet >/dev/null 2>&1 && nm-applet --indicator &

# STATUSBAR
command -v waybar >/dev/null 2>&1 && waybar &

# WALLPAPER 
if command -v awww-daemon >/dev/null 2>&1; then
	awww-daemon &
elif command -v swww >/dev/null 2>&1; then
	swww &
fi

# HYPRIDLE
command -v hypridle >/dev/null 2>&1 && hypridle &

# CLIPHIST
if command -v wl-paste >/dev/null 2>&1 && command -v cliphist >/dev/null 2>&1; then
	wl-paste --type text  --watch cliphist store &
	wl-paste --type image --watch cliphist store &
fi

# EXECUTE DWL
mkdir -p "$HOME/.cache"
exec dwl >"$HOME/.cache/dwl.log" 2>&1
EOF

	chown "$name:wheel" "/home/$name/.local/bin/start-dwl"
	chmod +x "/home/$name/.local/bin/start-dwl"
}

# TUIGREET SESSION REGISTRATION
register_dwl_session() {
	whiptail --infobox "Registering DWL with tuigreet..." 7 60
	mkdir -p /usr/share/wayland-sessions
	cat >/usr/share/wayland-sessions/dwl.desktop <<EOF
[Desktop Entry]
Name=DWL (Wayland Vanguard)
Comment=Dynamic Window Manager for Wayland — 4ndr0666
Exec=/home/${name}/.local/bin/start-dwl
Type=Application
DesktopNames=dwl
EOF
}

finalize() {
	whiptail --title "All done!" \
		--msgbox "Congrats! Provided there were no hidden errors, the script completed successfully and all the programs and configuration files should be in place.\\n\\nDWL is now a session in tuigreet. Select 'DWL (Wayland Vanguard)' from the session menu at your next login.\\n\\n-4ndr0666" 13 80
}

# DEPS 
pacman --noconfirm --needed -Sy libnewt ||
	error "Are you sure you're running this as the root user, are on an Arch-based distribution and have an internet connection?"

welcomemsg || error "User exited."
getuserandpass || error "User exited."
usercheck || error "User exited."
preinstallmsg || error "User exited."

refreshkeys ||
	error "Error automatically refreshing Arch keyring. Consider doing so manually."

for x in curl ca-certificates base-devel git ntp zsh dash \
          wayland wlroots wayland-protocols libxkbcommon libinput \
          libxcb pixman pkgconf; do
	whiptail --title "4NDR0DWL Installation" \
		--infobox "Installing \`$x\` which is required to install and configure other programs." 8 70
	installpkg "$x"
done

whiptail --title "4NDR0DWL Installation" \
	--infobox "Synchronizing system time to ensure successful and secure installation of software..." 8 70
ntpd -q -g >/dev/null 2>&1

adduserandpass || error "Error adding username and/or password."

[ -f /etc/sudoers.pacnew ] && cp /etc/sudoers.pacnew /etc/sudoers

# TRAP
trap 'rm -f /etc/sudoers.d/andro-temp' HUP INT QUIT TERM PWR EXIT
printf "%%wheel ALL=(ALL) NOPASSWD: ALL\nDefaults:%%wheel,root runcwd=*\n" \
	>/etc/sudoers.d/andro-temp

grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
sed -Ei "s/^#(ParallelDownloads).*/\1 = 5/;/^#Color$/s/#//" /etc/pacman.conf
sed -i "s/-j2/-j$(nproc)/;/^#MAKEFLAGS/s/^#//" /etc/makepkg.conf

manualinstall $aurhelper || error "Failed to install AUR helper."
$aurhelper -Y --save --devel

n=0
installationloop

putgitrepo "$dotfilesrepo" "/home/$name" "$repobranch"
rm -rf "/home/$name/.git/" "/home/$name/README.md" \
	"/home/$name/LICENSE" "/home/$name/FUNDING.yml"

[ -s "/home/$name/.config/newsboat/urls" ] ||
	echo "$rssurls" | sudo -u "$name" tee "/home/$name/.config/newsboat/urls" >/dev/null

[ ! -f "/home/$name/.config/nvim/autoload/plug.vim" ] && vimplugininstall

rmmod pcspkr
echo "blacklist pcspkr" >/etc/modprobe.d/nobeep.conf

chsh -s /bin/zsh "$name" >/dev/null 2>&1
sudo -u "$name" mkdir -p "/home/$name/.cache/zsh/"
sudo -u "$name" mkdir -p "/home/$name/.config/abook/"
sudo -u "$name" mkdir -p "/home/$name/.config/mpd/playlists/"

ln -sfT /bin/dash /bin/sh >/dev/null 2>&1

install_dwl        || error "DWL failed to compile or install."
setup_wayland_env  || error "Failed to write start-dwl wrapper."
register_dwl_session

whiptail --infobox "Brave browser is installed via progs.csv. Profile seeds on first launch." 7 70

echo "%wheel ALL=(ALL:ALL) ALL" >/etc/sudoers.d/00-andro-wheel-can-sudo
echo "%wheel ALL=(ALL:ALL) NOPASSWD: /usr/bin/shutdown,/usr/bin/reboot,/usr/bin/systemctl suspend,/usr/bin/wifi-menu,/usr/bin/mount,/usr/bin/umount,/usr/bin/pacman -Syu,/usr/bin/pacman -Syyu,/usr/bin/pacman -Syyu --noconfirm,/usr/bin/loadkeys,/usr/bin/pacman -Syyuw --noconfirm,/usr/bin/pacman -S -y --config /etc/pacman.conf --,/usr/bin/pacman -S -y -u --config /etc/pacman.conf --" \
	>/etc/sudoers.d/01-andro-cmds-without-password
echo "Defaults editor=/usr/bin/nvim" >/etc/sudoers.d/02-andro-visudo-editor
mkdir -p /etc/sysctl.d
echo "kernel.dmesg_restrict = 0" >/etc/sysctl.d/dmesg.conf

rm -f /etc/sudoers.d/andro-temp

finalize
```
