# Aurora Terminal SDDM theme

A dark, terminal-inspired login screen with a large 12-hour clock, subtle
caret/colon ticks, and short fade-in/focus transitions. The desktop selector
uses sessions detected by SDDM (for example GNOME, Plasma, or another installed
desktop); it does not assume KDE Plasma. SDDM-supported Sleep, Restart, and
Power Off actions are shown at the bottom and disabled when unavailable. The
last-used username is prefilled; when present, the password field gets focus
immediately and Enter submits the login.

## Preview

The background and layout are drawn by `Main.qml`; the theme does not require
external images, fonts, or network access. Its small clock and caret updates
run locally once per second; entrance and focus effects are brief.

## Install

Copy this folder to a directory SDDM scans for themes, such as
`/usr/share/sddm/themes/Final`, then select **Aurora Terminal** in
your distribution's SDDM settings tool. On KDE, this is System Settings →
Colors & Themes → Login Screen (SDDM). The greeter theme is independent of the
desktop you log into, and the selector lists the sessions SDDM detects.

To install from this checkout:

```sh
sudo install -d /usr/share/sddm/themes/Final
sudo cp -a themes/Final/. /usr/share/sddm/themes/Final/
```

No `theme.conf` is needed: this theme has no configurable settings.

Changing the active greeter theme is system-wide and may require administrator
access. This changes only the SDDM login screen; it does not change your GNOME,
Plasma, or other desktop session.
# Aurora-Terminal
