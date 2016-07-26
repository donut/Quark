#!/bin/bash

./generate.sh
git add .
git commit -am "update docs"
git push
git status