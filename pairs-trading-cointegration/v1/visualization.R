viz_pair_data <- function(data) {
  library(ggplot2)
  ggplot(data, aes(x = date)) +
    geom_line(aes(y = GOOG, color = "Google (Series A)")) +
    geom_line(aes(y = SPY, color = "SPY (Series B)")) +
    theme_minimal() +
    labs(title = "Cointegrated Price Series",
         y = "Price",
         color = "Series") +
    scale_color_brewer(palette = "Set1")
}

plot_spread_signals <- function(data) {
  library(ggplot2)
  ggplot(data, aes(x = date)) +
    geom_line(aes(y = zscore)) +
    geom_hline(yintercept = c(-1, 1), linetype = "dashed", color = "red") +
    geom_point(data = filter(data, signal != 0),
               aes(y = zscore, color = factor(signal))) +
    theme_minimal() +
    labs(title = "Z-score and Trading Signals",
         y = "Z-score",
         color = "Signal")
}

plot_portfolio_over_time <- function(results) {
  ggplot(results, aes(x = date, y = cumulative_ret)) +
    geom_line() +
    theme_minimal() +
    labs(title = "Cumulative Strategy Returns",
         y = "Return",
         x = "Date") +
    scale_y_continuous(labels = scales::percent)
}