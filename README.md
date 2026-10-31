# Why deliveries are late, and what to promise instead

A statistical root-cause analysis of late deliveries in R, rendered as an R Markdown report and rebuilt by GitHub Actions on every push.

**Report:** https://nags-gk.github.io/delivery-gap-r/

## Findings

- 57.3% of 172,765 delivered order lines arrived late. **Shipping mode decides it** (Cramér's V 0.48). Market, customer segment, department, weekday and payment type each have V below 0.01 and none is significant at 5%.
- A logistic regression adding six business factors to shipping mode moves holdout AUC from 0.651 to 0.652 (likelihood-ratio p = 0.98). Nothing beyond mode predicts lateness.
- A weekly p-chart by **order line** flags 10 of 162 weeks as out of control. Lines within an order share one outcome, so they are not independent. Charted by **order**, 1 of 162 weeks is out of control, about what chance produces. The process is stable.
- Actual shipping days are close to uniform within each mode (within about 2 percentage points), which suggests simulated delivery times.
- Recommendation: Second Class promises 2 days but behaves like Standard Class (2 to 6 days); a 6-day promise would reach 95% on time. First Class needs a 2-day promise or a faster carrier.

Treat these as a demonstration of method on a public, likely synthetic dataset, not as claims about a real supply chain.

## Methods

Chi-square tests of independence with Cramér's V, logistic regression (base `glm`) with a 70/30 holdout and AUC, likelihood-ratio test, Shewhart p-chart with variable subgroup sizes, chi-square goodness-of-fit, and empirical quantiles for promise setting. Helpers live in `R/analysis.R` and are covered by testthat tests.

## Run it

```r
install.packages(c("data.table", "ggplot2", "scales", "knitr", "rmarkdown", "testthat"))
testthat::test_dir("tests/testthat")
source("scripts/fetch_data.R")
rmarkdown::render("report.Rmd", output_file = "index.html", output_dir = "_site")
```

## Data

DataCo Smart Supply Chain for Big Data Analysis. Constante, F., Silva, F., Pereira, A. (2019), Mendeley Data, CC BY 4.0. Downloaded from a pinned GitHub mirror and size-checked; not stored in this repository. Customer personal fields are dropped on load.
