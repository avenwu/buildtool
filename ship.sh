#!/usr/bin/env bash

##############################################################################
##  Script to release android apk, instead of wasting to build every time for
##  each market channel, we hacked to modify the first generated apk by add
##  different empty file into xx.apk/META-INF/.
##
##  Here we have some example listed below, app_official.apk and app_baidu.apk
##  has nearly the same folder structure:
##      app_official.apk
##      ----/META-INF
##      ----/META-INF/official.channel
##
##      app_baidu.apk
##      ----/META-INF
##      ----/META-INF/baidu.channel
##############################################################################
startTime=$(date +"%s")
echo -e "Shipping started...\nStart Time:"`date`
echo -e "./gradlew assembleRelease the original apk"
. channels.properties
./gradlew clean assembleRelease
if [ "$?" != "0" ]; then
   echo "Release failed"
   exit 1
fi
ls build/outputs/apk/*_*.apk
echo -e "genarate apks with different channel flag"
rm -rf apk
mkdir apk && cp build/outputs/apk/*_*.apk apk/pregnancy.apk && cd apk
chmod a+rw pregnancy.apk
mkdir META-INF && touch META-INF/pregnancy.channel
updateApk() {
    echo -e "release of $1: start at"`date`
    cp pregnancy.apk pregnancy_$1.apk && cp META-INF/pregnancy.channel META-INF/$1.channel
    zip -r pregnancy_$1.apk META-INF/$1.channel
    rm META-INF/$1.channel
}
channels=(${market_channels//,/ })
for channel in ${channels[@]};do
    updateApk $channel &
done
wait
echo -e "Release all finished...\nEnd Time:"`date`
endTime=$(date +"%s")
timeDiff=$(($endTime-$startTime))
echo "Time consumed for release:"`date -u -d @"$timeDiff" +'%-Mm %-Ss'`
apks=(*.apk)
for apk in ${apks[@]};do
   echo -e "verify $apk"
   unzip -l $apk|grep channel
done
