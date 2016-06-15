#!/bin/bash
PYBOMBS_MIRROR_WORK_DIR=$(pwd)
cat recipe-repos.urls | while read REPO_URL REPO_NAME
do
	if [ ! -d recipes-origin ]; then
		mkdir recipes-origin
	fi

	if [ ! -d recipes-origin/${REPO_NAME} ]; then
		echo "No recipes-origin/${REPO_NAME} found. Fetching..."
		cd recipes-origin/
		echo "git clone ${REPO_URL} ${REPO_NAME}"
		git clone ${REPO_URL} ${REPO_NAME}
	else
		echo "Git updating recipes..."
		cd recipes-origin/${REPO_NAME}
		echo "Updating ${REPO_NAME}"
		git pull
	fi

	cd ${PYBOMBS_MIRROR_WORK_DIR}
done


if [ -d recipes ]; then
	echo "target recipes directory already exists, clean it."
	rm -rf ./recipes
fi

cp -r recipes-origin recipes

if [ -e pre-replace-upstream.urls ]; then 
	echo "===================="
	echo "pre-replace-upstream.urls found!"
	echo "Patching recipes with custom urls"
	
	cat pre-replace-upstream.urls | while read origin new
	do
		echo "Replacing ${origin} with ${new}"
		find ./recipes/ -name \*.lwr -exec sed -i "s,${origin},${new},g" {} \;
	done
	echo "Patching recipes done!"
	echo "===================="
	echo
fi


echo "===================="
grep  -r -E "(git|svn|wget)\+.*$" recipes/ | rev |cut -d' '  -f1 |rev > recipes-origin.urls

echo "recipes-origin.urls generated successfully!"
echo "===================="
echo 


if [ -e ignore.urls ]; then
	echo "===================="
	echo "ignore.urls found!"
	echo "Remove ignored urls from recipes-origin.urls"
	echo "Removed lines won't be fetched or replaced, mirror users can still fetch that repo directly from upstream."


	cat ignore.urls | while read url
	do
		echo "Deleting line contains ${url}"
		sed -i "\\,${url},d" recipes-origin.urls 
	done
	echo "recipes-origin.urls patched!"
	echo "===================="
fi
