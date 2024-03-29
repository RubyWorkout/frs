#!/bin/bash

# This bash script will help to prepare and configure your developer
# environment on latest Linux Ubuntu in minutes.
#
# (c) Vladislav Trotsenko 2022, MIT
#
# Example of usage: . ./setup.sh johndoe@example.com "John Doe" git_username git_token

# Coloring stdout
red=$(tput setaf 1)
green=$(tput setaf 2)
bold=$(tput bold)
reset=$(tput sgr0)

# Local vars
email=$1
name=$2
git_username=$3
git_token=$4
target_ruby_version="3.1.2"
steps_counter=0
steps_errors=()
final_step_index=8

# Reurns colorized step title
function step_title() {
  echo "${bold}${green}STEP $1: $2...${reset}"
}

# Install git, zsh and friends
function step_1() {
  cd ~
  step_title $1 "Installing GIT, ZSH, OhMyZsh and Spaceship Promt"
  sudo apt update
  sudo apt-get install -y git git-flow curl wget zsh powerline fonts-powerline software-properties-common apt-transport-https
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --unattended"
  sudo usermod -s $(which zsh) $(whoami)
  themes="$HOME/.oh-my-zsh/custom/themes"
  git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$themes/spaceship-prompt" --depth=1
  ln -s "$themes/spaceship-prompt/spaceship.zsh-theme" "$themes/spaceship.zsh-theme"
  sed -i 's/robbyrussell/spaceship/' .zshrc
}

# Install asdf, updates terminals configs
function step_2() {
  step_title $1 "Installing ASDF extendable version manager"
  asdf_path="$HOME/.asdf"
  git clone https://github.com/asdf-vm/asdf.git ${asdf_path} --branch v0.10.2
  echo ". $asdf_path/asdf.sh" >> ~/.bashrc
  echo ". $asdf_path/completions/asdf.bash" >> ~/.bashrc
  source ~/.bashrc
  echo ". $asdf_path/asdf.sh" >> ~/.zshrc
}

# Install asdf ruby plugin, requiered system dependencies, mri ruby, asdf config
function step_3() {
  step_title $1 "Installing ASDF Ruby plugin, build system dependencies, MRI Ruby $target_ruby_version"
  default_gems_config="$HOME/.default-gems"
  echo -n "" > ${default_gems_config}
  printf %"s\n" bundler pry gem-ctags yard > ${default_gems_config}
  asdf_config="$HOME/.asdfrc"
  $(asdf plugin add ruby)
  sudo apt-get install -y make cmake gcc libssl-dev libreadline-dev zlib1g-dev
  echo -n "" > ${asdf_config}
  echo "legacy_version_file = yes" >> ${asdf_config}
  $(asdf install ruby $target_ruby_version)
  $(asdf global ruby $target_ruby_version)
}

# Install Postgres and requiered system dependencies
function step_4() {
  step_title $1 "Installing Postgres and requiered system dependencies"
  sudo apt-get install -y postgresql libpq-dev
}

# Install vscode
function step_5() {
  step_title $1 "Installing Visual Studio Code"
  wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
  sudo add-apt-repository -y "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
  sudo apt install -y code
}

# Configure git
function step_6() {
  step_title $1 "Configuring git"
  wget https://raw.githubusercontent.com/RubyWorkout/frs/master/.gitignore_global
  credentials="$HOME/.my-credentials"
  echo -n "" > ${credentials}
  echo "https://${git_username}:${git_token}@github.com" >> ${credentials}
  git config --global user.email ${email}
  git config --global user.name ${name}
  git config --global credential.helper "store --file ${credentials}"
  git config --global alias.ignore "update-index --skip-worktree"
  git config --global alias.unignore "update-index --no-skip-worktree"
  git config --global alias.ignored "!git ls-files -v | grep \"^S\""
  git config --global core.editor nano
  git config --global core.excludesfile "$HOME/.gitignore_global"
  git config --global pull.rebase false
}

# Configure vscode
function step_7() {
  step_title $1 "Configuring Visual Studio Code"
  wget https://raw.githubusercontent.com/RubyWorkout/frs/master/settings.json -P ~/.config/Code/User
}

# Add shortcuts to dock
function step_8() {
  step_title $1 "Adding favorites to dock"
  gsettings set org.gnome.shell favorite-apps "['firefox.desktop', 'firefox_firefox.desktop', 'org.gnome.Nautilus.desktop', 'snap-store_ubuntu-software.desktop', 'org.gnome.Terminal.desktop', 'code.desktop']"
}

# Reboot OS
function inform_reboot {
  echo "Rebooting your OS..."
  sudo shutdown -r now
}

# Step runner
function run_step() {
  if ! eval "step_$1 $1"; then steps_errors+=($1)
  fi
}

# Failed steps summary
function print_fails_steps {
  printf -v joined '%s, ' "${steps_errors[@]}"
  echo "${red}Failed number of step(s): ${joined%,*} ${reset}"
}

# Steps list iterator
for s in $(seq 1 $final_step_index)
do
  ((steps_counter++))
  if eval "run_step $s"
    then echo "${green}$steps_counter of $final_step_index steps is done!${reset}"
  else echo "${red}Step $steps_counter fails.${reset}"
  fi
done

# Print out final result message
if [[ ${#steps_errors[@]} == 0 ]]
  then
  echo "${green}Congrats, your Ruby developer environment is ready${reset} 🚀"
  inform_reboot
else print_fails_steps
fi
