# Step 1 Functions ------------
library(dplyr)
library(MASS)

simulate_mortgages <- function(
    n,
    mean_loan,
    sd_loan,
    mean_rate,
    sd_rate,
    mean_term,
    sd_term
) {
  # Input validation
  if(n <= 0) stop("n must be positive")
  if(mean_loan <= 0 || sd_loan <= 0) stop("Loan parameters must be positive")
  
  # Calculate lognormal parameters correctly
  calc_lognormal_params <- function(m, s) {
    list(
      meanlog = log(m^2 / sqrt(s^2 + m^2)),
      sdlog = sqrt(log(1 + (s^2 / m^2)))
    )
  }
  
  loan_params <- calc_lognormal_params(mean_loan, sd_loan)
  term_params <- calc_lognormal_params(mean_term, sd_term)
  
  # Generate interest rates with positive constraint
  rate_sigma <- sd_rate / mean_rate  # Coefficient of variation
  rate_meanlog <- log(mean_rate) - 0.5 * log(1 + rate_sigma^2)
  rate_sdlog <- sqrt(log(1 + rate_sigma^2))
  
  df <- data.frame(
    LoanID = 1:n,
    LoanAmount = rlnorm(n, loan_params$meanlog, loan_params$sdlog),
    InterestRate = rlnorm(n, rate_meanlog, rate_sdlog),
    Term = pmax(1, round(rlnorm(n, term_params$meanlog, term_params$sdlog))), # Ensure ≥1 year
    DefaultFlag = 0,
    DefaultMonth = NA_integer_,
    PrepayFlag = 0,
    PrepayMonth = NA_integer_
  )
  
  return(df)
}
assign_defaults <- function(df, default_rate) {
  if(default_rate < 0 || default_rate > 1) stop("Default rate must be between 0-1")
  num_defaults <- round(nrow(df) * default_rate)
  if(num_defaults == 0) return(df)
  default_loans <- sample(df$LoanID, num_defaults, replace = FALSE)
  
  df %>%
    mutate(
      DefaultFlag = ifelse(LoanID %in% default_loans, 1, DefaultFlag),
      DefaultMonth = ifelse(
        LoanID %in% default_loans,
        mapply(function(term) sample(1:(term*12), 1), Term),
        DefaultMonth
      )
    ) %>%
    # Ensure defaults don't occur after term ends
    mutate(DefaultMonth = pmin(DefaultMonth, Term*12))
}
assign_prepayments <- function(df, prepay_rate) {
  if(prepay_rate < 0 || prepay_rate > 1) stop("Prepayment rate must be between 0-1")
  
  # Calculate prepayments based on original count
  num_prepays <- round(nrow(df) * prepay_rate)
  available_loans <- df %>% filter(DefaultFlag == 0)
  
  # Ensure we don't exceed available non-defaulted loans
  num_prepays <- min(num_prepays, nrow(available_loans))
  if(num_prepays == 0) return(df)
  
  prepay_loans <- sample(available_loans$LoanID, num_prepays, replace = FALSE)
  
  df %>%
    mutate(
      PrepayFlag = ifelse(LoanID %in% prepay_loans, 1, PrepayFlag),
      PrepayMonth = ifelse(
        LoanID %in% prepay_loans,
        mapply(function(term) sample(1:(term*12), 1), Term),
        PrepayMonth
      )
    ) %>%
    mutate(PrepayMonth = pmin(PrepayMonth, Term*12))
}

# Step 2: Cash flow modeling --------
library(FinCal)
calculate_monthly_payment <- function(loan_amount, interest_rate, term_years) {
  if (interest_rate == 0) {
    stop("Zero interest rate not accepted")
  }
  
  monthly_rate <- interest_rate / 12
  num_months <- term_years * 12
  pmt(monthly_rate, num_months, -loan_amount, fv = 0, type = 0)
}

generate_amort_schedule <- function(loan, start_date = as.Date("2025-01-01")) {
  monthly_rate <- loan$InterestRate/12
  num_months <- loan$Term * 12
  monthly_payment <- calculate_monthly_payment(loan$LoanAmount, loan$InterestRate, loan$Term)
  
  schedule <- data.frame(
    Month = 1:num_months,
    Date = seq(start_date, by = "month", length.out = num_months)
  )
  
  balance <- loan$LoanAmount
  interest_payment <- principal_payment <- numeric(num_months)
  
  for(i in 1:num_months) {
    interest_payment[i] <- balance * monthly_rate
    principal_payment[i] <- monthly_payment - interest_payment[i]
    balance <- balance - principal_payment[i]
    
    # Prevent negative balance
    if(abs(balance) < 1e-6) balance <- 0
    if(balance <= 0 && i < num_months) {
      schedule <- schedule[1:i,]
      break
    }
  }
  
  schedule %>%
    mutate(
      InterestPayment = interest_payment[1:n()],
      PrincipalPayment = principal_payment[1:n()],
      Balance = loan$LoanAmount - cumsum(PrincipalPayment)
    )
}

