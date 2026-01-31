# 05_plot_timing.R

library(ggplot2)
library(data.table)

source(file.path("scripts", "R", "functions.R"))

# Capture arguments
args <- if (interactive()) {
  c(file.path("data", "processed", "analysis_metrics.rds"), 
    file.path("output", "figures", "timing_plot.png"))
} else {
  commandArgs(trailingOnly = TRUE)
}
input_metrics <- args[1]
output_plot <- tail(args, 1)

metrics <- readRDS(input_metrics)
runtimes_dt_detailed <- metrics$runtimes_dt_detailed

if (!dir.exists(dirname(output_plot))) dir.create(dirname(output_plot), recursive = TRUE)

timing_plot <- ggplot(data = runtimes_dt_detailed) +
  geom_col(aes(x = epidemic_phase, y = timing, fill = model), position = position_dodge2()) +
  labs(x = "Epidemic phase", y = "Runtime (secs)", fill = "Model", title = "Model runtimes") +
  scale_color_brewer(palette = "Dark2") +
  scale_y_continuous(breaks = seq(0, max(runtimes_dt_detailed$timing) + 20, 25)) +
  get_plot_theme()

ggsave(output_plot, timing_plot, width = 8, height = 6)
