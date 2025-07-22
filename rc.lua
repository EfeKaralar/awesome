--[[

     Awesome WM configuration template
     github.com/lcpz

     Modified with your personal preferences and shortcuts

--]]

-- {{{ Required libraries

-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

local gears         = require("gears")
local awful         = require("awful")
                      require("awful.autofocus")
local wibox         = require("wibox")
local beautiful     = require("beautiful")
local naughty       = require("naughty")
local lain          = require("lain")
--local menubar       = require("menubar")
local freedesktop   = require("freedesktop")
local hotkeys_popup = require("awful.hotkeys_popup")
                      require("awful.hotkeys_popup.keys")
local mytable       = awful.util.table or gears.table -- 4.{0,1} compatibility

-- }}}

-- {{{ Error handling

-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify {
        preset = naughty.config.presets.critical,
        title = "Oops, there were errors during startup!",
        text = awesome.startup_errors
    }
end

-- Handle runtime errors after startup
do
    local in_error = false

    awesome.connect_signal("debug::error", function (err)
        if in_error then return end

        in_error = true

        naughty.notify {
            preset = naughty.config.presets.critical,
            title = "Oops, an error happened!",
            text = tostring(err)
        }

        in_error = false
    end)
end

-- }}}

-- {{{ Autostart windowless processes

-- This function will run once every time Awesome is started
local function run_once(cmd_arr)
    for _, cmd in ipairs(cmd_arr) do
        awful.spawn.with_shell(string.format("pgrep -u $USER -fx '%s' > /dev/null || (%s)", cmd, cmd))
    end
end

run_once({ "urxvtd", "unclutter -root" }) -- comma-separated entries

-- This function implements the XDG autostart specification
--[[
awful.spawn.with_shell(
    'if (xrdb -query | grep -q "^awesome\\.started:\\s*true$"); then exit; fi;' ..
    'xrdb -merge <<< "awesome.started:true";' ..
    -- list each of your autostart commands, followed by ; inside single quotes, followed by ..
    'dex --environment Awesome --autostart --search-paths ' ..
    '"${XDG_CONFIG_HOME:-$HOME/.config}/autostart:${XDG_CONFIG_DIRS:-/etc/xdg}/autostart";' -- https://github.com/jceb/dex
)
--]]

-- }}}

-- {{{ Variable definitions

local themes = {
    "blackburn",       -- 1
    "copland",         -- 2
    "dremora",         -- 3
    "holo",            -- 4
    "multicolor",      -- 5
    "powerarrow",      -- 6
    "powerarrow-dark", -- 7
    "rainbow",         -- 8
    "steamburn",       -- 9
    "vertex",          -- 10
    "default",         -- 11
    "gtk",             -- 12
    "sky",             -- 13
    "xresources",      -- 14
    "zenburn"          -- 15
}

local chosen_theme = themes[4]
-- local chosen_theme = "sky"
local modkey       = "Mod4"
local altkey       = "Mod1"

-- YOUR PREFERENCES (not copycat defaults)
local terminal     = "kitty"
local terminal_cmd = terminal .. " -e "
local editor       = os.getenv("EDITOR") or "vim"
local editor_cmd   = terminal .. " -e " .. editor
local browser      = "brave"
local prompt       = "rofi -show drun"
local file_browser = "thunar"

local vi_focus     = false -- vi-like client focus https://github.com/lcpz/awesome-copycats/issues/275
local cycle_prev   = true  -- cycle with only the previously focused client or all https://github.com/lcpz/awesome-copycats/issues/274

awful.util.terminal = terminal
awful.util.tagnames = { "1", "2", "3", "4", "5", "6", "7", "8", "9" }
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.corner.nw,
    awful.layout.suit.floating,
    --lain.layout.cascade,
    --lain.layout.cascade.tile,
    --lain.layout.centerwork,
    --lain.layout.centerwork.horizontal,
    --lain.layout.termfair,
    --lain.layout.termfair.center
}

lain.layout.termfair.nmaster           = 3
lain.layout.termfair.ncol              = 1
lain.layout.termfair.center.nmaster    = 3
lain.layout.termfair.center.ncol       = 1
lain.layout.cascade.tile.offset_x      = 2
lain.layout.cascade.tile.offset_y      = 32
lain.layout.cascade.tile.extra_padding = 5
lain.layout.cascade.tile.nmaster       = 5
lain.layout.cascade.tile.ncol          = 2

awful.util.taglist_buttons = mytable.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then client.focus:move_to_tag(t) end
    end),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then client.focus:toggle_tag(t) end
    end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

awful.util.tasklist_buttons = mytable.join(
     awful.button({ }, 1, function(c)
         if c == client.focus then
             c.minimized = true
         else
             c:emit_signal("request::activate", "tasklist", { raise = true })
         end
     end),
     awful.button({ }, 3, function()
         awful.menu.client_list({ theme = { width = 250 } })
     end),
     awful.button({ }, 4, function() awful.client.focus.byidx(1) end),
     awful.button({ }, 5, function() awful.client.focus.byidx(-1) end)
)

beautiful.init(string.format("%s/.config/awesome/themes/%s/theme.lua", os.getenv("HOME"), chosen_theme))

-- }}}

