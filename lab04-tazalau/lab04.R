# Зертханалық сабақ №4
# Үлкен деректерді тазалау және алдын ала өңдеу.

library(dplyr)
library(tidyr)
library(ggplot2)
library(nycflights13)

dir.create("screenshots", showWarnings = FALSE)
set.seed(4)

# ==== 1-тапсырма. «Лас» деректер жиынын құру ====
n <- 20000
raw <- data.frame(
  id = 1:n,
  city = sample(c("Алматы", "алматы", " Астана", "Астана ", "Шымкент", "ШЫМКЕНТ", "Қызылорда"),
                n, replace = TRUE),
  age = sample(c(18:70, NA, -5, 250), n, replace = TRUE,
               prob = c(rep(1, 53), 3, 0.3, 0.3)),
  income = round(rlnorm(n, 12.5, 0.4)),
  date = sample(c("2026-09-01", "01.09.2026", "2026/09/01", NA), n, replace = TRUE,
                prob = c(0.7, 0.15, 0.1, 0.05))
)
raw$income[sample(n, 400)] <- NA
raw$income[sample(n, 30)] <- raw$income[sample(n, 30)] * 50
raw <- rbind(raw, raw[sample(n, 800), ])
dim(raw)
head(raw, 10)

# ==== 2-тапсырма. Деректер сапасын бағалау ====
colSums(is.na(raw))
sum(duplicated(raw))
table(raw$city)
summary(raw$age)
summary(raw$income)

# ==== 3-тапсырма. Қайталанатын жазбаларды жою ====
clean <- distinct(raw)
nrow(raw) - nrow(clean)

# ==== 4-тапсырма. Мәтіндік мәндерді стандарттау ====
clean <- clean %>%
  mutate(city = trimws(city),
         city = paste0(toupper(substr(city, 1, 1)), tolower(substring(city, 2))))
table(clean$city)

# ==== 5-тапсырма. Қате мәндерді өңдеу ====
sum(clean$age < 0 | clean$age > 100, na.rm = TRUE)
clean <- clean %>% mutate(age = ifelse(age < 0 | age > 100, NA, age))
summary(clean$age)

# ==== 6-тапсырма. Күн форматын біріздендіру ====
parse_date <- function(x) {
  d <- as.Date(x, format = "%Y-%m-%d")
  d[is.na(d)] <- as.Date(x[is.na(d)], format = "%d.%m.%Y")
  d[is.na(d)] <- as.Date(x[is.na(d)], format = "%Y/%m/%d")
  d
}
clean$date <- parse_date(clean$date)
table(format(clean$date), useNA = "ifany")

# ==== 7-тапсырма. Шығарындыларды (outliers) IQR әдісімен анықтау ====
q <- quantile(clean$income, c(0.25, 0.75), na.rm = TRUE)
iqr <- diff(q)
upper <- q[2] + 1.5 * iqr
lower <- q[1] - 1.5 * iqr
c(lower = unname(lower), upper = unname(upper))
outliers <- sum(clean$income > upper | clean$income < lower, na.rm = TRUE)
outliers

p_before <- ggplot(clean, aes(y = income)) +
  geom_boxplot(fill = "#C45C26", alpha = 0.6, na.rm = TRUE) +
  labs(title = "Табыс: тазалауға дейін", y = "Табыс, ₸") +
  theme_minimal()
ggsave("screenshots/01_outliers_before.png", p_before, width = 5, height = 4, dpi = 110)

clean <- clean %>% mutate(income = ifelse(income > upper * 3, NA, pmin(income, upper)))

# ==== 8-тапсырма. Бос мәндерді толтыру ====
clean <- clean %>%
  group_by(city) %>%
  mutate(age = ifelse(is.na(age), round(median(age, na.rm = TRUE)), age),
         income = ifelse(is.na(income), median(income, na.rm = TRUE), income)) %>%
  ungroup() %>%
  filter(!is.na(date))
colSums(is.na(clean))
dim(clean)

p_after <- ggplot(clean, aes(x = city, y = income)) +
  geom_boxplot(fill = "#0F6E6B", alpha = 0.6) +
  labs(title = "Табыс: тазалаудан кейін", x = "Қала", y = "Табыс, ₸") +
  theme_minimal()
ggsave("screenshots/02_outliers_after.png", p_after, width = 7, height = 4, dpi = 110)

# ==== 9-тапсырма. Нақты үлкен деректер: nycflights13::flights ====
dim(flights)
colSums(is.na(flights))[colSums(is.na(flights)) > 0]
flights_clean <- flights %>%
  filter(!is.na(dep_time), !is.na(arr_delay)) %>%
  distinct()
nrow(flights) - nrow(flights_clean)
round(100 * nrow(flights_clean) / nrow(flights), 2)

# ==== 10-тапсырма. Нормализация және стандарттау ====
clean <- clean %>%
  mutate(income_minmax = (income - min(income)) / (max(income) - min(income)),
         income_z = as.numeric(scale(income)))
summary(clean[, c("income", "income_minmax", "income_z")])
