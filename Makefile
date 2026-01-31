# Basic Makefile template for paper-template project
# For more on Makefiles: https://www.gnu.org/software/make/manual/make.html

# Phony targets (targets that don't represent files)
.PHONY: all clean help render analyse install

# Default target
all:
	@echo "Available targets: all, clean, help, analyse, render"

# Help
help:
	@echo "Makefile targets:"
	@echo "  make all      - Show this message"
	@echo "  make clean    - Remove generated files"
	@echo "  make analyse  - Run the full analysis pipeline"
	@echo "  make render   - Render the paper"
	@echo "  make help     - Show detailed help"

# Clean
clean:
	@echo "Cleaning generated files..."
	rm -rf .quarto/
	rm -f paper/*.pdf paper/*.tex
	rm -rf output/figures/* output/tables/*
	rm -rf data/processed/*

# ============================================================================
# Analysis Pipeline
# ============================================================================

# Define outputs for each step
SIM_DATA := data/processed/simulated_data.rds
TRAJ_PLOT := output/figures/combined_traj_plot.png

MODEL_DEFS := data/processed/model_definitions.rds
MODEL_DESC_TABLE := output/tables/model_descriptions.rds

MODEL_RESULTS := data/processed/model_results.rds

ANALYSIS_METRICS := data/processed/analysis_metrics.rds

# List of plot outputs (each from a separate script)
PLOT_TIMING := output/figures/timing_plot.png
PLOT_RT_TOTAL := output/figures/rt_total_crps_plot.png
PLOT_INF_TOTAL := output/figures/infections_total_crps_plot.png
PLOT_RT_NOW := output/figures/rt_now_comparison_plot.png
PLOT_INF_REAL := output/figures/infections_real_time_comparison_plot.png
PLOT_RT_TV := output/figures/rt_crps_plot.png
PLOT_INF_TV := output/figures/infections_crps_plot.png

# List of all analysis outputs (plots)
ANALYSIS_OUTPUTS := $(PLOT_TIMING) \
                    $(PLOT_RT_TOTAL) \
                    $(PLOT_INF_TOTAL) \
                    $(PLOT_RT_NOW) \
                    $(PLOT_INF_REAL) \
                    $(PLOT_RT_TV) \
                    $(PLOT_INF_TV)

# Step 1a: Simulate Data
$(SIM_DATA): scripts/R/01_simulate_data.R
	@echo "Step 1a: Simulating data..."
	Rscript scripts/R/01_simulate_data.R $(SIM_DATA)

# Step 1b: Plot Simulated Data
$(TRAJ_PLOT): scripts/R/01_plot_simulated_data.R $(SIM_DATA)
	@echo "Step 1b: Plotting simulated data..."
	Rscript scripts/R/01_plot_simulated_data.R $(SIM_DATA) $(TRAJ_PLOT)

# Step 2: Define Models
$(MODEL_DEFS) $(MODEL_DESC_TABLE): scripts/R/02_define_models.R $(SIM_DATA)
	@echo "Step 2: Defining models..."
	Rscript scripts/R/02_define_models.R $(SIM_DATA) $(MODEL_DEFS) $(MODEL_DESC_TABLE)

# Step 3: Run Models
$(MODEL_RESULTS): scripts/R/03_run_models.R $(SIM_DATA) $(MODEL_DEFS)
	@echo "Step 3: Running models..."
	Rscript scripts/R/03_run_models.R $(SIM_DATA) $(MODEL_DEFS) $(MODEL_RESULTS)

# Step 4: Compute Metrics (Analysis)
$(ANALYSIS_METRICS): scripts/R/04_compute_metrics.R scripts/R/functions.R $(MODEL_RESULTS) $(SIM_DATA) $(MODEL_DEFS) $(MODEL_DESC_TABLE)
	@echo "Step 4: Computing metrics..."
	Rscript scripts/R/04_compute_metrics.R $(MODEL_RESULTS) $(SIM_DATA) $(MODEL_DEFS) $(MODEL_DESC_TABLE) $(ANALYSIS_METRICS)

# Step 5: Plotting (Separate Scripts)
$(PLOT_TIMING): scripts/R/05_plot_timing.R scripts/R/functions.R $(ANALYSIS_METRICS)
	@echo "Step 5a: Plotting timing..."
	Rscript scripts/R/05_plot_timing.R $(ANALYSIS_METRICS) $(PLOT_TIMING)

$(PLOT_RT_TOTAL): scripts/R/05_plot_rt_total.R scripts/R/functions.R $(ANALYSIS_METRICS)
	@echo "Step 5b: Plotting Rt total performance..."
	Rscript scripts/R/05_plot_rt_total.R $(ANALYSIS_METRICS) $(PLOT_RT_TOTAL)

$(PLOT_INF_TOTAL): scripts/R/05_plot_infections_total.R scripts/R/functions.R $(ANALYSIS_METRICS)
	@echo "Step 5c: Plotting Infections total performance..."
	Rscript scripts/R/05_plot_infections_total.R $(ANALYSIS_METRICS) $(PLOT_INF_TOTAL)

$(PLOT_RT_NOW): scripts/R/05_plot_rt_nowcast.R scripts/R/functions.R $(ANALYSIS_METRICS)
	@echo "Step 5d: Plotting Rt nowcast performance..."
	Rscript scripts/R/05_plot_rt_nowcast.R $(ANALYSIS_METRICS) $(PLOT_RT_NOW)

$(PLOT_INF_REAL): scripts/R/05_plot_infections_realtime.R scripts/R/functions.R $(ANALYSIS_METRICS)
	@echo "Step 5e: Plotting Infections real-time performance..."
	Rscript scripts/R/05_plot_infections_realtime.R $(ANALYSIS_METRICS) $(PLOT_INF_REAL)

$(PLOT_RT_TV): scripts/R/05_plot_rt_time_varying.R scripts/R/functions.R $(ANALYSIS_METRICS)
	@echo "Step 5f: Plotting Rt time-varying performance..."
	Rscript scripts/R/05_plot_rt_time_varying.R $(ANALYSIS_METRICS) $(PLOT_RT_TV)

$(PLOT_INF_TV): scripts/R/05_plot_infections_time_varying.R scripts/R/functions.R $(ANALYSIS_METRICS)
	@echo "Step 5g: Plotting Infections time-varying performance..."
	Rscript scripts/R/05_plot_infections_time_varying.R $(ANALYSIS_METRICS) $(PLOT_INF_TV)

# Main analysis target
analyse: $(ANALYSIS_OUTPUTS) $(TRAJ_PLOT)

# Render the paper
render: paper/index.qmd $(ANALYSIS_OUTPUTS) $(TRAJ_PLOT) $(MODEL_DESC_TABLE)
	@echo "Rendering paper..."
	quarto render paper/index.qmd

# Install dependencies
install:
	Rscript -e "renv::restore()"