-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })
o.window("Emulator", { float = true, center = true })

-- Workaround: glycin (GTK4's sandboxed image loader) has a known bwrap/dbus
-- timeout bug on unprivileged user namespaces that stalls the whole app for
-- ~25s while loading an SVG/image icon (e.g. Lutris freezing/"not responding"
-- shortly after launch). Confirmed via gdb: the loader was stuck in a
-- zbus::Connection thread. This disables glycin's sandbox — trades away that
-- sandboxing for correctness until upstream ships the timeout fix.
hl.env("GLYCIN_DISABLE_SANDBOX", "i-know-the-risks")

-- Give ~/.local/bin priority over /usr/share/omarchy/bin so user overrides
-- of omarchy-* commands (e.g. omarchy-screensaver) win. hyprctl setenv
-- doesn't reach the keybind/dispatch-spawned env, so this has to use hl.env.
hl.env("PATH", os.getenv("HOME") .. "/.local/bin:" .. os.getenv("PATH"))
