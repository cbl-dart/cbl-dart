#!/usr/bin/env bash

set -e

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
projectDir="$(cd "$scriptDir/.." && pwd)"
couchbaseLiteDartVersion="$(cat "$projectDir/native/couchbase-lite-dart/CouchbaseLiteDart.version")"

# Creates a new release for libcblitedart by creating an empty commit and a tag for the commit.
#
# The only parameter is optional and is the preid, e.g. beta.1, in case this is a prerelease.
#
# The current branch must be main and the working directory must be clean.
function libcblitedart() {
    local preid="$1"

    local release="$couchbaseLiteDartVersion"
    if [ -n "$preid" ]; then
        release="$release-$preid"
    fi

    echo "Creating release $release for libcblitedart"

    if [ "$(git branch --show-current)" != "main" ]; then
        echo "Aborting because main branch is not checked out."
        exit 1
    fi

    if [ -n "$(git status --untracked-files=no --porcelain)" ]; then
        echo "Aborting becaue working directory is not clean."
        exit 1
    fi

    local tag="libcblitedart-v$release"
    if [ "$(git tag -l "$tag")" ]; then
        echo "Tag for release $tag already exists."
        exit 1
    fi

    git commit --allow-empty -m "chore: cut release for \`libcblitedart\` \`$release\`"
    git tag -m "$tag" "$tag"

    echo "Created release with tag $tag"
    echo "To publish run: git push --follow-tags"
}

# Version Dart packages through melos except for the cbl_libcblite(dart)_api packages, which
# are versioned separately.
function packages() {
    melos version --ignore 'cbl_libcblite*' "$@"
}

"$@"
