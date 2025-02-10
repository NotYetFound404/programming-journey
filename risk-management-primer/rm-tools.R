# Step 1
simulate_gbm_with_shocks <- function(S0, drift, sigma, T, N, distribution = "std_normal", ...) {
  # S0: Initial price
  # drift: Drift (expected return) for the GBM
  # sigma: Volatility
  # T: Time horizon (in years)
  # N: Number of time steps
  # distribution: Type of shock distribution (see below for options)
  # ...: Additional parameters for the distribution (e.g., mean, sd, df, skewness)
  
  # Time increment
  dt <- T / N
  
  # Initialize the price vector
  S <- numeric(N + 1)
  S[1] <- S0
  
  # Simulate the GBM with shocks
  for (i in 2:(N + 1)) {
    # Generate a random normal increment for the GBM
    dW <- rnorm(1, mean = 0, sd = sqrt(dt))
    
    # Generate a shock based on the specified distribution
    shock <- switch(distribution,
                    std_normal = rnorm(1, mean = 0, sd = 1), # Standard normal
                    normal = rnorm(1, mean = list(...)$mean, sd = list(...)$sd), # Normal with specified mean and sd
                    skewed_normal = sn::rsn(1, xi = 0, omega = 1, alpha = list(...)$alpha), # Skewed normal
                    heavy_tail_normal = rt(1, df = list(...)$df) * sqrt((list(...)$df - 2) / list(...)$df), # Heavy-tailed normal (scaled t-distribution)
                    std_t = rt(1, df = list(...)$df), # Standard t-distribution
                    skewed_t = sn::rst(1, xi = 0, omega = 1, alpha = list(...)$alpha, nu = list(...)$nu), # Skewed t-distribution
                    stop("Invalid distribution specified")
    )
    
    # Update the price using the GBM formula with added shock
    S[i] <- S[i - 1] * exp((drift - 0.5 * sigma^2) * dt + sigma * dW) + shock
  }
  
  # Return the simulated price path
  return(S)
}

# # Exploring different paths
# # 1. Standard Normal Shocks
# # Simulates GBM where shocks follow a standard normal distribution
# price_path <- simulate_gbm_with_shocks(S0 = 100, drift = 0.05, sigma = 0.2, T = 1, N = 252, distribution = "std_normal")
# plot(price_path, type = "l", col = "blue", xlab = "Time", ylab = "Price", main = "GBM with Standard Normal Shocks")
# 
# # 2. Normal Shocks with Custom Mean and SD
# # Adjusts normal shocks to have mean = 0 and higher standard deviation (0.5)
# price_path <- simulate_gbm_with_shocks(S0 = 100, drift = 0.05, sigma = 0.2, T = 1, N = 252, distribution = "normal", mean = 0, sd = 0.5)
# plot(price_path, type = "l", col = "blue", xlab = "Time", ylab = "Price", main = "GBM with Normal Shocks (mean = 0, sd = 0.5)")
# 
# # 3. Skewed Normal Shocks
# # Introduces asymmetry in the shock distribution using a skewness parameter (alpha = 5)
# price_path <- simulate_gbm_with_shocks(S0 = 100, drift = 0.05, sigma = 0.2, T = 1, N = 252, distribution = "skewed_normal", alpha = 5)
# plot(price_path, type = "l", col = "blue", xlab = "Time", ylab = "Price", main = "GBM with Skewed Normal Shocks (alpha = 5)")
# 
# # 4. Heavy-Tailed Normal Shocks
# # Uses a Student's t-distribution with low degrees of freedom (df = 3) for fatter tails
# price_path <- simulate_gbm_with_shocks(S0 = 100, drift = 0.05, sigma = 0.2, T = 1, N = 252, distribution = "heavy_tail_normal", df = 3)
# plot(price_path, type = "l", col = "blue", xlab = "Time", ylab = "Price", main = "GBM with Heavy-Tailed Normal Shocks (df = 3)")
# 
# # 5. Standard t-Distribution Shocks
# # Models shocks from a standard t-distribution (df = 5), capturing heavier tails than normal
# price_path <- simulate_gbm_with_shocks(S0 = 100, drift = 0.05, sigma = 0.2, T = 1, N = 252, distribution = "std_t", df = 5)
# plot(price_path, type = "l", col = "blue", xlab = "Time", ylab = "Price", main = "GBM with Standard t-Distribution Shocks (df = 5)")
# 
# # 6. Skewed t-Distribution Shocks
# # Adds skewness (alpha = 2) to a t-distribution with 5 degrees of freedom (nu = 5)
# price_path <- simulate_gbm_with_shocks(S0 = 100, drift = 0.05, sigma = 0.2, T = 1, N = 252, distribution = "skewed_t", alpha = 2, nu = 5)
# plot(price_path, type = "l", col = "blue", xlab = "Time", ylab = "Price", main = "GBM with Skewed t-Distribution Shocks (alpha = 2, nu = 5)")

