#!/bin/sh

#CHANNEL_DIR=`pwd`
CHANNEL_DIR="./KLive/Channel"
TARGET_DIR="./KLive"
GROUP_NAME="Channel_GROUP"
M3U_NAME="klive.m3u"
SJVA_FOLDER="./"
SJVA_DB_NAME="sjva.db"

echo "* m3u Generator"
# SJVA 확인
echo -n "  - checking SJVA db file : "
#echo " input your SJVA folder(just Enter to default)"
#read -p "   e.g) /home/SJVA2 : " SJVA_FOLDER
#if [ -z ${SJVA_FOLDER} ] ; then
#SJVA_FOLDER="/home/SJVA2"
#echo " use Default folder : '${SJVA_FOLDER}/data/db'"
#else
#echo " use Input folder : '${SJVA_FOLDER}/data/db'"
#fi
if [ ! -f "${SJVA_FOLDER}/data/db/${SJVA_DB_NAME}" ] ; then
	echo "No db file. check the folder."
	echo ""
else
	SJVA_PORT="$(sqlite3 ${SJVA_FOLDER}/data/db/${SJVA_DB_NAME} "select value from system_setting where key='port'")"
	UNIQUE_FLAG="$(sqlite3 ${SJVA_FOLDER}/data/db/${SJVA_DB_NAME} "select value from system_setting where key='auth_use_apikey'")"
	SJVA_UNIQUE="$(sqlite3 ${SJVA_FOLDER}/data/db/${SJVA_DB_NAME} "select value from system_setting where key='auth_apikey'")"
	SJVA_DDNS="$(sqlite3 ${SJVA_FOLDER}/data/db/${SJVA_DB_NAME} "select value from system_setting where key='ddns'")"
	echo "OK"
	echo -n "  - delete current list : "
	rm -rf ${TARGET_DIR}/${M3U_NAME}
	echo "done"
	echo "  - make new list"
	CHNO=0 # 채널시작번호-1
	echo "#EXTM3U" >> "${TARGET_DIR}/${M3U_NAME}"
	
	# WAVVE
	CHANNEL_NAME="Channel_WAVVE"
	CHANNEL_ID="WAVVE"
	channel_id="wavve"
	CHNO=`expr ${CHNO} + 1`
	if [ -f "${CHANNEL_DIR}/${CHANNEL_NAME}" ]; then
		CNT=`grep -o Source ${CHANNEL_DIR}/${CHANNEL_NAME} | wc -w`
		printf '    %s : Channels %s ....' "${CHANNEL_ID}" "${CNT}"
		# tmp 설정
		rm -rf ${CHANNEL_DIR}/tmpId ${CHANNEL_DIR}/tmpName ${CHANNEL_DIR}/tmpurl ${CHANNEL_DIR}/tmpgroup
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep ServiceId >> ${CHANNEL_DIR}/tmpId
		sed -i 's/"ServiceId": "//' ${CHANNEL_DIR}/tmpId
		sed -i 's/"//' ${CHANNEL_DIR}/tmpId
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep Name >> ${CHANNEL_DIR}/tmpName
		sed -i "s/\"${CHANNEL_ID} Name\": \"//" ${CHANNEL_DIR}/tmpName
		sed -i 's/",//' ${CHANNEL_DIR}/tmpName
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep url >> ${CHANNEL_DIR}/tmpurl
		sed -i 's/"Icon_url": "//' ${CHANNEL_DIR}/tmpurl
		sed -i 's/",//' ${CHANNEL_DIR}/tmpurl
		cat ${CHANNEL_DIR}/${GROUP_NAME} | grep ${CHANNEL_ID} >> ${CHANNEL_DIR}/tmpgroup
		# m3u 생성
		LINE_CNT=1
		while [ 1 ] ;
		do
			LINE_ID=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpId) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_CNT_TEMP=`expr ${LINE_CNT} + 1`
			LINE_ID_PLUS=$(sed -n ${LINE_CNT_temp}p ${CHANNEL_DIR}/tmpId) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_NAME=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpName) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_URL=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpurl) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_GROUP=$(cat ${CHANNEL_DIR}/tmpgroup | grep "${channel_id}|${LINE_ID}" | grep "${LINE_NAME}" | awk '{ print $NF }')
			if [ -z "${LINE_GROUP}" ] ; then
                LINE_GROUP=${channel_id}
            fi
			if [ ! -z "${LINE_ID}" ] && [ ! -z "${LINE_ID_PLUS}" ] ; then
				STR="#EXTINF:-1 tvg-id=\"${channel_id}|${LINE_ID}\" tvg-name=\"${LINE_NAME}\" tvg-logo=\"${LINE_URL}\" group-title=\"${LINE_GROUP}\" tvg-chno=\"${CHNO}\" tvh-chnum=\"${CHNO}\",${LINE_NAME}"
				echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
				if [ "${UNIQUE_FLAG}" == "False" ] ; then
					STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID}&q=default"
				else
					STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID}&q=default&apikey=${SJVA_UNIQUE}"
				fi
				echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
				printf '\r    %s : Channels %s .... %s' "${CHANNEL_ID}" "${CNT}" "${LINE_CNT}"
				LINE_CNT=`expr ${LINE_CNT} + 1`
			    CHNO=`expr ${CHNO} + 1`
			else
				if [ ! -z "${LINE_ID}" ] && [ -z "${LINE_ID_PLUS}" ] ; then
					STR="#EXTINF:-1 tvg-id=\"${channel_id}|${LINE_ID}\" tvg-name=\"${LINE_NAME}\" tvg-logo=\"${LINE_URL}\" group-title=\"${LINE_GROUP}\" tvg-chno=\"${CHNO}\" tvh-chnum=\"${CHNO}\",${LINE_NAME}"
					echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
					if [ "${UNIQUE_FLAG}" == "False" ] ; then
						STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID}&q=default"
					else
						STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID}&q=default&apikey=${SJVA_UNIQUE}"
					fi
					echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
					break
				else
					LINE_CNT=`expr ${LINE_CNT} - 1`
			        CHNO=`expr ${CHNO} - 1`
					break
				fi
			fi
		done
		printf '\r    %s : Channels %s .... done\n' "${CHANNEL_ID}" "${LINE_CNT}"
		# tmp 삭제
		rm -rf ${CHANNEL_DIR}/tmpId ${CHANNEL_DIR}/tmpName ${CHANNEL_DIR}/tmpurl ${CHANNEL_DIR}/tmpgroup
	else
		printf '    %s : No list\n' "${CHANEL_ID}"
	fi
	
	# TVING
	CHANNEL_NAME="Channel_TVING"
	CHANNEL_ID="TVING"
	channel_id="tving"
	CHNO=`expr ${CHNO} + 1`
	if [ -f "${CHANNEL_DIR}/${CHANNEL_NAME}" ]; then
		CNT=`grep -o Source ${CHANNEL_DIR}/${CHANNEL_NAME} | wc -w`
		printf '    %s : Channels %s ....' "${CHANNEL_ID}" "${CNT}"
		# tmp 설정
		rm -rf ${CHANNEL_DIR}/tmpId ${CHANNEL_DIR}/tmpName ${CHANNEL_DIR}/tmpurl ${CHANNEL_DIR}/tmpgroup
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep ServiceId >> ${CHANNEL_DIR}/tmpId
		sed -i 's/"ServiceId": "//' ${CHANNEL_DIR}/tmpId
		sed -i 's/"//' ${CHANNEL_DIR}/tmpId
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep Name >> ${CHANNEL_DIR}/tmpName
		sed -i "s/\"${CHANNEL_ID} Name\": \"//" ${CHANNEL_DIR}/tmpName
		sed -i 's/",//' ${CHANNEL_DIR}/tmpName
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep url >> ${CHANNEL_DIR}/tmpurl
		sed -i 's/"Icon_url": "//' ${CHANNEL_DIR}/tmpurl
		sed -i 's/",//' ${CHANNEL_DIR}/tmpurl
		cat ${CHANNEL_DIR}/${GROUP_NAME} | grep ${CHANNEL_ID} >> ${CHANNEL_DIR}/tmpgroup
		# m3u 생성
		LINE_CNT=1
		while [ 1 ] ;
		do
			LINE_ID=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpId) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_CNT_TEMP=`expr ${LINE_CNT} + 1`
			LINE_ID_PLUS=$(sed -n ${LINE_CNT_temp}p ${CHANNEL_DIR}/tmpId) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_NAME=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpName) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_URL=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpurl) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_GROUP=$(cat ${CHANNEL_DIR}/tmpgroup | grep "${channel_id}|${LINE_ID}" | grep "${LINE_NAME}" | awk '{ print $NF }')
			if [ -z "${LINE_GROUP}" ] ; then
                LINE_GROUP=${channel_id}
            fi
			if [ ! -z "${LINE_ID}" ] && [ ! -z "${LINE_ID_PLUS}" ] ; then
				STR="#EXTINF:-1 tvg-id=\"${channel_id}|${LINE_ID}\" tvg-name=\"${LINE_NAME}\" tvg-logo=\"${LINE_URL}\" group-title=\"${LINE_GROUP}\" tvg-chno=\"${CHNO}\" tvh-chnum=\"${CHNO}\",${LINE_NAME}"
				echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
				if [ "${UNIQUE_FLAG}" == "False" ] ; then
					STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID}&q=default"
				else
					STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID}&q=default&apikey=${SJVA_UNIQUE}"
				fi
				echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
				printf '\r    %s : Channels %s .... %s' "${CHANNEL_ID}" "${CNT}" "${LINE_CNT}"
				LINE_CNT=`expr ${LINE_CNT} + 1`
			    CHNO=`expr ${CHNO} + 1`
			else
				if [ ! -z "${LINE_ID}" ] && [ -z "${LINE_ID_PLUS}" ] ; then
					STR="#EXTINF:-1 tvg-id=\"${channel_id}|${LINE_ID}\" tvg-name=\"${LINE_NAME}\" tvg-logo=\"${LINE_URL}\" group-title=\"${LINE_GROUP}\" tvg-chno=\"${CHNO}\" tvh-chnum=\"${CHNO}\",${LINE_NAME}"
					echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
					if [ "${UNIQUE_FLAG}" == "False" ] ; then
						STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID}&q=default"
					else
						STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID}&q=default&apikey=${SJVA_UNIQUE}"
					fi
					echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
					break
				else
			        LINE_CNT=`expr ${LINE_CNT} - 1`
			        CHNO=`expr ${CHNO} - 1`
					break
				fi
			fi
		done
		printf '\r    %s : Channels %s .... done\n' "${CHANNEL_ID}" "${LINE_CNT}"
		# tmp 삭제
		rm -rf ${CHANNEL_DIR}/tmpId ${CHANNEL_DIR}/tmpName ${CHANNEL_DIR}/tmpurl ${CHANNEL_DIR}/tmpgroup
		# modify
		sed -i 's@url.m3u8?m=url\&s=tving\&i=C04601@url.mpd?m=url\&s=tving\&i=C04601@' "${TARGET_DIR}/${M3U_NAME}"
		sed -i 's@url.m3u8?m=url\&s=tving\&i=C05661@url.mpd?m=url\&s=tving\&i=C05661@' "${TARGET_DIR}/${M3U_NAME}"
		sed -i 's@url.m3u8?m=url\&s=tving\&i=C07381@url.mpd?m=url\&s=tving\&i=C07381@' "${TARGET_DIR}/${M3U_NAME}"
		sed -i 's@url.m3u8?m=url\&s=tving\&i=C07382@url.mpd?m=url\&s=tving\&i=C07382@' "${TARGET_DIR}/${M3U_NAME}"
	else
		printf '    %s : No list\n' "${CHANEL_ID}"
	fi
	
