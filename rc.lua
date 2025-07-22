-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Chosen theme name
local chosen_theme="sky"

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- local lain = require("lain")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Try to load freedesktop with error handling
local freedesktop = nil
pcall(function() freedesktop = require("freedesktop") end)

-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
-- Try multiple theme paths with error handling
local theme_path = string.format("%s/.config/awesome/themes/%s/theme.lua", os.getenv("HOME"), chosen_theme)
local theme_loaded = false

-- Try to load the theme
if gears.filesystem.file_readable(theme_path) then
    theme_loaded = pcall(beautiful.init, theme_path)
end

-- Fallback to default theme if sky theme fails
if not theme_loaded then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Theme Error!",
        text = "Could not load '" .. chosen_theme .. "' theme. Using default theme."
    })
    -- Try default theme
    local default_theme_path = "/usr/share/awesome/themes/default/theme.lua"
    if gears.filesystem.file_readable(default_theme_path) then
        beautiful.init(default_theme_path)
    else
        -- Last resort - use zenburn which is usually available
        beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
    end
end

-- This is used later as the default terminal and editor to run.
terminal = "kitty"
terminal_cmd = terminal .. " -e "
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor
browser = "brave"
prompt = "rofi -show drun"
file_browser = "thunar"
-- email_client = ""

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
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
}
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
   { "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end },
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock()

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = gears.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  c:emit_signal(
                                                      "request::activate",
                                                      "tasklist",
                                                      {raise = true}
                                                  )
                                              end
                                          end),
                     awful.button({ }, 3, function()
                                              awful.menu.client_list({ theme = { width = 250 } })
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons
    }

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            mykeyboardlayout,
            wibox.widget.systray(),
            mytextclock,
            s.mylayoutbox,
        },
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

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

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end, {description = "swap with next client by index", group = "client"}),
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
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

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

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                    c:emit_signal(
                        "request::activate", "key.unminimize", {raise = true}
                    )
                  end
              end,
              {description = "restore minimized", group = "client"}),

    -- Prompt
    awful.key({ modkey },            "r",     function () awful.spawn(prompt)  end,
              {description = "run prompt", group = "launcher"}),

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
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"}),

    -- Custom Launchers
    awful.key({ modkey,           }, "w", function () awful.spawn(browser) end,
              {description = "open a browser", group = "launcher"}),
    awful.key({ modkey } , "e", function () awful.spawn(file_browser) end,
              {description = "open a file browser", group = "launcher"}),
    awful.key({ modkey } , "b", function () awful.spawn(terminal_cmd .. "bluetui") end,
              {description = "open the BlueTooth manager", group = "launcher"}),
    awful.key({ modkey, "Shift"} , "w", function () awful.spawn(terminal_cmd .. "nmtui") end,
              {description = "open the Network manager", group = "launcher"}),

    -- ThinkPad T14 Function Keys
    -- Volume Control
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

    -- Brightness Control
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

    -- WiFi/Signals Toggle (F8 - ThinkPad specific) - Multi-modal control
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

    -- Screen Lock
    awful.key({ }, "XF86ScreenSaver",
        function ()
            awful.spawn("loginctl lock-session")
        end,
        {description = "lock screen", group = "system"}),

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

    -- Media Control
    awful.key({ }, "XF86AudioPlay",
        function () awful.spawn("playerctl play-pause") end,
        {description = "play/pause media", group = "media"}),

    awful.key({ }, "XF86AudioNext",
        function () awful.spawn("playerctl next") end,
        {description = "next track", group = "media"}),

    awful.key({ }, "XF86AudioPrev",
        function () awful.spawn("playerctl previous") end,
        {description = "previous track", group = "media"}),

    -- F9-F12 Custom ThinkPad Keys
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

    -- Power Management
    awful.key({ }, "XF86Sleep",
        function ()
            awful.spawn("systemctl suspend")
        end,
        {description = "suspend system", group = "system"}),

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
        {description = "open file manager", group = "launcher"})
)

clientkeys = gears.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
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
    globalkeys = gears.table.join(globalkeys,
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

clientbuttons = gears.table.join(
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
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
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
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
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
    c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
