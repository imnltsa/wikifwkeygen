#!/bin/bash

clear
echo -e "Please put your device into pwned DFU mode with gaster pwn.\nThis script may not be compatible with i(Pad)OS 18.\nRequirements: Criptam, irecovery, pzb, img4, pyimg4\nMade by @dleovl"

deviceinfo=$(irecovery -q)
deviceid=$(echo "$deviceinfo" | awk '/PRODUCT/ {print $NF}')
boardconfig=$(echo "$deviceinfo" | awk '/MODEL/ {print $NF}')
rm -f *.im4p *.txt *.dec fw.json BuildManifest.plist 2>/dev/null
wget https://api.ipsw.me/v4/device/${deviceid} -O fw.json > /dev/null 2>&1
echo -e "\nDetected ${deviceid} ${boardconfig}\n"

echo -e "Enter .ipsw URL and press enter:\n"
read ipswurl
filename=$(basename "$ipswurl")
version=$(echo "$filename" | awk -F '_' '{print $(NF-2)}')
buildid=$(echo "$filename" | awk -F '_' '{print $(NF-1)}')

pzb --list "$ipswurl" > list.txt 2>&1
open -e list.txt

echo -e "\nEnter codename for ${buildid} (this can be acquired from Wikipedia under "Release history")\n"
read codename

clear
echo -e "Made by @dleovl\n\nUsing $ipswurl\n\nPlease wait..."

pzb --get "BuildManifest.plist" "$ipswurl" > /dev/null
pzb --get $(awk "/""${boardconfig}""/{x=1}x&&/iBSS[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1) "$ipswurl" > /dev/null
pzb --get $(awk "/""${boardconfig}""/{x=1}x&&/iBEC[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1) "$ipswurl" > /dev/null
pzb --get $(awk "/""${boardconfig}""/{x=1}x&&/LLB[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1) "$ipswurl" > /dev/null
pzb --get $(awk "/""${boardconfig}""/{x=1}x&&/iBoot[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1) "$ipswurl" > /dev/null
pzb --get $(awk "/""${boardconfig}""/{x=1}x&&/sep-firmware[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1) "$ipswurl" > /dev/null

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

img4 -i ${ibssfilename} -o iBSS.dec -k ${ibssiv}${ibsskey} > /dev/null
img4 -i ${ibecfilename} -o iBEC.dec -k ${ibeciv}${ibeckey} > /dev/null
img4 -i ${ibootfilename} -o iBoot.dec -k ${ibootiv}${ibootkey} > /dev/null
img4 -i ${llbfilename} -o LLB.dec -k ${llbiv}${llbkey} > /dev/null
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

echo "Finished. Check for legible text in iBSS/iBEC/iBoot/LLB (they have been opened in TextEdit). SEP firmware is not decrypted. Only contribute if you are entirely confident these are correct."