#!/usr/bin/env bash

STARTER_PATH=$WORKSPACE/$STARTER_DIR
LINKED_PATH=$WORKSPACE/$LINKED_DIR

echo "STARTER_PATH = ${STARTER_PATH}"
echo "LINKED_PATH = ${LINKED_PATH}"

cd $STARTER_PATH


echo "gem \"jbuilder-schema\", path: \"$LINKED_PATH\"" >> Gemfile

# This searches two directories up because we're in tmp/starter (the CI working directory).
#packages_string=$(find ./../../ -name 'jbuilder-schema*.gemspec' | grep -o 'jbuilder-schema.*' | sed "s/\/.*//")
#readarray -t packages <<<"$packages_string" # Convert to an array.

#for package in "${packages[@]}"
#do
  #:
  #grep -v "gem \"$package\"" Gemfile > Gemfile.tmp
  #mv Gemfile.tmp Gemfile
  #echo "gem \"$package\", path: \"../../tmp/core/$package\"" >> Gemfile
#done



#updates="${packages[@]}"
#bundle lock --conservative --update $updates
