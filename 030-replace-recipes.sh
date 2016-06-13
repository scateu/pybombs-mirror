#!/bin/bash

if [ ! -e recipes-mirror-replacement.urls ]; then
	echo "No recipes-mirror-replacement.urls found! Exit."
	exit -1
fi

if [ ! -d recipes ]; then
	echo "No target recipes directory found! Exit."
	exit -1
fi

cat recipes-mirror-replacement.urls | while read origin new
do
	echo "Replacing ${origin} with ${new}"
	find ./recipes/ -name \*.lwr -exec sed -i "s,${origin},${new},g" {} \;
	echo
done
