#!/usr/bin/env bash

STARTER_PATH=$WORKSPACE/$STARTER_DIR
LINKED_PATH=$WORKSPACE/$LINKED_DIR

echo "STARTER_PATH = ${STARTER_PATH}"
echo "LINKED_PATH = ${LINKED_PATH}"

cd $STARTER_PATH

# TODO: This might be a clumsy, long way to get the name of the gem that we're linking to, but it works.
GEMSPEC_PATH=$LINKED_PATH/*.gemspec # /home/runner/work/jbuilder-schema/jbuilder-schema/./*.gemspec
GEMSPEC=$(ls $GEMSPEC_PATH) # /home/runner/work/jbuilder-schema/jbuilder-schema/./jbuilder-schema.gemspec
GEMSPEC_FILE=$(basename -- "$GEMSPEC") # jbuilder-schema.gemspec
GEM_NAME="${GEMSPEC_FILE%.*}" # jbuilder-schema

echo "gem \"$GEM_NAME\", path: \"$LINKED_PATH\"" >> Gemfile

# TODO: We should be able to add this line back once we un-pin jbuilder-schema
#bundle lock --conservative --update $GEM_NAME