adjust_cash_flows <- function(schedule, loan) {
  modified_schedule <- schedule
  
  # Handle defaults
  if(!is.na(loan$DefaultMonth)) {
    default_month <- min(loan$DefaultMonth, nrow(modified_schedule))
    modified_schedule <- modified_schedule[1:default_month, ]
    modified_schedule$Balance[default_month] <- 0
  }
  
  # Handle prepayments
  if(!is.na(loan$PrepayMonth)) {
    prepay_month <- min(loan$PrepayMonth, nrow(modified_schedule))
    outstanding_balance <- modified_schedule$Balance[prepay_month]
    
    modified_schedule <- modified_schedule[1:prepay_month, ]
    modified_schedule$PrincipalPayment[prepay_month] <- 
      modified_schedule$PrincipalPayment[prepay_month] + outstanding_balance
    modified_schedule$Balance[prepay_month] <- 0
  }
  
  modified_schedule
}

aggregate_cash_flows <- function(pool_of_contracts) {
  library(data.table)
  
  process_loan <- function(loan) {
    schedule <- generate_amort_schedule(loan)
    adjusted_schedule <- adjust_cash_flows(schedule, loan)
    adjusted_schedule$UID <- loan$UID
    adjusted_schedule
  }
  
  # Parallel processing
  all_schedules <- parallel::mclapply(1:nrow(pool_of_contracts), function(i) {
    process_loan(pool_of_contracts[i, ])
  })
  
  # Data.table aggregation
  dt <- rbindlist(all_schedules)
  total_cash_flows <- dt[, .(
    TotalPrincipal = sum(PrincipalPayment, na.rm = TRUE),
    TotalInterest = sum(InterestPayment, na.rm = TRUE)
  ), by = Date]
  
  total_cash_flows[, TotalCashFlow := TotalPrincipal + TotalInterest]
  
  list(all_schedules = all_schedules, total_cash_flows = total_cash_flows)
}

# Step 3: Visualize Cash flows --------

# Plot
library(tidyr)
library(ggplot2)
library(scales)
library(stringr)

plot_portfolio_cashflow_trends <- function(cash_flows){
  # Aggregate View with Smoothing
  ggplot(cash_flows$total_cash_flows, aes(x = Date, y = TotalCashFlow)) +
    geom_line(color = "#1f77b4", size = 0.8) +
    geom_smooth(method = "loess", span = 0.2, color = "#ff7f0e", se = FALSE) +
    labs(title = "Portfolio Cash Flow Trends", 
         subtitle = "With LOESS Smoothing",
         x = "Date", y = "Total Cash Flow") +
    theme_minimal(base_size = 12)
  
}



# 1. Stacked Area Chart (Capital vs Interest)
plot_portfolio_cashflow_trends_breakdown <- function(cash_flows){
  cash_flows$total_cash_flows %>%
    pivot_longer(
      cols = c(TotalPrincipal, TotalInterest),
      names_to = "PaymentType",
      values_to = "Amount"
    ) %>%
    mutate(PaymentType = factor(PaymentType,
                                levels = c("TotalPrincipal", "TotalInterest"),
                                labels = c("Capital", "Interest"))) %>%
    ggplot(aes(x = Date, y = Amount, fill = PaymentType)) +
    geom_area(alpha = 0.85, position = "stack") +
    scale_fill_manual(values = c("Capital" = "#1f77b4", "Interest" = "#ff7f0e")) +
    scale_y_continuous(labels = dollar_format()) +
    labs(title = "Capital vs Interest Payment Composition",
         subtitle = "Stacked monthly payments breakdown",
         x = "Date", y = "Payment Amount",
         fill = "Component") +
    theme_minimal() +
    theme(legend.position = "top",
          panel.grid.major.x = element_blank(),
          panel.grid.minor = element_blank())
  
}


