# 000-setup.R ---------------------------------------------------------------
#
# Creates the standard project folder structure for a Govt 8001 / Quant 1
# data essay, and makes sure the `here` package is available.
#
# Safe to run more than once: existing folders and files are left alone.
# Runs the same on Windows, macOS and Linux - every path is built with
# here(), so there are no forward/backslash problems and no shell commands.
#
# HOW TO USE
#   1. Save this file in your project folder, next to the .Rproj file.
#   2. Open the project by double-clicking the .Rproj file.
#   3. Open this file in RStudio and run it:
#        Windows/Linux  Ctrl + Shift + Enter
#        macOS          Cmd + Shift + Return
#
# ---------------------------------------------------------------------------


## 1. Packages --------------------------------------------------------------

packages <- c("here")          # add "tidyverse", "janitor", ... if you want
                               # them installed at the same time

check_packages <- function(pkg) {
  missing <- pkg[!vapply(pkg, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) > 0) {
    message("Installing: ", paste(missing, collapse = ", "))
    install.packages(missing, dependencies = TRUE,
                     repos = "https://cloud.r-project.org")
  }
  invisible(lapply(pkg, library, character.only = TRUE))
}

check_packages(packages)


## 2. Check where we are ----------------------------------------------------

root <- here::here()
message("Project root: ", root)

if (!any(grepl("\\.Rproj$", list.files(root)))) {
  warning("No .Rproj file found at the project root.\n",
          "  Open the project by its .Rproj file first, or the folders may ",
          "be created in the wrong place.", call. = FALSE)
}


## 3. Create the folders ----------------------------------------------------

folders <- c(
  "Data",
  "Data/Raw",
  "Data/Clean",
  "Scripts",
  "Scripts/RScripts",
  "Scripts/Stata-Scripts",
  "Scripts/Python-Scripts",
  "Outputs",
  "Outputs/Figures",
  "Outputs/Tables",
  "Outputs/Text"
)

# here() takes the folder names one at a time, which is what keeps this
# working on Windows: R never sees a hand-written slash.
make_path <- function(relative) {
  do.call(here::here, as.list(strsplit(relative, "/", fixed = TRUE)[[1]]))
}

for (folder in folders) {
  path <- make_path(folder)
  if (dir.exists(path)) {
    message("  exists : ", folder)
  } else {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
    message("  created: ", folder)
  }
}


## 4. A starter .gitignore --------------------------------------------------

gitignore <- here::here(".gitignore")

if (file.exists(gitignore)) {
  message("  exists : .gitignore (left alone)")
} else {
  writeLines(c(
    "# R and RStudio",
    ".Rhistory",
    ".RData",
    ".Rproj.user/",
    "",
    "# Raw data stays out of the repository",
    "Data/Raw/",
    "*.csv",
    "*.dta",
    "*.xlsx",
    "",
    "# Things you can regenerate",
    "Outputs/",
    "*.pdf",
    "",
    "# Quarto",
    "/.quarto/",
    "/_site/"
  ), gitignore)
  message("  created: .gitignore")
}


## 5. Done ------------------------------------------------------------------

message("\nSetup complete. Put raw data in Data/Raw and scripts in ",
        "Scripts/RScripts,\nand use here() to reach them:\n",
        '  read.csv(here("Data", "Raw", "your-data.csv"))')
