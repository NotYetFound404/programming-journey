library(TTR)
library(dplyr)
library(tidyr)

calculate_spread <- function(data) {
  data %>%
    mutate(
      spread = GOOG - (hedge_ratio * SPY)
    )
}

calculate_zscore <- function(data, window = 20) {
  data %>%
    mutate(
      roll_mean = runMean(spread, n = window),
      roll_sd = runSD(spread, n = window),
      zscore = (spread - roll_mean) / roll_sd
    )
}

generate_signals <- function(data, zscore_threshold = 1) {
  data %>%
    mutate(
      signal = case_when(
        !is_cointegrated ~ 0,
        zscore > zscore_threshold ~ -1,  # Short spread
        zscore < -zscore_threshold ~ 1,  # Long spread
        TRUE ~ 0
      )
    )
}

