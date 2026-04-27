# Post-render script: reads YAML front matter from each chapter .qmd
# and writes _book/chapters-meta.json for the sidebar and index listing.
# Runs automatically after every quarto render.

library(yaml)
library(jsonlite)

or_default <- function(x, default) if (is.null(x) || identical(x, "")) default else x

config   <- yaml.load_file("_quarto.yml")
chapters <- config$book$chapters

# chapters can be strings or lists (e.g. list(text=..., file=...))
get_file <- function(ch) {
  if (is.character(ch)) ch
  else if (is.list(ch) && !is.null(ch$file)) ch$file
  else NULL
}

chapter_files <- Filter(
  Negate(is.null),
  lapply(chapters, function(ch) {
    f <- get_file(ch)
    if (is.null(f) || f == "index.qmd") NULL else f
  })
)

meta <- lapply(chapter_files, function(f) {
  if (!file.exists(f)) return(NULL)

  lines  <- readLines(f, warn = FALSE)
  delims <- which(trimws(lines) == "---")
  if (length(delims) < 2) return(NULL)

  parsed <- tryCatch(
    yaml.load(paste(lines[(delims[1] + 1):(delims[2] - 1)], collapse = "\n")),
    error = function(e) NULL
  )
  if (is.null(parsed)) return(NULL)

  # Author: handle string, list of strings, or list of {name: ...}
  author_str <- {
    a <- parsed$author
    if (is.null(a)) "" else {
      names <- sapply(a, function(x) {
        if (is.list(x)) or_default(x$name, "") else as.character(x)
      })
      paste(Filter(nchar, names), collapse = ", ")
    }
  }

  list(
    href   = sub("\\.qmd$", ".html", f),
    title  = or_default(parsed$title, f),
    author = author_str,
    date   = or_default(as.character(parsed$date), "")
  )
})

meta <- Filter(Negate(is.null), meta)

out <- "_book/chapters-meta.json"
write(toJSON(meta, auto_unbox = TRUE, pretty = TRUE), out)
message("chapters-meta.json: ", length(meta), " chapters written to ", out)
