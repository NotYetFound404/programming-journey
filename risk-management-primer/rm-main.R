# Load necessary libraries and modules
source("rm-tools.R")
library(xts)
library(PerformanceAnalytics) # For VaR and CVaR calculations


# Set seed for reproducibility
set.seed(123)


# Step 1: Synth historical price data simulation

# Generating synthethic historical data from a GBM with normal shocks
historical_data <- simulate_gbm_with_shocks(S0 = 100, drift = 0.05, sigma = 0.2, T = 1, N = 252, distribution = "std_normal")
dates <- seq(as.Date("2023-01-01"), by = "day", length.out = 253) # Create a date index (assuming 252 trading days in a year)
historical_xts <- xts(historical_data, order.by = dates) # Convert the historical data to an xts object
# Plot the data
plot(historical_xts, main = "Synthetic Historical Price Data", col = "blue")

# Step 2: Compute Historical VaR

# Calculate daily returns
returns <- diff(log(historical_xts))[-1] # Log returns
colnames(returns) <- "daily_returns"
# Plot Daily Returns
plot(returns, main = "Daily Historical Log-Returns")
hist(returns, main = "Histogram of Daily Historical Log-Returns")

# Compute historical VaR at 95% and 99% confidence levels
VaR_95 <- quantile(returns, probs = 0.05)
VaR_99 <- quantile(returns, probs = 0.01)

cat("Historical VaR at 95% confidence level:", VaR_95, "\n")
cat("Historical VaR at 99% confidence level:", VaR_99, "\n")


# Step 3: Compute Parametric VaR
# Calculate mean and standard deviation of returns
mean_return <- mean(returns)
sd_return <- sd(returns)

# Compute parametric VaR at 95% and 99% confidence levels
parametric_VaR_95 <- mean_return + sd_return * qnorm(0.05)
parametric_VaR_99 <- mean_return + sd_return * qnorm(0.01)

cat("Parametric VaR at 95% confidence level:", parametric_VaR_95, "\n")
cat("Parametric VaR at 99% confidence level:", parametric_VaR_99, "\n")

# Step 4: Compute CVaR (Expected Shortfall)
# Compute CVaR at 95% and 99% confidence levels
CVaR_95 <- mean(returns[returns <= VaR_95])
CVaR_99 <- mean(returns[returns <= VaR_99])

cat("CVaR at 95% confidence level:", CVaR_95, "\n")
cat("CVaR at 99% confidence level:", CVaR_99, "\n")

#Step 5: Apply the Cornish-Fisher Expansion
# Calculate skewness and kurtosis
skewness <- PerformanceAnalytics::skewness(returns)
kurtosis <- PerformanceAnalytics::kurtosis(returns)

# Cornish-Fisher adjustment factor
z_95 <- qnorm(0.05)
z_99 <- qnorm(0.01)

adjusted_z_95 <- z_95 + (skewness / 6) * (z_95^2 - 1) + (kurtosis / 24) * (z_95^3 - 3 * z_95) - (skewness^2 / 36) * (2 * z_95^3 - 5 * z_95)
adjusted_z_99 <- z_99 + (skewness / 6) * (z_99^2 - 1) + (kurtosis / 24) * (z_99^3 - 3 * z_99) - (skewness^2 / 36) * (2 * z_99^3 - 5 * z_99)

# Adjusted VaR using Cornish-Fisher expansion
CF_VaR_95 <- mean_return + sd_return * adjusted_z_95
CF_VaR_99 <- mean_return + sd_return * adjusted_z_99

cat("Cornish-Fisher Adjusted VaR at 95% confidence level:", CF_VaR_95, "\n")
cat("Cornish-Fisher Adjusted VaR at 99% confidence level:", CF_VaR_99, "\n")

# Step 6: Result comparison
# Create a data frame to store the results
results <- data.frame(
  Confidence_Level = c("95%", "99%"),
  Historical_VaR = c(VaR_95, VaR_99),
  Parametric_VaR = c(parametric_VaR_95, parametric_VaR_99),
  Cornish_Fisher_VaR = c(CF_VaR_95, CF_VaR_99),
  CVaR = c(CVaR_95, CVaR_99)
)

# Print the results
print(results)

# Step 7: More viz!
# Load ggplot2 for visualization
library(ggplot2)

# Reshape the data for plotting
library(tidyr)
results_long <- pivot_longer(results, cols = -Confidence_Level, names_to = "Metric", values_to = "Value")

# Plot the results
ggplot(results_long, aes(x = Confidence_Level, y = Value, fill = Metric)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Comparison of Risk Measures",
       x = "Confidence Level",
       y = "Value",
       fill = "Metric") +
  theme_minimal()

