return {
    setup = function()
        local original_entity_click = Entity.click
        local last_time = 0
        local last_url = nil

        function Entity:click(event, up)
            if up then return end
            if event.is_right or event.is_middle then
                return original_entity_click(self, event, up)
            end

            ya.emit("reveal", { self._file.url })
            local now = ya.time()
            local url = tostring(self._file.url)

            if (now - last_time < 0.5) and (url == last_url) then
                self.last_time = 0
                self.last_url = nil
                if self._file.cha.is_dir then
                    ya.emit("enter", {})
                else
                    ya.emit("open", { self._file.url })
                end
                return
            end

            last_time = now
            last_url = url
            original_entity_click(self, event, up)
        end
    end,
}