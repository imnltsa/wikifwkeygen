#!/bin/bash

clear
echo -e "Please put your device into pwned DFU mode with gaster pwn.\nThis script may not be compatible with i(Pad)OS 18.\nRequirements: Criptam, irecovery, pzb, img4, pyimg4\nMade by @dleovl"

deviceinfo=$(irecovery -q)
deviceid=$(echo "$deviceinfo" | awk '/PRODUCT/ {print $NF}')
detectedmodel=$(echo "$deviceinfo" | awk '/MODEL/ {print $NF}')
rm -f *.im4p *.txt *.dec fw.json 2>/dev/null
wget https://api.ipsw.me/v4/device/${deviceid} -O fw.json > /dev/null 2>&1
echo -e "\nDetected ${deviceid} ${detectedmodel}\n"

echo -e "Enter .ipsw URL and press enter:\n"
read ipswurl
filename=$(basename "$ipswurl")
version=$(echo "$filename" | awk -F '_' '{print $(NF-2)}')
buildid=$(echo "$filename" | awk -F '_' '{print $(NF-1)}')

clear
pzb --list "$ipswurl" > list.txt 2>&1
open -e list.txt
echo -e "Made by @dleovl\n\nUsing $ipswurl\n\nA file has been opened, please read it and type the model used for iBEC/iBSS/iBoot/LLB (should be different than DeviceTree, but really similar).\nFor example, j120 is used for iBEC/iBSS/iBoot/LLB while j120ap is used for DeviceTree. Type what would be in place of j120 (it should be closely related to your model). On the off chance that there is no direct match, please try the closest files (upon decryption, ensure the text is LEGIBLE. sep-firmware should stay the same)\n\nEnter the model found for your iBEC/iBSS/iBoot/LLB files:\n"
read model

echo -e "\nEnter codename for ${buildid} (this can be acquired from Wikipedia under "Release history")\n"
read codename

clear
echo -e "Made by @dleovl\n\nUsing $ipswurl\n\nPlease wait..."

pzb --get "Firmware/dfu/iBSS.$model.RELEASE.im4p" "$ipswurl" > /dev/null
pzb --get "Firmware/dfu/iBEC.$model.RELEASE.im4p" "$ipswurl" > /dev/null
pzb --get "Firmware/all_flash/LLB.$model.RELEASE.im4p" "$ipswurl" > /dev/null
pzb --get "Firmware/all_flash/iBoot.$model.RELEASE.im4p" "$ipswurl" > /dev/null
pzb --get "Firmware/all_flash/sep-firmware.$model.RELEASE.im4p" "$ipswurl" > /dev/null

criptam --build-id "$buildid" --device-identifier "$deviceid" > keys.txt

ibssiv=$(awk '/iBSS IV:/ {print $NF}' keys.txt)
ibsskey=$(awk '/iBSS Key:/ {print $NF}' keys.txt)
ibeciv=$(awk '/iBEC IV:/ {print $NF}' keys.txt)
ibeckey=$(awk '/iBEC Key:/ {print $NF}' keys.txt)
llbiv=$(awk '/LLB IV:/ {print $NF}' keys.txt)
llbkey=$(awk '/LLB Key:/ {print $NF}' keys.txt)
ibootiv=$(awk '/iBoot IV:/ {print $NF}' keys.txt)
ibootkey=$(awk '/iBoot Key:/ {print $NF}' keys.txt)

img4 -i iBSS* -o iBSS.dec -k ${ibssiv}${ibsskey} > /dev/null
img4 -i iBEC* -o iBEC.dec -k ${ibeciv}${ibeckey} > /dev/null
img4 -i iBoot* -o iBoot.dec -k ${ibootiv}${ibootkey} > /dev/null
img4 -i LLB* -o LLB.dec -k ${llbiv}${llbkey} > /dev/null
open -e iBSS.dec iBEC.dec iBoot.dec LLB.dec

sepfwinfo=$(pyimg4 im4p info -i sep-firmware*)
sepfwprodiv=$(echo "$sepfwinfo" | awk '/Type: PRODUCTION/ {getline; print $NF}')
sepfwprodkey=$(echo "$sepfwinfo" | awk '/Type: PRODUCTION/ {getline; getline; print $NF}')
sepfwdeviv=$(echo "$sepfwinfo" | awk '/Type: DEVELOPMENT/ {getline; print $NF}')
sepfwdevkey=$(echo "$sepfwinfo" | awk '/Type: DEVELOPMENT/ {getline; getline; print $NF}')

template="{{keys
 | Version               = ${version}
 | Build                 = ${buildid}
 | Device                = ${deviceid}
 | Codename              = ${codename}
 | DownloadURL           = ${ipswurl}

 | iBEC                  = iBEC.${model}.RELEASE.im4p
 | iBECIV                = ${ibeciv}
 | iBECKey               = ${ibeckey}

 | iBoot                 = iBoot.${model}.RELEASE.im4p
 | iBootIV               = ${ibootiv}
 | iBootKey              = ${ibootkey}

 | iBSS                  = iBSS.${model}.RELEASE.im4p
 | iBSSIV                = ${ibssiv}
 | iBSSKey               = ${ibsskey}

 | LLB                   = LLB.${model}.RELEASE.im4p
 | LLBIV                 = ${llbiv}
 | LLBKey                = ${llbkey}

 | SEPFirmware           = sep-firmware.${model}.RELEASE.im4p
 | SEPFirmwareIV         = Unknown
 | SEPFirmwareKey        = Unknown
 | SEPFirmwareKBAG       = ${sepfwprodiv}${sepfwprodkey}
 | SEPFirmwareDevKBAG    = ${sepfwdeviv}${sepfwdevkey}
}}"

mkdir -p wiki
echo "${template}" > "wiki/${codename}_${buildid}_(${deviceid}).txt"
open -e "wiki/${codename}_${buildid}_(${deviceid}).txt"

echo "Finished. You can ensure everything is correct by checking for legible text in iBSS/iBEC/iBoot/LLB (they have been opened). SEP firmware is not decrypted."
