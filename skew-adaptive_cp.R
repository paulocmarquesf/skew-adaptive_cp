# Skew-adaptive conformal prediction

# Paulo C. Marques F. <PauloCMF1@insper.edu.br>
#
#   and
#
# Helton Graziadei <helton@ufscar.br>

library(tidyverse)
library(ranger)

plot_intervals <- function(dataset, y, y_hat_tst, lower, upper, max_n = 100, method, color) {
    coverage <- mean(lower <= y & y <= upper)
    avg_width <- mean(upper - lower)
    tibble(id = seq_along(y), y, y_hat_tst, lower, upper) |>
        filter(id <= max_n)  |>
        ggplot(aes(x = id)) +
            geom_errorbar(aes(ymin = lower, ymax = upper), color = color) +
            geom_point(aes(y = y_hat_tst), color = "blue", size = 1) +
            geom_point(aes(y = y), color = "red", size = 1) +
            scale_y_continuous(labels = scales::label_number()) +
            labs(x = "Test sample unit", y = "",
                 title = sprintf("%s (Coverage = %.1f%%. Average width = %s)", method, 100 * coverage,
                                 format(avg_width, digits = 3, big.mark = " ", scientific = FALSE)),
                 caption = paste0("Dataset: ", stringr::str_remove(dataset, "\\.csv$"))) +
            theme_bw()
}

dataset <- "ames.csv"; response <- "Sale_Price"; prop <- c(0.5, 0.25, 0.25)
# dataset <- "bike_sharing.csv"; response <- "bikers"; prop <- c(0.5, 0.25, 0.25)
# dataset <- "california.csv"; response <- "median_house_value"; prop <- c(0.8, 0.1, 0.1)
# dataset <- "concrete.csv"; response <- "concrete_compressive"; prop <- c(0.5, 0.25, 0.25)
# dataset <- "diamonds.csv"; response <- "price"; prop <- c(0.8, 0.1, 0.1)
# dataset <- "energy.csv"; response <- "Usage_kWh"; prop <- c(0.8, 0.1, 0.1)
# dataset <- "used_cars.csv"; response <- "price"; prop <- c(0.5, 0.25, 0.25)

db <- read_csv(paste0("datasets/", dataset), show_col_types = FALSE) |>
    mutate(across(where(is.character), as.factor)) |>   
    rename(y = all_of(response))

set.seed(42)

ind <- sample(1:3, size = nrow(db), prob = prop, replace = TRUE)

trn <- db[ind == 1, ]
cal <- db[ind == 2, ]
tst <- db[ind == 3, ]

alpha <- 0.1

# CQR

qrf <- ranger(y ~ ., data = trn, quantreg = TRUE)

alpha_lo <- alpha / 2
alpha_hi <- 1 - alpha / 2

q_hat_cal <- predict(qrf, data = cal, type = "quantiles", quantiles = c(alpha_lo, 0.5, alpha_hi))$predictions

R <- pmax(q_hat_cal[, 1] - cal$y, cal$y - q_hat_cal[, 3])

r_hat <- sort(R)[ceiling((1 - alpha)*(nrow(cal) + 1))]

q_hat_tst <- predict(qrf, data = tst, type = "quantiles", quantiles = c(alpha_lo, 0.5, alpha_hi))$predictions

y_hat_tst <- q_hat_tst[, 2]

lower <- q_hat_tst[, 1] - r_hat
upper <- q_hat_tst[, 3] + r_hat

plot_intervals(dataset, tst$y, y_hat_tst, lower, upper, method = "CQR", color = "cornflowerblue")

# Scaled-score

rf1 <- ranger(y ~ ., data = trn)

y_hat_trn <- predict(rf1, data = trn)$predictions
y_hat_cal <- predict(rf1, data = cal)$predictions
y_hat_tst <- predict(rf1, data = tst)$predictions

trn2 <- trn |>
    mutate(delta = abs(y - y_hat_trn)) |>
    select(-y)

rf2 <- ranger(delta ~ ., data = trn2)

sigma_hat_trn <- predict(rf2, data = trn)$predictions
sigma_hat_cal <- predict(rf2, data = cal)$predictions
sigma_hat_tst <- predict(rf2, data = tst)$predictions

R <- abs(cal$y - y_hat_cal) / sigma_hat_cal
r_hat_scl <- sort(R)[ceiling((1 - alpha) * (nrow(cal) + 1))]

lower <- pmax(y_hat_tst - r_hat_scl * sigma_hat_tst, 0)
upper <- y_hat_tst + r_hat_scl * sigma_hat_tst

length_tst_scl <- upper - lower

plot_intervals(dataset, tst$y, y_hat_tst, lower, upper, method = "Scaled-score", color = "dark cyan")

# Skew-adaptive

trn3 <- trn |>
    mutate(tau = asinh((y - y_hat_trn) / (2*sigma_hat_trn))) |>
    select(-y)

rf3 <- ranger(tau ~ ., data = trn3)

gamma_hat_cal <- predict(rf3, data = cal)$predictions
gamma_hat_tst <- predict(rf3, data = tst)$predictions

R <- pmax(
    pmax(0,  y_hat_cal - cal$y) / (sigma_hat_cal * exp(-gamma_hat_cal)),
    pmax(0, cal$y - y_hat_cal) / (sigma_hat_cal * exp(gamma_hat_cal)) 
)

r_hat_skew <- sort(R)[ceiling((1 - alpha) * (nrow(cal) + 1))]

lower <- y_hat_tst - r_hat_skew * sigma_hat_tst * exp(-gamma_hat_tst)
upper <- y_hat_tst + r_hat_skew * sigma_hat_tst * exp(gamma_hat_tst)

length_tst_skew <- upper - lower

plot_intervals(dataset, tst$y, y_hat_tst, lower, upper, method = "Skew-adaptive", color = "dark orange")

### Prediction interval efficiency

print(dataset)

# calibration sample estimate \hat\varphi_n
(r_hat_skew / r_hat_scl) * mean(cosh(gamma_hat_cal))

# test sample average
mean(length_tst_skew / length_tst_scl)