# 2. Cumulative Payment Waterfall
plot_cumulative_payment_waterfall <- function(cash_flows){
  cumulative_plot <- cash_flows$total_cash_flows %>%
    arrange(Date) %>%
    mutate(CumulativeCapital = cumsum(TotalPrincipal),
           CumulativeInterest = cumsum(TotalInterest)) %>%
    pivot_longer(
      cols = starts_with("Cumulative"),
      names_to = "PaymentType",
      values_to = "Amount"
    ) %>%
    mutate(PaymentType = factor(str_remove(PaymentType, "Cumulative"),
                                levels = c("Capital", "Interest")))
  ggplot(cumulative_plot, aes(x = Date, y = Amount, color = PaymentType)) +
    geom_line(size = 1.2, alpha = 0.8) +
    geom_area(aes(fill = PaymentType), alpha = 0.15, position = "identity") +
    scale_color_manual(values = c("Capital" = "#2ca02c", "Interest" = "#d62728")) +
    scale_fill_manual(values = c("Capital" = "#2ca02c", "Interest" = "#d62728")) +
    scale_y_continuous(labels = dollar_format(scale = 1e-6, suffix = "M")) +
    labs(title = "Cumulative Capital & Interest Payments",
         subtitle = "Running total of principal recovered and interest earned",
         x = "Date", y = "Cumulative Amount",
         color = "Component", fill = "Component") +
    theme_minimal() +
    theme(legend.position = "bottom")
  
}
# 3. Proportional Donut Chart (Overall Portfolio)
plot_overall_portfolio <- function(cash_flows){
  total_payments <- cash_flows$total_cash_flows %>%
    summarise(TotalCapital = sum(TotalPrincipal),
              TotalInterest = sum(TotalInterest)) %>%
    pivot_longer(everything(), names_to = "Type", values_to = "Amount") %>%
    mutate(Percentage = Amount / sum(Amount),
           Type = str_remove(Type, "Total"))
  
  ggplot(total_payments, aes(x = 2, y = Percentage, fill = Type)) +
    geom_col(color = "white", width = 1) +
    coord_polar(theta = "y", start = 0) +
    geom_text(aes(label = percent(Percentage)),
              position = position_stack(vjust = 0.5),
              color = "white", size = 5) +
    scale_fill_manual(values = c("Capital" = "#17becf", "Interest" = "#bcbd22")) +
    xlim(0.5, 2.5) +
    labs(title = "Overall Portfolio Composition",
         subtitle = "Proportion of capital vs interest payments") +
    theme_void() +
    theme(legend.position = "bottom",
          plot.title = element_text(hjust = 0.5),
          plot.subtitle = element_text(hjust = 0.5))
  
}




# Step 3: Sensitivity analysis
# Function to propagate default shocks with stochastic terms
default_prepay_model <- function(delta_DA, stochastic = FALSE) {
  with(params, {
    # Calculate deterministic terms
    delta_DB <- alpha * delta_DA
    delta_DC <- beta * (delta_DA + delta_DB)
    
    # Add stochastic terms if enabled
    if (stochastic) {
      epsilon_B <- rnorm(1, mean = 0, sd = sigma)
      epsilon_C <- rnorm(1, mean = 0, sd = sigma)
      delta_DB <- delta_DB + epsilon_B
      delta_DC <- delta_DC + epsilon_C
    }
    
    # Calculate deterministic prepayment terms
    delta_PA <- -theta * delta_DA
    delta_PB <- (-gamma * delta_DA) + (-theta * delta_DB)
    delta_PC <- (-delta * (delta_DA + delta_DB)) + (-theta * delta_DC)
    
    # Add stochastic terms to prepayment if enabled
    if (stochastic) {
      eta_B <- rnorm(1, mean = 0, sd = sigma)
      eta_C <- rnorm(1, mean = 0, sd = sigma)
      nu_A <- rnorm(1, mean = 0, sd = sigma)
      nu_B <- rnorm(1, mean = 0, sd = sigma)
      nu_C <- rnorm(1, mean = 0, sd = sigma)
      
      delta_PA <- delta_PA + nu_A
      delta_PB <- delta_PB + eta_B + nu_B
      delta_PC <- delta_PC + eta_C + nu_C
    }
    
    # Return results as a data frame
    data.frame(
      SES = c("A", "B", "C"),
      DefaultChange = c(delta_DA, delta_DB, delta_DC),
      PrepayChange = c(delta_PA, delta_PB, delta_PC)
    )
  })
}