# Now! Let's sistematize the approach for multiple data generating processes

# 1: Define scenarios to compare
scenarios <- list(
  # Scenario 1: Standard Normal
  list(distribution = "std_normal"),
  # Scenario 2: Normal with mu=0, sd=0.5
  list(distribution = "normal", mean = 0, sd = 0.5),
  # Scenario 3: Skewed Normal (alpha=5)
  list(distribution = "skewed_normal", alpha = 5),
  # Scenario 4: Heavy-Tailed Normal (df=3)
  list(distribution = "heavy_tail_normal", df = 3),
  # Scenario 5: Standard t-Distribution (df=5)
  list(distribution = "std_t", df = 5),
  # Scenario 6: Skewed t-Distribution (alpha=2, nu=5)
  list(distribution = "skewed_t", alpha = 2, nu = 5)
)

library(purrr)
library(dplyr)
# 2: Run all scenarios
results_list <- map(scenarios, ~ do.call(analyze_shock_scenario, .))
# Combine results into a single data frame
results_df <- bind_rows(results_list)
# Print the results
print(results_df)


# 3: Visualize Comparisons
library(ggplot2)
library(tidyr)

# Plot VaR at 95% Confidence Level Across Scenarios:
# Reshape data for plotting
plot_data <- results_df %>%
  select(Distribution, Historical_VaR_95, Parametric_VaR_95, CF_VaR_95) %>%
  pivot_longer(cols = -Distribution, names_to = "Method", values_to = "VaR")

