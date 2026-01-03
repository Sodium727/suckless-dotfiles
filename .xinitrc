xset r rate 180 80
dunst&
feh --bg-scale /home/dat/.config/niri/bg/wallpaper.png
fcitx5&
xss-lock --transfer-sleep-lock -- slock &
brightnessctl -d tpacpi::kbd_backlight s 2

/home/dat/.dwm/scripts/bar.sh &

exec dwm
#exec i3
