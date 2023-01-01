#!/usr/bin/env bash

csv="./Ressources/tntdirect.csv"

FQDN="tntendirect.com"
Sub_D="https://s"
SubDir="live/playlist.m3u8"

timeout="5"
function get_http_status() {
  curl -o /dev/null -sLk -w "%{http_code}\n" --connect-timeout "$timeout" "$tvurl"
}


echo "#EXTM3U"
while IFS="," read -r canal nom_chaine nom_url nom_logo groupe
do

for tvurl in $(echo -e "$Sub_D"{2..15}".${FQDN}/$nom_url/$SubDir\n" | sed 's/^ *//g') ; do
      if [[ $(get_http_status) -eq 200 ]]; then
        echo -e "#EXTINF:0 tvg-name=\"${nom_chaine}\" tvg-logo=\"https://www.tntendirect.com/images/channel/${nom_logo}.png\" tvg-group=\"${groupe}\",${canal} - ${nom_chaine}\n$tvurl"
      fi
    done

done < <(tail -n +2 "$csv")
