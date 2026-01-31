# 05_plot_rt_time_varying.R

library(ggplot2)
library(data.table)
library(scales)

source(file.path("scripts", "R", "functions.R"))

# Capture arguments
args <- if (interactive()) {
  c(file.path("data", "processed", "analysis_metrics.rds"), 
    file.path("output", "figures", "rt_crps_plot.png"))
} else {
  commandArgs(trailingOnly = TRUE)
}
input_metrics <- args[1]
output_plot <- tail(args, 1)

metrics <- readRDS(input_metrics)
rt_crps_dt_final <- metrics$rt_crps_dt_final

if (!dir.exists(dirname(output_plot))) dir.create(dirname(output_plot), recursive = TRUE)

rt_crps_plot <- plot_crps_over_time(
    rt_crps_dt_final, 
    "Time-varying model performance (Rt)", 
    get_plot_theme()
) +
facet_wrap( ~ epidemic_phase, ncol = 1) +
theme(legend.position = "right") +
get_plot_theme()

ggsave(output_plot, rt_crps_plot, width = 8, height = 8)
