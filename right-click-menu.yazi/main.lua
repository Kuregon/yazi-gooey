local indexer = require(".indexer")
local MAX_ITEMS = 20

local function shell_quote(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

local set_index = ya.sync(function(state, idx)
    state.index = idx
end)

local get_index = ya.sync(function(state)
    return state.index
end)

local get_terminal = ya.sync(function(state)
	return state.terminal
end)

local get_hovered = ya.sync(function()
    local h = cx.active.current.hovered
    if not h then
        return nil
    end
    return {
        name = h.name,
        url = tostring(h.url),
        is_dir = h.cha.is_dir,
    }
end)

local function mime_of(path)
    local output, err = Command("file")
        :arg({ "-bL", "--mime-type", "--", tostring(path) })
        :output()

    local mime = output and output.stdout:gsub("%s+$", "")
    return mime
end

local function build_exec(exec, path)
    local quoted = shell_quote(path)
    local replaced_file = false
    exec = exec:gsub("%%([fFuU])", function()
        replaced_file = true
        return quoted
    end)
    exec = exec:gsub("%%[ick]", "")

    if not replaced_file then
        exec = exec .. " " .. quoted
    end
    return exec
end

local function entry()
    local terminalEmulator  = get_terminal()
    local file = get_hovered()
    if not file then
        return
    end    

    local cands, actions = {}, {}
    local function add(key, desc, action)
        cands[#cands + 1] = { on = key, desc = desc }
        actions[#cands] = action
    end

    if not file.is_dir then
        local mime = mime_of(file.url)
        if mime and mime ~= "" then
            local index = get_index()
            local apps = index[mime] or {}
            for i, app in ipairs(apps) do
                if i > MAX_ITEMS then break end
                add(tostring(i), app.name or app.exec, {
                    command = build_exec(app.exec, file.url),
                    terminal = app.terminal,
                })
            end
        end
    end

    add("o", "Open", { emit = { "open", {} } })
    add("O", "Open with...", {
        emit = { "open", { interactive = true } },
    })

    local pick = ya.which { cands = cands }
    if not pick then
        return
    end

    local action = actions[pick]
    if not action then
        return
    end

    if action.emit then
        ya.emit(action.emit[1], action.emit[2])
    elseif action.command then
        if action.terminal == false then
            local child, err = Command("sh")
                :arg("-lc")
                :arg(action.command)
                :spawn()
            if not child then
                ya.err(tostring(err))
                return
            end
            child:wait()
        else
            local child, err = Command(terminalEmulator)
                :arg("start")
                :arg("--always-new-process")
                :arg("--")
                :arg("sh")
                :arg("-lc")
                :arg(action.command)
                :spawn()

            if not child then
                ya.err(tostring(err))
            end
            child:wait()
        end
    end
end

local function setup(state, options)
    local original_entity_click = Entity.click
    state.terminal = options.terminal

    local cached = get_index()
    if not cached then
        local index = indexer.build_index()
        set_index(index)
    end

    function Entity:click(event, up)
        if not event.is_right then return original_entity_click(self, event, up) end
        ya.emit("reveal", { self._file.url })
        ya.emit("plugin", { "right-click-menu" })
    end
end

return {
    entry = entry,
    setup = setup
}
