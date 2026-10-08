# Кросс-платформалық іске қосу (Windows / macOS / Linux):
#   Rscript run_lab.R lab05-dplyr
# labNN.R файлы өз қалтасында орындалады, нәтиже output.txt-ке жазылады.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) stop("Қолданылуы: Rscript run_lab.R <қалта>, мысалы lab05-dplyr")
root <- normalizePath(".")
dir <- file.path(root, args[1])
if (!dir.exists(dir)) stop("Қалта табылмады: ", dir)
setwd(dir)
script <- list.files(pattern = "^lab[0-9]+.*\\.R$")[1]
sink("output.txt", split = FALSE)
sink(stdout(), type = "message")
options(width = 100, warn = 1)
res <- try(source(script, echo = TRUE, max.deparse.length = Inf, keep.source = TRUE,
                  prompt.echo = "> ", spaced = FALSE, encoding = "UTF-8"),
           outFile = stdout())  # қате мәтіні де output.txt-ке түседі
sink(type = "message"); sink()
setwd(root)
cat(args[1], ": ", if (inherits(res, "try-error")) "FAILED" else "OK",
    " (", length(readLines(file.path(dir, "output.txt"), warn = FALSE)), " lines)\n", sep = "")
if (inherits(res, "try-error")) quit(status = 1)
