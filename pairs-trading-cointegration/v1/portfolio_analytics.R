library(xts)
library(PerformanceAnalytics)
library(knitr)
library(kableExtra)

get_portfolio_xts <- function(portfolio){
  portfolio$date <- as.Date(portfolio$date) # Ensure 'date' is a Date object
  portfolio$daily_return <- c(NA,diff(log(portfolio$portafolio_value))) # Calculate daily returns from cumulative returns
  portfolio <- na.omit(portfolio) # Remove first row (NA return)
  portfolio_xts <- xts(portfolio$daily_return, order.by = portfolio$date) # Convert to xts object (required for PerformanceAnalytics)
  return(portfolio_xts)
}

# Compute performance metrics
calculate_performance_metrics <- function(portfolio_xts){
  performance_metrics <- data.frame(
    Metric = c("CAGR", "Sharpe Ratio", "Max Drawdown", "Volatility", "Sortino Ratio"),
    Value = c(
      Return.annualized(portfolio_xts, scale = 252),  # CAGR (Annualized Return)
      SharpeRatio.annualized(portfolio_xts, Rf = 0),  # Sharpe Ratio
      maxDrawdown(portfolio_xts),                     # Maximum Drawdown
      StdDev.annualized(portfolio_xts),               # Annualized Volatility
      SortinoRatio(portfolio_xts, MAR = 0)            # Sortino Ratio (downside risk)
    )
  )
}

# ----  Drawdown Plot ----
plot_max_dd <- function(portfolio_xts){
  drawdowns <- Drawdowns(portfolio_xts)  # Compute drawdowns
  drawdowns_df <- data.frame(date = index(drawdowns), drawdown = coredata(drawdowns))
  
  ggplot(drawdowns_df, aes(x = date, y = drawdown)) +
    geom_area(fill = "red", alpha = 0.5) +
    labs(title = "Portfolio Drawdowns", x = "Date", y = "Drawdown") +
    theme_minimal()
  
}

# # ---- Rolling Sharpe Ratio Plot ----
plot_rolling_sr <- function(portfolio_xts){
  rolling_sharpe <- rollapply(portfolio_xts, width = 60, FUN = SharpeRatio.annualized, by.column = TRUE, align = "right", fill = NA)
  
  rolling_sharpe_df <- data.frame(date = index(rolling_sharpe), sharpe = coredata(rolling_sharpe))
  
  ggplot(rolling_sharpe_df  %>%
           na.omit(), aes(x = date, y = sharpe)) +
    geom_line(color = "purple", size = 1) +
    labs(title = "Rolling 60-day Sharpe Ratio", x = "Date", y = "Sharpe Ratio") +
    theme_minimal()
}

#Nice html performance table
get_html_performance_metrics <- function(performance_metrics){
  performance_metrics %>%
    kable(format = "html", digits = 4, caption = "Portfolio Performance Summary") %>%
    kable_styling(full_width = FALSE, bootstrap_options = c("striped", "hover", "condensed"))
  
  
}
  
