# Conformal Predictive Distributions (Vovk et al.)

library(tidyverse)
library(ranger)

plot_intervals <- function(dataset, y, y_hat_tst, lower, upper, inside, max_n = 100, method, color) {
    coverage <- mean(inside)
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

H_n <- function(y, y_hat, R, u) {
    r <- y - y_hat
    (sum(R < r) + u * (1 + sum(R == r))) / (length(R) + 1)
}

cpd_interval <- function(y_hat, R, alpha, u) {
    values <- sort(unique(R))
    counts <- tabulate(match(R, values), nbins = length(values))
    before <- c(0L, head(cumsum(counts), -1L))
    after <- cumsum(counts)
    n <- length(R)
    m <- length(values)

    one_interval <- function(.y_hat, .u) {
        h <- numeric(2 * m + 1)
        h[seq(1, 2 * m + 1, by = 2)] <- (c(0L, after) + .u) / (n + 1)
        h[seq(2, 2 * m, by = 2)] <- (before + .u * (1 + counts)) / (n + 1)

        keep <- alpha / 2 < h & h <= 1 - alpha / 2

        if (!any(keep)) {
            return(c(lower = NA_real_, upper = NA_real_,
                     lower_closed = 0, upper_closed = 0))
        }

        first <- which(keep)[1]
        last <- tail(which(keep), 1)

        if (first %% 2 == 0) {
            k <- first / 2
            lower <- values[k]
            lower_closed <- 1
        } else {
            k <- (first - 1) / 2
            lower <- if (k == 0) -Inf else values[k]
            lower_closed <- 0
        }

        if (last %% 2 == 0) {
            k <- last / 2
            upper <- values[k]
            upper_closed <- 1
        } else {
            k <- (last - 1) / 2
            upper <- if (k == m) Inf else values[k + 1]
            upper_closed <- 0
        }

        c(lower = .y_hat + lower,
          upper = .y_hat + upper,
          lower_closed = lower_closed,
          upper_closed = upper_closed)
    }

    out <- vapply(seq_along(y_hat), function(i) one_interval(y_hat[i], u[i]), numeric(4))

    tibble(u = u,
           lower = as.numeric(out["lower", ]),
           upper = as.numeric(out["upper", ]),
           lower_closed = as.logical(out["lower_closed", ]),
           upper_closed = as.logical(out["upper_closed", ]))
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

rf <- ranger(y ~ ., data = trn)

y_hat_cal <- predict(rf, data = cal)$predictions
y_hat_tst <- predict(rf, data = tst)$predictions

R <- cal$y - y_hat_cal

U <- runif(nrow(tst))

intervals <- cpd_interval(y_hat_tst, R, alpha, U)

lower <- intervals$lower
upper <- intervals$upper

H_tst <- mapply(H_n, y = tst$y, y_hat = y_hat_tst, u = U, MoreArgs = list(R = R))
inside <- alpha / 2 < H_tst & H_tst <= 1 - alpha / 2

plot_intervals(dataset, tst$y, y_hat_tst, lower, upper, inside, method = "CPD", color = "dark orange")

print(dataset)
mean(inside)
mean(upper - lower)
