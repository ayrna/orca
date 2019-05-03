#!/bin/bash
jupyter nbconvert --ExecutePreprocessor.timeout=-1 --to markdown --execute orca_tutorial_1.ipynb
jupyter nbconvert --ExecutePreprocessor.timeout=-1 --to markdown --execute orca_tutorial_2.ipynb
jupyter nbconvert --ExecutePreprocessor.timeout=-1 --to markdown --execute orca_tutorial_3.ipynb

