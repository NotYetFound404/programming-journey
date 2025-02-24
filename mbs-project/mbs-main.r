source("utils.r")
set.seed(123)

# Step 1. Synthetic Data Generation
contracts_per_SES = 50

# Generate sample data with more accurate parameters
SES_A <- simulate_mortgages(
  n = contracts_per_SES,
  mean_loan = 850000,
  sd_loan = 100000,  # More realistic variance
  mean_rate = 0.025,
  sd_rate = 0.002,   # Smaller relative SD for rates
  mean_term = 5,
  sd_term = 1.5
) %>%
  assign_defaults(0.02) %>%
  assign_prepayments(0.10) %>%
  mutate(SES = "A",
         UID = paste0(SES, "-",LoanID)
         )

SES_B <- simulate_mortgages(
  n = contracts_per_SES,
  mean_loan = 450000,
  sd_loan = 100000,  # More realistic variance
  mean_rate = 0.05,
  sd_rate = 0.002,   # Smaller relative SD for rates
  mean_term = 10,
  sd_term = 1.5
) %>%
  assign_defaults(0.05) %>%
  assign_prepayments(0.035)%>%
  mutate(SES = "B",
         UID = paste0(SES, "-",LoanID)
  )

SES_C <- simulate_mortgages(
  n = contracts_per_SES,
  mean_loan = 150000,
  sd_loan = 50000,  # More realistic variance
  mean_rate = 0.085,
  sd_rate = 0.002,   # Smaller relative SD for rates
  mean_term = 30,
  sd_term = 1.5
) %>%
  assign_defaults(0.08) %>%
  assign_prepayments(0.01)%>%
  mutate(SES = "C",
         UID = paste0(SES, "-",LoanID)
  )
pool_of_contracts <- rbind(SES_A,SES_B,SES_C)

# Step 2: Cash flow modeling
cash_flows <- aggregate_cash_flows(pool_of_contracts)

plot_portfolio_cashflow_trends(cash_flows = cash_flows)
plot_portfolio_cashflow_trends_breakdown(cash_flows = cash_flows)
plot_cumulative_payment_waterfall(cash_flows = cash_flows)
plot_overall_portfolio(cash_flows = cash_flows)


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





# #Testing
# test_file("tests.R")
