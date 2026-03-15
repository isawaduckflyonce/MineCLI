#!/bin/bash

# Colored output
RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
BLU='\033[0;34m'
RST='\033[0m'

function red() {
  echo -e "${RED}$1${RST}"
}
function grn() {
  echo -e "${GRN}$1${RST}"
}
function ylw() {
  echo -e "${YLW}$1${RST}"
}
function blu() {
  echo -e "${BLU}$1${RST}"
}

# Java installation
function install_java() {
  echo "Options:"
  echo " [Y] Install 'openjdk-8-jre'"
  echo " [N] Do not install (abort)"
  echo " [C] Show the command first"
  while true; do
    read -rp "Install 'openjdk-8-jre'? [Y/n/c]: " choice
    choice=${choice:-Y}

    case "$choice" in
      y|Y )
        grn "Installing..."
        sudo apt install openjdk-8-jre -y > /dev/null 2>&1
        break
        ;;
      n|N )
        echo "Skipping installation."
        break
        ;;
      c|C )
        blu "'sudo apt install openjdk-8-jre -y'"
        ;;
      * )
        ylw "Please enter Y, N, C or E."
        ;;
    esac
  done
}

# Setting the Java Environment Variables
function set_env_var() {
  java_path=$(readlink -f "$(which java)" | sed "s:bin/java::")

  if grep -q "JAVA_HOME=${java_path}" ~/.bashrc; then
    grn "Java environment variables are already set up."
  else
    echo "The following lines will be added to into '.bashrc':"
    blu "export JAVA_HOME=${java_path}"
    blu "export PATH=\$PATH:\$JAVA_HOME/bin"

    while true; do
      read -rp "Do you want to continue? [Y/n]: " choice
      choice=${choice:-Y}

      case "$choice" in
        y|Y )
          if [ ! -w ~/.bashrc ]; then
            red "You do not have write permissions to your '.bashrc' file, consider modifying it manually."
            exit 1
          fi

          echo "export JAVA_HOME=${java_path}" >> ~/.bashrc
          echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> ~/.bashrc
          source "$HOME/.bashrc"
          break
          ;;
        n|N )
          echo "Bye!"
          exit 0
          ;;
        * )
          ylw "Please enter Y or N."
          ;;
      esac
    done
  fi
}

# Select minecraft version
function select_version() {
  while true; do
    read -rp "Select the Minecraft version [1.0 - 1.16]: " version
    if [[ $version =~ ^1\.([0-9]+)(\.[0-9]+)?$ ]]; then
      major=$(echo "$version" | cut -d. -f2)
      if (( major > 12 )); then
        ylw "Versions above 1.12 are not necessarily supported by Mine-CLI."
        echo "Recommended versions: 1.7 – 1.12"
        while true; do
          read -rp "Continue anyway? [y/N]: " choice
          choice=${choice:-N}
          case "$choice" in
            y|Y )
              MC_VERSION="$version"
              grn "Selected version: $MC_VERSION"
              break 2
              ;;
            n|N )
              ylw "Please select another version."
              break
              ;;
            * )
              ylw "Please enter Y or N."
              ;;
          esac
        done;
      else
        MC_VERSION="$version"
        grn "Selected version: $MC_VERSION"
        break
      fi
    else
      red "Invalid version format. Example: 1.12.2"
    fi
  done
}

clear
echo
grn "██████   ██████  ███                                    ████████  █████       █████"
grn "░░██████ ██████  ░░░                                   ███░░░░░███░░███       ░░███"
grn " ░███░█████░███  ████  ████████    ██████             ███     ░░░  ░███        ░███"
grn " ░███░░███ ░███ ░░███ ░░███░░███  ███░░███ ██████████░███          ░███        ░███"
grn " ░███ ░░░  ░███  ░███  ░███ ░███ ░███████ ░░░░░░░░░░ ░███          ░███        ░███"
grn " ░███      ░███  ░███  ░███ ░███ ░███░░░             ░░███     ███ ░███      █ ░███"
grn " █████     █████ █████ ████ █████░░██████             ░░█████████  ███████████ █████"
grn "░░░░░     ░░░░░ ░░░░░ ░░░░ ░░░░░  ░░░░░░               ░░░░░░░░░  ░░░░░░░░░░░ ░░░░░"
echo -e "\n # Welcome to the Mine-CLI installer.\n"

sleep 1

# Check for java 8 installation
grn "=============================="
echo "        Java installer"
grn "=============================="
echo "Checking for Java..."

if which java > /dev/null 2>&1; then
  grn "There is a java installation on your system."
  echo "Checking for java 8..."

  if java -version 2>&1 | grep -q -E 'openjdk version "1.8'; then
    grn "Java 8 is already installed on your system."
  else
    echo "Java 8 is not installed on your system."
    install_java
  fi
else
  red "No Java installations found.\n"
  install_java
fi

# Setting the Java Environment Variables
set_env_var
grn "Java 8 has been successfully installed and environment variables are set!\n"

# Server jar installer
grn "================================"
echo "        Server installer"
grn "================================"
select_version

echo "One of the following server jar files will be installed."
echo " [1] "
