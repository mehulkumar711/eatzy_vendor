#!/usr/bin/env bash
set -e

echo "=== Install Dependencies ==="
sudo apt update
sudo apt install -y git unzip curl wget libglu1-mesa openjdk-17-jdk qemu-kvm

echo "=== Add GitHub Runner User to KVM ==="
sudo usermod -aG kvm $USER
newgrp kvm

echo "=== Install Android SDK ==="
mkdir -p $HOME/android-sdk
cd $HOME/android-sdk

# Install cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O cmdtools.zip
unzip cmdtools.zip -d cmdline-tools
mv cmdline-tools/cmdline-tools cmdline-tools/latest

export ANDROID_HOME=$HOME/android-sdk
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH

yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-31" "system-images;android-31;google_apis;x86_64" "emulator"

echo "=== Create AVD ==="
echo no | avdmanager create avd -n ci-emulator -k "system-images;android-31;google_apis;x86_64" --device "pixel_5"

echo "=== Install Flutter ==="
cd $HOME
# Use stable channel
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:$HOME/flutter/bin"

flutter doctor -v

echo "=== Self-hosted runner ready ==="
echo "To register, run:"
echo "mkdir actions-runner && cd actions-runner"
echo "curl -o actions-runner-linux-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz"
echo "tar xzf actions-runner-linux-x64-2.311.0.tar.gz"
echo "./config.sh --url https://github.com/mehulkumar711/eatzy_vendor --token <token>"
echo "sudo ./svc.sh install"
echo "sudo ./svc.sh start"
