library(lmtest)
library(tseries)
rolling_cointegration_test <- function(data, window_size = 30) {
  n <- nrow(data)
  results <- list()
  
  for (i in 1:(n - window_size + 1)) {
    window_data <- data[i:(i + window_size - 1), ]
    
    # Fit regression
    model <- lm(SPY ~ GOOG, data = window_data)
    residuals <- residuals(model)
    
    # Perform statistical tests
    adf_test <- adf.test(residuals, alternative = "stationary")
    po_test <- po.test(window_data[, c("GOOG", "SPY")])
    dw_test <- dwtest(model)
    
    # Store results
    results[[i]] <- tibble(
      start_date = window_data$date[1],
      end_date = window_data$date[window_size],
      hedge_ratio = coef(model)["GOOG"],
      adf_pvalue = adf_test$p.value,
      po_pvalue = po_test$p.value,
      dw_statistic = dw_test$statistic,
      is_cointegrated = ifelse(adf_test$p.value < 0.05, 1, 0)
    )
  }
  
  return(bind_rows(results))
}