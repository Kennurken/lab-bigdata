# Зертханалық сабақ №8
# Корреляциялық және регрессиялық талдау.
# Деректер: nycflights13 (flights + weather).

library(dplyr)
library(ggplot2)
library(nycflights13)

dir.create("screenshots", showWarnings = FALSE)

# ==== 1-тапсырма. Деректерді біріктіру және дайындау ====
df <- flights %>%
  inner_join(weather, by = c("origin", "time_hour")) %>%
  filter(!is.na(arr_delay), !is.na(dep_delay), !is.na(air_time),
         !is.na(temp), !is.na(wind_speed), !is.na(visib), !is.na(precip)) %>%
  transmute(arr_delay, dep_delay, distance, air_time, hour = hour.x,
            temp_c = (temp - 32) * 5 / 9, wind_speed, visib, precip, origin)
dim(df)

# ==== 2-тапсырма. Корреляциялық матрица ====
num <- df %>% select(-origin)
cm <- round(cor(num), 3)
cm

# ==== 3-тапсырма. Корреляцияның маңыздылығы ====
cor.test(df$dep_delay, df$arr_delay)
cor.test(df$visib, df$dep_delay)
cor(df$dep_delay, df$arr_delay, method = "spearman")

# ==== 4-тапсырма. Корреляциялық матрицаны визуализациялау ====
cm_long <- as.data.frame(as.table(cm))
p1 <- ggplot(cm_long, aes(Var1, Var2, fill = Freq)) +
  geom_tile(colour = "white") +
  geom_text(aes(label = sprintf("%.2f", Freq)), size = 3) +
  scale_fill_gradient2(low = "#2B6CB0", mid = "white", high = "#C45C26", limits = c(-1, 1)) +
  labs(title = "Корреляциялық матрица", x = NULL, y = NULL, fill = "r") +
  theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave("screenshots/01_cor_matrix.png", p1, width = 7, height = 6, dpi = 110)

# ==== 5-тапсырма. Жұптық сызықтық регрессия ====
m1 <- lm(arr_delay ~ dep_delay, data = df)
summary(m1)

# ==== 6-тапсырма. Көптік регрессия ====
m2 <- lm(arr_delay ~ dep_delay + distance + hour + temp_c + wind_speed + visib + precip + origin,
         data = df)
summary(m2)

# ==== 7-тапсырма. Модельдерді салыстыру ====
data.frame(
  model = c("m1: dep_delay", "m2: көптік"),
  R2 = round(c(summary(m1)$r.squared, summary(m2)$r.squared), 4),
  adj_R2 = round(c(summary(m1)$adj.r.squared, summary(m2)$adj.r.squared), 4),
  RMSE = round(c(sqrt(mean(resid(m1)^2)), sqrt(mean(resid(m2)^2))), 2),
  AIC = round(c(AIC(m1), AIC(m2)))
)
anova(m1, m2)

# ==== 8-тапсырма. Болжам ====
new_flights <- data.frame(dep_delay = c(0, 30, 90), distance = 1000, hour = 17,
                          temp_c = 15, wind_speed = 10, visib = 10, precip = 0, origin = "JFK")
cbind(new_flights[, c("dep_delay", "origin")],
      round(predict(m2, new_flights, interval = "prediction"), 1))

# ==== 9-тапсырма. Регрессия графигі және қалдықтар ====
set.seed(8)
smp <- df[sample(nrow(df), 8000), ]
p2 <- ggplot(smp, aes(dep_delay, arr_delay)) +
  geom_point(alpha = 0.15, colour = "#0F6E6B") +
  geom_smooth(method = "lm", colour = "#C45C26") +
  labs(title = sprintf("arr_delay = %.2f + %.3f·dep_delay", coef(m1)[1], coef(m1)[2]),
       x = "Ұшу кешігуі, мин", y = "Келу кешігуі, мин") +
  theme_minimal()
ggsave("screenshots/02_regression.png", p2, width = 7, height = 4.8, dpi = 110)

res <- data.frame(fitted = fitted(m2), resid = resid(m2))[sample(nrow(df), 8000), ]
p3 <- ggplot(res, aes(fitted, resid)) +
  geom_point(alpha = 0.15) +
  geom_hline(yintercept = 0, colour = "#C45C26") +
  labs(title = "Көптік модельдің қалдықтары", x = "Болжам", y = "Қалдық") +
  theme_minimal()
ggsave("screenshots/03_residuals.png", p3, width = 7, height = 4.8, dpi = 110)
