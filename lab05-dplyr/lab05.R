# Зертханалық сабақ №5
# dplyr көмегімен деректерді сүзу, сұрыптау және топтау.
# Деректер: nycflights13::flights (336 776 рейс, Нью-Йорк, 2013).

library(dplyr)
library(nycflights13)

# ==== 1-тапсырма. Деректермен танысу ====
dim(flights)
glimpse(flights)

# ==== 2-тапсырма. select(): бағандарды таңдау ====
flights %>% select(year, month, day, carrier, origin, dest, dep_delay, arr_delay) %>% head()
flights %>% select(starts_with("dep"), ends_with("delay")) %>% head(3)

# ==== 3-тапсырма. filter(): жолдарды сүзу ====
jan_jfk <- flights %>% filter(month == 1, origin == "JFK")
nrow(jan_jfk)
long_delay <- flights %>% filter(arr_delay > 120)
nrow(long_delay)
flights %>% filter(dest %in% c("LAX", "SFO", "SEA"), !is.na(arr_delay)) %>% nrow()

# ==== 4-тапсырма. arrange(): сұрыптау ====
flights %>% arrange(desc(dep_delay)) %>%
  select(month, day, carrier, flight, origin, dest, dep_delay) %>% head(5)
flights %>% arrange(month, day, dep_time) %>% select(month, day, dep_time, carrier) %>% head(3)

# ==== 5-тапсырма. mutate(): жаңа бағандар ====
fl <- flights %>%
  filter(!is.na(air_time), air_time > 0) %>%
  mutate(speed_kmh = round(distance * 1.609 / (air_time / 60)),
         gain = dep_delay - arr_delay,
         late = arr_delay > 15)
fl %>% select(carrier, distance, air_time, speed_kmh, gain, late) %>% head()

# ==== 6-тапсырма. group_by() + summarise(): топтау ====
by_carrier <- fl %>%
  group_by(carrier) %>%
  summarise(flights = n(),
            mean_arr_delay = round(mean(arr_delay, na.rm = TRUE), 1),
            late_share = round(100 * mean(late, na.rm = TRUE), 1),
            .groups = "drop") %>%
  left_join(airlines, by = "carrier") %>%
  arrange(desc(mean_arr_delay))
print(by_carrier, n = 20)

# ==== 7-тапсырма. Әуежай және ай бойынша топтау ====
flights %>%
  group_by(origin, month) %>%
  summarise(n = n(), dep_delay = round(mean(dep_delay, na.rm = TRUE), 1), .groups = "drop") %>%
  arrange(desc(dep_delay)) %>% head(6)

# ==== 8-тапсырма. Ең көп ұшатын бағыттар ====
flights %>% count(origin, dest, sort = TRUE) %>%
  left_join(airports %>% select(faa, name), by = c("dest" = "faa")) %>% head(10)

# ==== 9-тапсырма. Біріктіру (join) және тізбек ====
flights %>%
  filter(!is.na(arr_delay)) %>%
  inner_join(planes %>% select(tailnum, plane_year = year), by = "tailnum") %>%
  mutate(age_group = cut(2013 - plane_year, c(-Inf, 5, 10, 20, Inf),
                         labels = c("0-5 жыл", "6-10 жыл", "11-20 жыл", "20+ жыл"))) %>%
  group_by(age_group) %>%
  summarise(n = n(), mean_delay = round(mean(arr_delay), 2), .groups = "drop")
