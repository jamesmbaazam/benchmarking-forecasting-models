# 01_plot_simulated_data.R
# Loads simulated data and creates trajectory plots

library(ggplot2)
library(patchwork)
library(scales)

# Capture arguments
args <- if (interactive()) {
  c(file.path("data", "processed", "simulated_data.rds"), 
    file.path("output", "figures", "combined_traj_plot.png"))
} else {
  commandArgs(trailingOnly = TRUE)
}
input_file <- args[1]
output_file <- tail(args, 1)

# Create output directory if it doesn't exist
output_dir <- dirname(output_file)
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# Load data
sim_data <- readRDS(input_file)
infections_true <- sim_data$infections_true
R_true <- sim_data$R_true
snapshot_dates <- sim_data$snapshot_dates

# Plotting
R_traj <- ggplot(data = R_true) +
  geom_line(aes(x = date, y = R)) +
    labs(x = "Date", y = "Rt")

infections_traj <- ggplot(data = infections_true) +
  geom_line(aes(x = date, y = confirm)) +
  geom_vline(xintercept = snapshot_dates, linetype = "dashed") +
  annotate("text", x = snapshot_dates["growth"], y = 7500, label = "Growth", color = "blue",
           angle = 90, vjust = -0.5) +
  annotate("text", x = snapshot_dates["peak"], y = 7500, label = "Peak", color = "blue",
           angle = 90, vjust = -0.5) +
  annotate("text", x = snapshot_dates["decline"], y = 7500, label = "Decline", color = "blue",
           angle = 90, vjust = -0.5) +
  scale_y_continuous(labels = scales::label_comma()) +
    labs(x = "Date", y = "Infections")

combined_traj_plot <- (R_traj/infections_traj) +
    plot_layout(axes = "collect") &
    scale_x_date(date_labels = "%b %d", date_breaks = "1 weeks") &
    theme_minimal()

# Save plot as PNG
ggsave(output_file, combined_traj_plot, width = 8, height = 6)
