# Importing modules
source("v1/data_generation.R")
source("v1/visualization.R")
source("v1/stat_tests.R")
source("v1/data_wrangling.R")
source("v1/backtest_engine.R")
source("v1/portfolio_analytics.R")
# For reproductibility
set.seed(123)

# Step 1: Data Generation
data <- generate_cointegrated_pair(n = 180)

# Step 2: Visualization
viz_pair_data(data = data)

# Step 3: Implementing Rolling Cointegration Tests
rolling_tests <- rolling_cointegration_test(data, window_size = 60) %>%
  mutate(date = end_date) # For joining purposes

# Step 4:  Merging Cointegration Results with Price Data
full_data <- full_join(
  data,
  rolling_tests,
  by = "date"
)
# Step 5: Computing the Spread
trading_data <- full_data %>%
  na.omit() %>% # Remove NA values from the start of the rolling window
  calculate_spread()

# Step 6: Normalizing the Spread with Z-score
trading_data <- calculate_zscore(trading_data,window = 7)

# Step 7: Defining Trading Signals
trading_data <- generate_signals(trading_data)

# Step 8: Visualizing Spread and Signals
plot_spread_signals(trading_data%>%
                      na.omit() )

# Step 9: Computing Strategy Returns
results <- calculate_returns(trading_data)

# Step 10: Visualizing Portfolio Performance
plot_portfolio_over_time(results)

# Step 11: Portafolio analytics
portfolio <- results %>% 
  select(date, cumulative_ret) %>%
  mutate(portafolio_value = 1000*cumulative_ret)

portfolio_xts <- get_portfolio_xts(portfolio = portfolio)
performance_metrics <- calculate_performance_metrics(portfolio_xts = portfolio_xts)
get_html_performance_metrics(performance_metrics=performance_metrics)
plot_max_dd(portfolio_xts)
plot_rolling_sr(portfolio_xts)


sum(na.omit(results$strategy_ret)!=0) #trades
sum(na.omit(results$strategy_ret)>0) #profitable trades
sum(na.omit(results$strategy_ret)<0) #unprofitable trades


ggplot(results %>% filter(strategy_ret != 0), aes(y = strategy_ret, x = roll_sd)) +
  geom_point(alpha = 0.6, color = "blue") +
  geom_smooth(method = "lm", color = "red", se = FALSE) +
  labs(
    title = "Strategy Returns vs. Rolling Standard Deviation",
    x = "Rolling Standard Deviation (Risk)",
    y = "Strategy Return"
  ) +
  theme_minimal()

ggplot(results %>% filter(strategy_ret != 0), aes(x = strategy_ret)) +
  geom_histogram(aes(y = after_stat(density)), bins = 60, fill = "steelblue", color = "white", alpha = 0.7) +
  geom_density(color = "red", size = 1) +
  labs(
    title = "Distribution of Strategy Returns",
    x = "Strategy Return",
    y = "Density"
  ) +
  theme_minimal()
