# yazi-gooey
Collections of plugins making yazi sort of hybrid, behaving a bit more like classic GUI explorers

double-click opens a folder by double clicking it, allowing mouse navigation. Very simple !

right-click-menu opens a menu (similar to pressing O), with some options from your .desktop files.
Works, but needs some improvements !

# Installation

place the plugin folders in the `~/.config/yazi/plugins/` folder.
Then load them in `~/.config/yazi/init.lua`:

```
require("double-click"):setup()
require("right-click-menu"):setup {
  terminal = "<TERMINAL>",
}
```

Replace `<TERMINAL>` with your favourite terminal emulator!
