#!/bin/bash
jupyter nbconvert --to script orca-tutorial-1.ipynb
octave-cli orca-tutorial-1.m
jupyter nbconvert --to script orca-tutorial-2.ipynb
octave-cli orca-tutorial-2.m
