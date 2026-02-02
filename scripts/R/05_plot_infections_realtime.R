# 05_plot_infections_realtime.R

library(ggplot2)
library(data.table)
library(scales)

source(file.path("scripts", "R", "functions.R"))

# Capture arguments
args <- if (interactive()) {
  c(file.path("data", "processed", "analysis_metrics.rds"), 
    file.path("output", "figures", "infections_real_time_comparison_plot.png"))
} else {
  commandArgs(trailingOnly = TRUE)
}
input_metrics <- args[1]
output_plot <- tail(args, 1)

metrics <- readRDS(input_metrics)
infections_real_time_performance <- metrics$infections_real_time_performance

if (!dir.exists(dirname(output_plot))) dir.create(dirname(output_plot), recursive = TRUE)

infections_real_time_comparison_plot <- plot_performance_vs_timing(
    infections_real_time_performance, 
    "crps", 
    "Model speed versus real-time performance in 
forecasting infections", 
    get_plot_theme()
) +
scale_y_continuous(labels = scales::label_comma()) +
labs(x = "Runtime (secs)", y = "CRPS")

ggsave(output_plot, infections_real_time_comparison_plot, width = 8, height = 6)
