# Benchmarking Forecasting Models

## Project Overview

This project is a reproducible research framework in R designed to benchmark the performance and computational efficiency of various forecasting models, specifically focusing on configurations within the `{EpiNow2}` package. It evaluates trade-offs between speed and accuracy in real-time reproduction number ($R_t$) estimation and short-term forecasting using simulated epidemic data.

The project employs a modular, Make-driven workflow to ensure reproducibility, leveraging Quarto for the final manuscript generation and `renv` for dependency management.

## Building and Running

The project is orchestrated via a `Makefile`.

### Core Commands

-   **Install Dependencies:**
    ```bash
    make install
    ```
    Restores the R package environment defined in `renv.lock`.

-   **Run Analysis Pipeline:**
    ```bash
    make analyse
    ```
    Executes the full pipeline: data simulation -> model definition -> model execution -> metric computation -> figure generation. This step is computationally intensive.

-   **Render Paper:**
    ```bash
    make render
    ```
    Compiles the final PDF manuscript (`paper/index.pdf`) from `paper/index.qmd`, ensuring all upstream analysis dependencies are up to date.

-   **Clean Artifacts:**
    ```bash
    make clean
    ```
    Removes generated outputs (figures, tables, processed data, and PDF).

## Development Conventions

### Coding Standards

-   **Modularity (One-Script, One-Task):** Analysis is split into discrete, atomic scripts (e.g., `01_simulate_data.R`, `03_run_models.R`, `05_plot_timing.R`) to isolate responsibilities.
-   **Dual-Mode Execution:** R scripts are designed to run both interactively (for debugging) and via the command line (for the build pipeline). They use the following pattern:
    ```r
    args <- if (interactive()) {
      c(file.path("path", "to", "input.rds"), file.path("path", "to", "output.rds"))
    } else {
      commandArgs(trailingOnly = TRUE)
    }
    ```
-   **Robust Path Handling:** Always use `file.path()` to construct file paths to ensure cross-platform compatibility.
-   **Centralized Logic:** Reusable functions (e.g., CRPS calculation, plotting themes) are maintained in `scripts/R/functions.R`.

### Data Flow & Architecture

1.  **Simulation:** `01_simulate_data.R` generates synthetic epidemic data → `data/processed/simulated_data.rds`.
2.  **Definition:** `02_define_models.R` creates model configurations → `data/processed/model_definitions.rds`.
3.  **Execution:** `03_run_models.R` fits the models (intensive) → `data/processed/model_results.rds`.
4.  **Analysis:** `04_compute_metrics.R` calculates performance metrics → `data/processed/analysis_metrics.rds`.
5.  **Visualization:** Series of `05_plot_*.R` scripts generate static `.png` figures in `output/figures/`.
6.  **Reporting:** `paper/index.qmd` reads the static figures and metrics to produce the final document.

### Output Management

-   **Intermediate Data:** Saved as `.rds` files in `data/processed/`.
-   **Figures:** Saved as `.png` files in `output/figures/` using `ggsave`.
-   **Tables:** Generated as data frames within the pipeline but primarily rendered directly in Quarto or passed as objects.
-   **Paper:** The final PDF is generated in `paper/index.pdf`.
