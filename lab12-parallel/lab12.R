# Зертханалық сабақ №12
# R тілінде үлкен деректерді параллель өңдеу.
# Пакеттер: parallel, future, future.apply, data.table.

library(parallel)
library(future)
library(future.apply)
library(data.table)
library(ggplot2)
library(nycflights13)

# mclapply (fork) Windows-та көп ядромен жұмыс істемейді — онда тізбектей орындалады.
mc_lapply <- function(X, FUN, mc.cores) {
  if (.Platform$OS.type == "windows") lapply(X, FUN) else mclapply(X, FUN, mc.cores = mc.cores)
}

dir.create("screenshots", showWarnings = FALSE)

# ==== 1-тапсырма. Есептеу ресурстарын анықтау ====
detectCores()
detectCores(logical = FALSE)
cores <- max(2, detectCores() - 2)
cores

# ==== 2-тапсырма. Ауыр тапсырма: bootstrap ====
fl <- as.data.table(flights)[!is.na(arr_delay)]
x <- fl$arr_delay
length(x)
boot_once <- function(i) {
  s <- sample(x, length(x), replace = TRUE)
  c(mean = mean(s), median = median(s))
}
B <- 200

# ==== 3-тапсырма. Тізбектей орындау (lapply) ====
set.seed(12)
t_seq <- system.time(r_seq <- lapply(1:B, boot_once))[["elapsed"]]
t_seq

# ==== 4-тапсырма. Fork-параллелизм: mclapply ====
RNGkind("L'Ecuyer-CMRG"); set.seed(12)
t_mc <- system.time(r_mc <- mc_lapply(1:B, boot_once, mc.cores = cores))[["elapsed"]]
t_mc

# ==== 5-тапсырма. Кластер: parLapply ====
cl <- makeCluster(cores)
clusterExport(cl, c("x", "boot_once"))
clusterSetRNGStream(cl, 12)
t_par <- system.time(r_par <- parLapply(cl, 1:B, boot_once))[["elapsed"]]
stopCluster(cl)
t_par

# ==== 6-тапсырма. future.apply ====
plan(multisession, workers = cores)
t_fut <- system.time(r_fut <- future_lapply(1:B, boot_once, future.seed = 12))[["elapsed"]]
plan(sequential)
t_fut

# ==== 7-тапсырма. Нәтижелерді салыстыру ====
res <- rbindlist(lapply(list(seq = r_seq, mc = r_mc, par = r_par, fut = r_fut), function(r) {
  m <- do.call(rbind, r)
  data.table(mean = mean(m[, "mean"]), ci_low = quantile(m[, "mean"], 0.025),
             ci_high = quantile(m[, "mean"], 0.975))
}), idcol = "method")
res[, (2:4) := lapply(.SD, round, 3), .SDcols = 2:4]
res

speed <- data.table(method = c("lapply (1 ядро)", "mclapply", "parLapply", "future_lapply"),
                    seconds = c(t_seq, t_mc, t_par, t_fut))
speed[, speedup := round(t_seq / seconds, 2)]
speed

# ==== 8-тапсырма. Деректерді бөліп параллель агрегаттау (split-apply-combine) ====
chunks <- split(fl, fl$month)
length(chunks)
agg_chunk <- function(d) d[, .(n = .N, delay = sum(arr_delay)), by = carrier]
t_chunk_seq <- system.time(a1 <- rbindlist(lapply(chunks, agg_chunk)))[["elapsed"]]
t_chunk_par <- system.time(a2 <- rbindlist(mc_lapply(chunks, agg_chunk, mc.cores = cores)))[["elapsed"]]
final <- a2[, .(n = sum(n), mean_delay = round(sum(delay) / sum(n), 2)), by = carrier][order(-n)]
head(final)
c(sequential = t_chunk_seq, parallel = t_chunk_par)

# ==== 9-тапсырма. Ядро санына тәуелділік ====
scal <- rbindlist(lapply(c(1, 2, 4, cores), function(k) {
  set.seed(12)
  data.table(cores = k, seconds = system.time(mc_lapply(1:B, boot_once, mc.cores = k))[["elapsed"]])
}))
scal[, speedup := round(scal$seconds[1] / seconds, 2)]
scal
p <- ggplot(scal, aes(cores, speedup)) +
  geom_line(colour = "#0F6E6B", linewidth = 1.2) + geom_point(size = 3, colour = "#0F6E6B") +
  geom_abline(slope = 1, intercept = 0, linetype = 2, colour = "#C45C26") +
  labs(title = "Параллель жылдамдату (bootstrap, 200 қайталау)",
       subtitle = "Үзік сызық — идеал сызықтық жылдамдату",
       x = "Ядро саны", y = "Жылдамдату, есе") +
  theme_minimal()
ggsave("screenshots/01_speedup.png", p, width = 7, height = 4.5, dpi = 110)
