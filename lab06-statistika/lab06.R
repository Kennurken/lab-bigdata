# Зертханалық сабақ №6
# Үлкен деректерді статистикалық талдау.
# Деректер: nycflights13::flights.

library(dplyr)
library(ggplot2)
library(nycflights13)

dir.create("screenshots", showWarnings = FALSE)
fl <- flights %>% filter(!is.na(arr_delay), !is.na(dep_delay))
nrow(fl)

# ==== 1-тапсырма. Сипаттамалық статистика ====
summary(fl$arr_delay)
x <- fl$arr_delay
stats_tbl <- data.frame(
  көрсеткіш = c("орта мән", "медиана", "мода", "стандартты ауытқу", "дисперсия",
                "ең кіші", "ең үлкен", "құлаш", "IQR", "вариация коэф., %"),
  мәні = round(c(mean(x), median(x), as.numeric(names(which.max(table(x)))), sd(x), var(x),
                 min(x), max(x), diff(range(x)), IQR(x), 100 * sd(x) / abs(mean(x))), 2)
)
stats_tbl

# ==== 2-тапсырма. Квантильдер ====
quantile(x, c(0.01, 0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.99))

# ==== 3-тапсырма. Асимметрия және эксцесс ====
skew <- mean((x - mean(x))^3) / sd(x)^3
kurt <- mean((x - mean(x))^4) / sd(x)^4 - 3
round(c(skewness = skew, excess_kurtosis = kurt), 3)

# ==== 4-тапсырма. Топтар бойынша статистика ====
fl %>%
  group_by(origin) %>%
  summarise(n = n(), mean = round(mean(arr_delay), 2), median = median(arr_delay),
            sd = round(sd(arr_delay), 2), q90 = quantile(arr_delay, 0.9), .groups = "drop")

# ==== 5-тапсырма. Жиілік кестесі ====
fl <- fl %>% mutate(delay_class = cut(arr_delay, c(-Inf, 0, 15, 60, 180, Inf),
  labels = c("ертерек/уақытында", "0-15 мин", "15-60 мин", "1-3 сағ", "3 сағ+")))
freq <- table(fl$delay_class)
cbind(саны = freq, үлесі_пайыз = round(100 * prop.table(freq), 2))

# ==== 6-тапсырма. Гипотезаны тексеру: t-тест (JFK vs LGA) ====
jfk <- fl$arr_delay[fl$origin == "JFK"]
lga <- fl$arr_delay[fl$origin == "LGA"]
t.test(jfk, lga)

# ==== 7-тапсырма. Хи-квадрат тесті: әуежай және кешігу ====
tab <- table(fl$origin, fl$arr_delay > 15)
tab
chisq.test(tab)

# ==== 8-тапсырма. Сенімділік аралығы (bootstrap) ====
set.seed(6)
boot_means <- replicate(2000, mean(sample(x, 5000, replace = TRUE)))
round(quantile(boot_means, c(0.025, 0.975)), 3)
round(mean(x) + c(-1, 1) * 1.96 * sd(x) / sqrt(length(x)), 3)

# ==== 9-тапсырма. Үлестірімді визуализациялау ====
p1 <- ggplot(fl %>% filter(arr_delay < 200), aes(arr_delay)) +
  geom_histogram(binwidth = 5, fill = "#0F6E6B", colour = "white") +
  geom_vline(xintercept = mean(x), colour = "#C45C26", linewidth = 1) +
  geom_vline(xintercept = median(x), colour = "#1C2430", linetype = 2, linewidth = 1) +
  labs(title = "Келу кешігуінің үлестірімі",
       subtitle = "Қызыл — орта мән, қара үзік — медиана",
       x = "Кешігу, мин", y = "Рейс саны") +
  theme_minimal()
ggsave("screenshots/01_histogram.png", p1, width = 8, height = 4.5, dpi = 110)

p2 <- ggplot(fl %>% filter(arr_delay < 200), aes(origin, arr_delay, fill = origin)) +
  geom_boxplot(outlier.alpha = 0.05, show.legend = FALSE) +
  labs(title = "Әуежайлар бойынша кешігу", x = "Әуежай", y = "Кешігу, мин") +
  theme_minimal()
ggsave("screenshots/02_boxplot.png", p2, width = 6, height = 4.5, dpi = 110)
