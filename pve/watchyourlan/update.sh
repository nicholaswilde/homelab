#!/usr/bin/env bash
 
function update_script() {
  if [[ ! -f /etc/systemd/system/semaphore.service ]]; then
    echo "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/semaphoreui/semaphore/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    echo "Stopping Service"
    systemctl stop semaphore
    echo "Stopped Service"

    echo "Updating ${APP} to v${RELEASE}"
    cd /opt
    wget -q https://github.com/semaphoreui/semaphore/releases/download/v${RELEASE}/semaphore_${RELEASE}_linux_amd64.deb
    $STD dpkg -i semaphore_${RELEASE}_linux_amd64.deb
    echo "${RELEASE}" >"/opt/${APP}_version.txt"
    echo "Updated ${APP} to v${RELEASE}"

    echo "Starting Service"
    systemctl start semaphore
    echo "Started Service"

    echo "Cleaning up"
    rm -rf /opt/semaphore_${RELEASE}_linux_amd64.deb
    echo "Cleaned"
    echo "Updated Successfully"
  else
    echo "No update required. ${APP} is already at v${RELEASE}."
  fi
  exit
}

update_script