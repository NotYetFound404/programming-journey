source("utils.r")
# Step 3: sensitivity analysis

library(ggplot2)
library(dplyr)

# Define sensitivity parameters with a list for better maintainability
params <- list(
  alpha = 1.5,  # SES B sensitivity to SES A default
  beta = 2.0,   # SES C sensitivity to SES A & B default
  gamma = 0.7,  # Prepayment reduction in B due to SES A default
  delta = 1.2,  # Prepayment reduction in C due to combined defaults
  theta = 0.5,  # Direct default-prepayment inverse relation
  sigma = 0.01  # Standard deviation for stochastic shocks
)

# Generate test data with a shock of 1% to SES A (deterministic)
shock_test_deterministic <- default_prepay_model(0.01, stochastic = FALSE)
# Generate test data with a shock of 1% to SES A (stochastic)
shock_test_stochastic <- default_prepay_model(0.01, stochastic = TRUE)

# Plot deterministic results
plot_shock_results(shock_test_deterministic, "Deterministic")

# Plot stochastic results
plot_shock_results(shock_test_stochastic, "Stochastic")

# Sensitivity analysis with stochastic model
#ses_a_shocks <- seq(0.01, 0.1, by = 0.01) #more granular
ses_a_shocks <- seq(0.01, 0.1, by = 0.025)

stochastic_sensitivity_data <- bind_rows(lapply(ses_a_shocks, function(shock) {
  res <- default_prepay_model(shock, stochastic = TRUE)
  cbind(SES_A_Shock = shock, res)
}))
deterministic_sensitivity_data <- bind_rows(lapply(ses_a_shocks, function(shock) {
  res <- default_prepay_model(shock, stochastic = FALSE)
  cbind(SES_A_Shock = shock, res)
}))


plot_sensitivity_results(stochastic_sensitivity_data, "Stochastic")
plot_sensitivity_results(deterministic_sensitivity_data, "Deterministic")

#step 5: getting PV using a yield curve
# Yield curve data
yield_curve <- data.frame(
  Maturity = c(1, 2, 3, 5, 7, 10, 15, 20, 25, 30),
  Yield = c(0.04, 0.041, 0.042, 0.044, 0.0455, 0.047, 0.049, 0.05, 0.051, 0.052)
)

library(dplyr)
library(ggplot2)

# Yield curve data
yield_curve <- data.frame(
  Maturity = c(1, 2, 3, 5, 7, 10, 15, 20, 25, 30),
  Yield = c(0.04, 0.041, 0.042, 0.044, 0.0455, 0.047, 0.049, 0.05, 0.051, 0.052)
)

# Define base mortgage pools
contracts_per_SES <- 50
SES_A <- generate_mortgage_pool(contracts_per_SES, 850000, 100000, 0.025, 0.002, 5, 1.5, 0.02, 0.10, "A")
SES_B <- generate_mortgage_pool(contracts_per_SES, 450000, 100000, 0.05, 0.002, 10, 1.5, 0.05, 0.035, "B")
SES_C <- generate_mortgage_pool(contracts_per_SES, 150000, 50000, 0.085, 0.002, 30, 1.5, 0.08, 0.01, "C")

# Combine into a single pool
base_pool <- bind_rows(SES_A, SES_B, SES_C)

# Iterate over sensitivity grid
shock_levels <- unique(deterministic_sensitivity_data$SES_A_Shock)
results <- list()
for (shock in shock_levels) {
  stressed_pool <- dynamic_adjustment(base_pool, deterministic_sensitivity_data, shock)
  cash_flows <- compute_cash_flows(stressed_pool)
  results[[as.character(shock)]] <- cash_flows
}

# Convert results to dataframe for visualization
results_df <- bind_rows(results, .id = "ShockLevel")

# Visualization
ggplot(results_df, aes(x = ShockLevel, y = FairMarketPrice, color = SES, group = SES)) +
  geom_line() +
  geom_point() +
  labs(title = "MBS Tranche Fair Market Pricing Analysis", x = "SES_A Default Shock", y = "Fair Market Price")
