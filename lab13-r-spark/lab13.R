# Зертханалық сабақ №13
# R және Apache Spark ортасында үлкен деректерді өңдеу.
# Spark 3.5 (local режим), клиент: sparklyr.

library(sparklyr)
library(dplyr)
library(ggplot2)
library(nycflights13)

dir.create("screenshots", showWarnings = FALSE)
# JAVA_HOME: егер орнатылмаған болса және macOS (Homebrew) жолы бар болса ғана қойылады.
# Windows/Linux-та JAVA_HOME жүйеде JDK 17-ге бағытталуы керек.
java_brew <- "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
if (!nzchar(Sys.getenv("JAVA_HOME")) && dir.exists(java_brew)) Sys.setenv(JAVA_HOME = java_brew)

# ==== 1-тапсырма. Spark-қа қосылу ====
spark_installed_versions()[, c("spark", "hadoop")]
conf <- spark_config()
conf$`sparklyr.shell.driver-memory` <- "4G"
conf$spark.sql.shuffle.partitions <- 8
sc <- spark_connect(master = "local[*]", version = "3.5", config = conf)
spark_version(sc)

# ==== 2-тапсырма. Деректерді Spark-қа жүктеу ====
flights_tbl <- copy_to(sc, flights, "flights", overwrite = TRUE)
airlines_tbl <- copy_to(sc, airlines, "airlines", overwrite = TRUE)
src_tbls(sc)
sdf_nrow(flights_tbl)
sdf_ncol(flights_tbl)
sdf_num_partitions(flights_tbl)

# ==== 3-тапсырма. dplyr етістіктерін Spark-та орындау ====
flights_tbl %>%
  filter(!is.na(arr_delay), dest == "LAX") %>%
  select(month, carrier, dep_delay, arr_delay) %>%
  head(5)

# ==== 4-тапсырма. Ленивті есептеу және SQL аудармасы ====
q <- flights_tbl %>%
  filter(!is.na(arr_delay)) %>%
  group_by(carrier) %>%
  summarise(n = n(), mean_delay = mean(arr_delay, na.rm = TRUE)) %>%
  arrange(desc(mean_delay))
show_query(q)
collect(q) %>% mutate(mean_delay = round(mean_delay, 2)) %>% head(8)

# ==== 5-тапсырма. Біріктіру (join) Spark ішінде ====
flights_tbl %>%
  left_join(airlines_tbl, by = "carrier") %>%
  group_by(name) %>%
  summarise(flights = n(), total_dist_mln = sum(distance, na.rm = TRUE) / 1e6) %>%
  arrange(desc(flights)) %>%
  collect() %>%
  mutate(total_dist_mln = round(total_dist_mln, 1)) %>%
  head(6)

# ==== 6-тапсырма. Spark SQL ====
DBI::dbGetQuery(sc, "
  SELECT origin, month, COUNT(*) AS n, ROUND(AVG(dep_delay), 2) AS dep_delay
  FROM flights WHERE dep_delay IS NOT NULL
  GROUP BY origin, month ORDER BY dep_delay DESC LIMIT 6")

# ==== 7-тапсырма. Spark-та жаңа баған және кэш ====
fl2 <- flights_tbl %>%
  filter(!is.na(arr_delay), !is.na(dep_delay), !is.na(distance)) %>%
  mutate(late = ifelse(arr_delay > 15, 1, 0),
         speed = distance / air_time * 60) %>%
  sdf_register("flights_clean")
tbl_cache(sc, "flights_clean")
sdf_nrow(fl2)
fl2 %>% summarise(late_share = mean(late), avg_speed = mean(speed, na.rm = TRUE)) %>% collect()

# ==== 8-тапсырма. Spark MLlib: сызықтық регрессия ====
parts <- sdf_random_split(fl2, train = 0.8, test = 0.2, seed = 13)
lm_model <- ml_linear_regression(parts$train, arr_delay ~ dep_delay + distance + hour)
lm_model
summary(lm_model)
pred <- ml_predict(lm_model, parts$test)
ml_regression_evaluator(pred, label_col = "arr_delay", metric_name = "rmse")
ml_regression_evaluator(pred, label_col = "arr_delay", metric_name = "r2")

# ==== 9-тапсырма. Spark MLlib: логистикалық регрессия ====
log_model <- ml_logistic_regression(parts$train, late ~ dep_delay + distance + hour + month)
pred2 <- ml_predict(log_model, parts$test)
ml_binary_classification_evaluator(pred2, label_col = "late", metric_name = "areaUnderROC")
pred2 %>% group_by(late, prediction) %>% summarise(n = n()) %>% collect() %>% arrange(late, prediction)

# ==== 10-тапсырма. Нәтижені R-ге алып визуализациялау ====
by_hour <- fl2 %>% group_by(hour) %>%
  summarise(late_share = mean(late), n = n()) %>%
  collect() %>% arrange(hour)
by_hour
p <- ggplot(by_hour, aes(hour, late_share * 100)) +
  geom_col(fill = "#0F6E6B") +
  labs(title = "Spark-та есептелген: сағат бойынша кешіккен рейс үлесі",
       x = "Ұшу сағаты", y = "Кешіккен рейс, %") +
  theme_minimal()
ggsave("screenshots/01_spark_by_hour.png", p, width = 7, height = 4.5, dpi = 110)

spark_disconnect(sc)
