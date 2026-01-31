# 05_plot_infections_total.R

library(ggplot2)
library(data.table)
library(scales)

source(file.path("scripts", "R", "functions.R"))

# Capture arguments
args <- if (interactive()) {
  c(file.path("data", "processed", "analysis_metrics.rds"), 
    file.path("output", "figures", "infections_total_crps_plot.png"))
} else {
  commandArgs(trailingOnly = TRUE)
}
input_metrics <- args[1]
output_plot <- tail(args, 1)

metrics <- readRDS(input_metrics)
infections_total_performance <- metrics$infections_total_performance

if (!dir.exists(dirname(output_plot))) dir.create(dirname(output_plot), recursive = TRUE)

infections_total_crps_plot <- plot_performance_vs_timing(
    infections_total_performance, 
    "total_crps", 
    "Model speed versus out-of-sample total \nperformance in forecasting infections", 
    get_plot_theme()
) +
scale_y_continuous(labels = scales::label_comma()) +
labs(x = "Runtime (secs)", y = "Total CRPS")

ggsave(output_plot, infections_total_crps_plot, width = 8, height = 6)


