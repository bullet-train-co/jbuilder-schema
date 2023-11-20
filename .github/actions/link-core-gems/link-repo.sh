#!/usr/bin/env bash

APPLICATION_PATH=$WORKSPACE/$APPLICATION_DIR
CORE_PATH=$WORKSPACE/$CORE_DIR

echo "APPLICATION_PATH = ${APPLICATION_PATH}"
cd $APPLICATION_PATH

# We do this to preve bundler from complaining that we're changing the lock file.
# Because we NEED to change the lock file.
bundle config unset deployment

packages_string=$(find $CORE_PATH -name 'bullet_train*.gemspec' | grep -o 'bullet_train.*' | sed "s/\/.*//")
readarray -t packages <<<"$packages_string" # Convert to an array.

for package in "${packages[@]}"
do
  :
  grep -v "gem \"$package\"" Gemfile > Gemfile.tmp
  mv Gemfile.tmp Gemfile
  echo "gem \"$package\", path: \"$CORE_PATH/$package\"" >> Gemfile
done

updates="${packages[@]}"

bundle lock --conservative --update $updates
bundle install

packages=(
  "bullet_train"
  "bullet_train-sortable"
)

echo "yalc dir ======"
npx yalc dir

starting_dir=$PWD

for package in "${packages[@]}"
do
  :
  npm_package=${package/_/-}
  echo "linking package: $package"
  echo "npm package: $npm_package"

  cd $CORE_PATH/$package
  yarn install
  yarn build
  npx yalc publish

  cd $starting_dir
  npx yalc add @bullet-train/$npm_package
done


# For some reason the fields package is called bullet-train/field and doesn't match the pattern for other packages.
# If it did match other packages it would be   bullet-train/bullet-train-fields.
# Since it's different we have to treat it special. It would be nice to standardize, but that's likely to have
# impacts beyond just fixing CI, so I'm doing the messy thing for now.

package="bullet_train-fields"
npm_package="fields"
echo "linking package: $package"
echo "npm package: $npm_package"

cd $CORE_PATH/$package
yarn install
yarn build
npx yalc publish

cd $starting_dir
npx yalc add @bullet-train/$npm_package


cat package.json


# We do this here becausue the  node/install-packages step complains about
# needing to modify the lock file.

yarn install
yarn build
yarn build:css


