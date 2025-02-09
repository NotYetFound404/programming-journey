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
    adjusted_schedule$UID <- loan$LoanID
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
