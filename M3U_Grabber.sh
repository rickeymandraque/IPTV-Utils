#!/bin/bash
# recupere les lien de iptvcat via https://github.com/eliashussary/iptvcat-scraper/raw/master/data/countries/france.json
#    .---------- constant part!
#    vvvv vvvv-- the code from above
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
IPTVCAT_URL="https://github.com/eliashussary/iptvcat-scraper/raw/master/data/countries/france.json"
IPTVCAT_LIST="$HOME/france-$(date +"%m-%d-%Y").json"
if [ ! -f $IPTVCAT_LIST ]; then
	echo "Téléchargement du fichier depuis github"
	wget -q "$IPTVCAT_URL" -O- | jq unique >$IPTVCAT_LIST
else
	echo "le fichier existe déja"
fi
NB_CHANNELS="$(cat $IPTVCAT_LIST | jq 'keys[]' | wc -l)"

printf "il y a actuellement "$NB_CHANNELS" sur la liste\n"
echo -e "#EXTM3U" >>./playlist-test1.m3u
for chan_number in $(cat "$IPTVCAT_LIST" |  jq 'keys[]'); do
	nom_chan="$(cat "$IPTVCAT_LIST" | jq -j '.['"$chan_number"'].channel' | tr -d \")"
	chan_id="$(cat "$IPTVCAT_LIST" | jq -j '.['"$chan_number"'].id' | tr -d \")"
	chan_status="$(cat "$IPTVCAT_LIST" | jq ".[$chan_number].status" | tr -d \")"
	groupe="$(cat "$IPTVCAT_LIST" | jq ".[$chan_number].country" | tr -d \")"
	urlchannel="$(cat "$IPTVCAT_LIST" | jq ".[$chan_number].link" | tr -d \")"
	if [ "$chan_status" == offline ]; then
		printf "$nom_chan ($groupe) est déclraré ${RED}$chan_status${NC}\n"
		printf "le numéro de l'index est: $chan_number\n"
		printf "les nom du groupe est: $groupe\n"
		printf "l\'identifiant de la est $chan_id\n"
		printf "Chaine $chan_number sur $NB_CHANNELS\n"
	else
		printf "Chaine $chan_number sur $NB_CHANNELS\n"
		printf "le numéro de l'index est: $chan_number\n"
		printf "les nom du groupe est: $groupe\n"
		printf "l\'identifiant de la est $chan_id\n"
		printf "$nom_chan ($groupe) est déclraré ${GREEN}$chan_status${NC}\n"
		echo -e "#EXTINF:-1 tvg-id=\"EPG N/A\" tvg-logo=\"$logo_chan\" tvg-name=\"$nom_chan\" group-title=\"$groupe\",$nom_chan \n$urlchannel"
		echo -e "#EXTINF:-1 tvg-id=\"EPG N/A\" tvg-logo=\"$logo_chan\" tvg-name=\"$nom_chan\" group-title=\"$groupe\",$nom_chan \n$urlchannel\n" >>./playlist-test1.m3u
	fi
done
