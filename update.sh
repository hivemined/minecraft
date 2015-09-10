#!/bin/sh
####
## Update to the latest Minecraft version and push changes to git
##
####

# toggle git integration
if [ "$2" = --git ]; then
    __ENABLE_GIT=1
    echo "Enabling automatic git processing."
else
    __ENABLE_GIT=0
fi

# fetch current version for comparison
OLD_VERSION=$(grep 'MINECRAFT_VERSION=' "$(dirname $0)/Dockerfile" | sed "s/^.*MINECRAFT_VERSION=\([0-9][0-9.]*[0-9]\).*/\1/")

# fetch latest version information from official source
echo "Fetching Minecraft version information."
wget -O versions.json -q "https://s3.amazonaws.com/Minecraft.Download/versions/versions.json"

if [ -z $1 ]; then
    NEW_VERSION=$(grep '\"release\": ' versions.json | sed "s/^.*\"\([0-9][0-9.]*[0-9]\)\".*/\1/")

elif grep -q "\"id\": \"${1}\"" versions.json; then
    NEW_VERSION="$1"

else
    echo "Specified version $1 could not be found! Aborting."
    exit 1
fi

echo "$OLD_VERSION  --->  $NEW_VERSION"
rm versions.json

# determine if an update is needed by comparing current and target versions
if [ "$OLD_VERSION" != "$NEW_VERSION" ]; then
    echo "Updating Minecraft to newer version now!"

    # set version information in Dockerfile and README.md
    sed -i "s/\(Current Version: \)[0-9][0-9.]*[0-9]/\1${NEW_VERSION}/" "$(dirname $0)/README.md"
    sed -i "s/\(MINECRAFT_VERSION=\)[0-9][0-9.]*[0-9]/\1${NEW_VERSION}/" "$(dirname $0)/Dockerfile"

    # update git repository with new tag
    if [ $__ENABLE_GIT = 1 ]; then
        git add README.md Dockerfile
        git commit -m "Update to $NEW_VERSION" && \
		git tag "$NEW_VERSION" && git push && git push origin "$NEW_VERSION"
    fi
else
    echo "Minecraft image already up to date! Staying at version $OLD_VERSION"
fi

