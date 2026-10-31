source(file.path("..", "..", "R", "analysis.R"))

test_that("Cramer's V is 1 for perfect association and ~0 for independence", {
  x <- rep(c("a", "b"), each = 500)
  expect_equal(assoc_test(x, x)$cramers_v, 1, tolerance = 1e-9)
  set.seed(1)
  expect_lt(assoc_test(sample(c("a", "b"), 5000, TRUE), sample(c("u", "v"), 5000, TRUE))$cramers_v, 0.05)
})

test_that("uniform_gof accepts uniform data and rejects skewed data", {
  set.seed(2)
  expect_gt(uniform_gof(sample(2:6, 5000, TRUE))$p_value, 0.01)
  expect_lt(uniform_gof(c(rep(2, 4000), 3:6))$p_value, 1e-6)
})

test_that("p_chart limits bracket the centre and flag a shifted week", {
  g <- rep(1:20, each = 200)
  late <- rbinom(length(g), 1, 0.4); late[g == 20] <- 1
  pc <- p_chart(late, g)
  expect_true(all(pc$lcl <= pc$center & pc$center <= pc$ucl))
  expect_true(pc[group == 20, out])
})

test_that("promise_for_target returns the smallest day meeting the target", {
  expect_equal(promise_for_target(c(2, 3, 4, 5, 6), 0.6), 4)
  expect_equal(promise_for_target(rep(2, 10), 0.95), 2)
})

test_that("auc matches known values", {
  expect_equal(auc(c(0, 0, 1, 1), c(0.1, 0.2, 0.8, 0.9)), 1)
  expect_equal(auc(c(0, 1, 0, 1), c(1, 1, 1, 1)), 0.5)
})

test_that("prop_diff CI contains the point estimate", {
  r <- prop_diff(60, 100, 40, 100)
  expect_equal(unname(r["diff"]), 0.2)
  expect_true(r["lo"] < 0.2 && r["hi"] > 0.2)
})
