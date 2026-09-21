# CWRF precipitation and mortality: code and figure data

Code and processed source data accompanying the revised manuscript. The repository contains plotting scripts for Figures 1-4 and Supplementary Figures 1-14, upstream processing scripts, and a public implementation of the two-stage epidemiological model supplied by Hanling.

## Contents

| Path | Contents |
| --- | --- |
| `code/plotting/` | 18 figure scripts: 14 NCL scripts and four Python scripts |
| `source_data/` | Processed NetCDF and CSV inputs for the figures |
| `code/processing/` | Climate, population, health-impact and figure-data processing |
| `code/modeling/two_stage_precipitation_mortality_dlm.R` | Site-specific distributed lag models and regional random-effects meta-analysis |
| `assets/` | Map helpers, boundaries and river geometry |
| `run_figures.py` | Figure execution entry point |

Raw daily mortality records and private intermediate health datasets are not included. The response-only illustrative mortality figure is not included. Tests, validation outputs and internal review files are excluded from this release.

## Installation

Use Linux or WSL for the complete workflow, including NCL. Python-only figures can also run on Windows.

```bash
conda env create -f environment.yml
conda activate cee-reproduce
```

The environment file specifies dependencies; it is not a lock file for the original analysis environment. Rendering can vary with installed fonts and library versions.

## Reproduce the figures

Run from the repository root:

```bash
python run_figures.py
python run_figures.py --figures python
python run_figures.py --figures Figure1 FigureS14
```

The runner stages source data and map assets in `outputs/figures/`. It writes figures and execution logs there without altering the supplied data. Use `--output` to select another output directory and `--ncl /path/to/ncl` if NCL is not on PATH. Set `NCARG_ROOT` to the NCL installation if required by your environment.

The supplied data are the author-provided figure inputs. Figure S14 uses the rounded regional estimates in the revised Supplementary Table 3; plotting it does not refit the epidemiological model.

## Epidemiological model

```bash
Rscript code/modeling/two_stage_precipitation_mortality_dlm.R authorized_input.csv outputs/model
```

CSV and XLSX inputs are supported. Required columns:

| Column | Definition |
| --- | --- |
| `region` | NE, NC, NW, EC, CC or SC |
| `county` | Site identifier, stored as text |
| `date` | Calendar date in YYYY-MM-DD format |
| `d3` | Daily non-accidental death count |
| `mean_temp` | Daily mean temperature |
| `rain_mm` | Daily precipitation in mm |

This script adapts Hanling's supplied model to a file-based interface. Stage 1 fits site-specific quasi-Poisson distributed lag models with lag days 0-14, temperature adjustment, calendar-time splines and day of week. Stage 2 pools cumulative associations by region and precipitation category using REML random-effects meta-analysis.

The target rainfall category is coded as 1, no/light rainfall below 10 mm as 0, and other categories as missing. Missing calendar dates remain explicit missing rows; mortality values are never filled with zeros. Fits that fail or produce warnings are recorded. Regions with one usable site retain the site estimate without a heterogeneity estimate.

The public wrapper adds input checks, calendar handling and regional pooling around the supplied model specification. It has not been refitted using the restricted study mortality records. Reproducing the published estimates and eligible-site counts requires the study inputs and eligibility rules. The `available_target_days` output is a diagnostic, not the published exposure-day count. Site-level outputs should remain in the authorized data environment.

## Recreate processed figure inputs

Processing requires external climate, population and authorized mortality inputs. This repository alone supports plotting from the supplied source data; it does not contain every input needed for an end-to-end raw-data run. Run processing in a separate working directory containing the named inputs. Python scripts with command-line interfaces describe their arguments through `--help`. NCL scripts use input filenames defined in the scripts.

| Figures | Processing scripts |
| --- | --- |
| 1 | `Figure1_prepare.ncl` |
| 2, 3, S8, S11 | `0.generate_figure2_3_s8_s11_data.py` |
| 4, S10 | `generate_figure4_s10_contribution_data.py` |
| S1-S7 | Corresponding `FigureS*_prepare.ncl` files |
| S9 | `build_FigureS9_storm_only_basis_private.py`, then `make_FigureS9_storm_only_source_data.py` |
| S12 | `FigureS12-B-PDF*.ncl`, `FigureS12-B-PDF*.py`, then `FigureS12_prepare.ncl` |
| S13 | `FigureS13_prepare.ncl` |
| S14 | Published estimates supplied in `FigureS14_RR.csv` |

The S12 NCL PDF scripts prepare CWRF/NEX-GDDP-CMIP6 ensemble-mean daily fields, using external files under `raw/`, `NASA/` and `OBS/`, plus the regional mask. The Python PDF scripts additionally require the named raw-CMIP6 ensemble-mean inputs. The Python scripts calculate daily spatial PDFs, their temporal means and 1.96 times the standard error across daily PDFs. These are the original daily-PDF uncertainty summaries, not a minimum-to-maximum range across models. `FigureS12_prepare.ncl` combines the PDF CSVs with the map inputs into two NetCDF files. Existing outputs should be moved aside before running exporters that refuse to overwrite them.

Health-impact processing starts with `0.prepare_cwrf_health_static.py` and `remap_population_to_cwrf.py`, followed by `0.calculate_cwrf_mortality.py`. Figure-data exporters then consume the resulting intermediate datasets. Projection scripts contain fixed regional RR inputs; they do not automatically import newly fitted R estimates. Updating those estimates requires regenerating downstream outputs.

Factor-order sensitivity can be generated from the public decomposition data:

```bash
python code/processing/make_Table_factor_order_sensitivity.py --input source_data/Figure4_plot_data.nc --output outputs/factor_order_sensitivity.csv
```

## Data access and reuse

Obtain underlying data from the providers and under the access terms described in the manuscript. Restricted daily mortality data, event dates and county-level mortality sequences are not redistributed here. See `THIRD_PARTY_NOTICES.md` for map-resource attribution. No blanket license is assigned to third-party data or assets by this package.
