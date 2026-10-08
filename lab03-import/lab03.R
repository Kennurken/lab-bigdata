# Зертханалық сабақ №3
# Деректерді CSV, Excel және JSON файлдарынан импорттау.

library(readr)
library(readxl)
library(writexl)
library(jsonlite)

dir.create("data", showWarnings = FALSE)
set.seed(3)

# ==== 1-тапсырма. Бастапқы деректер жиынын дайындау ====
n <- 5000
sales <- data.frame(
  order_id = 1:n,
  date = format(as.Date("2026-01-01") + sample(0:269, n, replace = TRUE)),
  city = sample(c("Қызылорда", "Алматы", "Астана", "Шымкент", "Ақтөбе"), n, replace = TRUE),
  product = sample(c("Ноутбук", "Телефон", "Планшет", "Құлаққап"), n, replace = TRUE),
  qty = sample(1:10, n, replace = TRUE),
  price = sample(c(350000, 180000, 120000, 25000), n, replace = TRUE)
)
sales$revenue <- sales$qty * sales$price
head(sales)

# ==== 2-тапсырма. Файлдарға экспорттау ====
write.csv(sales, "data/sales.csv", row.names = FALSE, fileEncoding = "UTF-8")
write_xlsx(sales, "data/sales.xlsx")
write_json(sales, "data/sales.json", pretty = TRUE)
file.info(list.files("data", full.names = TRUE))[, "size", drop = FALSE]

# ==== 3-тапсырма. CSV импорттау (base R және readr) ====
csv_base <- read.csv("data/sales.csv", encoding = "UTF-8")
dim(csv_base)
str(csv_base)

csv_readr <- read_csv("data/sales.csv", show_col_types = FALSE)
csv_readr
spec(csv_readr)

# ==== 4-тапсырма. Excel импорттау ====
excel_sheets("data/sales.xlsx")
xl <- read_excel("data/sales.xlsx", sheet = 1)
dim(xl)
head(xl, 5)
read_excel("data/sales.xlsx", range = "A1:D6")

# ==== 5-тапсырма. JSON импорттау ====
js <- fromJSON("data/sales.json")
dim(js)
head(js, 5)
student_json <- '{"name":"Ерлан","group":"ИС-00-1","courses":["Big Data","Mobile"],"gpa":3.6}'
fromJSON(student_json)

# ==== 6-тапсырма. Импорт нәтижелерін салыстыру ====
timing <- data.frame(
  format = c("CSV (read.csv)", "CSV (readr)", "Excel (readxl)", "JSON (jsonlite)"),
  seconds = c(
    system.time(read.csv("data/sales.csv"))[["elapsed"]],
    system.time(read_csv("data/sales.csv", show_col_types = FALSE))[["elapsed"]],
    system.time(read_excel("data/sales.xlsx"))[["elapsed"]],
    system.time(fromJSON("data/sales.json"))[["elapsed"]]
  ),
  rows = c(nrow(csv_base), nrow(csv_readr), nrow(xl), nrow(js))
)
timing

all.equal(csv_base$revenue, xl$revenue)
all.equal(csv_base$revenue, js$revenue)

# ==== 7-тапсырма. Импортталған деректерді тексеру ====
sum(is.na(csv_base))
table(csv_base$city)
aggregate(revenue ~ product, data = csv_base, FUN = sum)