: << "END"
	# EVERYON
	CHANNEL_NAME="Channel_everyon"
	CHANNEL_ID="EVERYON"
	channel_id="everyon"
	CHNO=`expr ${CHNO} + 1`
	if [ -f "${CHANNEL_DIR}/${CHANNEL_NAME}" ]; then
		CNT=`grep -o Source ${CHANNEL_DIR}/${CHANNEL_NAME} | wc -w`
		printf '    %s : Channels %s ....' "${CHANNEL_ID}" "${CNT}"
		# tmp 설정
		rm -rf ${CHANNEL_DIR}/tmpId ${CHANNEL_DIR}/tmpName ${CHANNEL_DIR}/tmpurl ${CHANNEL_DIR}/tmpgroup
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep '"Id"' >> ${CHANNEL_DIR}/tmpId
		sed -i 's/"Id": //' ${CHANNEL_DIR}/tmpId
		sed -i 's/,//' ${CHANNEL_DIR}/tmpId
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep Name >> ${CHANNEL_DIR}/tmpName
		sed -i "s/\"Name\": \"//" ${CHANNEL_DIR}/tmpName
		sed -i 's/",//' ${CHANNEL_DIR}/tmpName
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep url >> ${CHANNEL_DIR}/tmpurl
		sed -i 's/"Icon_url": "//' ${CHANNEL_DIR}/tmpurl
		sed -i 's/",//' ${CHANNEL_DIR}/tmpurl
		cat ${CHANNEL_DIR}/${GROUP_NAME} | grep ${CHANNEL_ID} >> ${CHANNEL_DIR}/tmpgroup
		# m3u 생성
		LINE_CNT=1
		while [ 1 ] ;
		do
			LINE_ID=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpId) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_CNT_TEMP=`expr ${LINE_CNT} + 1`
			LINE_ID_PLUS=$(sed -n ${LINE_CNT_temp}p ${CHANNEL_DIR}/tmpId) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_NAME=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpName) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_URL=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpurl) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_GROUP=$(cat ${CHANNEL_DIR}/tmpgroup | grep "${LINE_ID}" | grep "${LINE_NAME}" | awk '{ print $NF }')
			if [ -z "${LINE_GROUP}" ] ; then
                LINE_GROUP=${channel_id}
            fi
			if [ ! -z "${LINE_ID}" ] && [ ! -z "${LINE_ID_PLUS}" ] ; then
				STR="#EXTINF:-1 tvg-id=\"${LINE_ID}\" tvg-name=\"${LINE_NAME}\" tvg-logo=\"${LINE_URL}\" group-title=\"${LINE_GROUP}\" tvg-chno=\"${CHNO}\" tvh-chnum=\"${CHNO}\",${LINE_NAME}"
				echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
				if [ "${UNIQUE_FLAG}" == "False" ] ; then
					STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID}&q=default"
				else
					STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID}&q=default&apikey=${SJVA_UNIQUE}"
				fi
				echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
				printf '\r    %s : Channels %s .... %s' "${CHANNEL_ID}" "${CNT}" "${LINE_CNT}"
				LINE_CNT=`expr ${LINE_CNT} + 1`
			    CHNO=`expr ${CHNO} + 1`
			else
				if [ ! -z "${LINE_ID}" ] && [ -z "${LINE_ID_PLUS}" ] ; then
					STR="#EXTINF:-1 tvg-id=\"${LINE_ID}\" tvg-name=\"${LINE_NAME}\" tvg-logo=\"${LINE_URL}\" group-title=\"${LINE_GROUP}\" tvg-chno=\"${CHNO}\" tvh-chnum=\"${CHNO}\",${LINE_NAME}"
					echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
					if [ "${UNIQUE_FLAG}" == "False" ] ; then
						STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID}&q=default"
					else
						STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID}&q=default&apikey=${SJVA_UNIQUE}"
					fi
					echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
					break
				else
					LINE_CNT=`expr ${LINE_CNT} - 1`
			        CHNO=`expr ${CHNO} - 1`
					break
				fi
			fi
		done
		printf '\r    %s : Channels %s .... done\n' "${CHANNEL_ID}" "${LINE_CNT}"
		# tmp 삭제
		rm -rf ${CHANNEL_DIR}/tmpId ${CHANNEL_DIR}/tmpName ${CHANNEL_DIR}/tmpurl ${CHANNEL_DIR}/tmpgroup
	else
		printf '    %s : No list\n' "${CHANEL_ID}"
	fi
