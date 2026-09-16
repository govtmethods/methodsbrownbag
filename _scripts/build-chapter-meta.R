# Post-render script: reads YAML front matter from each chapter .qmd
# and writes _book/chapters-meta.json for the sidebar and index listing.
# Runs automatically after every quarto render.

library(yaml)
library(jsonlite)

# NB the length(x) == 0 guard: a chapter with no `date:` yields
# as.character(NULL) == character(0), which is neither NULL nor "" and
# serialises to [] — truthy in the consuming JS, so the index kicker would
# render a dangling " · " separator.
or_default <- function(x, default) {
  if (is.null(x) || length(x) == 0 || identical(x, "")) default else x
}

config   <- yaml.load_file("_quarto.yml")
chapters <- config$book$chapters

# chapters can be strings, lists (e.g. list(text=..., file=...)), or parts
# (list(part=..., chapters=...)). Parts are walked and their label is carried
# into the JSON as `part`, so the index and About page can group by season.
get_file <- function(ch) {
  if (is.character(ch)) ch
  else if (is.list(ch) && !is.null(ch$file)) ch$file
  else NULL
}

walk_chapters <- function(chs, part = "") {
  out <- list()
  for (ch in chs) {
    if (is.list(ch) && !is.null(ch$part)) {
      out <- c(out, walk_chapters(ch$chapters, as.character(ch$part)))
    } else {
      f <- get_file(ch)
      # index.qmd and references.qmd are chapters but not sessions.
      if (!is.null(f) && !(f %in% c("index.qmd", "references.qmd"))) {
        out[[length(out) + 1]] <- list(file = f, part = part)
      }
    }
  }
  out
}

chapter_entries <- walk_chapters(chapters)

meta <- lapply(chapter_entries, function(entry) {
  f <- entry$file
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
    date   = or_default(as.character(parsed$date), ""),
    part   = entry$part
  )
})

meta <- Filter(Negate(is.null), meta)

out <- "_book/chapters-meta.json"
write(toJSON(meta, auto_unbox = TRUE, pretty = TRUE), out)
message("chapters-meta.json: ", length(meta), " chapters written to ", out)
