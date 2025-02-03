---
tags:
  - reference
---
# :construction: Development

The development of my homelab is mainly done by watching YouTube videos and occasionally browsing Reddit.

## :twisted_rightwards_arrows: Workflow

1. Create VM or LXC.
2. Run setup playbook.
3. Add to lxcAll inventory.
4. Clone and log into homelab repo on container.
5. Setup app.
6. Add to AdGuardHome.
7. Run AdGuardHome sync.
8. Add to Traefik.
9. Add to homepage.
10. Add to homelab docs.
11. Add to WatchYourLAN.
12. Add to Beszel.

## :page_facing_up: New Document Pages

New pages for this site can be created using [jinja2][3] and the `.template.md.j2` file.

!!! quote "Create new page"

    ```shell
    jinja2 .template.md.j2 -D app_name="New App" -D app_port=8080 -D config_path=/opt/new-app > new-app.md
    ```

## :link: References

[3]: <../tools/jinja2-cli.md>
