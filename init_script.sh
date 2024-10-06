#!/bin/bash

# Enable debug mode for detailed logging
set -ex
exec > >(tee -a /tmp/output.log) 2>&1

# Step 1: Update system and install required dependencies
sudo apt-get update -y
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    libx11-6 \
    libx11-dev \
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    libpulse0 \
    qemu-kvm \
    libxkbcommon-x11-0 \
    libxkbcommon-x11-dev \
    libnss3 \
    libxkbfile1 \
    libxi6 \
    unzip \
    vim \
    openjdk-17-jdk

# Step 2: Install Java
wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.8+7/OpenJDK17U-jdk_x64_linux_hotspot_17.0.8_7.tar.gz
tar -xzf OpenJDK17U-jdk_x64_linux_hotspot_17.0.8_7.tar.gz
sudo mv jdk-17.0.8+7 /usr/local/jdk-17-temurin

# Export JAVA_HOME and add to PATH
export JAVA_HOME=/usr/local/jdk-17-temurin
export PATH=$PATH:$JAVA_HOME/bin

# Step 3: Install Android SDK
mkdir -p /opt/android-sdk/cmdline-tools
curl -o sdk-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
unzip sdk-tools.zip -d /opt/android-sdk/cmdline-tools
mv /opt/android-sdk/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest

# Export ANDROID_SDK_ROOT and update PATH
export ANDROID_SDK_ROOT=/opt/android-sdk
export PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_SDK_ROOT/emulator
export PATH=$PATH:$ANDROID_SDK_ROOT/platform-tools
export PATH=$PATH:$ANDROID_SDK_ROOT/build-tools/33.0.2

# Install Android SDK components
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.2"
sdkmanager "system-images;android-31;google_apis;x86_64"
sdkmanager "emulator"

# Step 4: Create Android AVD
avdmanager create avd -n Pixel_6_Android_12 -k "system-images;android-31;google_apis;x86_64" -d pixel_6
emulator -avd Pixel_6_Android_12 -no-window -no-audio -gpu swiftshader_indirect &

# Step 5: Install Node.js manually using tar.gz
curl -O https://nodejs.org/dist/v20.17.0/node-v20.17.0-linux-x64.tar.xz
tar -xf node-v20.17.0-linux-x64.tar.xz
sudo mv node-v20.17.0-linux-x64 /usr/local/node-v20.17.0

# Export Node.js to PATH
export PATH=$PATH:/usr/local/node-v20.17.0/bin

# Step 6: Verify Java installation
java -version  # Should show the installed version of Temurin JDK 17

# Step 7: Verify Node.js installation
node -v  # Should output v20.17.0
npm -v   # Should output the corresponding npm version
npm install -g appium
appium -p 4723 &  # Start Appium server on default port 4723
sleep 5

# Step 8: Install Selenium Grid and WebDrivers

# Download Selenium standalone server
wget https://github.com/SeleniumHQ/selenium/releases/download/selenium-4.12.0/selenium-server-4.12.0.jar
sudo mkdir -p /opt/selenium
sudo mv selenium-server-4.12.0.jar /opt/selenium/selenium-server.jar

# Start Selenium Hub
java -jar /opt/selenium/selenium-server.jar hub --port 4444 > /tmp/selenium-hub.log 2>&1 &
sleep 10

# Step 9: Configure Selenium Nodes with Appium

# Node 1 - Start Selenium Node with Appium server
java -jar /opt/selenium/selenium-server.jar node --port 5555 --max-sessions 5 --hub http://localhost:4444 --browser "browserName=firefox,maxInstances=2" > /tmp/selenium-node1.log 2>&1 &
appium -p 4725 &  # Appium server on different port for Node 1
sleep 10

# Node 2 - Start Selenium Node with Appium server
java -jar /opt/selenium/selenium-server.jar node --port 5556 --max-sessions 5 --hub http://localhost:4444 --browser "browserName=firefox,maxInstances=2" > /tmp/selenium-node2.log 2>&1 &
appium -p 4726 &  # Appium server on different port for Node 2
sleep 10

# Step 10: Verify Selenium Grid setup
curl http://localhost:4444/status  # Should return the Grid status
ps aux | grep selenium  # Check if the processes are running
ps aux | grep appium  # Check if both Appium servers are running

echo "Selenium Grid Hub and Nodes with Appium servers are running successfully."
