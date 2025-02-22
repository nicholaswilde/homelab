#!/usr/bin/env bash

function update_script() {

  if [[ ! -f /etc/systemd/system/changedetection.service ]]; then
    echo "No ${APP} Installation Found!"
    exit 1
  fi

  if ! dpkg -s libjpeg-dev >/dev/null 2>&1; then
    echo "Installing Dependencies"
    apt-get update
    apt-get install -y libjpeg-dev
    echo "Updated Dependencies"
  fi

  pipx install changedetection.io --upgrade

  pipx install playwright --upgrade

  if [[ -f /etc/systemd/system/browserless.service ]]; then
    echo "Updating Browserless (Patience)"
    git -C /opt/browserless/ fetch --all &>/dev/null
    git -C /opt/browserless/ reset --hard origin/main
    npm update --prefix /opt/browserless
    /opt/browserless/node_modules/playwright-core/cli.js install --with-deps
    # Update Chrome separately, as it has to be done with the force option. Otherwise the installation of other browsers will not be done if Chrome is already installed.
    # /opt/browserless/node_modules/playwright-core/cli.js install --force chrome &>/dev/null
    /opt/browserless/node_modules/playwright-core/cli.js install chromium firefox webkit
    npm run build --prefix /opt/browserless
    npm run build:function --prefix /opt/browserless
    npm prune production --prefix /opt/browserless
    systemctl restart browserless
    echo "Updated Browserless"
  else
    echo "No Browserless Installation Found!"
  fi

  systemctl restart changedetection
  echo "Updated Successfully"
  exit
}

update_script