-- {{{ Menu

-- Create a launcher widget and a main menu
local myawesomemenu = {
   { "Hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
   { "Manual", string.format("%s -e man awesome", terminal) },
   { "Edit config", string.format("%s -e %s %s", terminal, editor, awesome.conffile) },
   { "Restart", awesome.restart },
   { "Quit", function() awesome.quit() end },
}

awful.util.mymainmenu = freedesktop.menu.build {
    before = {
        { "Awesome", myawesomemenu, beautiful.awesome_icon },
        -- other triads can be put here
    },
    after = {
        { "Open terminal", terminal },
        -- other triads can be put here
    }
}

-- }}}

-- {{{ Screen

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", function(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end)

-- No borders when rearranging only 1 non-floating or maximized client
screen.connect_signal("arrange", function (s)
    local only_one = #s.tiled_clients == 1
    for _, c in pairs(s.clients) do
        if only_one and not c.floating or c.maximized or c.fullscreen then
            c.border_width = 0
        else
            c.border_width = beautiful.border_width
        end
    end
end)

-- Create a wibox for each screen and add it
awful.screen.connect_for_each_screen(function(s) beautiful.at_screen_connect(s) end)

-- }}}

-- {{{ Mouse bindings

root.buttons(mytable.join(
    awful.button({ }, 3, function () awful.util.mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))

-- }}}

-- {{{ Key bindings

globalkeys = mytable.join(
    -- Show help
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),

    -- Tag browsing - YOUR STYLE
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    -- Window focus - YOUR VIM-STYLE NAVIGATION
    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),

    -- Layout manipulation - YOUR STYLE
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            if cycle_prev then
                awful.client.focus.history.previous()
            else
                awful.client.focus.byidx(-1)
            end
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "cycle with previous/go back", group = "client"}),

    -- Master width factor - YOUR STYLE
    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey, "Control" }, "n", function ()
        local c = awful.client.restore()
        -- Focus restored client
        if c then
            c:emit_signal("request::activate", "key.unminimize", {raise = true})
        end
    end, {description = "restore minimized", group = "client"}),

    -- Dropdown application (keep copycat feature)
    awful.key({ modkey, }, "z", function () awful.screen.focused().quake:toggle() end,
              {description = "dropdown application", group = "launcher"}),

    -- Show/hide wibox (keep copycat feature)
    awful.key({ modkey }, "b", function ()
            for s in screen do
                s.mywibox.visible = not s.mywibox.visible
                if s.mybottomwibox then
                    s.mybottomwibox.visible = not s.mybottomwibox.visible
                end
            end
        end,
        {description = "toggle wibox", group = "awesome"}),

    -- On-the-fly useless gaps change (keep copycat feature)
    awful.key({ altkey, "Control" }, "+", function () lain.util.useless_gaps_resize(1) end,
              {description = "increment useless gaps", group = "tag"}),
    awful.key({ altkey, "Control" }, "-", function () lain.util.useless_gaps_resize(-1) end,
              {description = "decrement useless gaps", group = "tag"}),

    -- Dynamic tagging (keep copycat feature)
    awful.key({ modkey, "Shift" }, "n", function () lain.util.add_tag() end,
              {description = "add new tag", group = "tag"}),
    awful.key({ modkey, "Shift" }, "r", function () lain.util.rename_tag() end,
              {description = "rename tag", group = "tag"}),
    awful.key({ modkey, "Shift" }, "Left", function () lain.util.move_tag(-1) end,
              {description = "move tag to the left", group = "tag"}),
    awful.key({ modkey, "Shift" }, "Right", function () lain.util.move_tag(1) end,
              {description = "move tag to the right", group = "tag"}),
    awful.key({ modkey, "Shift" }, "d", function () lain.util.delete_tag() end,
              {description = "delete tag", group = "tag"}),

    -- YOUR LAUNCHER PREFERENCES
    awful.key({ modkey },            "r",     function () awful.spawn(prompt)  end,
              {description = "run rofi prompt", group = "launcher"}),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"}),

    -- YOUR CUSTOM LAUNCHERS
    awful.key({ modkey,           }, "w", function () awful.spawn(browser) end,
              {description = "open brave browser", group = "launcher"}),
    awful.key({ modkey } , "e", function () awful.spawn(file_browser) end,
              {description = "open thunar file browser", group = "launcher"}),
    awful.key({ modkey } , "g", function () awful.spawn(terminal_cmd .. "bluetui") end,
              {description = "open the BlueTooth manager", group = "launcher"}),
    awful.key({ modkey, "Shift"} , "n", function () awful.spawn(terminal_cmd .. "nmtui") end,
              {description = "open the Network manager", group = "launcher"}),

    -- ThinkPad T14 Function Keys - YOUR VOLUME CONTROL
    awful.key({ }, "XF86AudioRaiseVolume",
        function ()
            awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ +5%")
            -- Show notification
            awful.spawn.easy_async("pactl get-sink-volume @DEFAULT_SINK@", function(stdout)
                local volume = stdout:match("(%d+)%%")
                if volume then
                    naughty.notify({
                        title = "Volume",
                        text = "Volume: " .. volume .. "%",
                        timeout = 1,
                        preset = naughty.config.presets.low
                    })
                end
            end)
        end,
        {description = "increase volume", group = "media"}),

    awful.key({ }, "XF86AudioLowerVolume",
        function ()
            awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ -5%")
            -- Show notification
            awful.spawn.easy_async("pactl get-sink-volume @DEFAULT_SINK@", function(stdout)
                local volume = stdout:match("(%d+)%%")
                if volume then
                    naughty.notify({
                        title = "Volume",
                        text = "Volume: " .. volume .. "%",
                        timeout = 1,
                        preset = naughty.config.presets.low
                    })
                end
            end)
        end,
        {description = "decrease volume", group = "media"}),

    awful.key({ }, "XF86AudioMute",
        function ()
            awful.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle")
            -- Show notification
            awful.spawn.easy_async("pactl get-sink-mute @DEFAULT_SINK@", function(stdout)
                local muted = stdout:match("Mute: (%w+)")
                naughty.notify({
                    title = "Volume",
                    text = muted == "yes" and "Muted" or "Unmuted",
                    timeout = 1,
                    preset = naughty.config.presets.low
                })
            end)
        end,
        {description = "toggle mute", group = "media"}),

    -- Microphone Control
    awful.key({ }, "XF86AudioMicMute",
        function ()
            awful.spawn("pactl set-source-mute @DEFAULT_SOURCE@ toggle")
            awful.spawn.easy_async("pactl get-source-mute @DEFAULT_SOURCE@", function(stdout)
                local muted = stdout:match("Mute: (%w+)")
                naughty.notify({
                    title = "Microphone",
                    text = muted == "yes" and "Mic Muted" or "Mic Unmuted",
                    timeout = 1,
                    preset = naughty.config.presets.low
                })
            end)
        end,
        {description = "toggle microphone mute", group = "media"}),

    -- YOUR BRIGHTNESS CONTROL
    awful.key({ }, "XF86MonBrightnessUp",
        function ()
            awful.spawn("brightnessctl set +10%")
            -- Show notification
            awful.spawn.easy_async("brightnessctl get", function(current)
                awful.spawn.easy_async("brightnessctl max", function(max)
                    local percentage = math.floor((tonumber(current) / tonumber(max)) * 100)
                    naughty.notify({
                        title = "Brightness",
                        text = "Brightness: " .. percentage .. "%",
                        timeout = 1,
                        preset = naughty.config.presets.low
                    })
                end)
            end)
        end,
        {description = "increase brightness", group = "system"}),

    awful.key({ }, "XF86MonBrightnessDown",
        function ()
            awful.spawn("brightnessctl set 10%-")
            -- Show notification
            awful.spawn.easy_async("brightnessctl get", function(current)
                awful.spawn.easy_async("brightnessctl max", function(max)
                    local percentage = math.floor((tonumber(current) / tonumber(max)) * 100)
                    naughty.notify({
                        title = "Brightness",
                        text = "Brightness: " .. percentage .. "%",
                        timeout = 1,
                        preset = naughty.config.presets.low
                    })
                end)
            end)
        end,
        {description = "decrease brightness", group = "system"}),

    -- YOUR MULTI-MODAL WIFI/SIGNALS CONTROL (F8)
    -- Regular press: Control both WiFi and Bluetooth
    awful.key({ }, "XF86WLAN",
        function ()
            -- Check current WiFi state
            awful.spawn.easy_async("nmcli radio wifi", function(wifi_stdout)
                awful.spawn.easy_async("bluetoothctl show", function(bt_stdout)
                    local wifi_enabled = wifi_stdout:match("enabled")
                    local bt_enabled = bt_stdout:match("Powered: yes")

                    if wifi_enabled and bt_enabled then
                        -- Both on, turn both off
                        awful.spawn("nmcli radio wifi off")
                        awful.spawn("bluetoothctl power off")
                        naughty.notify({
                            title = "Wireless",
                            text = "WiFi & Bluetooth Disabled",
                            timeout = 2,
                            preset = naughty.config.presets.normal
                        })
                    elseif not wifi_enabled and not bt_enabled then
                        -- Both off, turn both on
                        awful.spawn("nmcli radio wifi on")
                        awful.spawn("bluetoothctl power on")
                        naughty.notify({
                            title = "Wireless",
                            text = "WiFi & Bluetooth Enabled",
                            timeout = 2,
                            preset = naughty.config.presets.normal
                        })
                    else
                        -- Mixed state, turn both on
                        awful.spawn("nmcli radio wifi on")
                        awful.spawn("bluetoothctl power on")
                        naughty.notify({
                            title = "Wireless",
                            text = "WiFi & Bluetooth Enabled",
                            timeout = 2,
                            preset = naughty.config.presets.normal
                        })
                    end
                end)
            end)
        end,
        {description = "toggle wifi and bluetooth", group = "system"}),

    -- Shift + F8: Control WiFi only
    awful.key({ "Shift" }, "XF86WLAN",
        function ()
            awful.spawn.easy_async("nmcli radio wifi", function(stdout)
                if stdout:match("enabled") then
                    awful.spawn("nmcli radio wifi off")
                    naughty.notify({
                        title = "WiFi Only",
                        text = "WiFi Disabled",
                        timeout = 2,
                        preset = naughty.config.presets.normal
                    })
                else
                    awful.spawn("nmcli radio wifi on")
                    naughty.notify({
                        title = "WiFi Only",
                        text = "WiFi Enabled",
                        timeout = 2,
                        preset = naughty.config.presets.normal
                    })
                end
            end)
        end,
        {description = "toggle wifi only", group = "system"}),

    -- Ctrl + F8: Control Bluetooth only
    awful.key({ "Control" }, "XF86WLAN",
        function ()
            awful.spawn.easy_async("bluetoothctl show", function(stdout)
                if stdout:match("Powered: yes") then
                    awful.spawn("bluetoothctl power off")
                    naughty.notify({
                        title = "Bluetooth Only",
                        text = "Bluetooth Disabled",
                        timeout = 2,
                        preset = naughty.config.presets.normal
                    })
                else
                    awful.spawn("bluetoothctl power on")
                    naughty.notify({
                        title = "Bluetooth Only",
                        text = "Bluetooth Enabled",
                        timeout = 2,
                        preset = naughty.config.presets.normal
                    })
                end
            end)
        end,
        {description = "toggle bluetooth only", group = "system"}),

    -- Display Toggle (External monitor)
    awful.key({ }, "XF86Display",
        function ()
            awful.spawn("autorandr --change")
            naughty.notify({
                title = "Display",
                text = "Switching display configuration",
                timeout = 2,
                preset = naughty.config.presets.normal
            })
        end,
        {description = "toggle external display", group = "system"}),

    -- YOUR F9-F12 CUSTOM MAPPINGS
    -- F9 - Notifications (Message icon)
    awful.key({ }, "XF86Messenger",
        function ()
            -- Toggle notification history/center
            naughty.destroy_all_notifications()
            naughty.notify({
                title = "Notifications",
                text = "Notification center opened\nRecent notifications cleared",
                timeout = 2,
                preset = naughty.config.presets.normal
            })
        end,
        {description = "open notifications center", group = "system"}),

    -- F10 - Start Media (Phone pickup icon)
    awful.key({ }, "XF86Phone",
        function ()
            awful.spawn("playerctl play")
            naughty.notify({
                title = "Media",
                text = "Media started",
                timeout = 1,
                preset = naughty.config.presets.low
            })
        end,
        {description = "start media playback", group = "media"}),

    -- F11 - Stop Media (Phone hangup icon)
    awful.key({ }, "XF86PhoneHangup",
        function ()
            awful.spawn("playerctl stop")
            naughty.notify({
                title = "Media",
                text = "Media stopped",
                timeout = 1,
                preset = naughty.config.presets.low
            })
        end,
        {description = "stop media playback", group = "media"}),

    -- F12 - Calculator (Star icon)
    awful.key({ }, "XF86Favorites",
        function ()
            awful.spawn("gnome-calculator")
        end,
        {description = "open calculator", group = "launcher"}),

    -- Media Control (standard keys)
    awful.key({ }, "XF86AudioPlay",
        function () awful.spawn("playerctl play-pause") end,
        {description = "play/pause media", group = "media"}),

    awful.key({ }, "XF86AudioNext",
        function () awful.spawn("playerctl next") end,
        {description = "next track", group = "media"}),

    awful.key({ }, "XF86AudioPrev",
        function () awful.spawn("playerctl previous") end,
        {description = "previous track", group = "media"}),

    -- Power Management
    awful.key({ }, "XF86Sleep",
        function ()
            awful.spawn("systemctl suspend")
        end,
        {description = "suspend system", group = "system"}),

    -- Screen Lock
    awful.key({ }, "XF86ScreenSaver",
        function ()
            awful.spawn("loginctl lock-session")
        end,
        {description = "lock screen", group = "system"}),

    -- Calculator (if XF86Calculator exists separately)
    awful.key({ }, "XF86Calculator",
        function ()
            awful.spawn("gnome-calculator")
        end,
        {description = "open calculator", group = "launcher"}),

    -- Home folder
    awful.key({ }, "XF86Explorer",
        function ()
            awful.spawn(file_browser)
        end,
        {description = "open file manager", group = "launcher"}),

    -- Bluetooth Toggle (separate control for other machines)
    awful.key({ }, "XF86Bluetooth",
        function ()
            awful.spawn.easy_async("bluetoothctl show", function(stdout)
                if stdout:match("Powered: yes") then
                    awful.spawn("bluetoothctl power off")
                    naughty.notify({
                        title = "Bluetooth",
                        text = "Bluetooth Disabled",
                        timeout = 2,
                        preset = naughty.config.presets.normal
                    })
                else
                    awful.spawn("bluetoothctl power on")
                    naughty.notify({
                        title = "Bluetooth",
                        text = "Bluetooth Enabled",
                        timeout = 2,
                        preset = naughty.config.presets.normal
                    })
                end
            end)
        end,
        {description = "toggle bluetooth only", group = "system"}),

    -- Destroy all notifications (keep copycat feature)
    awful.key({ "Control",           }, "space", function() naughty.destroy_all_notifications() end,
              {description = "destroy all notifications", group = "hotkeys"}),

    -- Take a screenshot (keep copycat feature)
    awful.key({ altkey }, "p", function() os.execute("screenshot") end,
              {description = "take a screenshot", group = "hotkeys"}),

    -- Widgets popups (keep copycat features)
    awful.key({ altkey, }, "c", function () if beautiful.cal then beautiful.cal.show(7) end end,
              {description = "show calendar", group = "widgets"}),
    awful.key({ altkey, }, "h", function () if beautiful.fs then beautiful.fs.show(7) end end,
              {description = "show filesystem", group = "widgets"}),
    awful.key({ altkey, }, "w", function () if beautiful.weather then beautiful.weather.show(7) end end,
              {description = "show weather", group = "widgets"}),

    -- Copy utilities (keep copycat features)
    awful.key({ modkey }, "c", function () awful.spawn.with_shell("xsel | xsel -i -b") end,
              {description = "copy terminal to gtk", group = "hotkeys"}),
    awful.key({ modkey }, "v", function () awful.spawn.with_shell("xsel -b | xsel") end,
              {description = "copy gtk to terminal", group = "hotkeys"}),

    -- MPD control (keep copycat features if you use MPD)
    awful.key({ altkey, "Control" }, "Up",
        function ()
            os.execute("mpc toggle")
            if beautiful.mpd then beautiful.mpd.update() end
        end,
        {description = "mpc toggle", group = "widgets"}),
    awful.key({ altkey, "Control" }, "Down",
        function ()
            os.execute("mpc stop")
            if beautiful.mpd then beautiful.mpd.update() end
        end,
        {description = "mpc stop", group = "widgets"}),
    awful.key({ altkey, "Control" }, "Left",
        function ()
            os.execute("mpc prev")
            if beautiful.mpd then beautiful.mpd.update() end
        end,
        {description = "mpc prev", group = "widgets"}),
    awful.key({ altkey, "Control" }, "Right",
        function ()
            os.execute("mpc next")
            if beautiful.mpd then beautiful.mpd.update() end
        end,
        {description = "mpc next", group = "widgets"}),
    awful.key({ altkey }, "0",
        function ()
            local common = { text = "MPD widget ", position = "top_middle", timeout = 2 }
            if beautiful.mpd and beautiful.mpd.timer.started then
                beautiful.mpd.timer:stop()
                common.text = common.text .. lain.util.markup.bold("OFF")
            else
                if beautiful.mpd then beautiful.mpd.timer:start() end
                common.text = common.text .. lain.util.markup.bold("ON")
            end
            naughty.notify(common)
        end,
        {description = "mpc on/off", group = "widgets"}),

    -- Non-empty tag browsing (keep copycat feature)
    awful.key({ altkey }, "Left", function () lain.util.tag_view_nonempty(-1) end,
              {description = "view  previous nonempty", group = "tag"}),
    awful.key({ altkey }, "Right", function () lain.util.tag_view_nonempty(1) end,
              {description = "view  previous nonempty", group = "tag"})
)