# Helper functions for systemic approach
compute_risk_measures <- function(returns) {
  # browser()
  # Calculate returns (if not already provided)
  
  # Historical VaR
  historical_VaR_95 <- quantile(returns, probs = 0.05)
  historical_VaR_99 <- quantile(returns, probs = 0.01)
  
  # Parametric (Normal) VaR
  mean_return <- mean(returns)
  sd_return <- sd(returns)
  parametric_VaR_95 <- mean_return + sd_return * qnorm(0.05)
  parametric_VaR_99 <- mean_return + sd_return * qnorm(0.01)
  
  # Cornish-Fisher Adjusted VaR
  skewness <- PerformanceAnalytics::skewness(returns)
  kurtosis <- PerformanceAnalytics::kurtosis(returns)
  
  # Adjustment factors
  z_95 <- qnorm(0.05)
  z_99 <- qnorm(0.01)
  
  adjusted_z_95 <- z_95 + (skewness / 6) * (z_95^2 - 1) + 
    (kurtosis / 24) * (z_95^3 - 3 * z_95) - 
    (skewness^2 / 36) * (2 * z_95^3 - 5 * z_95)
  
  adjusted_z_99 <- z_99 + (skewness / 6) * (z_99^2 - 1) + 
    (kurtosis / 24) * (z_99^3 - 3 * z_99) - 
    (skewness^2 / 36) * (2 * z_99^3 - 5 * z_99)
  
  CF_VaR_95 <- mean_return + sd_return * adjusted_z_95
  CF_VaR_99 <- mean_return + sd_return * adjusted_z_99
  
  # CVaR
  CVaR_95 <- mean(returns[returns <= historical_VaR_95])
  CVaR_99 <- mean(returns[returns <= historical_VaR_99])
  
  # Return results as a data frame
  data.frame(
    Historical_VaR_95 = historical_VaR_95,
    Parametric_VaR_95 = parametric_VaR_95,
    CF_VaR_95 = CF_VaR_95,
    CVaR_95 = CVaR_95,
    Historical_VaR_99 = historical_VaR_99,
    Parametric_VaR_99 = parametric_VaR_99,
    CF_VaR_99 = CF_VaR_99,
    CVaR_99 = CVaR_99
  )
}

analyze_shock_scenario <- function(distribution, seed = 123, ...) {
  # Set seed for reproducibility
  set.seed(seed)
  # browser()
  # Generate synthetic data
  price_path <- simulate_gbm_with_shocks(
    S0 = 100,
    drift = 0.05,
    sigma = 0.2,
    T = 1,
    N = 252,
    distribution = distribution,
    ...
  )
  
  # Convert to returns
  returns <- diff(log(price_path))[-1]
  
  # Compute risk measures
  results <- compute_risk_measures(returns)
  
  # Add metadata about the scenario
  results$Distribution <- distribution
  results$Seed <- seed
  results$Parameters <- paste(list(...), collapse = ", ")
  
  return(results)
}

