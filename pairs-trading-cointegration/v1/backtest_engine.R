calculate_returns <- function(data) {
  data %>%
    na.omit() %>%
    mutate(
      ret_GOOG = GOOG / lag(GOOG) - 1,
      ret_SPY = SPY / lag(SPY) - 1,
      strategy_ret = lag(signal) * (ret_GOOG - hedge_ratio * ret_SPY),  # Strategy P&L
      cumulative_ret = cumprod(1 + replace_na(strategy_ret, 0))  # Cumulative returns
    )
}
