#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")"
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CURR_FOLDERNAME=$(basename "$PWD")
if [ $CURR_FOLDERNAME = "scripts" ]; then
  cd ..
  CURR_FOLDERNAME="$(basename "$PWD")"
fi

PROJECT_DIR="$PWD"

if [[ $(uname -m) == 'arm64' ]]; then
  echo "THis mac is arm64"
  
  echo "Checking Command Line Tools for Xcode"
  # Only run if the tools are not installed yet
  # To check that try to print the SDK path
  xcode-select -p &> /dev/null
  if [ $? -ne 0 ]; then
    echo "Command Line Tools for Xcode not found. Installing from softwareupdate…"
  # This temporary file prompts the 'softwareupdate' utility to list the Command Line Tools
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
    PROD=$(softwareupdate -l | grep "\*.*Command Line" | tail -n 1 | sed 's/^[^C]* //')
    softwareupdate -i "$PROD" --verbose;
  else
    echo "Command Line Tools for Xcode have been installed."
  fi
  xcode-select --install

  export HOMEBREW_INSTALL_FROM_API=1
  if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew"
    # Homebrew default install dir is /opt/homebrew for m1 macs
    mkdir -p /opt/homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C /opt/homebrew
    export PATH="/opt/homebrew/bin:$PATH"
  fi
  
  echo "Homebrew is installed"
  echo "Downloading node-canvas dependencies"
  brew install pkg-config cairo pango libpng
fi

if ! [ -f nodejs-mac-arm64/bin/node ]; then
  echo "Downloading NodeJS LTS (ARM64)"
  curl -o ./nodejs-mac-arm64.tar.gz --create-dirs https://nodejs.org/dist/v18.12.1/node-v18.12.1-darwin-arm64.tar.gz  
  mkdir nodejs-mac-arm64 && tar -xzf nodejs-mac-arm64.tar.gz -C nodejs-mac-arm64 --strip-components=1 && rm ./nodejs-mac-arm64.tar.gz
fi

if ! [ -f nodejs-mac-x64/bin/node ]; then
  echo "Downloading NodeJS LTS (x64)"
  curl -o ./nodejs-mac-x64.tar.gz --create-dirs https://nodejs.org/dist/v18.12.1/node-v18.12.1-darwin-x64.tar.gz     
  mkdir nodejs-mac-x64 && tar -xzf nodejs-mac-x64.tar.gz -C nodejs-mac-x64 --strip-components=1 && rm ./nodejs-mac-x64.tar.gz
fi

export CORRETTO_BASEDIR="$HOME/Library/Application Support/Purple HATS"
mkdir -p "$CORRETTO_BASEDIR" 

if ! [ -f jre/bin/java ]; then
  cd "$CORRETTO_BASEDIR" 
  if ! [ -f amazon-corretto-11.jdk.x64/Contents/Home/bin/java ]; then
      echo "Downloading Corretto (x64)"
      curl -L -o ./corretto-11.tar.gz "https://corretto.aws/downloads/latest/amazon-corretto-11-x64-macos-jdk.tar.gz"
      tar -zxf ./corretto-11.tar.gz
      rm -f ./corretto-11.tar.gz
      mv amazon-corretto-11.jdk amazon-corretto-11.jdk.x64
  else
    echo "Found Corretto (x64)"
  fi

  echo "INFO: Set path to Corretto-11 JDK"
  export JAVA_HOME="$CORRETTO_BASEDIR/amazon-corretto-11.jdk.x64/Contents/Home"
  export PATH="$JAVA_HOME/bin:$PATH"

  echo "INFO: Build JRE SE"
  cd "$PROJECT_DIR"
  jlink --output jre --add-modules java.se

fi

source "${__dir}/hats_shell.sh"

if ! [ -f verapdf/verapdf ]; then
  echo "Downloading VeraPDF"
  if [ -d "./verapdf" ]; then rm -Rf ./verapdf; fi
  if [ -d "./verapdf-installer" ]; then rm -Rf ./verapdf-installer; fi
  curl -L -o ./verapdf-installer.zip http://downloads.verapdf.org/rel/verapdf-installer.zip
  unzip -j ./verapdf-installer.zip -d ./verapdf-installer
  ./verapdf-installer/verapdf-install "${__dir}/verapdf-auto-install-macos.xml"
  cp -r /tmp/verapdf .
  rm -rf ./verapdf-installer.zip ./verapdf-installer /tmp/verapdf
  
fi

if [ -d "/Applications/Cloudflare WARP.app" ]; then
  curl -sSLJ -o "/tmp/Cloudflare_CA.pem" "https://developers.cloudflare.com/cloudflare-one/static/documentation/connections/Cloudflare_CA.pem"
  export NODE_EXTRA_CA_CERTS="/tmp/Cloudflare_CA.pem"
fi

if ! [ -f package.json ] && [ -d purple-hats ]; then
  cd purple-hats
fi

if [ -d "node_modules" ]; then
  echo "Deleting node_modules before installation"
  rm -rf node_modules 
fi

echo "Installing Node dependencies to $PWD"
npm ci --force

echo "Installing Playwright browsers"
npx playwright install webkit







