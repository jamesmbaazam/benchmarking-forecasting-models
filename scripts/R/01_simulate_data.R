# 01_simulate_data.R
# Generates and saves simulated data

library(EpiNow2)
library(data.table)
library(lubridate)

# Capture arguments
args <- if (interactive()) {
  c(file.path("data", "processed", "simulated_data.rds"))
} else {
  commandArgs(trailingOnly = TRUE)
}
output_file <- tail(args, 1)

set.seed(9876)

# Create output directory if it doesn't exist
output_dir <- dirname(output_file)
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# Shared inputs for simulation
obs <- obs_opts(
  scale = Normal(0.1, 0.025),
  return_likelihood = TRUE
)
rt_prior_default <- Normal(2, 0.1)
options(mc.cores = parallel::detectCores() - 1)

# Generate estimates object using example data
cases <- example_confirmed[1:60]
estimates <- epinow(
  data = cases,
  generation_time = generation_time_opts(example_generation_time),
  delays = delay_opts(example_incubation_period + example_reporting_delay),
  rt = rt_opts(prior = rt_prior_default, rw = 14),
  gp = NULL,
  obs = obs,
  forecast = forecast_opts(horizon = 0),
  output = "fit"
)

# Arbitrary reproduction number trajectory
R <- c(
    seq(1, 1.5, length.out = 15),
    seq(1.5, 1, length.out = 15),
    seq(1, 0.5, length.out = 15),
    seq(0.5, 1, length.out = 15),
    seq(1, 1.4, length.out = 10),
    seq(1.4, 1, length.out = 10),
    seq(1, 0.8, length.out = 10),
    seq(0.8, 1, length.out = 10)
)
R_noisy <- R * rnorm(length(R), 1, 0.05)

# Forecast infections
forecast <- forecast_infections(
  estimates$estimates,
  R = R_noisy,
  samples = 1
)

# Extract and prepare simulated true infections
infections_true <- forecast$summarised[variable == "infections", .(date, confirm = ceiling(mean))]
R_true <- data.frame(date = infections_true$date, R = R_noisy)

snapshot_dates <- c(
    "growth" = as.Date("2020-05-02"),
    "peak" = as.Date("2020-05-09"),
    "decline" = as.Date("2020-05-21")
)

# Save data for next steps
saveRDS(list(
  infections_true = infections_true,
  R_true = R_true,
  snapshot_dates = snapshot_dates,
  obs = obs,
  rt_prior_default = rt_prior_default
), output_file)