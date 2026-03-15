#!/bin/bash

MC_SERVER=""
MC_VERSION=""

#Minecraft versions
versions="\
 1.0.0 1.0.1\
 1.1.0\
 1.2.1 1.2.2 1.2.3 1.2.4 1.2.5\
 1.3.1 1.3.2\
 1.4.2 1.4.4 1.4.5 1.4.6 1.4.7\
 1.5 1.5.1 1.5.2\
 1.6.1 1.6.2 1.6.4\
 1.7.2 1.7.4 1.7.5 1.7.6 1.7.7 1.7.8 1.7.9 1.7.10\
 1.8 1.8.1 1.8.2 1.8.3 1.8.4 1.8.5 1.8.6 1.8.7 1.8.8 1.8.9\
 1.9 1.9.1 1.9.2 1.9.3 1.9.4\
 1.10 1.10.1 1.10.2\
 1.11 1.11.1 1.11.2\
 1.12 1.12.1 1.12.2 "

versions_extra="\
 1.13 1.13.1 1.13.2\
 1.14 1.14.1 1.14.2 1.14.3 1.14.4\
 1.15 1.15.1 1.15.2\
 1.16 1.16.1 1.16.2 1.16.3 1.16.4 1.16.5 "

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
  echo " [Y] Install 'openjdk-8-jre' *"
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

# Select server type
function select_type() {
  echo "Please choose the type of server you'd like to install:"
  echo " [1] Vanilla server * (Standard Minecraft experience)"
  echo " [2] Optifine server (Optimized for performance and graphics)"
  echo " [3] Forge server (For mods and custom content)"
  echo " [4] Custom server (Advanced users with custom setup)"
  echo " [5] Skip server download (If you already have a server jar file)"

  while true; do
    read -rp "Enter the number corresponding to your choice (1-5): " choice
    choice=${choice:-1}

    case "$choice" in
      1 )
        grn "You selected the Vanilla server."
        MC_SERVER="Vanilla"
        break
        ;;
      2 )
        grn "You selected the Optifine server."
        MC_SERVER="Optifine"
        break
        ;;
      3 )
        grn "You selected the Forge server."
        MC_SERVER="Forge"
        break
        ;;
      4 )
        ylw "You selected the Custom server."
        MC_SERVER="Custom"
        break
        ;;
      5 )
        ylw "You chose to skip the server download."
        MC_SERVER="None"
        break
        ;;
      * )
        echo "Invalid choice, please enter a number between [1-5]. Try again."
        ;;
    esac
  done
}

# Select minecraft version
function check_version() {
  local major="$1"
  local minor="$2"

  if [ -n "$minor" ]; then
    local input="1.${major}.${minor}"
  else
    local input="1.${major}"
  fi

  # Check if version exists by matching full version or major version
  found="false"
  echo "$versions" | grep -E " $input " > /dev/null && found="true"
  [[ $found = "false" ]] && echo "$versions_extra" | grep -E " $input " > /dev/null && found="true"

  if [[ $found = "true" ]] > /dev/null; then
    echo "Version $input found."
    return 0
  else
    echo "Version $input not found."
    return 1
  fi
}

# Select a valid version
function select_version() {
  while true; do
    read -rp "Select the Minecraft version [1.0 - 1.16]: " version

    if [[ $version =~ ^1\.([0-9]+)(\.[0-9]+)?$ ]]; then
      major=$(echo "$version" | cut -d. -f2)
      minor=$(echo "$version" | cut -d. -f3)

      # Check if version exists
      if ! check_version "$major" "$minor"; then
        continue
      fi

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
      red "Invalid version format. Example: 1.12.2, 1.9, 1.0.0"
    fi
  done
}

function install_serer() {

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
grn  "=============================="
echo "        Java installer"
grn  "=============================="
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
grn  "================================"
echo "        Server installer"
grn  "================================"
select_type
select_version

install_server