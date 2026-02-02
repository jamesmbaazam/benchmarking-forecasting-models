# 03_run_models.R
# Runs the EpiNow2 models on simulated data

library(EpiNow2)
library(data.table)
library(purrr)
library(parallel)

# Capture arguments
args <- if (interactive()) {
  c(file.path("data", "processed", "simulated_data.rds"), 
    file.path("data", "processed", "model_definitions.rds"), 
    file.path("data", "processed", "model_results.rds"))
} else {
  commandArgs(trailingOnly = TRUE)
}
sim_data_path <- args[1]
model_defs_path <- args[2]
output_path <- tail(args, 1)

# Ensure output directory exists
if (!dir.exists(dirname(output_path))) dir.create(dirname(output_path), recursive = TRUE)

set.seed(9876)

# Load data and definitions
sim_data <- readRDS(sim_data_path)
defs <- readRDS(model_defs_path)

infections_true <- sim_data$infections_true
snapshot_dates <- sim_data$snapshot_dates

model_configs <- defs$model_configs
model_inputs <- defs$model_inputs
data_length <- defs$data_length

# Prepare data snapshots
data_snaps <- lapply(
  snapshot_dates,
  function(snap_date) {
    tail(infections_true[date <= snap_date], data_length)
  }
)

# Run models
# Using safely to handle failures without stopping
safe_epinow <- purrr::safely(epinow)
results <- lapply(
  data_snaps, function(data) {
    lapply(
      model_configs,
      function(model) {
        do.call(
          safe_epinow,
          c(
            data = list(data),
            model_inputs,
            model
          )
        )
      }
    )
  }
)

saveRDS(results, output_path)
