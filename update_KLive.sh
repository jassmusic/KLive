#!/bin/sh

cur=`pwd`
cd ./KLive
echo "jassmusic KLive git update"
git pull
echo "done"
cd $cur
echo ""
bash ./KLive/m3u/make_klive.m3u.sh
