# Analysis helpers for the delivery SLA gap report. Pure functions, unit-tested in tests/testthat.
suppressPackageStartupMessages({
  library(data.table)
})

#' Read the DataCo CSV, drop personal fields, and derive delivery fields.
#' Shipping-canceled lines have no delivery outcome and are excluded.
load_orders <- function(path) {
  d <- fread(path, encoding = "Latin-1", showProgress = FALSE)
  setnames(d, make.names(names(d)))
  pii <- c("Customer.Email", "Customer.Fname", "Customer.Lname", "Customer.Password", "Customer.Street",
           "Customer.Zipcode", "Product.Description", "Product.Image")
  d[, (intersect(pii, names(d))) := NULL]
  d <- d[Delivery.Status != "Shipping canceled"]
  d[, `:=`(
    mode = factor(Shipping.Mode, levels = c("Same Day", "First Class", "Second Class", "Standard Class")),
    promised = Days.for.shipment..scheduled.,
    actual = Days.for.shipping..real.,
    order_ts = as.POSIXct(order.date..DateOrders., format = "%m/%d/%Y %H:%M", tz = "UTC")
  )]
  d[, `:=`(late = as.integer(actual > promised), delay = actual - promised,
           week = as.Date(cut(as.Date(order_ts), "week")),
           weekday = factor(weekdays(order_ts), levels = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")))]
  d[]
}

#' Chi-square test of independence plus Cramer's V (effect size, 0 = none, 1 = perfect association).
assoc_test <- function(x, y) {
  tab <- table(x, y)
  ct <- suppressWarnings(chisq.test(tab, correct = FALSE))
  k <- min(dim(tab)) - 1
  list(statistic = unname(ct$statistic), df = unname(ct$parameter), p_value = ct$p.value,
       cramers_v = sqrt(unname(ct$statistic) / (sum(tab) * k)), n = sum(tab))
}

#' Chi-square goodness-of-fit of integer values against a discrete uniform over their observed range.
uniform_gof <- function(x) {
  lv <- seq(min(x), max(x))
  obs <- tabulate(factor(x, levels = lv), nbins = length(lv))
  if (length(lv) < 2) return(list(levels = lv, p_value = NA_real_, statistic = NA_real_, max_share_gap = 0))
  ct <- chisq.test(obs, p = rep(1 / length(lv), length(lv)))
  list(levels = lv, statistic = unname(ct$statistic), p_value = ct$p.value,
       max_share_gap = max(abs(obs / sum(obs) - 1 / length(lv))))
}

#' p-chart (Shewhart) for a weekly proportion with variable subgroup sizes.
p_chart <- function(late, group) {
  g <- data.table(late = late, group = group)[, .(x = sum(late), n = .N), by = group][order(group)]
  pbar <- sum(g$x) / sum(g$n)
  g[, `:=`(p = x / n, center = pbar, lcl = pmax(0, pbar - 3 * sqrt(pbar * (1 - pbar) / n)),
           ucl = pmin(1, pbar + 3 * sqrt(pbar * (1 - pbar) / n)))]
  g[, out := p < lcl | p > ucl]
  g[]
}

#' Smallest whole-day promise that meets an on-time target, from the empirical distribution of actual days.
promise_for_target <- function(actual, target = 0.95) {
  d <- sort(unique(actual))
  hit <- vapply(d, function(k) mean(actual <= k), numeric(1))
  d[which(hit >= target)[1]]
}

#' Area under the ROC curve (Mann-Whitney form), no dependencies.
auc <- function(y, score) {
  r <- rank(score)
  n1 <- sum(y == 1); n0 <- sum(y == 0)
  (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}

#' Two-proportion difference with a normal-approximation confidence interval.
prop_diff <- function(x1, n1, x2, n2, conf = 0.95) {
  p1 <- x1 / n1; p2 <- x2 / n2
  se <- sqrt(p1 * (1 - p1) / n1 + p2 * (1 - p2) / n2)
  z <- qnorm(1 - (1 - conf) / 2)
  c(diff = p1 - p2, lo = p1 - p2 - z * se, hi = p1 - p2 + z * se)
}
