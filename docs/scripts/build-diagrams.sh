#!/bin/sh

# USAGE:
#   build-diagrams.sh <source_dir> <outout_dir>

# DESCRIPTION:
#   Build .uxf diagrams from source_dir into source_dir/output_dir

# ARGS:
#   source_dir: Directory to mount, containing source files
#   outout_dir: Directory relative to source_dir for output files

# EXAMPLE:
#   Assume PWD=/home/john/github/docks
#
#   docks:
#     - docs
#       - deployment.uxf
#     - README.md
#
#   To build the files in docks/docs to docks/docs/output
#
#   $ build.sh $(pwd)/docs output

sourceDir=$1
outputDir=$2

userId=$(id -u)
groupId=$(id -g)

echo "Executing as user:group ($userId:$groupId)"

mkdir -p $sourceDir/$outputDir

echo "Building .uxf files from $sourceDir to $sourceDir/$outputDir"
for i in $sourceDir/*.uxf; do
    [ -f "$i" ] || break

    fileNameExt=$(basename -- "$i")
    fileName="${fileNameExt%.*}"

    echo "Building $fileNameExt to $outputDir/$fileName.pdf"
    sudo docker run --name umlet-docker --rm -i --user="$userId:$groupId" --net=none -v "$sourceDir:/data" egeldenhuys/umlet-docker \
    java -jar umlet.jar -action=convert -format="png" -filename="/data/$fileNameExt" -output="/data/$fileName.png"
done
