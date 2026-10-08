# Зертханалық сабақ №7
# ggplot2 көмегімен үлкен деректерді визуализациялау.
# Деректер: nycflights13 (flights, weather, airlines).

library(dplyr)
library(ggplot2)
library(nycflights13)

dir.create("screenshots", showWarnings = FALSE)
theme_set(theme_minimal(base_size = 12))
save_plot <- function(p, name, w = 8, h = 4.8) {
  ggsave(file.path("screenshots", name), p, width = w, height = h, dpi = 110)
  name
}

# ==== 1-тапсырма. Сызықтық график: күндік рейс саны ====
daily <- flights %>%
  mutate(date = as.Date(time_hour, tz = "America/New_York")) %>%
  count(date)
summary(daily$n)
daily %>% arrange(n) %>% head(3)
p1 <- ggplot(daily, aes(date, n)) +
  geom_line(colour = "#0F6E6B") +
  geom_smooth(method = "loess", span = 0.2, colour = "#C45C26", se = FALSE) +
  labs(title = "2013 жылғы күндік рейстер саны", x = "Күн", y = "Рейстер")
save_plot(p1, "01_line_daily.png")

# ==== 2-тапсырма. Бағандық диаграмма: авиакомпаниялар ====
by_carrier <- flights %>% count(carrier) %>%
  left_join(airlines, by = "carrier") %>% arrange(desc(n))
head(by_carrier, 5)
p2 <- ggplot(by_carrier, aes(reorder(name, n), n)) +
  geom_col(fill = "#0F6E6B") +
  coord_flip() +
  labs(title = "Авиакомпаниялар бойынша рейс саны", x = NULL, y = "Рейстер")
save_plot(p2, "02_bar_carriers.png")

# ==== 3-тапсырма. Гистограмма және тығыздық ====
p3 <- ggplot(flights %>% filter(!is.na(air_time)), aes(air_time, fill = origin)) +
  geom_density(alpha = 0.45) +
  labs(title = "Ұшу уақытының тығыздығы", x = "Ұшу уақыты, мин", y = "Тығыздық", fill = "Әуежай")
save_plot(p3, "03_density.png")

# ==== 4-тапсырма. Үлкен деректердегі шашырау: hex-bin ====
p4 <- ggplot(flights %>% filter(!is.na(arr_delay), dep_delay < 300, arr_delay < 300),
             aes(dep_delay, arr_delay)) +
  geom_hex(bins = 60) +
  scale_fill_viridis_c(trans = "log10") +
  labs(title = "Ұшу және келу кешігуі (327 мың нүкте)", x = "Ұшу кешігуі, мин",
       y = "Келу кешігуі, мин", fill = "Рейс")
save_plot(p4, "04_hexbin.png")

# ==== 5-тапсырма. Boxplot: айлар бойынша ====
p5 <- ggplot(flights %>% filter(!is.na(dep_delay), dep_delay < 120),
             aes(factor(month), dep_delay)) +
  geom_boxplot(fill = "#E9D8C4", outlier.shape = NA) +
  stat_summary(fun = mean, geom = "point", colour = "#C45C26", size = 2) +
  labs(title = "Айлар бойынша ұшу кешігуі", x = "Ай", y = "Кешігу, мин")
save_plot(p5, "05_boxplot_month.png")

# ==== 6-тапсырма. Жылу картасы: апта күні × сағат ====
heat <- flights %>%
  filter(!is.na(dep_delay)) %>%
  mutate(wday = factor(format(time_hour, "%u"), labels = c("Дс", "Сс", "Ср", "Бс", "Жм", "Сб", "Жс"))) %>%
  group_by(wday, hour) %>%
  summarise(delay = mean(dep_delay), .groups = "drop")
p6 <- ggplot(heat, aes(hour, wday, fill = delay)) +
  geom_tile() +
  scale_fill_gradient(low = "#F7F4EF", high = "#C45C26") +
  labs(title = "Орташа ұшу кешігуі: апта күні және сағат", x = "Сағат", y = NULL, fill = "мин")
save_plot(p6, "06_heatmap.png")

# ==== 7-тапсырма. Фасеттер: әуежайлар бойынша ауа райы ====
p7 <- ggplot(weather %>% filter(!is.na(temp)), aes(time_hour, (temp - 32) * 5 / 9)) +
  geom_line(alpha = 0.4, colour = "#0F6E6B") +
  facet_wrap(~origin, ncol = 1) +
  labs(title = "Әуежайлардағы температура, °C", x = NULL, y = "°C")
save_plot(p7, "07_facets_weather.png", h = 6)

# ==== 8-тапсырма. Құрама график: кешігу үлесі және рейс саны ====
monthly <- flights %>% filter(!is.na(arr_delay)) %>%
  group_by(month) %>%
  summarise(n = n(), late = mean(arr_delay > 15), .groups = "drop")
monthly
p8 <- ggplot(monthly, aes(month)) +
  geom_col(aes(y = n), fill = "#D9E6E5") +
  geom_line(aes(y = late * 100000), colour = "#C45C26", linewidth = 1.2) +
  geom_point(aes(y = late * 100000), colour = "#C45C26", size = 2.5) +
  scale_x_continuous(breaks = 1:12) +
  scale_y_continuous(name = "Рейс саны", sec.axis = sec_axis(~ . / 1000, name = "Кешіккен рейс, %")) +
  labs(title = "Ай сайынғы рейстер және кешігу үлесі", x = "Ай")
save_plot(p8, "08_combo.png")
list.files("screenshots")
