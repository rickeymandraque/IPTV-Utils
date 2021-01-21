#!/bin/bash

RED='\033[38;5;160m' #ex echo -e "${RED} ALERT"
NC='\033[0m'    #ex echo -e "${NC} Normal"
GREEN='\033[38;1;32m'   #ex echo -e "${GREEN} OK"

dico="$HOME/dicorange.lst"
dicolite="$HOME/dicorangelite.lst"
VAR_LISTE="$( cat $dico)"
VAR_LISTE2="$( cat $dicolite)"
urlbase="http://cdn.webtv4.cdnfr.orange.fr/hs/HALO"
urllist="$HOME/Orangeforce.lst"
urlcsv="$HOME/Orangeforce.csv"
playlist="$HOME/Orangeforce.m3u"
file="index.m3u8"

echo -e "#EXTM3U\n" >>"$playlist"
echo -e "nom,url" >>"$urlcsv"
for channel in $VAR_LISTE; do
	fullurl="$(echo -e "$urlbase"{1..5}"/hls/live/"$channel"_live/$file")"
	for fullchannel in $fullurl; do
		if curl -s -I "$fullchannel" 2>&1 | grep -w "200"; then
			#statements
			echo -e "${GREEN}lien valide trouvé${NC}"
			echo -e "#EXTINF:-1 tvg-name=\"$channel\" tvg-language=\"Français\" group-title=\"Orange\" ,$channel\n$fullchannel" >>"$playlist"
			echo -e "$channel,$fullchannel" >>"$urlcsv"
			echo -e "$fullchannel" >>"$urllist"
		else
			echo -e "$fullchannel: ${RED}invalide${NC}"
		fi
	done
done
echo -e "Toute les urls ont été testées"