# Plot
ggplot(plot_data, aes(x = Distribution, y = VaR, fill = Method)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(
    title = "Comparison of VaR (95%) Across Shock Distributions",
    x = "Shock Distribution",
    y = "VaR",
    fill = "Method"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

#Plot CVaR at 99% Confidence Level:
plot_data_cvar <- results_df %>%
  select(Distribution, CVaR_99) %>%
  pivot_longer(cols = -Distribution, names_to = "Metric", values_to = "Value")
ggplot(plot_data_cvar, aes(x = Distribution, y = Value, fill = Metric)) +
  geom_bar(stat = "identity") +
  labs(
    title = "CVaR (99%) Across Shock Distributions",
    x = "Shock Distribution",
    y = "CVaR"
  ) +
  theme_minimal()

# Step 5: Monte Carlo Simulations (Optional)
# To assess robustness, run multiple simulations for each scenario and compute average results:
library(furrr)
plan(multisession) # Enable parallel processing

# Run 100 Monte Carlo simulations per scenario
monte_carlo_results <- future_map(1:1000, ~ {
  map(scenarios, ~ do.call(analyze_shock_scenario, c(., seed = runif(n = 1)*1000000)))
}, .progress = TRUE)

# Combine results
monte_carlo_df <- bind_rows(monte_carlo_results)


# Aggregate results (e.g., mean VaR across simulations)
summary_df <- monte_carlo_df %>%
  group_by(Distribution) %>%
  summarise(
    Mean_Historical_VaR_95 = mean(Historical_VaR_95),
    Mean_Parametric_VaR_95 = mean(Parametric_VaR_95),
    Mean_CF_VaR_95 = mean(CF_VaR_95),
    SD_Historical_VaR_95 = sd(Historical_VaR_95),
    SD_Parametric_VaR_95 = sd(Parametric_VaR_95),
    SD_CF_VaR_95 = sd(CF_VaR_95)
  )

print(summary_df)

# Viz the monte carlo
library(ggplot2)
library(tidyr)

# 1. Boxplot of VaR Methods Across Distributions (95% Confidence Level)
# Reshape data to focus on 95% VaR methods
plot_data_95 <- monte_carlo_df %>%
  select(Distribution, Historical_VaR_95, Parametric_VaR_95, CF_VaR_95) %>%
  pivot_longer(
    cols = -Distribution,
    names_to = "Method",
    values_to = "VaR"
  ) %>%
  mutate(Method = gsub("_VaR_95", "", Method))

# Boxplot
ggplot(plot_data_95, aes(x = Method, y = VaR, fill = Method)) +
  geom_boxplot() +
  facet_wrap(~Distribution, scales = "free_y") +
  labs(
    title = "Distribution of VaR (95%) Across Methods and Shock Distributions",
    x = "Method",
    y = "VaR (95%)"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


#2. Violin Plot of CVaR (99% Confidence Level)

# Reshape data for CVaR
plot_data_cvar <- monte_carlo_df %>%
  select(Distribution, CVaR_95, CVaR_99) %>%
  pivot_longer(
    cols = -Distribution,
    names_to = "Confidence_Level",
    values_to = "CVaR"
  ) %>%
  mutate(Confidence_Level = gsub("CVaR_", "", Confidence_Level))

# Violin plot
ggplot(plot_data_cvar, aes(x = Distribution, y = CVaR, fill = Confidence_Level)) +
  geom_violin(alpha = 0.7, position = position_dodge(width = 0.8)) +
  labs(
    title = "CVaR Across Distributions and Confidence Levels",
    x = "Shock Distribution",
    y = "CVaR"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

#3. Faceted Scatterplot: Parametric vs. Historical VaR (95%)
ggplot(monte_carlo_df, aes(x = Parametric_VaR_95, y = Historical_VaR_95, color = Distribution)) +
  geom_point(alpha = 0.6) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray") +
  facet_wrap(~Distribution, scales = "free") +
  labs(
    title = "Parametric vs. Historical VaR (95%)",
    x = "Parametric VaR",
    y = "Historical VaR"
  ) +
  theme_minimal()

#4. Line Plot: Mean VaR Across Methods (95% and 99%)
# Calculate mean VaR for each method and confidence level
mean_plot_data <- monte_carlo_df %>%
  group_by(Distribution) %>%
  summarise(
    Mean_Historical_95 = mean(Historical_VaR_95),
    Mean_Parametric_95 = mean(Parametric_VaR_95),
    Mean_CF_95 = mean(CF_VaR_95),
    Mean_Historical_99 = mean(Historical_VaR_99),
    Mean_Parametric_99 = mean(Parametric_VaR_99),
    Mean_CF_99 = mean(CF_VaR_99)
  ) %>%
  pivot_longer(
    cols = -Distribution,
    names_to = c("Method", "Confidence_Level"),
    names_sep = "_",
    values_to = "Mean_VaR"
  )

# Line plot
ggplot(mean_plot_data, aes(x = Confidence_Level, y = Mean_VaR, color = Method, group = Method)) +
  geom_line(linewidth = 1) +
  geom_point(size = 3) +
  facet_wrap(~Distribution, scales = "free_y") +
  labs(
    title = "Mean VaR Across Methods and Confidence Levels",
    x = "Confidence Level",
    y = "Mean VaR"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

#5. Heatmap: VaR Method Error (Parametric vs. Historical)
# Compute error: Parametric VaR - Historical VaR (95%)
error_data <- monte_carlo_df %>%
  mutate(Error_Parametric = Parametric_VaR_95 - Historical_VaR_95)

# Heatmap
ggplot(error_data, aes(x = Distribution, y = Error_Parametric)) +
  geom_bin2d(bins = 30) +
  scale_fill_viridis_c(option = "magma") +
  labs(
    title = "Error in Parametric VaR (95%) vs. Historical VaR",
    x = "Shock Distribution",
    y = "Parametric VaR Error",
    fill = "Frequency"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


# Key Insights to Highlight:
#   Cornish-Fisher Pitfalls:
#   
#   Fails when skewness/kurtosis are extreme (e.g., in heavy-tailed t-distributions).
# 
# Compare CF_VaR vs. Historical_VaR in skewed or heavy-tailed scenarios.
# 
# Historical VaR "Luck":
#   
#   Historical VaR varies more across simulations (see Monte Carlo SD_Historical_VaR).
# 
# Sensitive to sample size (try reducing N in simulate_gbm_with_shocks).
# 
# Parametric VaR Efficiency:
#   
#   Works best under normality (e.g., std_normal scenario).
# 
# Underestimates risk in skewed/heavy-tailed distributions.
# 
# CVaR as a Robust Metric:
#   
#   Always exceeds VaR, capturing tail risk.
# 
# Less sensitive to distribution assumptions than parametric VaR.


# Key Insights to Extract:
#   Parametric VaR Underestimation:
#   
#   In heavy-tailed distributions (e.g., heavy_tail_normal, std_t), parametric VaR (assuming normality) consistently underestimates risk compared to historical/Cornish-Fisher VaR.
# 
# Cornish-Fisher Adjustment:
#   
#   In skewed distributions (e.g., skewed_normal), Cornish-Fisher VaR aligns better with historical VaR than parametric VaR.
# 
# CVaR as Tail Risk Indicator:
#   
#   CVaR values are always more extreme than VaR, especially in non-normal scenarios.
# 
# Method Variability:
#   
#   Historical VaR shows higher variability (wider boxplots) due to reliance on empirical quantiles.