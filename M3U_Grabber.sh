#!/bin/bash
# recupere les lien de iptvcat via https://github.com/eliashussary/iptvcat-scraper/raw/master/data/countries/france.json

IPTVCAT_URL="https://github.com/eliashussary/iptvcat-scraper/raw/master/data/countries/france.json"
IPTVCAT_LIST="$HOME/france$-(date +"%m-%d-%Y").json"
wget "$IPTVCAT_URL" -O $IPTVCAT_LIST

for chan_number in $(cat $IPTVCAT_LIST | jq 'keys[]'); do
	for nom_chan in $(cat $IPTVCAT_LIST | jq ".[$chan_number].channel" | tr -d \"); do
		for chan_status in $(cat $IPTVCAT_LIST | jq ".[$chan_number].status" | tr -d \"); do
			for groupe in $(cat $IPTVCAT_LIST | jq ".[$chan_number].country" | tr -d \"); do
				if [ $chan_status == offline ]; then
					echo        "$nom_chan ($groupe) est $chan_status"
				else
					echo -e "#EXTINF:-1, tvg-id=\"EPG N/A\" tvg-logo=\"$logo_chan\" tvg-name=\"$nom_chan\" group-title=\"$groupe\",$nom_chan \n$urlchanless/$chan_number"
				fi
			done
		done
	done
done
