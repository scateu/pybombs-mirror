#!/bin/bash

if [ -z $PYBOMBS_MIRROR_WORK_DIR ]; then
	PYBOMBS_MIRROR_WORK_DIR=$(pwd)
fi

_DIR=${PYBOMBS_MIRROR_WORK_DIR}

if [ -z $DRY_RUN ]; then
	DRY_RUN=false  # when set to true, nothing will be fetched, for debug purpose
fi

# Currently, all mirrored repo are served through http or https: 
# like: 
# 	git+http, svn+http, wget+http
# or:
# 	git+https, svn+https, wget+https
if [ -z ${PYBOMBS_MIRROR_BASE_URL} ]; then
	PYBOMBS_MIRROR_BASE_URL="http://localhost/pybombs" # *NO* tailing / should be added.
	echo "No PYBOMBS_MIRROR_BASE_URL passed in, using ${PYBOMBS_MIRROR_BASE_URL}"
fi


#========================================================

function delete_directory_if_exist() {
if [ -d $1 ]; then
	echo "Directory $1 already exists, clean it"
	rm -rf $1
fi
}

function delete_file_if_exist() {
if [ -e $1 ]; then
	echo "File $1 already exists, clean it"
	rm  $1
fi
}

function require_file_existance() {
if [ ! -e $1 ]; then 
	echo "No file $1 found! Exit."
	exit -1
fi
}

function require_directory_existance() {
if [ ! -d $1 ]; then 
	echo "No directory $1 found! Exit."
	exit -1
fi
}

function make_clean_dir(){
if [ -d $1 ]; then
	rm -rf $1
	echo "Purge existed $1 directory."
fi
echo "mkdir $1"
mkdir $1
}



#10-retrieve-urls-from-recipes:
#=============

require_file_existance ${_DIR}/upstream-recipe-repos.urls

cat ${_DIR}/upstream-recipe-repos.urls | while read REPO_URL REPO_NAME
do
	if [ ! -d ${_DIR}/recipes-origin ]; then
		mkdir ${_DIR}/recipes-origin
	fi

	if [ ! -d ${_DIR}/recipes-origin/${REPO_NAME} ]; then
		echo "No recipes-origin/${REPO_NAME} found. Fetching..."
		cd ${_DIR}/recipes-origin/
		echo "git clone ${REPO_URL} ${REPO_NAME}"
		git clone ${REPO_URL} ${REPO_NAME}
	else
		echo "Git updating recipes..."
		cd ${_DIR}/recipes-origin/${REPO_NAME}
		echo "Updating ${REPO_NAME}"
		git pull
	fi

	cd ${_DIR}
done


delete_directory_if_exist ${_DIR}/_recipes
cp -r ${_DIR}/recipes-origin ${_DIR}/_recipes

if [ -e ${_DIR}/pre-replace-upstream.urls ]; then 
	echo "===================="
	echo "pre-replace-upstream.urls found!"
	echo "Patching _recipes with custom urls"
	
	cat ${_DIR}/pre-replace-upstream.urls | while read origin new
	do
		echo "Replacing ${origin} with ${new}"
		grep -rl "${origin}" ${_DIR}/_recipes/ |grep -v \.git |xargs -r sed -i "s,${origin},${new},g" 
	done
	echo "Patching _recipes done!"
	echo "===================="
	echo
fi


echo "===================="
grep  -r -E "(git|svn|wget)\+.*$" ${_DIR}/_recipes/ | rev |cut -d' '  -f1 |rev > ${_DIR}/recipes-origin.urls
echo "recipes-origin.urls generated successfully!"
echo "===================="
echo 


if [ -e ${_DIR}/ignore.urls ]; then
	echo "===================="
	echo "ignore.urls found!"
	echo "Remove ignored urls from recipes-origin.urls"
	echo "Removed lines won't be fetched or replaced, mirror users can still fetch that repo directly from upstream."
	cat ${_DIR}/ignore.urls | while read url
	do
		echo "Deleting line contains ${url}"
		sed -i "\\,${url},d" ${_DIR}/recipes-origin.urls 
	done
	echo "recipes-origin.urls patched!"
	echo "===================="
