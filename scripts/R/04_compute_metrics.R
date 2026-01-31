# 04_compute_metrics.R
# Computes analysis metrics and saves results

library(EpiNow2)
library(scoringutils)
library(data.table)
library(rstan)
library(ggplot2)
library(dplyr)
library(purrr)
library(lubridate)
library(scales)
library(posterior)
library(parallel)

source(file.path("scripts", "R", "functions.R"))

# Capture arguments
args <- if (interactive()) {
  c(file.path("data", "processed", "model_results.rds"), 
    file.path("data", "processed", "simulated_data.rds"), 
    file.path("data", "processed", "model_definitions.rds"), 
    file.path("output", "tables", "model_descriptions.rds"),
    file.path("data", "processed", "analysis_metrics.rds"))
} else {
  commandArgs(trailingOnly = TRUE)
}
results_path <- args[1]
sim_data_path <- args[2]
defs_path <- args[3]
model_desc_path <- args[4]

out_metrics_path <- tail(args, 1)

# Ensure output directory exists
if (!dir.exists(dirname(out_metrics_path))) dir.create(dirname(out_metrics_path), recursive = TRUE)

# Load inputs
results <- readRDS(results_path)
sim_data <- readRDS(sim_data_path)
defs <- readRDS(defs_path)
model_descriptions <- readRDS(model_desc_path)

infections_true <- sim_data$infections_true
R_true <- sim_data$R_true
snapshot_dates <- sim_data$snapshot_dates
horizon <- defs$horizon
data_length <- defs$data_length

# --- Runtimes ---
runtimes_by_snapshot <- get_model_results(results, "timing")
runtimes_dt <- lapply(runtimes_by_snapshot, function(x) as.data.table(x)) |>
  rbindlist(idcol = "snapshot_date", ignore.attr = TRUE)
snapshot_date_labels <- names(snapshot_dates)
runtimes_dt[, epidemic_phase := snapshot_date_labels[match(snapshot_date, snapshot_date_labels)]]

runtimes_dt_long <- melt(
  runtimes_dt,
  id.vars = "epidemic_phase",
  measure.vars = model_descriptions$model,
  variable.name = "model",
  value.name = "timing"
)

runtimes_dt_detailed <- merge(runtimes_dt_long, model_descriptions, by = "model")
runtimes_dt_detailed <- make_cols_factors(runtimes_dt_detailed, except = "timing")
runtimes_dt_detailed <- add_epidemic_phase_levels(runtimes_dt_detailed)

# --- CRPS Processing ---
rt_crps <- process_crps(results, "R", R_true$R, snapshot_dates, horizon, data_length, infections_true)
rt_crps_full <- merge.data.table(rt_crps, model_descriptions, by = "model")
rt_crps_dt <- make_cols_factors(rt_crps_full, except = c("date", "crps"))
rt_crps_dt_final <- add_epidemic_phase_levels(rt_crps_dt)

infections_crps <- process_crps(results, "infections", infections_true$confirm, snapshot_dates, horizon, data_length, infections_true)
infections_crps_full <- merge.data.table(infections_crps, model_descriptions, by = "model")
infections_crps_dt <- make_cols_factors(infections_crps_full, except = c("date", "crps"))
infections_crps_dt_final <- add_epidemic_phase_levels(infections_crps_dt)

# --- Overall Performance ---
rt_total_crps <- calculate_total_crps(rt_crps_dt_final, by = c("model", "epidemic_phase"), horizon = horizon)
rt_total_performance <- merge(rt_total_crps, runtimes_dt_detailed, by = c("model", "epidemic_phase"))

infections_total_crps <- calculate_total_crps(infections_crps_dt_final, by = c("model", "epidemic_phase"), horizon = horizon)
infections_total_performance <- merge(infections_total_crps, runtimes_dt_detailed, by = c("model", "epidemic_phase"))

# --- Nowcast Performance ---
rt_nowcast <- rt_crps_dt_final[, .SD[.N-(horizon + 1)], by = .(model, epidemic_phase)][, snapshot_date := NULL]
rt_nowcast_performance <- merge(rt_nowcast, runtimes_dt_detailed, by = c("model", "epidemic_phase", "description"))

# --- Real-time Infection Forecast ---
infections_real_time <- infections_crps_dt_final[, .SD[.N], by = .(model, epidemic_phase)][, snapshot_date := NULL]
infections_real_time_performance <- merge(infections_real_time, runtimes_dt_detailed, by = c("model", "epidemic_phase", "description"))

# --- Save Metrics ---
metrics <- list(
  runtimes_dt_detailed = runtimes_dt_detailed,
  rt_total_performance = rt_total_performance,
  infections_total_performance = infections_total_performance,
  rt_nowcast_performance = rt_nowcast_performance,
  infections_real_time_performance = infections_real_time_performance,
  rt_crps_dt_final = rt_crps_dt_final,
  infections_crps_dt_final = infections_crps_dt_final
)

saveRDS(metrics, out_metrics_path)