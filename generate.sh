#!/bin/bash

# Docs by jazzy
# https://github.com/realm/jazzy
# ------------------------------

git submodule update --remote

cd Quark
swift build
swift package generate-xcodeproj
cd ..

jazzy --swift-version 3 -o ./ \
      --readme 'Quark/README.md' \
      --xcodebuild-arguments -scheme,Quark \
      --source-directory 'Quark' \
      --author 'Zewo' \
      --author_url 'http://zewo.io' \
      --module 'Quark' \
      --github_url 'https://github.com/QuarkX/Quark' \
      --skip-undocumented