fi

#20-fetch:
#=============

require_file_existance ${_DIR}/recipes-origin.urls

delete_file_if_exist ${_DIR}/_recipes-mirror-replacement.urls 

if [ ! -d ${_DIR}/git ]; then 
	mkdir ${_DIR}/git
fi
if [ ! -d ${_DIR}/svn ]; then 
	mkdir ${_DIR}/svn
fi
if [ ! -d ${_DIR}/wget ]; then 
	mkdir ${_DIR}/wget
fi

if [ -e ${_DIR}/failed.log ]; then 
	echo "Previous failed.log found! Roll it to failed.log.1 ."
	mv ${_DIR}/failed.log ${_DIR}/failed.log.1
	echo
fi


cat ${_DIR}/recipes-origin.urls | sed 's/+/ /' | while read protocol url
do 
	echo "====================="
	echo "ENTERING: $PYBOMBS_MIRROR_WORK_DIR"
	cd $PYBOMBS_MIRROR_WORK_DIR

	ORIGIN_PYBOMBS_URL="$protocol+$url"
	echo "ORGIGIN_PYBOMBS_URL: $ORIGIN_PYBOMBS_URL"
	#TARGET_PATH="$protocol/$(basename $url)"

	# If duplication of name like  git+git://git.code.sf.net/p/openlte/code --> code happens
	# You can use the following name scheme (Not beautiful... indeed...)

	TARGET_PATH="$protocol/$(basename $(dirname $url))_$(basename $url)"

	echo "UPSTREAM: $url"
	MIRROR_PYBOMBS_URL="${protocol}+PYBOMBS_MIRROR_BASE_URL/${TARGET_PATH}"
	echo "MIRROR_PYBOMBS_URL: ${MIRROR_PYBOMBS_URL}"


	FETCHING_SUCCESS=true #predefine status
	if [ $protocol = "wget" ]; then
		if [ -e ${_DIR}/$TARGET_PATH ]; then
			echo "${_DIR}/$TARGET_PATH exists, skipping"
		else
			if [ -e ${_DIR}/${TARGET_PATH}.tmp ]; then
				echo "${_DIR}/${TARGET_PATH}.tmp exists.. remove it."
				rm ${_DIR}/${TARGET_PATH}.tmp 
			fi
			echo "EXECUTING: wget $url -O ${_DIR}/${TARGET_PATH}.tmp"
			if [ ! $DRY_RUN = true ]; then
				wget $url --tries=3 -O ${_DIR}/${TARGET_PATH}.tmp
				if [ $? -eq 0 ]; then
					echo "Fetching done. Renaming ${_DIR}/${TARGET_PATH}.tmp to ${_DIR}/${TARGET_PATH}"
					mv ${_DIR}/${TARGET_PATH}.tmp ${_DIR}/${TARGET_PATH}
				else
					FETCHING_SUCCESS=false
				fi
			fi
		fi
	elif [ $protocol = "git" ]; then
		if [ -d ${_DIR}/$TARGET_PATH ]; then
			echo "${_DIR}/$TARGET_PATH exists, syncing"
			cd ${_DIR}/$TARGET_PATH
			
			if [ ! $DRY_RUN = true ]; then
				/usr/bin/timeout -s INT 3600 git remote -v update || FETCHING_SUCCESS=false
				git repack -a -d
			fi
		else
			echo "EXECUTING: git clone --mirror $url ${_DIR}/$TARGET_PATH"
			if [ ! $DRY_RUN = true ]; then
				git clone --mirror $url ${_DIR}/$TARGET_PATH || FETCHING_SUCCESS=false
			fi
		fi
	elif [ $protocol = "svn" ]; then

		if [ ! $DRY_RUN = true ]; then
			echo "TODO"
			FETCHING_SUCCESS=false
		fi
	fi


	cd $PYBOMBS_MIRROR_WORK_DIR
	if [ $FETCHING_SUCCESS = true ]; then
		echo "${ORIGIN_PYBOMBS_URL} ${MIRROR_PYBOMBS_URL}" >> ${_DIR}/_recipes-mirror-replacement.urls
		echo "${ORIGIN_PYBOMBS_URL} fetching success!"
	else
		echo "${ORIGIN_PYBOMBS_URL}" >> failed.log
		echo "${ORIGIN_PYBOMBS_URL} fetching failed"
	fi

	echo "====================="
	echo
	
