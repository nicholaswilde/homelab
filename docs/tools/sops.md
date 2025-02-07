---
tags:
 - tool
---
# :key: SOPS

[SOPS][1] is used to encrypt and decrypt secrets in my homelab.

Typically, my secrets are kept in `.env` files that are read as environmental variables and then used my configs.

[age][2] is my encryption of choice.

## :hammer_and_wrench: Installation

!!! quote ""

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

!!! quote ""

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

    === "Manual"
    
        ```yaml
        ---
        creation_rules:
          - filename_regex: \.yaml$
            age: 'age1x2at6wwq2gks47fsep9a25emdeqd93e3k0gfsswtmhruqrteu5jqjvy7kd'
          - filename_regex: \.db$
            age: 'age1x2at6wwq2gks47fsep9a25emdeqd93e3k0gfsswtmhruqrteu5jqjvy7kd'
        ```

## :pencil: Usage

### :lock: Encrypt

!!! quote ""

    === ".env"
    
        ```shell
        sops -e .env > .env.enc
        ```

### :closed_lock_with_key: Decrypt

!!! quote ""

    === ".env"
    
        ```shell
        sops -d --input-type dotenv --output-type dotenv .env.enc
        ```

## :link: References

[1]: <https://getsops.io/>
[2]: <https://github.com/FiloSottile/age>
