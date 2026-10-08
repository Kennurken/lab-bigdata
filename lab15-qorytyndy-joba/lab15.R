# Зертханалық сабақ №15
# Қорытынды жоба: RStudio ортасында Big Data толық циклдік талдауы.
# Зерттеу сұрағы: Нью-Йорк әуежайларында рейстердің кешігуіне не әсер етеді
# және қай рейстер кешігу қаупінде?
# Цикл: жинау → сақтау → тазалау → түрлендіру → талдау → визуализация → модель → шешім.

library(data.table)
library(dplyr)
library(ggplot2)
library(DBI)
library(RSQLite)
library(rpart)
library(nycflights13)

dir.create("screenshots", showWarnings = FALSE)
dir.create("data", showWarnings = FALSE)
set.seed(15)
theme_set(theme_minimal(base_size = 12))

# ==== 1-кезең. Деректерді жинау ====
sources <- list(flights = flights, weather = weather, airlines = airlines,
                airports = airports, planes = planes)
data.frame(кесте = names(sources),
           жол = sapply(sources, nrow),
           баған = sapply(sources, ncol),
           МБ = round(sapply(sources, function(x) as.numeric(object.size(x)) / 1024^2), 1))

# ==== 2-кезең. Сақтау: CSV және SQLite ====
fwrite(flights, "data/flights.csv")
con <- dbConnect(SQLite(), "data/project.sqlite")
for (nm in names(sources)) {
  d <- as.data.frame(sources[[nm]])
  if ("time_hour" %in% names(d)) d$time_hour <- format(d$time_hour, "%Y-%m-%d %H:%M:%S")
  dbWriteTable(con, nm, d, overwrite = TRUE)
}
dbListTables(con)
dbGetQuery(con, "SELECT COUNT(*) AS flights FROM flights")

# ==== 3-кезең. Сапаны тексеру және тазалау ====
fl <- fread("data/flights.csv")
na_share <- round(100 * colMeans(is.na(fl)), 2)
na_share[na_share > 0]
sum(duplicated(fl))
cancelled <- fl[is.na(dep_time), .N]
cancelled
fl <- fl[!is.na(dep_time) & !is.na(arr_delay)]
fl <- fl[arr_delay < quantile(arr_delay, 0.999)]
nrow(fl)

# ==== 4-кезең. Түрлендіру және байыту ====
wx <- as.data.table(weather)[, .(origin, time_hour = as.POSIXct(time_hour), temp_c = (temp - 32) * 5 / 9,
                                 wind_speed, visib, precip)]
fl[, time_hour := as.POSIXct(time_hour, tz = "America/New_York")]
wx[, time_hour := as.POSIXct(format(time_hour, tz = "America/New_York"), tz = "America/New_York")]
fl <- merge(fl, wx, by = c("origin", "time_hour"), all.x = TRUE)
fl <- merge(fl, as.data.table(airlines), by = "carrier", all.x = TRUE)
fl[, `:=`(late = arr_delay > 15,
          season = fcase(month %in% c(12, 1, 2), "Қыс", month %in% 3:5, "Көктем",
                         month %in% 6:8, "Жаз", default = "Күз"),
          part_of_day = fcase(hour < 12, "Таң", hour < 17, "Күндіз", default = "Кеш"),
          bad_weather = visib < 3 | precip > 0.05)]
dim(fl)
fl[, .N, by = season]

# ==== 5-кезең. Сипаттамалық талдау және KPI ====
kpi <- fl[, .(рейстер = .N,
              кешіккен_пайыз = round(100 * mean(late), 1),
              орта_кешігу_мин = round(mean(arr_delay), 1),
              медиана_мин = median(arr_delay))]
kpi
cancelled_pct <- round(100 * cancelled / nrow(flights), 2)
cancelled_pct
by_airline <- fl[, .(n = .N, late_pct = round(100 * mean(late), 1), delay = round(mean(arr_delay), 1)),
                 by = name][n > 5000][order(-late_pct)]
