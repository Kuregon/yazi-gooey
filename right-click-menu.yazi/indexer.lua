local APPS_DIR = "/usr/share/applications"

local function list_files()
    local output, err = Command("find")
        :arg({
            APPS_DIR,
            "-maxdepth", "1",
            "-type", "f",
            "-name", "*.desktop",
            "-print0",
        }):output()

    if not output or not output.status.success then
        ya.err("Could not list desktop files: " .. tostring(err or output.stderr))
        return {}
    end

    local files = {}
    for path in output.stdout:gmatch("([^%z]+)%z") do
        files[#files + 1] = path
    end

    return files
end

local function split_semicolon_list(value)
    local items = {}
    for item in (value or ""):gmatch("([^;]+)") do
        local sanitised_item = item:match("^%s*(.-)%s*$")
        if sanitised_item ~= "" then
            items[#items + 1] = sanitised_item
        end
    end
    return items
end

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function build_index()
    local index = {}

    for _, path in ipairs(list_files()) do
        local handle = io.open(path, "r")
        if handle then
            local section
            local entry = {}

            for raw_line in handle:lines() do
                local line = trim(raw_line)
                if line ~= "" and not line:match("^[#;]") then
                    local group = line:match("^%[(.-)%]$")
                    if group then
                        section = group
                    elseif section == "Desktop Entry" then
                        local key, value = line:match("^([^=]+)=(.*)$")
                        if key then
                            entry[trim(key)] = value
                        end
                    end
                end
            end

            handle:close()

            if entry.Type == "Application"
                and entry.Hidden ~= "true"
                and entry.Exec
                and entry.MimeType
            then
                local mimes = split_semicolon_list(entry.MimeType)
                for _, mime in ipairs(mimes) do
                    local handlers = index[mime]
                    if not handlers then
                        handlers = {}
                        index[mime] = handlers
                    end

                    handlers[#handlers + 1] = {
                        name = entry.Name or entry.Exec,
                        exec = entry.Exec,
                        terminal = entry.Terminal == "true",
                    }
                end
            end
        end
    end

    return index
end

return {
    build_index = build_index
}
