-- Map syslog priority/severity to log level
-- Syslog severity levels (from RFC 3164/5424):
-- 0 = Emergency, 1 = Alert, 2 = Critical, 3 = Error
-- 4 = Warning, 5 = Notice, 6 = Informational, 7 = Debug

function map_syslog_level(tag, timestamp, record)
    local pri = tonumber(record["pri"])

    if pri then
        -- Extract severity from priority (severity = pri % 8)
        local severity = pri % 8

        -- Map severity number to log level string
        local level_map = {
            [0] = "emergency",
            [1] = "alert",
            [2] = "critical",
            [3] = "error",
            [4] = "warning",
            [5] = "notice",
            [6] = "info",
            [7] = "debug"
        }

        record["level"] = level_map[severity] or "info"
    else
        record["level"] = "info"
    end

    -- Set 'time' field in ISO8601 format
    record["time"] = os.date("!%Y-%m-%dT%H:%M:%SZ", timestamp)

    -- Keep hostname from syslog
    if record["host"] and record["host"] ~= "-" then
        record["hostname"] = record["host"]
    end

    -- Use ident (program name) as service if available
    if not record["service"] and record["ident"] and record["ident"] ~= "-" then
        record["service"] = record["ident"]
    elseif not record["service"] and record["hostname"] then
        record["service"] = record["hostname"]
    else
        record["service"] = "syslog"
    end

    -- Clean up fields
    record["pri"] = nil
    record["ident"] = nil
    record["host"] = nil

    return 1, timestamp, record
end
