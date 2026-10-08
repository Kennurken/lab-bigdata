# Зертханалық сабақ №10
# R және MongoDB: NoSQL деректерін талдау.
# Сервер: MongoDB 8.0 (localhost:27017), клиент: mongolite.

library(mongolite)
library(dplyr)
library(nycflights13)

url <- "mongodb://127.0.0.1:27017"

# ==== 1-тапсырма. MongoDB-ге қосылу ====
col <- mongo(collection = "flights", db = "bigdata_lab", url = url)
col$drop()
col$count()

# ==== 2-тапсырма. Құжаттарды енгізу (insert) ====
fl <- flights %>%
  left_join(airlines, by = "carrier") %>%
  rename(airline = name) %>%
  as.data.frame()
system.time(col$insert(fl))
col$count()

# ==== 3-тапсырма. Іздеу (find) және проекция ====
col$find('{"origin":"JFK","dest":"LAX"}',
         fields = '{"_id":0,"month":1,"day":1,"carrier":1,"dep_delay":1}',
         limit = 5)
col$find('{"dep_delay":{"$gt":900}}',
         fields = '{"_id":0,"month":1,"day":1,"carrier":1,"origin":1,"dest":1,"dep_delay":1}',
         sort = '{"dep_delay":-1}')

# ==== 4-тапсырма. Санау және бірегей мәндер ====
col$count('{"month":12}')
length(col$distinct("dest"))
sort(col$distinct("origin"))

# ==== 5-тапсырма. Агрегация конвейері ($group) ====
col$aggregate('[
  {"$match": {"arr_delay": {"$ne": null}}},
  {"$group": {"_id": "$airline", "flights": {"$sum": 1},
              "avg_delay": {"$avg": "$arr_delay"},
              "max_delay": {"$max": "$arr_delay"}}},
  {"$sort": {"avg_delay": -1}},
  {"$limit": 8}
]') %>% mutate(avg_delay = round(avg_delay, 2))

# ==== 6-тапсырма. Ай бойынша агрегация және $project ====
col$aggregate('[
  {"$match": {"arr_delay": {"$ne": null}}},
  {"$group": {"_id": "$month", "n": {"$sum": 1},
              "late": {"$sum": {"$cond": [{"$gt": ["$arr_delay", 15]}, 1, 0]}}}},
  {"$project": {"n": 1, "late_pct": {"$round": [{"$multiply": [{"$divide": ["$late", "$n"]}, 100]}, 1]}}},
  {"$sort": {"_id": 1}}
]')

# ==== 7-тапсырма. Индекс және жылдамдық ====
t1 <- system.time(for (i in 1:10) col$count('{"tailnum":"N14228"}'))[["elapsed"]]
col$index(add = '{"tailnum":1}')
t2 <- system.time(for (i in 1:10) col$count('{"tailnum":"N14228"}'))[["elapsed"]]
data.frame(without_index = t1, with_index = t2)
col$index()$name

# ==== 8-тапсырма. Кірістірілген құжаттар (NoSQL ерекшелігі) ====
st <- mongo(collection = "students", db = "bigdata_lab", url = url)
st$drop()
st$insert(c(
  '{"name":"Ерлан","group":"ИС-00-1","courses":[{"title":"Big Data","grade":92},{"title":"Mobile","grade":88}]}',
  '{"name":"Аружан","group":"ИС-00-1","courses":[{"title":"Big Data","grade":95}],"hobby":"шахмат"}',
  '{"name":"Дастан","group":"ИС-00-2","courses":[{"title":"Big Data","grade":74},{"title":"Java","grade":81}]}'
))
st$find('{"courses.title":"Java"}', fields = '{"_id":0,"name":1,"group":1}')
st$aggregate('[{"$unwind":"$courses"},
  {"$group":{"_id":"$courses.title","avg":{"$avg":"$courses.grade"},"n":{"$sum":1}}},
  {"$sort":{"_id":1}}]')

# ==== 9-тапсырма. Жаңарту және жою ====
st$update('{"name":"Дастан"}', '{"$set":{"group":"ИС-00-1"}}')
st$remove('{"hobby":{"$exists":true}}')
st$find(fields = '{"_id":0,"name":1,"group":1}')

# ==== 10-тапсырма. MongoDB нәтижесін R-де талдау ====
jfk <- col$find('{"origin":"JFK","arr_delay":{"$ne":null}}', fields = '{"_id":0,"carrier":1,"arr_delay":1}')
dim(jfk)
jfk %>% group_by(carrier) %>% summarise(n = n(), mean_delay = round(mean(arr_delay), 1)) %>%
  arrange(desc(n)) %>% head(5)
