#!/bin/sh

# USAGE:
#   build.sh <source_dir> <outout_dir>

# DESCRIPTION:
#   Build documentation from source_dir into source_dir/output_dir

# NOTE:
#   Builds .uxf files to source_dir/images as well as source_dir/output_dir

# ARGS:
#   source_dir: Directory to mount, containing source files
#   outout_dir: Directory relative to source_dir for output files

# EXAMPLE:
#   Assume PWD=/home/john/github/docks
#
#   docks:
#     - docs
#       - document.tex
#     - README.md
#
#   To build the files in docks/docs to docks/docs/output
#
#   $ build.sh $(pwd)/docs output

set -e

sourceDir=$1
outputDir=$2
imageOutputDir="images/uml"

userId=$(id -u)
groupId=$(id -g)

echo "Executing as user:group ($userId:$groupId)"

mkdir -p $sourceDir/$outputDir
mkdir -p $sourceDir/$imageOutputDir

touch $sourceDir/$outputDir/mahFile
echo "hi56" > $sourceDir/$outputDir/mahFile

if ! [ -z ${CI+x} ]
then
  set +e
  git config --global user.name "Travis CI"
  git config --global user.email "builds@travis-ci.com"
  git remote add upstream https://${GH_TOKEN}@github.com/tripleparity/tmp-docs.git > /dev/null 2>&1
  git tag -d t-$TRAVIS_BRANCH
  git push upstream :refs/tags/t-$TRAVIS_BRANCH
  git tag t-$TRAVIS_BRANCH
  set -e
fi

echo "Building .uxf files from $sourceDir to $sourceDir/$outputDir"
for i in $sourceDir/*.uxf; do
    [ -f "$i" ] || break

    fileNameExt=$(basename -- "$i")
    fileName="${fileNameExt%.*}"

    echo "Building $fileNameExt to $outputDir/$fileName.png"
    sudo docker run --name umlet-docker --rm -i --user="$userId:$groupId" --net=none -v "$sourceDir:/data" egeldenhuys/umlet-docker \
    java -jar umlet.jar -action=convert -format="png" -filename="/data/$fileNameExt" -output="/data/$outputDir/$fileName.png"

    # TEST:
    fileSize=$(stat -c%s "$sourceDir/$outputDir/$fileName.png")
    if [ "$fileSize" -eq "0" ]
    then
      echo "Failed to build $fileNameExt"
      exit 1
    fi

    # Import images for pdf generation
    cp $sourceDir/$outputDir/$fileName.png $sourceDir/$imageOutputDir
done

echo "Building .tex files from $sourceDir to $sourceDir/$outputDir"
oldPwd=$(pwd)

# Fix the latex image path problem
cd $sourceDir
for i in $sourceDir/*.tex; do
    [ -f "$i" ] || break

    fileNameExt=$(basename -- "$i")
    fileName="${fileNameExt%.*}"

    echo "Building $fileNameExt to $outputDir/$fileName.pdf"
    # sudo docker run --rm -it -v "$sourceDir:/pandoc" --user="$userId:$groupId" --net=none geometalab/pandoc \
    # pandoc "$fileNameExt" -o "$outputDir/$fileName.pdf"
    pdflatex -interaction=nonstopmode -halt-on-error $sourceDir/$fileNameExt

    # Cope pdf files to output dir
    cp $sourceDir/$fileName.pdf $sourceDir/$outputDir
done
cd $oldPwd
