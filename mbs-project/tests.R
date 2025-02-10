library(testthat)
source("utils.r")


# # Sanity check (should go in main)
# sum(SES_A$PrepayFlag) == round(0.10*contracts_per_SES) & sum(SES_A$DefaultFlag) == 0.02*contracts_per_SES
# sum(SES_B$PrepayFlag) == round(0.035*contracts_per_SES) & sum(SES_B$DefaultFlag) == round(0.05*contracts_per_SES)
# sum(SES_C$PrepayFlag) == round(0.01*contracts_per_SES) & sum(SES_C$DefaultFlag) == round(0.08*contracts_per_SES)

# Create test data
test_loan <- data.frame(
  LoanID = 1,
  LoanAmount = 100000,
  InterestRate = 0.05,  # 5% annual rate
  Term = 5,             # 5 years
  DefaultFlag = 0,
  DefaultMonth = NA,
  PrepayFlag = 0,
  PrepayMonth = NA,
  SES = "A",
  UID = "A-1"
)

describe("calculate_monthly_payment", {
  it("calculates correct monthly payment for standard loan", {
    payment <- calculate_monthly_payment(100000, 0.05, 5)
    expected_payment <- 1887.12  # Pre-calculated value
    expect_equal(payment, expected_payment, tolerance = 0.01)
  })
  
  it("handles edge cases correctly", {
    expect_equal(calculate_monthly_payment(0, 0.05, 5), 0)  # Zero loan amount
    expect_error(calculate_monthly_payment(100000, 0, 5), 
                 "Zero interest rate not accepted")  # Zero interest rate should error
  })
})

describe("generate_amort_schedule", {
  schedule <- generate_amort_schedule(test_loan)
  
  it("generates correct number of payments", {
    expect_equal(nrow(schedule), 60)  # 5 years * 12 months
  })
  
  it("ensures balance decreases over time", {
    expect_true(all(diff(schedule$Balance) <= 0))
  })
  
  it("results in final balance close to zero", {
    expect_true(abs(tail(schedule$Balance, 1)) < 1e-6)
  })
  
  it("all principal payment equals loan amount", {
    expect_true((100000- sum(schedule$PrincipalPayment))< 1e-10 )
  })
  
  
  it("maintains payment composition", {
    monthly_payment <- calculate_monthly_payment(test_loan$LoanAmount, 
                                                 test_loan$InterestRate, 
                                                 test_loan$Term)
    payment_diff <- abs(schedule$InterestPayment + 
                          schedule$PrincipalPayment - 
                          monthly_payment)
    expect_true(all(payment_diff < 1e-6))
  })
})

describe("adjust_cash_flows", {
  it("handles default case correctly", {
    default_loan <- test_loan
    default_loan$DefaultMonth <- 24
    default_loan$DefaultFlag <- 1
    
    default_schedule <- generate_amort_schedule(default_loan)
    adjusted_default <- adjust_cash_flows(default_schedule, default_loan)
    
    expect_equal(nrow(adjusted_default), 24)
    expect_equal(adjusted_default$Balance[24], 0)
    expect_false((100000- sum(adjusted_default$PrincipalPayment))< 1e-10 )
    
  })
  
  it("handles prepayment case correctly", {
    prepay_loan <- test_loan
    prepay_loan$PrepayMonth <- 36
    prepay_loan$PrepayFlag <- 1
    
    prepay_schedule <- generate_amort_schedule(prepay_loan)
    adjusted_prepay <- adjust_cash_flows(prepay_schedule, prepay_loan)
    
    expect_equal(nrow(adjusted_prepay), 36)
    expect_equal(adjusted_prepay$Balance[36], 0)
    expect_true( (100000- sum(adjusted_prepay$PrincipalPayment))< 1e-10 )
  })
})

describe("aggregate_cash_flows", {
  # Create test data
  test_loan <- data.frame(
    LoanID = 1,
    LoanAmount = 100000,
    InterestRate = 0.05,  # 5% annual rate
    Term = 5,             # 5 years
    DefaultFlag = 0,
    DefaultMonth = NA,
    PrepayFlag = 0,
    PrepayMonth = NA,
    SES = "A",
    UID = "A-1"
  )
  
  
  test_pool <- rbind(test_loan, test_loan)
  test_pool$LoanID <- 1:2
  test_pool$UID <- c("A-1", "A-2")
  result <- aggregate_cash_flows(test_pool)
  schedule <- generate_amort_schedule(test_loan)
  
  
  
  # Check later...
  # it("amortization schedule for one loan should equal same in pool", {
  #   expect_equal(result$all_schedules[1], schedule)
  # })
  
  
  it("returns correct structure", {
    expect_true(is.list(result))
    expect_true(all(c("all_schedules", "total_cash_flows") %in% names(result)))
  })
  
  it("calculates correct total cash flows", {
    total_flows <- result$total_cash_flows
    expect_equal(total_flows$TotalCashFlow,
                 total_flows$TotalPrincipal + total_flows$TotalInterest)
  })
  
  it("preserves individual schedules", {
    expect_equal(length(result$all_schedules), nrow(test_pool))
  })
})

