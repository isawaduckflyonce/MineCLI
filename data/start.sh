#!/bin/bash

JAR_FILE=$(ls ./1.*.*.jar | head -n 1) # Picks the first .jar in the folder
XMS=1G # Minimum RAM
XMX=4G # Maximum RAM

if [ ! -f "$JAR_FILE" ]; then
  echo "Error: No Minecraft server .jar found in this directory."
  exit 1
fi

if [ ! -f eula.txt ]; then
  echo "eula=true" > eula.txt
  echo "Created eula.txt and accepted the EULA automatically."
fi

if [ ! -f server.properties ]; then
  cat <<EOL > server.properties
# Minecraft server properties

server-name=Local Minecraft Server
motd=Local Minecraft Server
max-players=4
online-mode=false
difficulty=3
gamemode=0

server-ip=
server-port=25565
view-distance=12
EOL
  echo "Created default server.properties."
fi

# --- START SERVER ---
echo "Starting Minecraft server from $JAR_FILE..."
java -Xms$XMS -Xmx$XMX -jar "$JAR_FILE" nogui