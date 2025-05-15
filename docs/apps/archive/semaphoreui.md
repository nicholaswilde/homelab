---
tags:
  - lxc
  - proxmox
---
# ![semaphoreui](https://cdn.jsdelivr.net/gh/selfhst/icons/svg/semaphore-ui.svg){ width="32" } Semaphore UI

[Semaphore UI][1] is being used as a GUI to Ansible to help manage my playbooks.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `3000`

    :material-information-outline: Configuration path: `/etc/semaphore`

    :material-file-key: Admin password: `cat ~/semaphore.creds`

    :material-database: Database: `BoltDB`

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/semaphore.sh)"
        ```

    === "ARM64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/asylumexp/Proxmox/raw/main/ct/semaphore.sh)"
        ```

## :gear: Config

Make symlinks to repo.

## :simple-authentik: [authentik][2]

!!! example "authentik GUI"

    `Applications -> Applications`

    Redirect URI: `https://semaphore.company/api/auth/oidc/authentik/redirect/`

!!! abstract "/etc/semaphore/config.json"

    === "Manual"

        ```json
        {
          "oidc_providers": {
            "authentik": {
              "display_name": "Sign in with authentik",
              "provider_url": "https://authentik.company/application/o/<slug>/",
              "client_id": "<client-id>",
              "client_secret": "<client-secret>",
              "redirect_url": "https://semaphore.company/api/auth/oidc/authentik/redirect/",
              "username_claim": "preferred_username",
              "name_claim": "preferred_username",
              "scopes": ["openid", "profile", "email"]
            }
          },
          "web_host": "/",
          ...
        }
        ```
!!! tip

    The name of the oidc_provider (e.g. `authentik`) needs to match the name on the redirect URL.

!!! tip

    If a `Not Found` error is displayed after the login, you might need to set the web_root to `/` (see https://github.com/semaphoreui/semaphore/issues/2681):

!!! abstract "`/etc/semaphore/config.json`"

    ```json
    {    
      "web_host": "/"
    }
    ```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/semaphore.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/semaphore.yaml"
    ```

## :link: References

- <https://community-scripts.github.io/ProxmoxVE/scripts?id=semaphore>
- <https://pimox-scripts.com/scripts?id=semaphore>

[1]: <https://semaphoreui.com/>
[2]: <https://docs.goauthentik.io/integrations/services/semaphore/>
