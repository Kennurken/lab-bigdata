# Зертханалық сабақ №1
# R статистикалық ортасының негізгі компоненттері.
# Командалық консоль, объектілер, пакеттер, функциялар, құрылғылар.

dir.create("screenshots", showWarnings = FALSE)

# ==== 1-тапсырма. R ортасы туралы ақпарат ====
R.version.string
Sys.info()[c("sysname", "machine")]
getwd()

# ==== 2-тапсырма. Консольді калькулятор ретінде қолдану ====
25 + 17
144 / 12
2^10
sqrt(625)
17 %% 5
17 %/% 5
log(100, base = 10)
exp(1)
round(pi, 4)

# ==== 3-тапсырма. Объектілер құру және меншіктеу ====
group <- "ИС-00-1"
students_count <- 24
average_grade <- 3.85
is_active <- TRUE
ls()
class(group)
class(students_count)
class(is_active)
students_count * average_grade

# ==== 4-тапсырма. Кірістірілген функциялар ====
grades <- c(78, 85, 92, 67, 88, 95, 73, 81)
length(grades)
sum(grades)
mean(grades)
median(grades)
max(grades)
min(grades)
sd(grades)
sort(grades, decreasing = TRUE)

# ==== 5-тапсырма. Өз функциясын жазу ====
grade_letter <- function(score) {
  if (score >= 90) "A"
  else if (score >= 75) "B"
  else if (score >= 60) "C"
  else "F"
}
sapply(grades, grade_letter)

bmi <- function(weight, height) round(weight / height^2, 1)
bmi(70, 1.75)

# ==== 6-тапсырма. Пакеттермен жұмыс ====
nrow(installed.packages())
library(stats)
search()
packageVersion("ggplot2")
library(ggplot2)
"ggplot2" %in% loadedNamespaces()

# ==== 7-тапсырма. Анықтама жүйесі ====
args(mean)
args(round)
names(formals(sd))
help.search("median", package = "stats")$matches[, c("Topic", "Title")]

# ==== 8-тапсырма. Графикалық құрылғылар ====
png("screenshots/01_base_plot.png", width = 900, height = 550, res = 120)
barplot(grades,
        names.arg = paste0("С", seq_along(grades)),
        col = "#0F6E6B",
        main = "Студенттердің бағалары",
        xlab = "Студент", ylab = "Балл")
abline(h = mean(grades), col = "#C45C26", lwd = 2, lty = 2)
dev.off()
dev.list()

# ==== 9-тапсырма. Жұмыс кеңістігін басқару ====
save(grades, group, file = "workspace.RData")
rm(grades)
exists("grades")
load("workspace.RData")
exists("grades")
ls()
