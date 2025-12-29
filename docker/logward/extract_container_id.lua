-- Extract container ID from Docker log filepath
-- Path format: /var/lib/docker/containers/CONTAINER_ID/CONTAINER_ID-json.log

function extract_container_id(tag, timestamp, record)
    local filepath = record["filepath"]

    if filepath then
        local container_id = filepath:match("/var/lib/docker/containers/([^/]+)/")

        if container_id then
            record["container_id"] = container_id
            record["container_short_id"] = container_id:sub(1, 12)
        end
    end

    return 1, timestamp, record
end
