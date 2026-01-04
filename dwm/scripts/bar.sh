# #!/bin/bash
#
# refresh_rate=3 # seconds 
#
# while [[ true ]]; do
#     xsetroot -name "$(cat /sys/class/power_supply/BAT0/capacity)%"
#     sleep $refresh_rate
#     xsetroot -name "$(date +"%T")"
#     sleep $refresh_rate
#     xsetroot -name "$(date +"%a, %b %d, %y")"
#     sleep $refresh_rate
# done

#!/bin/bash
# Simple, practical dwm status bar
refresh_rate=2  # seconds

# Helpers
human() {
  # bytes/sec -> human readable (KB/s or MB/s)
  local b=$1
  if [ "$b" -ge 1048576 ]; then
    awk -v v="$b" 'BEGIN{printf("%.1fM", v/1048576)}'
  else
    awk -v v="$b" 'BEGIN{printf("%.0fK", v/1024)}'
  fi
}

# detect battery directory (BAT0, BAT1, etc) 
# battery_dir="$(ls /sys/class/power_supply/ 2>/dev/null | grep -E '^BAT|^Battery|^battery' | head -n1)"
# [ -n "$battery_dir" ] && battery_path="/sys/class/power_supply/$battery_dir" || battery_path=""

#(currently i don't need that)
battery_path="/sys/class/power_supply/BAT0"

# detect default network interface (IPv4 default route)
iface="$(ip -o -4 route show default 2>/dev/null | awk '{print $5}' | head -n1)"
if [ -n "$iface" ] && [ -r "/sys/class/net/$iface/statistics/rx_bytes" ]; then
  prev_rx=$(cat /sys/class/net/$iface/statistics/rx_bytes)
  prev_tx=$(cat /sys/class/net/$iface/statistics/tx_bytes)
else
  iface=""
  prev_rx=0
  prev_tx=0
fi

while true; do
  # BATTERY
  if [ -n "$battery_path" ] && [ -r "$battery_path/capacity" ]; then
    cap=$(cat "$battery_path/capacity")
    st=$(cat "$battery_path/status" 2>/dev/null || echo "Unknown")
    case "$st" in
      Charging) bat_icon="⚡" ;;
      Discharging) bat_icon="🔋" ;;
      Full) bat_icon="🔌" ;;
      *) bat_icon="" ;;
    esac
    BAT="$bat_icon ${cap}%"
  else
    BAT=""
  fi

  # CPU load (1-min average)
  LOAD=$(cut -d ' ' -f1 /proc/loadavg)

  # MEMORY usage %
  MEMPCT=$(awk '/MemTotal:/ {t=$2} /MemAvailable:/ {a=$2} END{if(t>0) printf("%d", (t-a)/t*100); else print 0}' /proc/meminfo)

  # VOLUME (pactl preferred, amixer fallback)
  VOL="$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | awk 'NR==1{print $5}' )"
  if [ -z "$VOL" ]; then
    VOL="$(amixer get Master 2>/dev/null | awk -F'[][]' 'END{print $2}')"
  fi
  [ -z "$VOL" ] && VOL="—"

  # NETWORK speed
  # if [ -n "$iface" ]; then
  #   cur_rx=$(cat /sys/class/net/$iface/statistics/rx_bytes)
  #   cur_tx=$(cat /sys/class/net/$iface/statistics/tx_bytes)
  #
  #   rx_rate=$(( (cur_rx - prev_rx) / refresh_rate ))
  #   tx_rate=$(( (cur_tx - prev_tx) / refresh_rate ))
  #
  #   RX_H=$(human "$rx_rate")
  #   TX_H=$(human "$tx_rate")
  #
  #   prev_rx=$cur_rx
  #   prev_tx=$cur_tx
  #
  #   NET="${iface} ↓${RX_H} ↑${TX_H}"
  # else
  #   NET=""
  # fi

  # TIME/DATE
  TIME="$(date '+%a %b %d %T')"

  # Compose status line (practical layout)
  status="${BAT} | CPU ${LOAD} | MEM ${MEMPCT}% | VOL ${VOL} | ${TIME}"

  # Set root window name
  xsetroot -name "$status"

  sleep "$refresh_rate"
done
