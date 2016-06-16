#!/bin/bash

PYBOMBS_MIRROR_WORK_DIR=$(pwd)
PYBOMBS_SITE_BASE=/pybombs

if [ ! -e recipe-repos.urls ]; then
	echo "No recipe-repos.urls found! Exit."
	exit -1
fi

if [ ! -d recipes ]; then
	echo "No target recipes directory found! Exit."
	exit -1
fi


## Make .git bare repos for recipes.

if [ -d _recipes_bare ]; then
	rm -rf _recipes_bare
	echo "Purge previous _recipes_bare directory."
fi

mkdir _recipes_bare

cat recipe-repos.urls | while read REPO_URL REPO_NAME
do
	if [ -e recipes/${REPO_NAME} ]; then
		cd recipes/${REPO_NAME};
		git commit -am "PyBOMBS Mirror Replacement: $(date)"
	else
		echo "recipes/${REPO_NAME} doesn't exist!"
	fi
	
	cd ${PYBOMBS_MIRROR_WORK_DIR}
	git clone --mirror recipes/${REPO_NAME} _recipes_bare/${REPO_NAME}.git
done

#RSYNC_PARAM="rsync -av --no-perms --no-owner --no-group --delete"
RSYNC_PARAM="-prv --delete"

rsync $RSYNC_PARAM git/ ${PYBOMBS_SITE_BASE}/git/
rsync $RSYNC_PARAM wget/ ${PYBOMBS_SITE_BASE}/wget/
rsync $RSYNC_PARAM svn/ ${PYBOMBS_SITE_BASE}/svn/
rsync $RSYNC_PARAM _recipes_bare/ ${PYBOMBS_SITE_BASE}/recipes/
rsync $RSYNC_PARAM recipes-mirror-replacement.urls ${PYBOMBS_SITE_BASE}/
rsync $RSYNC_PARAM pre-replace-upstream.urls ${PYBOMBS_SITE_BASE}/

echo "maybe you need to : sudo chown -R www-data:www-data ${PYBOMBS_SITE_BASE}"
