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



# Inspect results
sum(SES_A$PrepayFlag)
sum(SES_A$DefaultFlag)

sum(SES_B$PrepayFlag)
sum(SES_B$DefaultFlag)

sum(SES_C$PrepayFlag)
sum(SES_C$DefaultFlag)


# Step 2: Cash flow modeling 
test <- aggregate_cash_flows(pool_of_contracts)

# Aggregate View with Smoothing
ggplot(test$total_cash_flows, aes(x = Date, y = TotalCashFlow)) +
  geom_line(color = "#1f77b4", size = 0.8) +
  geom_smooth(method = "loess", span = 0.2, color = "#ff7f0e", se = FALSE) +
  labs(title = "Portfolio Cash Flow Trends", 
       subtitle = "With LOESS Smoothing",
       x = "Date", y = "Total Cash Flow") +
  theme_minimal(base_size = 12)


library(tidyr)
library(ggplot2)
library(scales)
library(stringr)

# 1. Stacked Area Chart (Capital vs Interest)
test$total_cash_flows %>%
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

# 2. Cumulative Payment Waterfall
cumulative_plot <- test$total_cash_flows %>%
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

# 3. Proportional Donut Chart (Overall Portfolio)
total_payments <- test$total_cash_flows %>%
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

