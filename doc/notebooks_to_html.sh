#!/bin/bash
jupyter nbconvert --ExecutePreprocessor.timeout=-1 --to html_toc --execute orca-tutorial-1.ipynb
jupyter nbconvert --ExecutePreprocessor.timeout=-1 --to html_toc --execute orca-tutorial-2.ipynb

