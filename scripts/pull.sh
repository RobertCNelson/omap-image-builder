#!/bin/bash

git pull --rebase --no-edit git@gitlab.gfnd.rcn-ee.org:RobertCNelson/omap-image-builder.git
git pull --rebase --no-edit git@gitlab.gfnd.rcn-ee.org:RobertCNelson/omap-image-builder.git --tags
git pull --rebase --no-edit git@github.com:beagleboard/image-builder.git master
git pull --rebase --no-edit git@github.com:beagleboard/image-builder.git master --tags
git pull --rebase --no-edit git@github.com:RobertCNelson/omap-image-builder.git master
git pull --rebase --no-edit git@github.com:RobertCNelson/omap-image-builder.git master --tags
git pull --rebase --no-edit git@openbeagle.org:beagleboard/image-builder.git master
git pull --rebase --no-edit git@openbeagle.org:beagleboard/image-builder.git master --tags
