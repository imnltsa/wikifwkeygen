#!/bin/bash

echo -e "\nPlease put your device into pwned DFU mode with gaster pwn.\nThis script may not be compatible with i(Pad)OS 18.\nRequirements: Criptam, irecovery, pzb, img4, pyimg4\nMade by @dleovl\n"

deviceinfo=$(irecovery -q)
deviceid=$(echo "$deviceinfo" | awk '/PRODUCT/ {print $NF}')
boardconfig=$(echo "$deviceinfo" | awk '/MODEL/ {print $NF}')
rm -f *.im4p *.txt *.dec fw.json BuildManifest.plist
wget https://api.ipsw.me/v4/device/${deviceid} -O fw.json
echo -e "Detected ${deviceid} ${boardconfig}\n"

echo -e "Enter .ipsw URL and press enter:\n"
read ipswurl
filename=$(basename "$ipswurl")
version=$(echo "$filename" | awk -F '_' '{print $(NF-2)}')
buildid=$(echo "$filename" | awk -F '_' '{print $(NF-1)}')

pzb --list "$ipswurl" > list.txt
open -e list.txt

echo -e "\nEnter codename for ${buildid} (this can be acquired from Wikipedia under "Release history")\n"
read codename

echo -e "\nDownloading components...\n"

pzb --get "BuildManifest.plist" "$ipswurl"
pzb --get $(awk "/""${boardconfig}""/{x=1}x&&/iBSS[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1) "$ipswurl"
pzb --get $(awk "/""${boardconfig}""/{x=1}x&&/iBEC[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1) "$ipswurl"
pzb --get $(awk "/""${boardconfig}""/{x=1}x&&/LLB[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1) "$ipswurl"
pzb --get $(awk "/""${boardconfig}""/{x=1}x&&/iBoot[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1) "$ipswurl"
pzb --get $(awk "/""${boardconfig}""/{x=1}x&&/sep-firmware[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1) "$ipswurl"

echo -e "\nObtaining keys...\n"

criptam --build-id "$buildid" --device-identifier "$deviceid" > keys.txt

ibssiv=$(awk '/iBSS IV:/ {print $NF}' keys.txt)
ibsskey=$(awk '/iBSS Key:/ {print $NF}' keys.txt)
ibssfilename=$(basename $(awk "/${boardconfig}/{x=1}x&&/iBSS[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1))
ibeciv=$(awk '/iBEC IV:/ {print $NF}' keys.txt)
ibeckey=$(awk '/iBEC Key:/ {print $NF}' keys.txt)
ibecfilename=$(basename $(awk "/${boardconfig}/{x=1}x&&/iBEC[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1))
llbiv=$(awk '/LLB IV:/ {print $NF}' keys.txt)
llbkey=$(awk '/LLB Key:/ {print $NF}' keys.txt)
llbfilename=$(basename $(awk "/${boardconfig}/{x=1}x&&/LLB[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1))
ibootiv=$(awk '/iBoot IV:/ {print $NF}' keys.txt)
ibootkey=$(awk '/iBoot Key:/ {print $NF}' keys.txt)
ibootfilename=$(basename $(awk "/${boardconfig}/{x=1}x&&/iBoot[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1))

echo -e "Decrypting components...\n"

img4 -i ${ibssfilename} -o iBSS.dec -k ${ibssiv}${ibsskey}
img4 -i ${ibecfilename} -o iBEC.dec -k ${ibeciv}${ibeckey}
img4 -i ${ibootfilename} -o iBoot.dec -k ${ibootiv}${ibootkey}
img4 -i ${llbfilename} -o LLB.dec -k ${llbiv}${llbkey}
open -e iBSS.dec iBEC.dec iBoot.dec LLB.dec

sepfwfilename=$(basename $(awk "/${boardconfig}/{x=1}x&&/sep-firmware[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1))
sepfwinfo=$(pyimg4 im4p info -i ${sepfwfilename})
sepfwprodiv=$(echo "$sepfwinfo" | awk '/Type: PRODUCTION/ {getline; print $NF}')
sepfwprodkey=$(echo "$sepfwinfo" | awk '/Type: PRODUCTION/ {getline; getline; print $NF}')
sepfwdeviv=$(echo "$sepfwinfo" | awk '/Type: DEVELOPMENT/ {getline; print $NF}')
sepfwdevkey=$(echo "$sepfwinfo" | awk '/Type: DEVELOPMENT/ {getline; getline; print $NF}')

content="{{keys
 | Version               = ${version}
 | Build                 = ${buildid}
 | Device                = ${deviceid}
 | Codename              = ${codename}
 | DownloadURL           = ${ipswurl}

 | iBEC                  = ${ibecfilename}
 | iBECIV                = ${ibeciv}
 | iBECKey               = ${ibeckey}

 | iBoot                 = ${ibootfilename}
 | iBootIV               = ${ibootiv}
 | iBootKey              = ${ibootkey}

 | iBSS                  = ${ibssfilename}
 | iBSSIV                = ${ibssiv}
 | iBSSKey               = ${ibsskey}

 | LLB                   = ${llbfilename}
 | LLBIV                 = ${llbiv}
 | LLBKey                = ${llbkey}

 | SEPFirmware           = ${sepfwfilename}
 | SEPFirmwareIV         = Unknown
 | SEPFirmwareKey        = Unknown
 | SEPFirmwareKBAG       = ${sepfwprodiv}${sepfwprodkey}
 | SEPFirmwareDevKBAG    = ${sepfwdeviv}${sepfwdevkey}
}}"

mkdir -p wiki
echo "${content}" > "wiki/${codename}_${buildid}_(${deviceid}).txt"
open -e "wiki/${codename}_${buildid}_(${deviceid}).txt"
rm -f *.im4p

echo -e "\nFinished, please make sure there are no errors. Check for legible text in iBSS/iBEC/iBoot/LLB (they have been opened in TextEdit).\nSEP firmware is not decrypted. Only contribute if you are entirely confident these are correct.\n\nYour file has been saved as wiki/${codename}_${buildid}_(${deviceid}).txt\n"