# Function to plot results
plot_shock_results <- function(df, title) {
  p_default <- ggplot(df, aes(x = SES, y = DefaultChange, fill = SES)) +
    geom_col() +
    ggtitle(paste("Default Rate Propagation:", title)) +
    theme_minimal()
  
  p_prepay <- ggplot(df, aes(x = SES, y = PrepayChange, fill = SES)) +
    geom_col() +
    ggtitle(paste("Prepayment Rate Changes:", title)) +
    theme_minimal()
  
  gridExtra::grid.arrange(p_default, p_prepay, ncol = 2)
}
plot_sensitivity_results <- function(sensitivity_data, title){
  # Plot sensitivity results
  ggplot(sensitivity_data, aes(x = SES_A_Shock, color = SES)) +
    geom_line(aes(y = DefaultChange, linetype = "Default")) +
    geom_line(aes(y = PrepayChange, linetype = "Prepayment")) +
    facet_wrap(~SES, scales = "free_y") +
    labs(title = paste0("Sensitivity to SES A Default Shocks ( ", title, " )"),
         x = "SES A Default Shock",
         y = "Rate Change") +
    theme_minimal()
  
}


# Mini version tools
# Function to find yield based on WAL
get_yield <- function(wal) {
  yield_curve$Yield[which.min(abs(yield_curve$Maturity - wal))]
}

# Function to simulate mortgages
generate_mortgage_pool <- function(n, mean_loan, sd_loan, mean_rate, sd_rate, mean_term, sd_term, default_rate, prepay_rate, SES) {
  data.frame(
    LoanID = 1:n,
    LoanAmount = rnorm(n, mean_loan, sd_loan),
    InterestRate = rnorm(n, mean_rate, sd_rate),
    LoanTerm = rnorm(n, mean_term, sd_term),
    DefaultRate = default_rate,
    PrepayRate = prepay_rate,
    SES = SES
  ) %>%
    mutate(UID = paste0(SES, "-", LoanID))
}

# Function to adjust default and prepayment rates
dynamic_adjustment <- function(pool, sensitivity_data, shock_level) {
  adj_data <- sensitivity_data %>% filter(SES_A_Shock == shock_level)
  
  for (ses in c("A", "B", "C")) {
    delta_default <- adj_data %>% filter(SES == ses) %>% pull(DefaultChange)
    delta_prepay <- adj_data %>% filter(SES == ses) %>% pull(PrepayChange)
    
    pool <- pool %>% mutate(
      DefaultRate = ifelse(SES == ses, DefaultRate + delta_default, DefaultRate),
      PrepayRate = ifelse(SES == ses, pmax(0, pmin(1, PrepayRate + delta_prepay)), PrepayRate) # Ensure [0,1] bounds
    )
  }
  return(pool)
}

# Function to compute cash flows, PV, WAL, Effective Yield, and Fair Market Price
compute_cash_flows <- function(pool) {
  pool <- pool %>% mutate(
    MonthlyPayment = (LoanAmount * InterestRate / 12) / (1 - (1 + InterestRate / 12)^(-LoanTerm * 12)),
    ExpectedCashFlow = (1 - DefaultRate) * (1 - PrepayRate) * MonthlyPayment,
    DiscountRate = sapply(LoanTerm, get_yield),
    PV_CashFlow = ExpectedCashFlow / (1 + DiscountRate)^(LoanTerm)
  )
  
  # Compute Weighted Average Life (WAL)
  pool <- pool %>% mutate(
    WAL = (LoanTerm * ExpectedCashFlow) / sum(ExpectedCashFlow)
  )
  
  # Compute Effective Yield
  pool <- pool %>% mutate(
    EffectiveYield = (sum(ExpectedCashFlow) / sum(PV_CashFlow))^(1 / mean(LoanTerm)) - 1
  )
  
  # Compute Par Value of MBS
  par_value <- sum(pool$LoanAmount)
  
  # Compute Fair Market Price based on risk-adjusted yield
  pool_summary <- pool %>%
    group_by(SES) %>%
    summarise(
      TotalCashFlow = sum(ExpectedCashFlow),
      PV_TotalCashFlow = sum(PV_CashFlow),
      WAL = sum(WAL),
      EffectiveYield = mean(EffectiveYield),
      ParValue = par_value,
      RiskAdjYield = case_when(
        SES == "A" ~ get_yield(mean(WAL)) + 0.005,  # Senior Tranche
        SES == "B" ~ get_yield(mean(WAL)) + 0.02,   # Mezzanine Tranche
        SES == "C" ~ get_yield(mean(WAL)) + 0.05    # Junior Tranche
      ),
      FairMarketPrice = PV_TotalCashFlow / (1 + RiskAdjYield)^WAL
    )
  
  return(pool_summary)
}