clientkeys = mytable.join(
    awful.key({ altkey, "Shift"   }, "m",      lain.util.magnify_client,
              {description = "magnify client", group = "client"}),
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    -- YOUR CLOSE KEY (not copycat's Shift+c)
    awful.key({ modkey }, "q",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "(un)maximize", group = "client"}),
    awful.key({ modkey, "Control" }, "m",
        function (c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end ,
        {description = "(un)maximize vertically", group = "client"}),
    awful.key({ modkey, "Shift"   }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end ,
        {description = "(un)maximize horizontally", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = mytable.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = mytable.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)

-- }}}

-- {{{ Rules

-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     callback = awful.client.setslave,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen,
                     size_hints_honor = false
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
          "pinentry",
        },
        class = {
          "Arandr",
          "Blueman-manager",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
          "Wpa_gui",
          "veromix",
          "xtightvncviewer"},

        -- Note that the name property shown in xprop might be set slightly after creation of the client
        -- and the name shown there might not match defined rules here.
        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "ConfigManager",  -- Thunderbird's about:config.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = true }
    },

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}

-- }}}

-- {{{ Signals

-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- Custom
    if beautiful.titlebar_fun then
        beautiful.titlebar_fun(c)
        return
    end

    -- Default
    -- buttons for the titlebar
    local buttons = mytable.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c, { size = 16 }) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = vi_focus})
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- switch to parent after closing child window
local function backham()
    local s = awful.screen.focused()
    local c = awful.client.focus.history.get(s, 0)
    if c then
        client.focus = c
        c:raise()
    end
end

-- attach to minimized state
client.connect_signal("property::minimized", backham)
-- attach to closed state
client.connect_signal("unmanage", backham)
-- ensure there is always a selected client during tag switching or logins
tag.connect_signal("property::selected", backham)

-- }}}