END
	
	# VIDEOPORTAL
	CHANNEL_NAME="Channel_videoportal"
	CHANNEL_ID="VIDEOPORTAL"
	channel_id="videoportal"
	CHNO=`expr ${CHNO} + 1`
	if [ -f "${CHANNEL_DIR}/${CHANNEL_NAME}" ]; then
		CNT=`grep -o Source ${CHANNEL_DIR}/${CHANNEL_NAME} | wc -w`
		printf '    %s : Channels %s ....' "${CHANNEL_ID}" "${CNT}"
		# tmp 설정
		rm -rf ${CHANNEL_DIR}/tmpId ${CHANNEL_DIR}/tmpName ${CHANNEL_DIR}/tmpurl ${CHANNEL_DIR}/tmpgroup
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep '"Id"' >> ${CHANNEL_DIR}/tmpId
		sed -i 's/"Id": //' ${CHANNEL_DIR}/tmpId
		sed -i 's/,//' ${CHANNEL_DIR}/tmpId
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep Name >> ${CHANNEL_DIR}/tmpName
		sed -i "s/\"Name\": \"//" ${CHANNEL_DIR}/tmpName
		sed -i 's/",//' ${CHANNEL_DIR}/tmpName
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep url >> ${CHANNEL_DIR}/tmpurl
		sed -i 's/"Icon_url": "//' ${CHANNEL_DIR}/tmpurl
		sed -i 's/",//' ${CHANNEL_DIR}/tmpurl
		cat ${CHANNEL_DIR}/${GROUP_NAME} | grep ${CHANNEL_ID} >> ${CHANNEL_DIR}/tmpgroup
		# m3u 생성
		LINE_CNT=1
		while [ 1 ] ;
		do
			LINE_ID=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpId) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_CNT_TEMP=`expr ${LINE_CNT} + 1`
			LINE_ID_PLUS=$(sed -n ${LINE_CNT_temp}p ${CHANNEL_DIR}/tmpId) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_NAME=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpName) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_URL=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpurl) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_GROUP=$(cat ${CHANNEL_DIR}/tmpgroup | grep "${LINE_ID}" | grep "${LINE_NAME}" | awk '{ print $NF }')
			if [ -z "${LINE_GROUP}" ] ; then
                LINE_GROUP=${channel_id}
            fi
			if [ ! -z "${LINE_ID}" ] && [ ! -z "${LINE_ID_PLUS}" ] ; then
				STR="#EXTINF:-1 tvg-id=\"${LINE_ID}\" tvg-name=\"${LINE_NAME}\" tvg-logo=\"${LINE_URL}\" group-title=\"${LINE_GROUP}\" tvg-chno=\"${CHNO}\" tvh-chnum=\"${CHNO}\",${LINE_NAME}"
				echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
				if [ "${UNIQUE_FLAG}" == "False" ] ; then
					STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID}&q=default"
				else
					STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID}&q=default&apikey=${SJVA_UNIQUE}"
				fi
				echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
				printf '\r    %s : Channels %s .... %s' "${CHANNEL_ID}" "${CNT}" "${LINE_CNT}"
				LINE_CNT=`expr ${LINE_CNT} + 1`
			    CHNO=`expr ${CHNO} + 1`
			else
				if [ ! -z "${LINE_ID}" ] && [ -z "${LINE_ID_PLUS}" ] ; then
					STR="#EXTINF:-1 tvg-id=\"${LINE_ID}\" tvg-name=\"${LINE_NAME}\" tvg-logo=\"${LINE_URL}\" group-title=\"${LINE_GROUP}\" tvg-chno=\"${CHNO}\" tvh-chnum=\"${CHNO}\",${LINE_NAME}"
					echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
					if [ "${UNIQUE_FLAG}" == "False" ] ; then
						STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID}&q=default"
					else
						STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID}&q=default&apikey=${SJVA_UNIQUE}"
					fi
					echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
					break
				else
					LINE_CNT=`expr ${LINE_CNT} - 1`
			        CHNO=`expr ${CHNO} - 1`
					break
				fi
			fi
		done
		printf '\r    %s : Channels %s .... done\n' "${CHANNEL_ID}" "${LINE_CNT}"
		# tmp 삭제
		rm -rf ${CHANNEL_DIR}/tmpId ${CHANNEL_DIR}/tmpName ${CHANNEL_DIR}/tmpurl ${CHANNEL_DIR}/tmpgroup
	else
		printf '    %s : No list\n' "${CHANEL_ID}"
	fi

	# ADD
	CHANNEL_NAME="Channel_baseball"
	ADD_ID="BASEBALL"
	CHANNEL_ID="VIDEOPORTAL"
	channel_id="videoportal"
	CHNO=`expr ${CHNO} + 1`
	if [ -f "${CHANNEL_DIR}/${CHANNEL_NAME}" ]; then
		CNT=`grep -o Source ${CHANNEL_DIR}/${CHANNEL_NAME} | wc -w`
		printf '    %s : Channels %s ....' "${ADD_ID}" "${CNT}"
		# tmp 설정
		rm -rf ${CHANNEL_DIR}/tmpId ${CHANNEL_DIR}/tmpName ${CHANNEL_DIR}/tmpurl ${CHANNEL_DIR}/tmpgroup
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep '"Id"' >> ${CHANNEL_DIR}/tmpId
		sed -i 's/"Id": //' ${CHANNEL_DIR}/tmpId
		sed -i 's/,//' ${CHANNEL_DIR}/tmpId
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep Name >> ${CHANNEL_DIR}/tmpName
		sed -i "s/\"Name\": \"//" ${CHANNEL_DIR}/tmpName
		sed -i 's/",//' ${CHANNEL_DIR}/tmpName
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep url >> ${CHANNEL_DIR}/tmpurl
		sed -i 's/"Icon_url": "//' ${CHANNEL_DIR}/tmpurl
		sed -i 's/",//' ${CHANNEL_DIR}/tmpurl
		cat ${CHANNEL_DIR}/${GROUP_NAME} | grep ${CHANNEL_ID} >> ${CHANNEL_DIR}/tmpgroup
		# m3u 생성
		LINE_CNT=1
		while [ 1 ] ;
		do
			LINE_ID=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpId) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_CNT_TEMP=`expr ${LINE_CNT} + 1`
			LINE_ID_PLUS=$(sed -n ${LINE_CNT_temp}p ${CHANNEL_DIR}/tmpId) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_NAME=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpName) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_URL=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpurl) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_GROUP=$(cat ${CHANNEL_DIR}/tmpgroup | grep "${LINE_ID}" | grep "${LINE_NAME}" | awk '{ print $NF }')
			if [ -z "${LINE_GROUP}" ] ; then
                LINE_GROUP=${channel_id}
            fi
			if [ ! -z "${LINE_ID}" ] && [ ! -z "${LINE_ID_PLUS}" ] ; then
				STR="#EXTINF:-1 tvg-id=\"${LINE_ID}\" tvg-name=\"${LINE_NAME}\" tvg-logo=\"${LINE_URL}\" group-title=\"${LINE_GROUP}\" tvg-chno=\"${CHNO}\" tvh-chnum=\"${CHNO}\",${LINE_NAME}"
				echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
				if [ "${UNIQUE_FLAG}" == "False" ] ; then
					STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID}&q=default"
				else
					STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID}&q=default&apikey=${SJVA_UNIQUE}"
				fi
				echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
				printf '\r    %s : Channels %s .... %s' "${ADD_ID}" "${CNT}" "${LINE_CNT}"
				LINE_CNT=`expr ${LINE_CNT} + 1`
			    CHNO=`expr ${CHNO} + 1`
			else
				if [ ! -z "${LINE_ID}" ] && [ -z "${LINE_ID_PLUS}" ] ; then
					STR="#EXTINF:-1 tvg-id=\"${LINE_ID}\" tvg-name=\"${LINE_NAME}\" tvg-logo=\"${LINE_URL}\" group-title=\"${LINE_GROUP}\" tvg-chno=\"${CHNO}\" tvh-chnum=\"${CHNO}\",${LINE_NAME}"
					echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
					if [ "${UNIQUE_FLAG}" == "False" ] ; then
						STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID}&q=default"
					else
						STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID}&q=default&apikey=${SJVA_UNIQUE}"
					fi
					echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
					break
				else
					LINE_CNT=`expr ${LINE_CNT} - 1`
			        CHNO=`expr ${CHNO} - 1`
					break
				fi
			fi
		done
		printf '\r    %s : Channels %s .... done\n' "${ADD_ID}" "${LINE_CNT}"
		# tmp 삭제
		rm -rf ${CHANNEL_DIR}/tmpId ${CHANNEL_DIR}/tmpName ${CHANNEL_DIR}/tmpurl ${CHANNEL_DIR}/tmpgroup
	else
		printf '    %s : No list\n' "${ADD_ID}"
	fi
	
	# kbs
	CHANNEL_NAME="Channel_kbs"
	CHANNEL_ID="kbs"
	channel_id="kbs"
	CHNO=`expr ${CHNO} + 1`
	if [ -f "${CHANNEL_DIR}/${CHANNEL_NAME}" ]; then
		CNT=`grep -o Source ${CHANNEL_DIR}/${CHANNEL_NAME} | wc -w`
		printf '    %s : Channels %s ....' "${CHANNEL_ID}" "${CNT}"
		# tmp 설정
		rm -rf ${CHANNEL_DIR}/tmpId ${CHANNEL_DIR}/tmpName ${CHANNEL_DIR}/tmpurl ${CHANNEL_DIR}/tmpgroup
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep '"Id"' >> ${CHANNEL_DIR}/tmpId
		sed -i 's/"Id": //' ${CHANNEL_DIR}/tmpId
		sed -i 's/,//' ${CHANNEL_DIR}/tmpId
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep Name >> ${CHANNEL_DIR}/tmpName
		sed -i "s/\"Name\": \"//" ${CHANNEL_DIR}/tmpName
		sed -i 's/",//' ${CHANNEL_DIR}/tmpName
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep url >> ${CHANNEL_DIR}/tmpurl
		sed -i 's/"Icon_url": "//' ${CHANNEL_DIR}/tmpurl
		sed -i 's/",//' ${CHANNEL_DIR}/tmpurl
		cat ${CHANNEL_DIR}/${GROUP_NAME} | grep ${CHANNEL_ID} >> ${CHANNEL_DIR}/tmpgroup
		# m3u 생성
		LINE_CNT=1
		while [ 1 ] ;
		do
			LINE_ID=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpId) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_CNT_TEMP=`expr ${LINE_CNT} + 1`
			LINE_ID_PLUS=$(sed -n ${LINE_CNT_temp}p ${CHANNEL_DIR}/tmpId) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_NAME=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpName) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_URL=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpurl) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_GROUP=$(cat ${CHANNEL_DIR}/tmpgroup | grep "${LINE_ID}" | grep "${LINE_NAME}" | awk '{ print $NF }')
			if [ -z "${LINE_GROUP}" ] ; then
                LINE_GROUP=${channel_id}
            fi
			if [ ! -z "${LINE_ID}" ] && [ ! -z "${LINE_ID_PLUS}" ] ; then
				STR="#EXTINF:-1 tvg-id=\"${LINE_ID}\" tvg-name=\"${LINE_NAME}\" tvg-logo=\"${LINE_URL}\" group-title=\"${LINE_GROUP}\" tvg-chno=\"${CHNO}\" tvh-chnum=\"${CHNO}\",${LINE_NAME}"
				echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
				if [ "${UNIQUE_FLAG}" == "False" ] ; then
					STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID#*|}&q=default"
				else
					STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID#*|}&q=default&apikey=${SJVA_UNIQUE}"
				fi
				echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
				printf '\r    %s : Channels %s .... %s' "${CHANNEL_ID}" "${CNT}" "${LINE_CNT}"
				LINE_CNT=`expr ${LINE_CNT} + 1`
			    CHNO=`expr ${CHNO} + 1`
			else
				if [ ! -z "${LINE_ID}" ] && [ -z "${LINE_ID_PLUS}" ] ; then
					STR="#EXTINF:-1 tvg-id=\"${LINE_ID}\" tvg-name=\"${LINE_NAME}\" tvg-logo=\"${LINE_URL}\" group-title=\"${LINE_GROUP}\" tvg-chno=\"${CHNO}\" tvh-chnum=\"${CHNO}\",${LINE_NAME}"
					echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
					if [ "${UNIQUE_FLAG}" == "False" ] ; then
						STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID#*|}&q=default"
					else
						STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID#*|}&q=default&apikey=${SJVA_UNIQUE}"
					fi
					echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
					break
				else
					LINE_CNT=`expr ${LINE_CNT} - 1`
			        CHNO=`expr ${CHNO} - 1`
					break
				fi
			fi
		done
		printf '\r    %s : Channels %s .... done\n' "${CHANNEL_ID}" "${LINE_CNT}"
		# tmp 삭제
		rm -rf ${CHANNEL_DIR}/tmpId ${CHANNEL_DIR}/tmpName ${CHANNEL_DIR}/tmpurl ${CHANNEL_DIR}/tmpgroup
	else
		printf '    %s : No list\n' "${CHANEL_ID}"
	fi	
	
	# sbs
	CHANNEL_NAME="Channel_sbs"
	CHANNEL_ID="sbs"
	channel_id="sbs"
	CHNO=`expr ${CHNO} + 1`
	if [ -f "${CHANNEL_DIR}/${CHANNEL_NAME}" ]; then
		CNT=`grep -o Source ${CHANNEL_DIR}/${CHANNEL_NAME} | wc -w`
		printf '    %s : Channels %s ....' "${CHANNEL_ID}" "${CNT}"
		# tmp 설정
		rm -rf ${CHANNEL_DIR}/tmpId ${CHANNEL_DIR}/tmpName ${CHANNEL_DIR}/tmpurl ${CHANNEL_DIR}/tmpgroup
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep '"Id"' >> ${CHANNEL_DIR}/tmpId
		sed -i 's/"Id": //' ${CHANNEL_DIR}/tmpId
		sed -i 's/,//' ${CHANNEL_DIR}/tmpId
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep Name >> ${CHANNEL_DIR}/tmpName
		sed -i "s/\"Name\": \"//" ${CHANNEL_DIR}/tmpName
		sed -i 's/",//' ${CHANNEL_DIR}/tmpName
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep url >> ${CHANNEL_DIR}/tmpurl
		sed -i 's/"Icon_url": "//' ${CHANNEL_DIR}/tmpurl
		sed -i 's/",//' ${CHANNEL_DIR}/tmpurl
		cat ${CHANNEL_DIR}/${GROUP_NAME} | grep ${CHANNEL_ID} >> ${CHANNEL_DIR}/tmpgroup
		# m3u 생성
		LINE_CNT=1
		while [ 1 ] ;
		do
			LINE_ID=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpId) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_CNT_TEMP=`expr ${LINE_CNT} + 1`
			LINE_ID_PLUS=$(sed -n ${LINE_CNT_temp}p ${CHANNEL_DIR}/tmpId) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_NAME=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpName) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_URL=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpurl) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_GROUP=$(cat ${CHANNEL_DIR}/tmpgroup | grep "${LINE_ID}" | grep "${LINE_NAME}" | awk '{ print $NF }')
			if [ -z "${LINE_GROUP}" ] ; then
                LINE_GROUP=${channel_id}
            fi
			if [ ! -z "${LINE_ID}" ] && [ ! -z "${LINE_ID_PLUS}" ] ; then
				STR="#EXTINF:-1 tvg-id=\"${LINE_ID}\" tvg-name=\"${LINE_NAME}\" tvg-logo=\"${LINE_URL}\" group-title=\"${LINE_GROUP}\" tvg-chno=\"${CHNO}\" tvh-chnum=\"${CHNO}\",${LINE_NAME}"
				echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
				if [ "${UNIQUE_FLAG}" == "False" ] ; then
					STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID#*|}&q=default"
				else
					STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID#*|}&q=default&apikey=${SJVA_UNIQUE}"
				fi
				echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
				printf '\r    %s : Channels %s .... %s' "${CHANNEL_ID}" "${CNT}" "${LINE_CNT}"
				LINE_CNT=`expr ${LINE_CNT} + 1`
			    CHNO=`expr ${CHNO} + 1`
			else
				if [ ! -z "${LINE_ID}" ] && [ -z "${LINE_ID_PLUS}" ] ; then
					STR="#EXTINF:-1 tvg-id=\"${LINE_ID}\" tvg-name=\"${LINE_NAME}\" tvg-logo=\"${LINE_URL}\" group-title=\"${LINE_GROUP}\" tvg-chno=\"${CHNO}\" tvh-chnum=\"${CHNO}\",${LINE_NAME}"
					echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
					if [ "${UNIQUE_FLAG}" == "False" ] ; then
						STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID#*|}&q=default"
					else
						STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID#*|}&q=default&apikey=${SJVA_UNIQUE}"
					fi
					echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
					break
				else
					LINE_CNT=`expr ${LINE_CNT} - 1`
			        CHNO=`expr ${CHNO} - 1`
					break
				fi
			fi
		done
		printf '\r    %s : Channels %s .... done\n' "${CHANNEL_ID}" "${LINE_CNT}"
		# tmp 삭제
		rm -rf ${CHANNEL_DIR}/tmpId ${CHANNEL_DIR}/tmpName ${CHANNEL_DIR}/tmpurl ${CHANNEL_DIR}/tmpgroup
	else
		printf '    %s : No list\n' "${CHANEL_ID}"
	fi

	# youtube-dl
	CHANNEL_NAME="Channel_youtubedl"
	CHANNEL_ID="youtubedl"
	channel_id="youtubedl"
	CHNO=`expr ${CHNO} + 1`
	if [ -f "${CHANNEL_DIR}/${CHANNEL_NAME}" ]; then
		CNT=`grep -o Source ${CHANNEL_DIR}/${CHANNEL_NAME} | wc -w`
		printf '    %s : Channels %s ....' "${CHANNEL_ID}" "${CNT}"
		# tmp 설정
		rm -rf ${CHANNEL_DIR}/tmpId ${CHANNEL_DIR}/tmpName ${CHANNEL_DIR}/tmpurl ${CHANNEL_DIR}/tmpgroup
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep '"Id"' >> ${CHANNEL_DIR}/tmpId
		sed -i 's/"Id": //' ${CHANNEL_DIR}/tmpId
		sed -i 's/,//' ${CHANNEL_DIR}/tmpId
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep Name >> ${CHANNEL_DIR}/tmpName
		sed -i "s/\"Name\": \"//" ${CHANNEL_DIR}/tmpName
		sed -i 's/",//' ${CHANNEL_DIR}/tmpName
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep url >> ${CHANNEL_DIR}/tmpurl
		sed -i 's/"Icon_url": "//' ${CHANNEL_DIR}/tmpurl
		sed -i 's/",//' ${CHANNEL_DIR}/tmpurl
		cat ${CHANNEL_DIR}/${GROUP_NAME} | grep ${CHANNEL_ID} >> ${CHANNEL_DIR}/tmpgroup
		# m3u 생성
		LINE_CNT=1
		while [ 1 ] ;
		do
			LINE_ID=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpId) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_CNT_TEMP=`expr ${LINE_CNT} + 1`
			LINE_ID_PLUS=$(sed -n ${LINE_CNT_temp}p ${CHANNEL_DIR}/tmpId) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_NAME=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpName) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_URL=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpurl) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_GROUP=$(cat ${CHANNEL_DIR}/tmpgroup | grep "${LINE_ID}" | grep "${LINE_NAME}" | awk '{ print $NF }')
			if [ -z "${LINE_GROUP}" ] ; then
                LINE_GROUP=${channel_id}
            fi
			if [ ! -z "${LINE_ID}" ] && [ ! -z "${LINE_ID_PLUS}" ] ; then
				STR="#EXTINF:-1 tvg-id=\"${LINE_ID}\" tvg-name=\"${LINE_NAME}\" tvg-logo=\"${LINE_URL}\" group-title=\"${LINE_GROUP}\" tvg-chno=\"${CHNO}\" tvh-chnum=\"${CHNO}\",${LINE_NAME}"
				echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
				if [ "${UNIQUE_FLAG}" == "False" ] ; then
					STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID#*|}&q=default"
				else
					STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID#*|}&q=default&apikey=${SJVA_UNIQUE}"
				fi
				echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
				printf '\r    %s : Channels %s .... %s' "${CHANNEL_ID}" "${CNT}" "${LINE_CNT}"
				LINE_CNT=`expr ${LINE_CNT} + 1`
			    CHNO=`expr ${CHNO} + 1`
			else
				if [ ! -z "${LINE_ID}" ] && [ -z "${LINE_ID_PLUS}" ] ; then
					STR="#EXTINF:-1 tvg-id=\"${LINE_ID}\" tvg-name=\"${LINE_NAME}\" tvg-logo=\"${LINE_URL}\" group-title=\"${LINE_GROUP}\" tvg-chno=\"${CHNO}\" tvh-chnum=\"${CHNO}\",${LINE_NAME}"
					echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
					if [ "${UNIQUE_FLAG}" == "False" ] ; then
						STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID#*|}&q=default"
					else
						STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID#*|}&q=default&apikey=${SJVA_UNIQUE}"
					fi
					echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
					break
				else
					LINE_CNT=`expr ${LINE_CNT} - 1`
			        CHNO=`expr ${CHNO} - 1`
					break
				fi
			fi
		done
		printf '\r    %s : Channels %s .... done\n' "${CHANNEL_ID}" "${LINE_CNT}"
		# tmp 삭제
		rm -rf ${CHANNEL_DIR}/tmpId ${CHANNEL_DIR}/tmpName ${CHANNEL_DIR}/tmpurl ${CHANNEL_DIR}/tmpgroup
	else
		printf '    %s : No list\n' "${CHANEL_ID}"
	fi
	
	# streamlink
	CHANNEL_NAME="Channel_streamlink"
	CHANNEL_ID="streamlink"
	channel_id="streamlink"
	CHNO=`expr ${CHNO} + 1`
	if [ -f "${CHANNEL_DIR}/${CHANNEL_NAME}" ]; then
		CNT=`grep -o Source ${CHANNEL_DIR}/${CHANNEL_NAME} | wc -w`
		printf '    %s : Channels %s ....' "${CHANNEL_ID}" "${CNT}"
		# tmp 설정
		rm -rf ${CHANNEL_DIR}/tmpId ${CHANNEL_DIR}/tmpName ${CHANNEL_DIR}/tmpurl ${CHANNEL_DIR}/tmpgroup
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep '"Id"' >> ${CHANNEL_DIR}/tmpId
		sed -i 's/"Id": //' ${CHANNEL_DIR}/tmpId
		sed -i 's/,//' ${CHANNEL_DIR}/tmpId
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep Name >> ${CHANNEL_DIR}/tmpName
		sed -i "s/\"Name\": \"//" ${CHANNEL_DIR}/tmpName
		sed -i 's/",//' ${CHANNEL_DIR}/tmpName
		cat ${CHANNEL_DIR}/${CHANNEL_NAME} | grep url >> ${CHANNEL_DIR}/tmpurl
		sed -i 's/"Icon_url": "//' ${CHANNEL_DIR}/tmpurl
		sed -i 's/",//' ${CHANNEL_DIR}/tmpurl
		cat ${CHANNEL_DIR}/${GROUP_NAME} | grep ${CHANNEL_ID} >> ${CHANNEL_DIR}/tmpgroup
		# m3u 생성
		LINE_CNT=1
		while [ 1 ] ;
		do
			LINE_ID=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpId) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_CNT_TEMP=`expr ${LINE_CNT} + 1`
			LINE_ID_PLUS=$(sed -n ${LINE_CNT_temp}p ${CHANNEL_DIR}/tmpId) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_NAME=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpName) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_URL=$(sed -n ${LINE_CNT}p ${CHANNEL_DIR}/tmpurl) # | sed -e 's/^ *//g' -e 's/ *$//g')
			LINE_GROUP=$(cat ${CHANNEL_DIR}/tmpgroup | grep "${LINE_ID}" | grep "${LINE_NAME}" | awk '{ print $NF }')
			if [ -z "${LINE_GROUP}" ] ; then
                LINE_GROUP=${channel_id}
            fi
			if [ ! -z "${LINE_ID}" ] && [ ! -z "${LINE_ID_PLUS}" ] ; then
				STR="#EXTINF:-1 tvg-id=\"${LINE_ID}\" tvg-name=\"${LINE_NAME}\" tvg-logo=\"${LINE_URL}\" group-title=\"${LINE_GROUP}\" tvg-chno=\"${CHNO}\" tvh-chnum=\"${CHNO}\",${LINE_NAME}"
				echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
				if [ "${UNIQUE_FLAG}" == "False" ] ; then
					STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID#*|}&q=default"
				else
					STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID#*|}&q=default&apikey=${SJVA_UNIQUE}"
				fi
				echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
				printf '\r    %s : Channels %s .... %s' "${CHANNEL_ID}" "${CNT}" "${LINE_CNT}"
				LINE_CNT=`expr ${LINE_CNT} + 1`
			    CHNO=`expr ${CHNO} + 1`
			else
				if [ ! -z "${LINE_ID}" ] && [ -z "${LINE_ID_PLUS}" ] ; then
					STR="#EXTINF:-1 tvg-id=\"${LINE_ID}\" tvg-name=\"${LINE_NAME}\" tvg-logo=\"${LINE_URL}\" group-title=\"${LINE_GROUP}\" tvg-chno=\"${CHNO}\" tvh-chnum=\"${CHNO}\",${LINE_NAME}"
					echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
					if [ "${UNIQUE_FLAG}" == "False" ] ; then
						STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID#*|}&q=default"
					else
						STR="${SJVA_DDNS}/klive/api/url.m3u8?m=url&s=${channel_id}&i=${LINE_ID#*|}&q=default&apikey=${SJVA_UNIQUE}"
					fi
					echo ${STR} >> "${TARGET_DIR}/${M3U_NAME}"
					break
				else
					LINE_CNT=`expr ${LINE_CNT} - 1`
			        CHNO=`expr ${CHNO} - 1`
					break
				fi
			fi
		done
		printf '\r    %s : Channels %s .... done\n' "${CHANNEL_ID}" "${LINE_CNT}"
		# tmp 삭제
		rm -rf ${CHANNEL_DIR}/tmpId ${CHANNEL_DIR}/tmpName ${CHANNEL_DIR}/tmpurl ${CHANNEL_DIR}/tmpgroup
	else
		printf '    %s : No list\n' "${CHANEL_ID}"
	fi
	
	printf '    Total %s Channels\n' "${CHNO}"
	echo "Finish!"
fi
