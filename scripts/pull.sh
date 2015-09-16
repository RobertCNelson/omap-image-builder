#!/bin/bash

git pull --no-edit git@github.com:beagleboard/image-builder.git master
git pull --no-edit git@github.com:beagleboard/image-builder.git master --tags
git pull --no-edit git@github.com:RobertCNelson/omap-image-builder.git master
git pull --no-edit git@github.com:RobertCNelson/omap-image-builder.git master --tags

