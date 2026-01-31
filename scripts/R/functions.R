# Helper functions for benchmarking analysis

#' Extract results from an epinow run
#' @param x A model run object
#' @param variable Variable to extract: "timing", "R", "infections", "reports"
extract_results <- function(x, variable) {
  stopifnot(
    "variable must be one of c(\"timing\", \"R\", \"infections\", \"reports\")" = 
      variable %in% c("timing", "R", "infections", "reports")
  )
  # Return NA if there's an error
  if (!is.null(x$error)) {
    return(NA)
  }

  if (variable == "timing") {
    return(round(as.duration(x$result$timing), 1))
  } else {
    obj <- x$result$estimates$fit
  }

  # Extracting "Rt", "infections", and "reports" is different based on the object's class and
  # other settings
  if (inherits(obj, "stanfit")) {
    # Depending on rt_opts(use_rt = TRUE/FALSE), R shows up as R or gen_R
    if (variable == "R") {
      # The non-mechanistic model returns "gen_R" where as the others sample "R".
      if ("R[1]" %in% names(obj)) {
        return(rstan::extract(obj, "R")$R)
      } else {
        return(rstan::extract(obj, "gen_R")$gen_R)
      }
    } else {
      return(rstan::extract(obj, variable)[[variable]])
    }
  } else {
    obj_mat <- as_draws_matrix(obj)
    # Extracting R depends on the value of rt_opts(use_rt = )
    if (variable == "R") {
      if ("R[1]" %in% variables(obj_mat)) {
          return(subset_draws(obj_mat, "R"))
      } else {
        return(subset_draws(obj_mat, "gen_R"))
      }
    } else {
        return(subset_draws(obj_mat, variable))
      }
    }
}

#' Apply extract_results to a nested list
get_model_results <- function(results_by_snapshot, variable) {
  # Get model results list
  purrr::map_depth(results_by_snapshot, 2, extract_results, variable)
}

#' Convert columns to factors
make_cols_factors <- function(data, except){
  data[
    ,
    (setdiff(names(data), except)) := 
      lapply(.SD, as.factor),
    .SDcols = setdiff(names(data), except)
  ]
  data[]
}

#' Add epidemic phase factor levels
add_epidemic_phase_levels <- function(data){
  data[, epidemic_phase := factor(epidemic_phase, levels = c("growth", "peak", "decline"))]
  data[]
}

#' Calculate CRPS
calc_crps <- function(estimates, truth) {
    # if the object is not a matrix, then it's an NA (failed run)
    if (!inherits(estimates, c("matrix"))) return(rep(NA_real_, length(truth)))
    # Assumes that the estimates object is structured with the samples as rows
    shortest_obs_length <- min(ncol(estimates), length(truth))
    reduced_truth <- head(truth, shortest_obs_length)
    estimates_transposed <- t(estimates) # transpose to have samples as columns
    reduced_estimates <- head(estimates_transposed, shortest_obs_length)
    crps_sample(reduced_truth, reduced_estimates)
}

#' Process CRPS results
process_crps <- function(results, variable, truth, snapshot_dates, horizon, data_length, infections_true) {
    # Extract values
    results_by_snapshot <- get_model_results(results, variable = variable)

    # Get the dates reference from the true infections time series
    dates_ref <- infections_true$date
    # For each snapshot (growth, peak, decline)
    crps_by_snapshot <- purrr::imap(
        results_by_snapshot,
        function(results_by_model, snapshot_ref_label) {
            # Get the correct slice of truth data for this snapshot date. Note that we now
            # include the test data, i.e., the forecast horizon
            snapshot_date <- snapshot_dates[snapshot_ref_label]
            truth_slice <- tail(
                truth[1:which(dates_ref == snapshot_date + horizon)],
                data_length
            )

            # For each model in this snapshot, calculate CRPS comparing model estimates to truth slice
            purrr::map(results_by_model, function(res) {
                calc_crps(estimates = res, truth = truth_slice)
            })
        })

    # Add dates column based on snapshot length
    crps_with_dates <- purrr::imap(
        crps_by_snapshot,
        function(results_by_model, snapshot_ref_label) {
            date_end <- snapshot_dates[snapshot_ref_label] + horizon

            purrr::map(results_by_model, function(crps_values) {
                data.table(crps = crps_values)[,
                    date := seq.Date(
                        from = date_end - .N + 1,
                        to = date_end,
                        by = "day"
                    )]
            })
        })
    # Flatten the results into one dt
    crps_flat <- lapply(
        crps_with_dates,
        function(snapshot_results) {
            rbindlist(snapshot_results, idcol = "model")
        }) |
        rbindlist(idcol = "snapshot_date")

    # Replace the snapshot dates with their description
    snapshot_date_labels <- names(snapshot_dates)
    # Replace the snapshot dates with their description
    crps_flat[, epidemic_phase := snapshot_date_labels[
        match(snapshot_date, snapshot_date_labels)
    ]]

    return(crps_flat[])
}

#' Calculate total CRPS
calculate_total_crps <- function(data, by, horizon) {
    evaluation_data <- data[, .SD[(.N - horizon + 1):.N], by = by]
    evaluation_data[, .(total_crps = sum(crps, na.rm = TRUE)), by = by]
}

#' Plot performance vs timing
plot_performance_vs_timing <- function(performance_dt, performance_col, title, plot_theme_custom) {
  plot <- ggplot(data = performance_dt) +
    geom_point(
      aes(
        x = timing,
        y = .data[[performance_col]],
        color = model
      ),
      size = 5,
      stroke = 2.2,
      shape = 1
    ) +
    facet_wrap(~ epidemic_phase) +
    guides(
      color = guide_legend(title = "Model")
    ) +
    labs(title = title) +
    plot_theme_custom +
    scale_color_brewer(palette = "Dark2")
  return(plot)
}

#' Plot CRPS over time
plot_crps_over_time <- function(data, title, plot_theme_custom) {
    plot <- ggplot(data = data[!is.na(crps)]) + # remove failed models
        geom_line(
            aes(x = date,
                y = crps,
                color = model
            )
        ) +
        labs(
            x = "Time",
            y = "CRPS",
            title = title
        ) +
        guides(
            color = guide_legend(title = "Model"),
            linetype = guide_legend(title = "Fitting algorithm")
        ) +
        scale_y_continuous(labels = scales::label_comma()) +
        plot_theme_custom
    return(plot)
}

#' Get custom plot theme
get_plot_theme <- function() {
  theme_minimal() +
    theme(plot.title = element_text(size = 18),
          strip.text = element_text(size = 13),
          axis.title = element_text(size = 13),
          axis.text = element_text(size = 11),
          panel.border = element_rect(color = "black", fill = NA, linewidth = 0.5)
    )
}
