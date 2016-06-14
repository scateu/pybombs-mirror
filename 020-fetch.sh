#!/bin/bash

DRY_RUN=false

PYBOMBS_MIRROR_ROOT_DIR=$(pwd)

# Currently, all mirrored repo are served as http or https: 
# like: 
# 	git+http, svn+http, wget+http
# or:
# 	git+https, svn+https, wget+https
PYBOMBS_MIRROR_BASE_URL="http://localhost/pybombs" # *NO* tailing / should be added.


if [ ! -e recipes-origin.urls ]; then 
	echo "No recipes-origin.urls found! Exit."
	exit -1
fi

if [ -e recipes-mirror-replacement.urls ]; then
	echo "Previous recipes-mirror-replacement.urls exists, purge it."
	rm recipes-mirror-replacement.urls
fi

if [ ! -d git ]; then 
	mkdir git
fi
if [ ! -d svn ]; then 
	mkdir svn
fi
if [ ! -d wget ]; then 
	mkdir wget
fi

if [ -e failed.log ]; then 
	echo "Previous failed.log found! Roll it to failed.log.1 ."
	mv failed.log failed.log.1
	echo
fi


cat recipes-origin.urls | sed 's/+/ /' | while read protocol url
do 
	echo "ENTERING: $PYBOMBS_MIRROR_ROOT_DIR"
	cd $PYBOMBS_MIRROR_ROOT_DIR

	ORIGIN_PYBOMBS_URL="$protocol+$url"
	echo "ORGIGIN_PYBOMBS_URL: $ORIGIN_PYBOMBS_URL"
	TARGET_PATH="./$protocol/$(basename $url)"

	echo "UPSTREAM: $url"
	MIRROR_PYBOMBS_URL="${protocol}+${PYBOMBS_MIRROR_BASE_URL}/${protocol}/$(basename $url)"
	echo "MIRROR_PYBOMBS_URL: ${MIRROR_PYBOMBS_URL}"


	FETCHING_SUCCESS=true #predefine status
	if [ $protocol = "wget" ]; then
		if [ -e $TARGET_PATH ]; then
			echo "$TARGET_PATH exists, skipping"
		else
			if [ -e ${TARGET_PATH}.tmp ]; then
				echo "${TARGET_PATH}.tmp exists.. remove it."
				rm ${TARGET_PATH}.tmp 
			fi
			echo "EXECUTING: wget $url -O ${TARGET_PATH}.tmp"
			if [ ! $DRY_RUN = true ]; then
				wget $url --tries=3 -O ${TARGET_PATH}.tmp
				if [ $? -eq 0 ]; then
					echo "Fetching done. Renaming ${TARGET_PATH}.tmp to ${TARGET_PATH}"
					mv ${TARGET_PATH}.tmp ${TARGET_PATH}
				else
					FETCHING_SUCCESS=false
				fi
			fi
		fi
	elif [ $protocol = "git" ]; then
		echo "git clone --mirror $url $TARGET_PATH"
		if [ -d $TARGET_PATH ]; then
			echo "$TARGET_PATH exists, syncing"
			cd $TARGET_PATH
			
			if [ ! $DRY_RUN = true ]; then
				/usr/bin/timeout -s INT 3600 git remote -v update || FETCHING_SUCCESS=false
				git repack -a -d
			fi
		else
			echo "EXECUTING: git clone --mirror $url $TARGET_PATH"
			if [ ! $DRY_RUN = true ]; then
				git clone --mirror $url $TARGET_PATH || FETCHING_SUCCESS=false
			fi
		fi
	elif [ $protocol = "svn" ]; then

		if [ ! $DRY_RUN = true ]; then
			echo "TODO"
		fi
	fi


	cd $PYBOMBS_MIRROR_ROOT_DIR
	if [ $FETCHING_SUCCESS = true ]; then
		echo "${ORIGIN_PYBOMBS_URL} ${MIRROR_PYBOMBS_URL}" >> recipes-mirror-replacement.urls
		echo "${ORIGIN_PYBOMBS_URL} fetching success!"
	else
		echo "${ORIGIN_PYBOMBS_URL}" >> failed.log
		echo "${ORIGIN_PYBOMBS_URL} fetching failed"
	fi

	echo "====================="
	echo
	
done
