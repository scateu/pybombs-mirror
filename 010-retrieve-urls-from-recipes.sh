#!/bin/bash
if [ ! -d recipes-origin ]; then
	echo "No recipes-origin found. Fetching..."
	mkdir recipes-origin
	cd recipes-origin
	echo "git clone git@github.com:gnuradio/gr-recipes.git gr-recipes"
	git clone git@github.com:gnuradio/gr-recipes.git gr-recipes
	echo "git clone git@github.com:gnuradio/gr-etcetera.git gr-etcetera"
	git clone git@github.com:gnuradio/gr-etcetera.git gr-etcetera
	cd ..
else
	echo "Git updating recipes..."
	cd recipes-origin/gr-etcetera/
	echo "Updating gr-etcetera"
	git pull
	cd ../..
	echo "Updating gr-recipes"
	cd recipes-origin/gr-recipes/
	git pull
	cd ../../
fi


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
