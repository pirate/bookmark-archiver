#!/usr/bin/env bash

### Bash Environment Setup
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
# set -o xtrace
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
IFS=$'\n'

REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && cd .. && pwd )"

if [[ -f "$REPO_DIR/.venv/bin/activate" ]]; then
    source "$REPO_DIR/.venv/bin/activate"
else
    echo "[!] Warning: No virtualenv presesnt in $REPO_DIR.venv"
fi
cd "$REPO_DIR"

CURRENT_PLAFORM="$(uname)"
REQUIRED_PLATFORM="Linux"
if [[ "$CURRENT_PLAFORM" != "$REQUIRED_PLATFORM" ]]; then
   echo "[!] Skipping the Debian package build on $CURRENT_PLAFORM (it can only be run on $REQUIRED_PLATFORM)."
   exit 0
fi

VERSION="$(jq -r '.version' < "$REPO_DIR/package.json")"
DEBIAN_VERSION="1"
PGP_KEY_ID="7D5695D3B618872647861D51C38137A7C1675988"
# make sure you have this in ~/.dput.cf:
#     [archivebox-ppa]
#     fqdn: ppa.launchpad.net
#     method: ftp
#     incoming: ~archivebox/ubuntu/archivebox/
#     login: anonymous
#     allow_unsigned_uploads: 0


# cleanup build artifacts
rm -Rf build deb_dist dist archivebox-*.tar.gz

# make sure the stdeb.cfg file is up-to-date with all the dependencies

# build source and binary packages
python3 setup.py --command-packages=stdeb.command \
    sdist_dsc --debian-version=$DEBIAN_VERSION \
    bdist_deb

# sign the build with your PGP key ID
debsign -k "$PGP_KEY_ID" "deb_dist/archivebox_${VERSION}-${DEBIAN_VERSION}_source.changes"

# push the build to launchpad ppa
# dput archivebox "deb_dist/archivebox_${VERSION}-${DEBIAN_VERSION}_source.changes"
