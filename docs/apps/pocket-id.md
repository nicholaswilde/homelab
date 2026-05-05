---
tags:
  - lxc
  - proxmox
---
# ![Pocket ID](https://github.com/pocket-id.png){ width="32" } Pocket ID

[Pocket ID][1] is a self-hosted authentication service designed to provide OIDC (OpenID Connect) authentication for various applications and services.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `1411`
    :material-information-outline: Configuration path: `/opt/pocket-id/.env`

!!! warning

    Pocket ID **requires HTTPS** to function correctly. Ensure you use a reverse proxy with a valid SSL certificate.

!!! code ""

    === "AMD64"

        ```shell
        bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/pocket-id.sh)"
        ```

## :gear: Config

### Gitea OIDC Configuration

#### 1. Pocket ID Setup
1. **Create Client:** Create a new OIDC client named **Gitea**.
2. **Callback URL:** Set to `https://<Gitea Host>/user/oauth2/PocketID/callback`.
3. **Credentials:** Copy the **Client ID**, **Client Secret**, and **OIDC Discovery URL**.

#### 2. Gitea Setup
1. **Admin Login:** Log in to Gitea as an administrator.
2. Go to **Site Administration** → **Identity & Access** → **Authentication Sources**.
3. Click **Add Authentication Source**.
4. Configure Fields:
    * **Authentication Type:** OAuth2
    * **Authentication Name:** `PocketID`
    * **OAuth2 Provider:** OpenID Connect
    * **Client ID (Key):** Paste the Client ID.
    * **Client Secret:** Paste the Client Secret.
    * **OpenID Connect Auto Discovery URL:** Paste the OIDC Discovery URL.
5. Enable **Skip local 2FA**.
6. Set **Additional Scopes** to `openid email profile`.
7. Save the settings and test the login.

### Immich OIDC Configuration

#### 1. Pocket ID Setup
1. **Create Client:** Create a new OIDC client (e.g., named `immich`).
2. **Callback URLs:** Add the following three URLs:
    * `https://<IMMICH-DOMAIN>/auth/login`
    * `https://<IMMICH-DOMAIN>/user-settings`
    * `app.immich:///oauth-callback`
3. **Credentials:** Copy the **Client ID**, **Client Secret**, and **OIDC Discovery URL**.

#### 2. Immich Setup
1. In Immich, go to **Administration** > **Settings** > **Authentication Settings** > **OAuth**.
2. Enable **Login with OAuth**.
3. Configure Fields:
    * **Issuer URL:** Paste the OIDC Discovery URL.
    * **Client ID:** Paste the Client ID.
    * **Client Secret:** Paste the Client Secret.
4. **Button Text (Optional):** Change to `Login with Pocket ID`.
5. Save the settings and test the login.

## :link: References

- <https://pocket-id.org/>
- <https://pocket-id.org/docs/client-examples>

[1]: <https://pocket-id.org/>
