# 05_plot_infections_time_varying.R

library(ggplot2)
library(data.table)
library(scales)

source(file.path("scripts", "R", "functions.R"))

# Capture arguments
args <- if (interactive()) {
  c(file.path("data", "processed", "analysis_metrics.rds"), 
    file.path("output", "figures", "infections_crps_plot.png"))
} else {
  commandArgs(trailingOnly = TRUE)
}
input_metrics <- args[1]
output_plot <- tail(args, 1)

metrics <- readRDS(input_metrics)
infections_crps_dt_final <- metrics$infections_crps_dt_final

if (!dir.exists(dirname(output_plot))) dir.create(dirname(output_plot), recursive = TRUE)

infections_crps_plot <- plot_crps_over_time(
    infections_crps_dt_final, 
    "Time-varying model performance (infections)", 
    get_plot_theme()
) +
facet_wrap(~epidemic_phase, ncol = 1) +
theme(legend.position = "right") +
labs(y = "CRPS") +
get_plot_theme()

ggsave(output_plot, infections_crps_plot, width = 8, height = 8)
