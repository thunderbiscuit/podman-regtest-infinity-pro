# This script will build the website and push it to the gh-pages branch,
# publishing it automatically to https://thunderbiscuit.github.io/podman-regtest-infinity-pro/.

set -euo pipefail

rm -rf ./site/*
just builddocs
cd ./site/
git init .
git switch --create gh-pages
git add .
git commit --message "Deploy $(date +"%Y-%m-%d")"
git remote add upstream git@github.com:thunderbiscuit/podman-regtest-infinity-pro.git
git push upstream gh-pages --force
cd ..
