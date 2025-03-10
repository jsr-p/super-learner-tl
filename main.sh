#!/usr/bin/env bash

mkdir -p figs output

# Simulation 
Rscript scripts/slearn.R
Rscript scripts/plot_sim.R

# Empirical
wget https://github.com/robjellis/lalonde/raw/refs/heads/master/lalonde_data.csv \
	--output-document=data/lalonde_data.csv
Rscript scripts/lalonde.R
    
# Tables
python scripts/table.py
python scripts/gt_table.py
