---
tags:
  - lxc
  - proxmox
  - docker
---
# ![LogWard](https://github.com/logward-dev.png){ width="32" } LogWard

[LogWard][1] is an open-source, self-hosted log management tool.

## :hammer_and_wrench: Installation

!!! example ""

    :material-console-network: Default Port: `3000`

!!! code "`homelab/docker/logward`"

    === "Task"
    
        ```shell
        task up
        ```

    === "Docker Compose"
    
        ```shell
        docker compose up
        ```

## :gear: Config

!!! abstract "`homelab/docker/logward/.env`"

    ```ini
    --8<-- "logward/.env.tmpl"
    ```

??? abstract "`homelab/docker/logward/compose.yaml`"

    ```yaml
    --8<-- "logward/compose.yaml"
    ```

## :ledger: Logging

To enable automatic log collection from other Docker containers:

1.  **Generate API Key**: Log in to LogWard, go to Project Settings, and create an API Key.
2.  **Update Config**: Add the API key to your `.env` file.

    ```ini
    FLUENT_BIT_API_KEY=lp_your_api_key_here
    ```

3.  **Create Config Files**: Ensure the following configuration files exist in your `docker/logward` directory.

    ??? abstract "fluent-bit.conf"
    
        ```ini
        # Fluent Bit Configuration for LogWard

        [SERVICE]
            # Flush logs every 5 seconds
            Flush        5
            # Run in foreground
            Daemon       Off
            # Log level (error, warning, info, debug, trace)
            Log_Level    info
            # Parsers configuration file
            Parsers_File /fluent-bit/etc/parsers.conf

        # =============================================================================
        # INPUT - Docker Container Logs
        # =============================================================================
        [INPUT]
            Name              tail
            Path              /var/lib/docker/containers/*/*.log
            Parser            docker
            Tag               docker.*
            Refresh_Interval  5
            Mem_Buf_Limit     5MB
            Skip_Long_Lines   On
            Path_Key          filepath

        # =============================================================================
        # FILTER - Parse and Enrich
        # =============================================================================
        # Extract container metadata (name, id, image)
        [FILTER]
            Name                parser
            Match               docker.*
            Key_Name            log
            Parser              docker_json
            Reserve_Data        On
            Preserve_Key        On

        # Add required fields for LogWard API
        [FILTER]
            Name                modify
            Match               docker.*
            # Set default level if not present
            Add                 level info
            # Rename 'log' field to 'message'
            Rename              log message
            # Set service name from container_name
            Copy                container_name service

        # Remove unnecessary fields to reduce log size
        [FILTER]
            Name                record_modifier
            Match               docker.*
            Remove_key          stream
            Remove_key          filepath
            Remove_key          container_name

        # =============================================================================
        # OUTPUT - Send to LogWard
        # =============================================================================
        [OUTPUT]
            Name                http
            Match               docker.*
            Host                ${LOGWARD_API_HOST}
            Port                8080
            URI                 /api/v1/ingest/single
            Format              json_lines
            Header              X-API-Key ${LOGWARD_API_KEY}
            Header              Content-Type application/json
            # Date/time settings
            Json_date_key       time
            Json_date_format    iso8601
            # Retry settings
            Retry_Limit         3
            # TLS (disable for internal Docker network)
            tls                 Off
        ```

    ??? abstract "parsers.conf"
    
        ```ini
        # Fluent Bit Parsers Configuration

        # Parser for Docker JSON logs
        [PARSER]
            Name        docker_json
            Format      json
            Time_Key    time
            Time_Format %Y-%m-%dT%H:%M:%S.%L%z
            Time_Keep   On

        # Parser for Docker container logs
        [PARSER]
            Name        docker
            Format      json
            Time_Key    time
            Time_Format %Y-%m-%dT%H:%M:%S.%L%z
            Time_Keep   On
        ```

    ??? abstract "extract_container_id.lua"
    
        ```lua
        -- Extract container ID from Docker log file path
        -- Path format: /var/lib/docker/containers/<container_id>/<container_id>-json.log

        function extract_container_id(tag, timestamp, record)
            local filepath = record["filepath"]

            if filepath == nil then
                return 0, timestamp, record
            end

            -- Extract container ID from path
            -- Example: /var/lib/docker/containers/abc123.../abc123...-json.log
            local container_id = filepath:match("/var/lib/docker/containers/([^/]+)/")

            if container_id then
                record["container_id"] = container_id
                record["container_short_id"] = container_id:sub(1, 12)
            end

            -- Return code: 1 = modified and keep, 0 = no change
            return 1, timestamp, record
        end
        ```
    
    ??? abstract "wrap_logs.lua"

        ```lua
        -- Dummy file if not provided
        function wrap_logs(tag, timestamp, record)
            return 0, timestamp, record
        end
        ```

4.  **Enable Logging**: Start the stack with the logging profile.

    !!! code ""

        === "Task"
        
            ```shell
            task up-logging
            ```
            
        === "Docker Compose"
        
            ```shell
            docker compose --profile logging up -d
            ```

## :simple-raspberrypi: Raspberry Pi

If you are running on a Raspberry Pi, the standard Fluent Bit docker image might not work because it requires a page size of 4k. The Raspberry Pi kernel often uses a page size of 16k.

To check your page size, run:

!!! code ""

    ```shell
    getconf PAGESIZE
    ```

If the output is `16384`, you must generate a custom Fluent Bit docker image with `jemalloc` support disabled.

!!! code ""

    === "Task"

        ```shell
        task build
        ```

    === "Docker"

        ```shell
        docker build -t fluent-bit-16k:latest .
        ```

Ensure that your `compose.yaml` is using the custom image:

```yaml
image: fluent-bit-16k:latest
```

## :simple-traefikproxy: Traefik

??? abstract "`homelab/pve/traefik/conf.d/logward.yaml`"

    ```yaml
    --8<-- "traefik/conf.d/logward.yaml"
    ```

## :wrench: Troubleshooting

If you are experiencing issues with log collection, follow these steps:

1.  **Verify Fluent Bit is running:**

    ```shell
    docker compose ps fluent-bit
    ```

2.  **Check Fluent Bit logs:**

    ```shell
    docker compose logs fluent-bit
    ```

3.  **Test connectivity:**

    Verify you can reach LogWard's Fluent Bit port (514) from your source device.

    ```shell
    nc -zv YOUR_LOGWARD_IP 514
    ```

4.  **Verify API Key:**

    Ensure `FLUENT_BIT_API_KEY` is correctly set in your `.env` file.

5.  **Test Syslog Manually:**

    Send a test message to verify the pipeline.

    === "UDP"

        ```shell
        echo "<14>Test syslog message from terminal" | nc -u -w1 YOUR_LOGWARD_IP 514
        ```

    === "TCP"

        ```shell
        echo "<14>Test syslog message from terminal" | nc -w1 YOUR_LOGWARD_IP 514
        ```

## :simple-task: Task List

!!! example ""

    ```yaml
    --8<-- "logward/task-list.txt"
    ```

## :link: References

- <https://github.com/logward-dev/logward>

[1]: <https://github.com/logward-dev/logward>
