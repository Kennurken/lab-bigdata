# Зертханалық сабақ №11
# data.table көмегімен үлкен деректерді өңдеу.
# Деректер: 2 млн жолдық сатылым журналы (генерацияланған) + nycflights13.

library(data.table)
library(dplyr)
library(nycflights13)

dir.create("data", showWarnings = FALSE)
setDTthreads(0)
getDTthreads()

# ==== 1-тапсырма. 2 млн жолдық деректер жиынын құру және сақтау ====
set.seed(11)
n <- 2e6
dt <- data.table(
  id = 1:n,
  date = as.IDate("2026-01-01") + sample(0:272, n, replace = TRUE),
  city = sample(c("Алматы", "Астана", "Шымкент", "Қызылорда", "Ақтөбе", "Қарағанды"), n, TRUE),
  product = sample(c("Ноутбук", "Телефон", "Планшет", "Құлаққап", "Монитор"), n, TRUE),
  qty = sample(1:8, n, TRUE),
  price = round(runif(n, 5000, 400000), -2)
)
dt[, revenue := qty * price]
t_write <- system.time(fwrite(dt, "data/sales_2m.csv"))[["elapsed"]]
round(file.size("data/sales_2m.csv") / 1024^2, 1)
t_write

# ==== 2-тапсырма. fread() және read.csv() жылдамдығы ====
t_fread <- system.time(d1 <- fread("data/sales_2m.csv"))[["elapsed"]]
t_base <- system.time(d2 <- read.csv("data/sales_2m.csv"))[["elapsed"]]
data.frame(fread = t_fread, read.csv = t_base, speedup = round(t_base / t_fread, 1))
dim(d1)
rm(d2); invisible(gc())

# ==== 3-тапсырма. DT[i, j, by] синтаксисі: сүзу (i) ====
d1[city == "Қызылорда" & product == "Ноутбук"][1:5]
d1[revenue > 3e6, .N]

# ==== 4-тапсырма. Есептеу (j) және топтау (by) ====
d1[, .(total = sum(revenue), mean_check = round(mean(revenue)), orders = .N), by = city][order(-total)]
d1[, .(revenue_mln = round(sum(revenue) / 1e6, 1)), by = .(month = month(date), product)][order(month, -revenue_mln)][1:10]

# ==== 5-тапсырма. Сілтеме арқылы өзгерту (:=) ====
d1[, discount := fifelse(qty >= 5, 0.1, 0)]
d1[, net := revenue * (1 - discount)]
d1[, .(gross = sum(revenue), net = sum(net)), by = discount]

# ==== 6-тапсырма. Кілттер (setkey) және бинарлық іздеу ====
t_scan <- system.time(for (i in 1:20) d1[city == "Ақтөбе" & product == "Монитор", .N])[["elapsed"]]
setkey(d1, city, product)
t_key <- system.time(for (i in 1:20) d1[.("Ақтөбе", "Монитор"), .N])[["elapsed"]]
data.frame(vector_scan = t_scan, binary_search = t_key)
key(d1)

# ==== 7-тапсырма. Біріктіру (join) ====
regions <- data.table(city = c("Алматы", "Астана", "Шымкент", "Қызылорда", "Ақтөбе", "Қарағанды"),
                      region = c("Оңтүстік", "Орталық", "Оңтүстік", "Оңтүстік", "Батыс", "Орталық"))
setkey(regions, city)
regions[d1, on = "city"][, .(revenue_bln = round(sum(revenue) / 1e9, 2)), by = region]

# ==== 8-тапсырма. data.table, dplyr және base R жылдамдығын салыстыру ====
df <- as.data.frame(d1)
bench <- data.frame(
  method = c("data.table", "dplyr", "base aggregate"),
  seconds = c(
    system.time(d1[, .(s = sum(revenue)), by = .(city, product)])[["elapsed"]],
    system.time(df %>% group_by(city, product) %>% summarise(s = sum(revenue), .groups = "drop"))[["elapsed"]],
    system.time(aggregate(revenue ~ city + product, data = df, FUN = sum))[["elapsed"]]
  )
)
bench

# ==== 9-тапсырма. Ұзын/кең формат (dcast / melt) ====
wide <- dcast(d1, city ~ product, value.var = "revenue", fun.aggregate = function(x) round(sum(x) / 1e9, 2))
wide
melt(wide, id.vars = "city", variable.name = "product", value.name = "revenue_bln")[1:6]

# ==== 10-тапсырма. Нақты деректер: flights ====
fl <- as.data.table(flights)
fl[!is.na(arr_delay), .(n = .N, delay = round(mean(arr_delay), 1)), keyby = .(origin, carrier)][n > 5000]

file.remove("data/sales_2m.csv")
