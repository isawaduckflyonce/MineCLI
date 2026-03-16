#!/bin/bash

MC_SERVER=""
MC_SERVER_FILE=""

# Colored output
RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
BLU='\033[0;34m'
RST='\033[0m'

### COLORED OUTPUT ###
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
######################

### Java installation ###
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
        sudo apt install openjdk-8-jre -y > /dev/null 2>&1 || {
          echo "Installation failed, exiting."
          exit 1
        }
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
#########################

### Server installation ###
# Select server type
function select_type() {
  echo "Please choose the type of server you'd like to install:"
  echo " [1] Vanilla server * (Standard Minecraft experience)"
  echo " [2] OptiFine server (Optimized for performance and graphics)"
  echo " [3] Forge server (For mods and custom content)"
  echo " [4] Custom server (Advanced users with custom setup)"
  echo " [5] Skip server download (If you already have a server jar file)"

  while true; do
    read -rp "Enter the number corresponding to your choice (1-5): " choice
    choice=${choice:-1}

    echo
    case "$choice" in
      1 )
        grn "You selected the Vanilla server."
        MC_SERVER="Vanilla"
        break
        ;;
      2 )
        grn "You selected the OptiFine server."
        MC_SERVER="OptiFine"
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

# Select a valid version
function list_servers() {
  local servers
  servers="$(dirname "${BASH_SOURCE[0]}")/data/Servers"

  [[ -d "$servers" ]] || {
    red "Servers directory was not found, aborting."
    exit 1
  }

  [[ ! "$(ls -A "$servers/$1")" ]] && {
    red "No files for $1 servers were found, aborting."
    exit 1
  }

  shopt -s nullglob
  local i=0
  for version in $(printf '%s\n' "$servers/$1"/*.jar | sort -V); do
    i=$((i + 1))
    printf " [%2d] %s - %s\n" "$i" "$MC_SERVER" "$(basename -s .jar "$version")"

    # Save paths to tempfile
    echo "$version" >> "$2"
  done
  shopt -u nullglob
}

# Select a server from the server list
function select_server() {
  local max
  max=$( wc -l < "$1" )
  local choice

  while true; do
    read -rp "Select a server [1-$max]: " choice

    [[ "$choice" =~ ^[0-9]+$ ]] || {
      ylw "Please enter a valid number."
      continue
    }

    (( choice >= 1 && choice <= max )) || {
      ylw "Please select a number between 1 and $max."
      continue
    }

    # Get selected jar path
    MC_SERVER_FILE=$(head -n "$choice" "$TMPFILE" | tail -n 1)
    grn "Selected server: $MC_SERVER - $(basename -s .jar "$MC_SERVER_FILE")"
    break
  done
}

function select_version() {
  local TMPFILE
  TMPFILE=$( mktemp )

  echo -e "\nAvailable $MC_SERVER server versions:"
  case "$MC_SERVER" in
    "Vanilla")
      list_servers "Vanilla" "$TMPFILE"
      select_server "$TMPFILE"
      ;;
    "Forge")
      list_servers "Forge" "$TMPFILE"
      select_server "$TMPFILE"
      ;;
    "OptiFine")
      list_servers "OptiFine" "$TMPFILE"
      select_server "$TMPFILE"
      ;;
    # TODO: Handle custom server files
  esac

  rm -f "$TMPFILE"
}

function install_server() {
  echo "Creating server folder..."

  local FOLDER_PATH
  FOLDER_PATH="$(dirname "${BASH_SOURCE[0]}")/minecraft/$MC_SERVER-$(basename -s .jar "$MC_SERVER_FILE")"
  local i=0

  [[ -d "$FOLDER_PATH" ]] && ylw "A server of the same type and version already exists."

  while [[ -d "$FOLDER_PATH" ]]; do
    i=$(( i + 1 ))
    FOLDER_PATH="$(dirname "${BASH_SOURCE[0]}")/minecraft/$MC_SERVER-$(basename -s .jar "$MC_SERVER_FILE")($i)"
  done

  mkdir -p "$FOLDER_PATH"
  grn "Server folder created successfully, you can find it at '$FOLDER_PATH'"

  cp "$MC_SERVER_FILE" "$FOLDER_PATH/$(basename "$MC_SERVER_FILE")"
  grn "Server jar file moved to '$FOLDER_PATH'"

  # Start script for the server
  # TODO: Ask user for launch args.
  cat > "$FOLDER_PATH/start.sh" << 'EOF'
#!/bin/bash
java -Xmx2G -Xms1G -jar server.jar nogui
EOF

  chmod u+x "$FOLDER_PATH/start.sh"
  grn "Start script created at '$FOLDER_PATH/start.sh'."
}
###########################

### Program start ###
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

if command -v java >/dev/null 2>&1; then
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