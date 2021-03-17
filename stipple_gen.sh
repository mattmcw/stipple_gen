#!/bin/bash

# processing-java requires the full path of the sketch
SKETCH=`realpath ./`

# pass all arguments on bash script to stipple_gen.pde sketch
processing-java --sketch="${SKETCH}" --run \
	"${@}"
