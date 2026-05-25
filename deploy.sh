#!/bin/bash
set -e

echo "Building Flutter web..."
cd app
fvm flutter build web --release --base-href /green-spots/
cd ..

echo "Deploying to gh-pages..."
cd app/build/web

git init
git checkout -B gh-pages
git add .
git commit -m "deploy"
git remote remove origin 2>/dev/null || true
git remote add origin git@github.com:f1sh1918/green-spots.git
git push --force origin gh-pages

cd ../../..
echo "Done! https://f1sh1918.github.io/green-spots/"