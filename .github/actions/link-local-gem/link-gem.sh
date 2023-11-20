#!/usr/bin/env bash

APPLICATION_PATH=$WORKSPACE/$APPLICATION_DIR
GEM_PATH=$WORKSPACE/$LOCAL_GEM_DIR

echo "APPLICATION_PATH = ${APPLICATION_PATH}"
echo "GEM_PATH = ${GEM_PATH}"

cd $APPLICATION_PATH

# TODO: This might be a clumsy, long way to get the name of the gem that we're linking to, but it works.
GEMSPEC_PATH=$GEM_PATH/*.gemspec # /home/runner/work/jbuilder-schema/jbuilder-schema/./*.gemspec
GEMSPEC=$(ls $GEMSPEC_PATH) # /home/runner/work/jbuilder-schema/jbuilder-schema/./jbuilder-schema.gemspec
GEMSPEC_FILE=$(basename -- "$GEMSPEC") # jbuilder-schema.gemspec
GEM_NAME="${GEMSPEC_FILE%.*}" # jbuilder-schema

echo "gem \"$GEM_NAME\", path: \"$GEM_PATH\"" >> Gemfile

# TODO: We should be able to add this line back once we merge the un-pinning of jbuilder-schema
#bundle lock --conservative --update $GEM_NAME
