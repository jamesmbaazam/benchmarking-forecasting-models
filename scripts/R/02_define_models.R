# 02_define_models.R
# Defines model configurations and descriptions

library(EpiNow2)
library(data.table)

# Capture arguments
args <- if (interactive()) {
  c(file.path("data", "processed", "simulated_data.rds"), 
    file.path("data", "processed", "model_definitions.rds"), 
    file.path("output", "tables", "model_descriptions.rds"))
} else {
  commandArgs(trailingOnly = TRUE)
}
input_file <- args[1]
output_defs <- args[2]
output_desc <- tail(args, 1)

# Ensure output directories exist
if (!dir.exists(dirname(output_defs))) dir.create(dirname(output_defs), recursive = TRUE)
if (!dir.exists(dirname(output_desc))) dir.create(dirname(output_desc), recursive = TRUE)

# Load shared inputs from simulation step
sim_data <- readRDS(input_file)
rt_prior_default <- sim_data$rt_prior_default
obs <- sim_data$obs

# Model Descriptions
model_descriptions <- data.table(
  model = c("default", "non_mechanistic", "rw7", "non_residual"),
  description = c(
  "Default model (non-stationary prior on Rt)",
  "No mechanistic prior on Rt",
  "7-day random walk prior on Rt",
  "Stationary prior on Rt"
  ))

saveRDS(model_descriptions, output_desc)

# Model Configurations
model_configs <- list(
  default = list(
    rt = rt_opts(prior = rt_prior_default)
  ),
  non_mechanistic = list(
    rt = NULL
  ),
  rw7 = list(
    rt = rt_opts(prior = rt_prior_default, rw = 7),
    gp = NULL
  ),
  non_residual = list(
    rt = rt_opts(prior = rt_prior_default, gp_on = "R0")
  )
)

# Common Inputs
delay <- example_incubation_period + example_reporting_delay
horizon <- 7

model_inputs <- list(
  generation_time = generation_time_opts(example_generation_time),
  delays = delay_opts(delay),
  obs = obs,
  forecast = forecast_opts(horizon = horizon),
  verbose = FALSE
)

# Save definitions
saveRDS(list(
  model_configs = model_configs,
  model_inputs = model_inputs,
  horizon = horizon,
  data_length = 70 # defined here as constant
), output_defs)
