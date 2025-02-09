generate_cointegrated_pair <- function(n = 180, beta = 0.8, noise = 0.1) {
  # Generate random walk for first series
  price_A <- cumsum(rnorm(n, 0, 1))
  
  # Generate cointegrated series
  error <- arima.sim(list(ar = 0.3), n) * noise
  price_B <- (price_A / beta) + error
  
  return(data.frame(
    date = seq.Date(from = Sys.Date() - n + 1, to = Sys.Date(), by = "day"),
    GOOG = 100 + price_A,  # Arbitrary starting price for GOOG
    SPY = 100 + price_B    # Arbitrary starting price for SPY
  ))
}

