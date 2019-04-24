#!/bin/bash
jupyter nbconvert --to script orca_tutorial_1.ipynb
octave-cli --eval "orca_tutorial_1"
jupyter nbconvert --to script orca_tutorial_2.ipynb
octave-cli --eval "orca_tutorial_2"
