#!/bin/bash

# update the image name as necessary.
imagename="cppalliance/ruby2.4:1"
docker build -t $imagename . 2>&1 | tee /tmp/output.txt
