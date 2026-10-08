# Зертханалық сабақ №9
# R және SQL: деректер қорымен жұмыс.
# ДҚ: SQLite (DBI + RSQLite), деректер: nycflights13.

library(DBI)
library(RSQLite)
library(dplyr)
library(nycflights13)

# ==== 1-тапсырма. Деректер қорына қосылу ====
if (file.exists("flights.sqlite")) file.remove("flights.sqlite")
con <- dbConnect(SQLite(), "flights.sqlite")
con

# ==== 2-тапсырма. Кестелерді жүктеу ====
fl <- flights %>% mutate(time_hour = format(time_hour, "%Y-%m-%d %H:%M:%S"))
dbWriteTable(con, "flights", as.data.frame(fl))
dbWriteTable(con, "airlines", as.data.frame(airlines))
dbWriteTable(con, "airports", as.data.frame(airports))
dbListTables(con)
dbListFields(con, "flights")
file.size("flights.sqlite") / 1024^2

# ==== 3-тапсырма. SELECT және WHERE ====
dbGetQuery(con, "SELECT COUNT(*) AS n FROM flights")
dbGetQuery(con, "
  SELECT month, day, carrier, flight, origin, dest, dep_delay
  FROM flights
  WHERE dep_delay > 600
  ORDER BY dep_delay DESC
  LIMIT 5")

# ==== 4-тапсырма. GROUP BY және агрегаттау ====
dbGetQuery(con, "
  SELECT origin,
         COUNT(*) AS flights,
         ROUND(AVG(dep_delay), 2) AS avg_dep_delay,
         ROUND(100.0 * SUM(arr_delay > 15) / COUNT(arr_delay), 1) AS late_pct
  FROM flights
  GROUP BY origin
  ORDER BY avg_dep_delay DESC")

# ==== 5-тапсырма. JOIN ====
dbGetQuery(con, "
  SELECT a.name AS airline, COUNT(*) AS flights, ROUND(AVG(f.arr_delay), 2) AS avg_arr_delay
  FROM flights f JOIN airlines a ON f.carrier = a.carrier
  GROUP BY a.name
  HAVING COUNT(*) > 10000
  ORDER BY avg_arr_delay")

dbGetQuery(con, "
  SELECT f.dest, p.name, COUNT(*) AS n
  FROM flights f LEFT JOIN airports p ON f.dest = p.faa
  GROUP BY f.dest ORDER BY n DESC LIMIT 5")

# ==== 6-тапсырма. Параметрлі сұраныс ====
dbGetQuery(con, "SELECT COUNT(*) AS n, ROUND(AVG(arr_delay),2) AS avg_delay
                 FROM flights WHERE carrier = ? AND month = ?",
           params = list("UA", 7))

# ==== 7-тапсырма. Индекс және жылдамдық ====
q <- "SELECT COUNT(*) FROM flights WHERE dest = 'LAX'"
t_before <- system.time(for (i in 1:20) dbGetQuery(con, q))[["elapsed"]]
dbExecute(con, "CREATE INDEX idx_dest ON flights(dest)")
t_after <- system.time(for (i in 1:20) dbGetQuery(con, q))[["elapsed"]]
data.frame(without_index = t_before, with_index = t_after)
dbGetQuery(con, paste("EXPLAIN QUERY PLAN", q))

# ==== 8-тапсырма. Көрініс (VIEW) және жаңарту ====
dbExecute(con, "CREATE VIEW monthly AS
  SELECT month, COUNT(*) AS n, ROUND(AVG(arr_delay),2) AS delay FROM flights GROUP BY month")
dbGetQuery(con, "SELECT * FROM monthly")
dbExecute(con, "CREATE TABLE notes(id INTEGER PRIMARY KEY, text TEXT)")
dbExecute(con, "INSERT INTO notes(text) VALUES ('ИС-00-1'), ('Big Data')")
dbExecute(con, "UPDATE notes SET text = 'Үлкен деректер' WHERE id = 2")
dbGetQuery(con, "SELECT * FROM notes")

# ==== 9-тапсырма. SQL және dplyr нәтижесін салыстыру ====
sql_res <- dbGetQuery(con, "SELECT carrier, COUNT(*) AS n FROM flights GROUP BY carrier ORDER BY carrier")
dplyr_res <- flights %>% count(carrier) %>% arrange(carrier) %>% as.data.frame()
all.equal(sql_res$n, dplyr_res$n)

dbDisconnect(con)
