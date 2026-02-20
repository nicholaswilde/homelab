---
tags:
 - tool
---
# :key: SOPS

[SOPS][1] is used to encrypt and decrypt secrets in my homelab.

Typically, my secrets are kept in `.env` files that are read as environmental variables and then used my configs.

Other files are encrypted that have secrets, such as yaml config or sqlite db files.

[age][2] is my encryption of choice.

## :hammer_and_wrench: Installation

!!! code ""

    === "reprepro"

        ```shell
        apt install sops
        ```
        
    === "brew"
    
        ```shell
        brew install sops
        ```

## :gear: Config

### :key: Keys

!!! abstract "~/.config/sops/age/keys.txt"

    === "SCP"

        ```shell
        (
          [ -d ~/.config/sops/age ] || mkdir -p ~/.config/sops/age
          scp nicholas@192.168.2.250/home/nicholas/.config/sops/age/keys.txt ~/.config/sops/age/
        )
        ```

    === "LastPass"

        ```shell
        (
          [ -d ~/.config/sops/age ] || mkdir -p ~/.config/sops/age
          lpass show sops-age --attach=att-2571789250549588435-38084 -q > ~/.config/sops/age/keys.txt
        )
        ```

!!! abstract ".sops.yaml"

    === "Automatic"
        ```bash
        cat <<EOF > .sops.yaml
        ---
        creation_rules:
          - filename_regex: (\.ya?ml|\.db|\.env|\.json|\.ini|\.toml)$
            pgp: '78E2E084522FB8A14C0D9AED800C8DB8B299A622'
            age: 'age1x2at6wwq2gks47fsep9a25emdeqd93e3k0gfsswtmhruqrteu5jqjvy7kd'
        EOF
        ```

    === "Download"

        ```bash
        curl -LO https://github.com/nicholaswilde/homelab/raw/refs/heads/main/.sops.yaml
        ```
        
    === "Manual"
    
        ```yaml
        ---
        creation_rules:
          - filename_regex: (\.ya?ml|\.db|\.env|\.json|\.ini|\.toml)$
            pgp: '78E2E084522FB8A14C0D9AED800C8DB8B299A622'
            age: 'age1x2at6wwq2gks47fsep9a25emdeqd93e3k0gfsswtmhruqrteu5jqjvy7kd'
        ```

## :pencil: Usage

### :lock: Encrypt

!!! code ""

    === "task"

        ```shell
        task encrypt
        ```
        
    === ".env"
    
        ```shell
        sops -e .env > .env.enc
        ```

### :closed_lock_with_key: Decrypt

!!! code ""

    === "task"

        ```shell
        task decrypt
        ```
        
    === ".env"
    
        ```shell
        sops -d --input-type dotenv --output-type dotenv .env.enc > .env
        ```

## :link: References

[1]: <https://getsops.io/>
[2]: <https://github.com/FiloSottile/age>