done

#30-replace-recipes:
#=============

require_file_existance ${_DIR}/_recipes-mirror-replacement.urls 
require_directory_existance ${_DIR}/_recipes

echo "Replacing PYBOMBS_MIRROR_BASE_URL with ${PYBOMBS_MIRROR_BASE_URL} in recipes-mirror-replacement.urls .."
cp ${_DIR}/_recipes-mirror-replacement.urls ${_DIR}/recipes-mirror-replacement.urls 
sed -i "s,PYBOMBS_MIRROR_BASE_URL,${PYBOMBS_MIRROR_BASE_URL},g" ${_DIR}/recipes-mirror-replacement.urls
echo "Done."


cat ${_DIR}/recipes-mirror-replacement.urls | while read origin new
do
	echo "${origin} --> ${new}"
	grep -rl "${origin}" ${_DIR}/_recipes/ |grep -v \.git |xargs -r sed -i "s,${origin},${new},g" 
	echo
done

#40-deploy:
#=============

require_file_existance ${_DIR}/upstream-recipe-repos.urls 
require_directory_existance ${_DIR}/_recipes 

## Make .git bare repos for recipes.

make_clean_dir ${_DIR}/recipes

cat ${_DIR}/upstream-recipe-repos.urls | while read REPO_URL REPO_NAME
do
	if [ -e ${_DIR}/_recipes/${REPO_NAME} ]; then
		cd ${_DIR}/_recipes/${REPO_NAME};
		git commit -am "PyBOMBS Mirror Replacement: $(date)"
	else
		echo "_recipes/${REPO_NAME} doesn't exist!"
	fi
	
	git clone --mirror ${_DIR}/_recipes/${REPO_NAME} ${_DIR}/recipes/${REPO_NAME}.git
done

echo "Cleaning up"

delete_file_if_exist ${_DIR}/_recipes-mirror-replacement.urls
delete_directory_if_exist ${_DIR}/_recipes


echo "maybe you need to : sudo chown -R www-data:www-data ${_DIR}"

cd ${_DIR}

echo "Generating README.txt....."

require_file_existance ${_DIR}/upstream-recipe-repos.urls

cat > ${_DIR}/README.txt <<EOF

PyBOMBS Mirror Site

Example Usage
==============

    sudo pip install pybombs
    rm -rf ~/.pybombs
EOF

cat ${_DIR}/upstream-recipe-repos.urls | while read REPO_URL REPO_NAME
do
	echo "    pybombs recipes add ${REPO_NAME} git+${PYBOMBS_MIRROR_BASE_URL}/git/${REPO_NAME}.git" >> ${_DIR}/README.txt
done

cat >> ${_DIR}/README.txt <<EOF
    mkdir gnuradio-prefix
    cd gnuradio-prefix
    pybombs prefix init
    pybombs install gnuradio
    . ./setup_env.sh
    gnuradio-companion


Update
=======

EOF

cat ${_DIR}/upstream-recipe-repos.urls | while read REPO_URL REPO_NAME
do
	echo "    pybombs recipes remove ${REPO_NAME}" >> ${_DIR}/README.txt
	echo "    pybombs recipes add ${REPO_NAME} git+${PYBOMBS_MIRROR_BASE_URL}/git/${REPO_NAME}.git" >> ${_DIR}/README.txt
done
