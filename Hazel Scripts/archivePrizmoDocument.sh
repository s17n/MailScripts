#!/bin/zsh

theFile=$1
#theFile="$HOME/Library/Mobile Documents/62UF8HAVJA~com~creaceed~mas~prizmo2/Documents/📥 PDF Scans/dt-Belege-split-2801-02.pdf"

prizmoRoot="$HOME/Library/Mobile\ Documents/62UF8HAVJA~com~creaceed~mas~prizmo2/Documents"
archiveRoot="$HOME/Library/Mobile\ Documents/com\~apple\~CloudDocs/Daten/Prizmo-Archiv"

theDate=$(date +%Y%m%d-%H%M)
theBasename=$(basename $theFile)
theDirname=$(dirname $theFile)
theOriginalFilename=$(echo $theBasename | sed -e 's/pdf/pzdoc/g')
theArchiveFilename=$theDate"_"$theOriginalFilename

theCommand="mv $prizmoRoot/$theOriginalFilename $archiveRoot/$theArchiveFilename"
#echo $theCommand
eval "$theCommand"
