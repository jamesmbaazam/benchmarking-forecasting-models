# 05_plot_rt_nowcast.R

library(ggplot2)
library(data.table)

source(file.path("scripts", "R", "functions.R"))

# Capture arguments
args <- if (interactive()) {
  c(file.path("data", "processed", "analysis_metrics.rds"), 
    file.path("output", "figures", "rt_now_comparison_plot.png"))
} else {
  commandArgs(trailingOnly = TRUE)
}
input_metrics <- args[1]
output_plot <- tail(args, 1)

metrics <- readRDS(input_metrics)
rt_nowcast_performance <- metrics$rt_nowcast_performance

if (!dir.exists(dirname(output_plot))) dir.create(dirname(output_plot), recursive = TRUE)

rt_now_comparison_plot <- plot_performance_vs_timing(
    rt_nowcast_performance, 
    "crps", 
    "Model speed versus nowcast performance in \nestimating Rt", 
    get_plot_theme()
) +
labs(x = "Runtime (secs)", y = "CRPS")

ggsave(output_plot, rt_now_comparison_plot, width = 8, height = 6)
