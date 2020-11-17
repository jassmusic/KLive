#!/bin/bash
WAVVE_name="Channel_WAVVE"
#TVING_name="Channel_TVING"
#everyon_name="Channel_everyon"
videoportal_name="Channel_videoportal"
etc_name="Channel_etc"
total=0

#dir=`pwd`
dir="./KLive/Channel"
target_dir="./KLive/xml"
name="Channel.json"
flag=0

echo "* Channel.json Generator"
echo -n " - delete current list : "
rm -rf ${dir}/${name}
echo "done"

echo " - make new list"
echo "[" >> ${dir}/${name}

if [ -f ${dir}/${WAVVE_name} ]; then
    if [ ${flag} == 1 ]; then
        echo "," >> ${dir}/${name}
    fi
    cat ${dir}/${WAVVE_name} >> ${dir}/${name}
    flag=1
    cnt=`grep -o Source ${dir}/${WAVVE_name} | wc -w`
    printf '   WAVVE : Channels %s\n' "${cnt}"
    total=`expr ${total} + ${cnt}`
else
    flag=0
    printf '   WAVVE : No list\n'
fi

: << "END"
if [ -f ${dir}/${TVING_name} ]; then
    if [ ${flag} == 1 ]; then
        echo "," >> ${dir}/${name}
    fi
    cat ${dir}/${TVING_name} >> ${dir}/${name}
    flag=1
    cnt=`grep -o Source ${dir}/${TVING_name} | wc -w`
    printf '   TVING : Channels %s\n' "${cnt}"
    total=`expr ${total} + ${cnt}`
else
    flag=0
    printf '   TVING : No list\n'
fi
END

: << "END"
if [ -f ${dir}/${everyon_name} ]; then
    if [ ${flag} == 1 ]; then
        echo "," >> ${dir}/${name}
    fi
    cat ${dir}/${everyon_name} >> ${dir}/${name}
    flag=1
    cnt=`grep -o Source ${dir}/${everyon_name} | wc -w`
    printf '   everyon : Channels %s\n' "${cnt}"
    total=`expr ${total} + ${cnt}`
else
    flag=0
    printf '   everyon : No list\n'
fi
END

if [ -f ${dir}/${videoportal_name} ]; then
    if [ ${flag} == 1 ]; then
        echo "," >> ${dir}/${name}
    fi
    cat ${dir}/${videoportal_name} >> ${dir}/${name}
    flag=1
    cnt=`grep -o Source ${dir}/${videoportal_name} | wc -w`
    printf '   videoportal : Channels %s\n' "${cnt}"
    total=`expr ${total} + ${cnt}`
else
    flag=0
    printf '   videoportal : No list\n'
fi

if [ -f ${dir}/${etc_name} ]; then
    if [ ${flag} == 1 ]; then
	echo "," >> ${dir}/${name}
    fi
    cat ${dir}/${etc_name} >> ${dir}/${name}
    flag=1
    cnt=`grep -o Source ${dir}/${etc_name} | wc -w`
    printf '   etc : Channels %s\n' "${cnt}"
    total=`expr ${total} + ${cnt}`
else
    flag=0
    printf '   etc : No list\n'
fi

echo "" >> ${dir}/${name}
echo "]" >> ${dir}/${name}

printf '   Total %s Channels\n' "${total}"
echo "Finish!"

echo -n " - copy to target dir : "
cp ${dir}/${name} ${target_dir}/${name}
echo "done"
