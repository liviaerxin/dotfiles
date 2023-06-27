#!/usr/bin/env bash
#
# bootstrap installs things.

cd "$(dirname "$0")/.."
DOTFILES_ROOT=$(pwd -P)

set -e

echo ''

ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"

ok() {
    echo -e "${COL_GREEN}[OK]${COL_RESET} "$1
}

bot() {
    echo -e "\n${COL_GREEN}\[._.]/${COL_RESET} - "$1
}

running() {
    echo -en "${COL_YELLOW} ⇒ ${COL_RESET}"$1": "
}

action() {
    echo -e "\n${COL_YELLOW}[ACTION]:${COL_RESET}\n ⇒ $1..."
}

warn() {
    echo -e "${COL_YELLOW}[WARNING]${COL_RESET} "$1
}

error() {
    echo -e "${COL_RED}[ERROR]${COL_RESET} "$1
}

print_error() {
    printf " [✖] %s\n" "$1"
}

print_success() {
    printf " [✔] %s\n" "$1"
}

print_result() {

    if [ "$1" -eq "0" ]; then
        print_success "$2"
    else
        print_error "$2"
    fi

    return "$1"

}

require_brew() {
    running "brew $@"
    brew list $@ > /dev/null 2>&1
    ret_code=$?
    if [[ $ret_code != 0 ]]; then
        action "brew install $1 $2"
        brew install $1 $2
        if [[ $? != 0 ]]; then
            error "failed to install $1! aborting..."
            # exit -1
        fi
    fi
    ok
}

require_cask() {
    running "brew cask $@"
    brew cask list $@ > /dev/null 2>&1
    ret_code=$?
    if [[ $ret_code != 0 ]]; then
        action "brew cask install $1 $2"
        brew install --cask $1
        if [[ $? != 0 ]]; then
            error "failed to install $1! aborting..."
            # exit -1
        fi
    fi
    ok
}

# ###########################################################
# Install non-brew various tools (PRE-BREW Installs)
# ###########################################################
bot "ensuring build/install tools are available"
if xcode-select --print-path &>/dev/null; then
    ok "XCode command line tools already installed."
elif xcode-select --install &>/dev/null; then
    ok "Finished installing XCode command line tools."
else
    error "Failed to install XCode command line tools."
fi

bot "Installing Rosetta..."
sudo softwareupdate --install-rosetta

ok "Rosetta Installed"


# ###########################################################
# install homebrew (CLI Packages)
# ###########################################################
running "checking homebrew..."
brew_bin=$(which brew) 2>&1 > /dev/null
if [[ $? != 0 ]]; then
  action "installing homebrew"
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  if [[ $? != 0 ]]; then
    error "unable to install homebrew, script $0 abort!"
    exit 2
  fi
  brew analytics off
else
  ok
  bot "Homebrew"
  read -r -p "run brew update && upgrade? [y|N] " response
  if [[ $response =~ (y|yes|Y) ]]; then
    action "updating homebrew..."
    brew update
    ok "homebrew updated"
    action "upgrading brew packages..."
    brew upgrade
    ok "brews upgraded"
  else
    ok "skipped brew package upgrades."
  fi
fi

if [[ ! -d "./oh-my-zsh/custom/themes/powerlevel9k" ]]; then
  git clone https://github.com/bhilburn/powerlevel9k.git oh-my-zsh/custom/themes/powerlevel9k
fi

bot "Dotfiles Setup"
read -r -p "symlink ./homedir/* files in ~/ (these are the dotfiles)? [y|N] " response
if [[ $response =~ (y|yes|Y) ]]; then
  bot "creating symlinks for project dotfiles..."
  pushd homedir > /dev/null 2>&1
  now=$(date +"%Y.%m.%d.%H.%M.%S")

  for file in .*; do
    if [[ $file == "." || $file == ".." ]]; then
      continue
    fi
    running "~/$file"
    # if the file exists:
    if [[ -e ~/$file ]]; then
        mkdir -p ~/.dotfiles_backup/$now
        mv ~/$file ~/.dotfiles_backup/$now/$file
        echo "backup saved as ~/.dotfiles_backup/$now/$file"
    fi
    # symlink might still exist
    unlink ~/$file > /dev/null 2>&1
    # create the link
    ln -s ~/.dotfiles/homedir/$file ~/$file
    echo -en '\tlinked';ok
  done

  popd > /dev/null 2>&1
fi


read -r -p "Install fonts? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  bot "installing fonts"
  # need fontconfig to install/build fonts
  require_brew fontconfig
  ./fonts/install.sh
  brew tap homebrew/cask-fonts
  require_brew svn #required for roboto
  require_cask font-fontawesome
  require_cask font-awesome-terminal-fonts
  require_cask font-hack
  require_cask font-inconsolata-dz-for-powerline
  require_cask font-inconsolata-g-for-powerline
  require_cask font-inconsolata-for-powerline
  require_cask font-roboto-mono
  require_cask font-roboto-mono-for-powerline
  require_cask font-source-code-pro
  ok
fi