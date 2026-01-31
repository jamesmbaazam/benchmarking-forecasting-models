# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

R-based academic paper template using Quarto for reproducible research. Renders to PDF via LaTeX with version-controlled dependencies using renv.

## Quick Commands

### Rendering
```bash
quarto render paper/index.qmd    # Renders to paper/index.pdf
make clean                         # Remove generated files
```

### R Dependencies
```bash
Rscript -e "renv::restore()"      # Install packages from renv.lock
```
In R: `renv::snapshot()` to update renv.lock after adding packages.

### R Version
R version is pinned in `.Rversion` (currently 4.5.1). `.Rprofile` checks version on startup and warns if mismatched.

## Architecture

**Data Flow**: `data/raw/` (immutable) → `scripts/R/` → `output/figures|tables/` → `paper/index.qmd` → `paper/index.pdf`

**Key Files**:
- `paper/index.qmd` - Main document (generic article template)
- `paper/references.bib` - Bibliography
- `renv.lock` - R package versions
- `.Rversion` - Required R version
- `_quarto.yml` - Rendering configuration

**Execution**: Quarto runs from project root (`execute-dir: project`). Code chunks use paths relative to project root.

## Configuration

### _quarto.yml
- No `output-dir` - PDFs render alongside source
- `freeze: auto` - Caches execution
- `echo: false` - Hides code by default
- Figures save to `output/figures/`

### .Rprofile
- Checks R version vs `.Rversion`
- Activates renv
- Sets CRAN mirror and parallel cores

## CI/CD

### render.yml
- Triggers on: `paper/`, `scripts/`, `data/`, `_quarto.yml`, `renv.lock`, `.Rprofile` changes
- Uses R 4.5.1 (pinned)
- Automatic renv caching (5-10x speedup)
- Uploads `paper/*.pdf` as artifacts

### checks.yml
- Spell check with `paper/.wordlist.txt`
- Warnings only (non-blocking)

## Important Notes

- **R version**: Must match `.Rversion` for reproducibility
- **PDF location**: `paper/index.pdf` (gitignored)
- **Figures**: Auto-saved to `output/figures/` via knitr settings
- **LaTeX**: Kept in `paper/` for debugging (`keep-tex: true`)
- **Docker**: Optional `Dockerfile` for extreme reproducibility

## Reproducibility

See `REPRODUCIBILITY.md` for:
- Seed setting guidelines
- Data provenance templates
- Computational environment documentation
- Reproducibility checklist

## Documentation

- `README.md` - Research project documentation (users fill this out for their specific analysis)
- `INSTRUCTIONS.md` - Template setup guide with installation and usage instructions
- `REPRODUCIBILITY.md` - Reproducibility best practices
- `data/README.md` - Data documentation template

## Coding Standards & Workflow

When refactoring or adding new analysis code, adhere to these patterns:

### 1. Modularity (One-Script, One-Task)
- Avoid monolithic scripts. Split workflows into granular steps:
  - **Data Generation**: `01_simulate_data.R` (Saves `.rds`)
  - **Data Plotting**: `01_plot_simulated_data.R` (Reads `.rds`, saves `.png`)
  - **Model Definitions**: `02_define_models.R`
  - **Execution**: `03_run_models.R` (Computationally intensive)
  - **Analysis**: `04_compute_metrics.R` (Metrics & Tables)
  - **Plotting**: `05_plot_*.R` (One script per figure group)

### 2. Make-Driven Workflow
- The `Makefile` is the source of truth for the project state.
- Define specific targets for every output artifact.
- Use representative targets (e.g., `ANALYSIS_METRICS`) for steps producing multiple files.
- Ensure strict dependency declaration (e.g., plotting targets depend on analysis targets).

### 3. Dual-Mode Execution & Robust Paths
- Scripts must support both interactive debugging and CLI execution:
  ```r
  args <- if (interactive()) {
    c(file.path("data", "processed", "input.rds"), file.path("output", "figures", "plot.png"))
  } else {
    commandArgs(trailingOnly = TRUE)
  }
  ```
- Always use `file.path()` for constructing paths to ensure cross-platform compatibility.
- Use `tail(args, 1)` for the output path to align with Makefile recipes.

### 4. Intermediate State Persistence
- Use `.rds` files to pass data between steps (`data/processed/`).
- plotting scripts should *read* processed data, not re-compute it.
- This decoupling allows lightweight plotting without loading heavy libraries (e.g., `stan`, `EpiNow2`).

### 5. Centralized Logic
- Place reusable logic (CRPS calculations, themes) in `scripts/R/functions.R`.
- Use a global plotting theme (e.g., `get_plot_theme()`) for visual consistency.

### 6. Output Management
- **Figures**: Save as `.png` using `ggsave` in `output/figures/`.
- **Metrics**: Save as `.rds` in `data/processed/`.
- **Quarto**: Use `knitr::include_graphics()` for plots. Do not run heavy analysis in `.qmd` chunks.
