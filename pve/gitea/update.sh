

function update_script() {
   if [[ ! -f /usr/local/bin/gitea ]]; then
      msg_error "No ${APP} Installation Found!"
      exit
   fi
   RELEASE=$(curl -fsSL https://github.com/go-gitea/gitea/releases/latest | grep "title>Release" | cut -d " " -f 4 | sed 's/^v//')
   msg_info "Updating $APP to ${RELEASE}"
   curl -fsSL "https://github.com/go-gitea/gitea/releases/download/v$RELEASE/gitea-$RELEASE-linux-amd64" -o $(basename "https://github.com/go-gitea/gitea/releases/download/v$RELEASE/gitea-$RELEASE-linux-amd64")
   systemctl stop gitea
   rm -rf /usr/local/bin/gitea
   mv gitea* /usr/local/bin/gitea
   chmod +x /usr/local/bin/gitea
   systemctl start gitea
   msg_ok "Updated $APP Successfully"
   exit
}