by_airline
by_part <- fl[, .(late_pct = round(100 * mean(late), 1)), by = part_of_day][order(late_pct)]
by_part
fl[!is.na(bad_weather), .(n = .N, late_pct = round(100 * mean(late), 1)), by = bad_weather]

# ==== 6-кезең. Гипотезаларды тексеру ====
chisq.test(table(fl$part_of_day, fl$late))
t.test(arr_delay ~ bad_weather, data = fl[!is.na(bad_weather)])
round(cor(fl$dep_delay, fl$arr_delay), 3)

# ==== 7-кезең. Визуализация ====
monthly <- fl[, .(late_pct = 100 * mean(late), n = .N), by = month][order(month)]
p1 <- ggplot(monthly, aes(month, late_pct)) +
  geom_line(colour = "#0F6E6B", linewidth = 1.2) + geom_point(size = 3, colour = "#0F6E6B") +
  scale_x_continuous(breaks = 1:12) +
  labs(title = "Ай бойынша кешіккен рейстер үлесі", x = "Ай", y = "Кешіккен рейс, %")
ggsave("screenshots/01_monthly.png", p1, width = 7, height = 4.2, dpi = 110)

hourly <- fl[, .(late_pct = 100 * mean(late)), by = .(hour, origin)]
p2 <- ggplot(hourly[hour >= 5], aes(hour, late_pct, colour = origin)) +
  geom_line(linewidth = 1.1) +
  labs(title = "Ұшу сағаты бойынша кешігу қаупі", x = "Сағат", y = "Кешіккен рейс, %", colour = "Әуежай")
ggsave("screenshots/02_hourly.png", p2, width = 7, height = 4.2, dpi = 110)

p3 <- ggplot(by_airline, aes(reorder(name, late_pct), late_pct)) +
  geom_col(fill = "#C45C26") + coord_flip() +
  labs(title = "Авиакомпаниялар: кешіккен рейс үлесі", x = NULL, y = "%")
ggsave("screenshots/03_airlines.png", p3, width = 7, height = 4.5, dpi = 110)

# ==== 8-кезең. Болжам моделі ====
md <- fl[!is.na(visib) & !is.na(wind_speed) & !is.na(precip),
         .(late = factor(late, labels = c("уақытында", "кешікті")), hour, month, distance,
           visib, wind_speed, precip, temp_c, origin = factor(origin), carrier = factor(carrier))]
idx <- sample(nrow(md), 0.8 * nrow(md))
tree <- rpart(late ~ ., data = md[idx], method = "class",
              control = rpart.control(cp = 0.0005, maxdepth = 6))
pred <- predict(tree, md[-idx], type = "prob")[, "кешікті"]
truth <- md[-idx]$late == "кешікті"
auc <- function(score, y) {
  r <- rank(score); n1 <- sum(y); n0 <- sum(!y)
  (sum(r[y]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}
round(auc(pred, truth), 3)
risk <- data.table(score = pred, late = truth)[, decile := ntile(score, 10)]
lift <- risk[, .(late_pct = round(100 * mean(late), 1), n = .N), by = decile][order(decile)]
lift
p4 <- ggplot(lift, aes(factor(decile), late_pct)) +
  geom_col(fill = "#0F6E6B") +
  geom_hline(yintercept = 100 * mean(truth), linetype = 2, colour = "#C45C26") +
  labs(title = "Модель бойынша қауіп децильдері (тек жоспар деректері)",
       subtitle = "Үзік сызық — орташа кешігу үлесі", x = "Қауіп децилі (1 — ең төмен)", y = "Нақты кешігу, %")
ggsave("screenshots/04_lift.png", p4, width = 7, height = 4.2, dpi = 110)

# ==== 9-кезең. Нәтижелерді сақтау ====
dbWriteTable(con, "kpi_airlines", as.data.frame(by_airline), overwrite = TRUE)
dbGetQuery(con, "SELECT * FROM kpi_airlines ORDER BY late_pct DESC LIMIT 3")
dbDisconnect(con)
file.remove("data/flights.csv")
