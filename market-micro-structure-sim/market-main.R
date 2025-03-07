library(data.table)
library(ggplot2)

# PHASE 1: Define Core Data Structures
# ------------------------------------

# Order Book Structure
order_book <- data.table(
  price = numeric(),
  quantity = numeric(),
  order_type = character(),  # "bid" or "ask"
  order_id = integer(),
  timestamp = as.POSIXct(character())
)

# Trade Execution Log
trade_log <- data.table(
  trade_id = integer(),
  timestamp = as.POSIXct(character()),
  trade_price = numeric(),
  trade_volume = numeric(),
  trade_type = character()  # "buy" or "sell"
)

# Market State Variables
market_state <- list(
  current_price = 60000,
  best_bid = NA,
  best_ask = NA,
  spread = NA,
  liquidity_depth = list()
)

# PHASE 2: Initialize the Market
# -------------------------------

set.seed(123)  # For reproducibility

# Function to generate initial order book
initialize_order_book <- function(initial_price, num_orders = 100) {
  bids <- data.table(
    price = sort(runif(num_orders / 2, initial_price * 0.98, initial_price), decreasing = TRUE),
    quantity = runif(num_orders / 2, 0.01, 5),
    order_type = "bid",
    order_id = 1:(num_orders / 2),
    timestamp = 1
  )
  
  asks <- data.table(
    price = sort(runif(num_orders / 2, initial_price, initial_price * 1.02)),
    quantity = runif(num_orders / 2, 0.01, 5),
    order_type = "ask",
    order_id = (num_orders / 2 + 1):num_orders,
    timestamp = 1
  )
  
  return(rbind(bids, asks))
}

# Initialize Order Book
total_orders <- 200
order_book <- initialize_order_book(market_state$current_price, total_orders)

# Update Market State
market_state$best_bid <- max(order_book[order_type == "bid"]$price)
market_state$best_ask <- min(order_book[order_type == "ask"]$price)
market_state$spread <- market_state$best_ask - market_state$best_bid

# Visualization: Order Book Depth
plot_order_book <- function(order_book) {
  ggplot(order_book, aes(x = price, y = quantity, fill = order_type)) +
    geom_bar(stat = "identity", position = "stack", alpha = 0.7) +
    scale_fill_manual(values = c("bid" = "blue", "ask" = "red")) +
    labs(title = "Initial Order Book Depth", x = "Price", y = "Quantity") +
    theme_minimal()
}

# Plot Order Book Depth
plot_order_book(order_book)

# PHASE 3: Simulate Order Flow
# -----------------------------

# Function to generate limit orders
generate_limit_order <- function(price, quantity, order_type, order_id) {
  data.table(
    price = price,
    quantity = quantity,
    order_type = order_type,
    order_id = order_id,
    timestamp = Sys.time()
  )
}

# Function to generate market orders
generate_market_order <- function(order_type, quantity) {
  data.table(
    trade_id = nrow(trade_log) + 1,
    timestamp = Sys.time(),
    trade_price = ifelse(order_type == "buy", market_state$best_ask, market_state$best_bid),
    trade_volume = quantity,
    trade_type = order_type
  )
}

# PHASE 4: Order Matching & Execution
# ------------------------------------

# Function to execute market orders
library(dplyr)

execute_market_order <- function(order_type, quantity) {
  print("=== Executing Market Order ===")
  print(paste("Order Type:", order_type, "| Quantity:", quantity, "BTC"))
  
  remaining_quantity <- quantity  # Track how much is still needed
  
  while (remaining_quantity > 0) {
    if (order_type == "buy") {
      best_order_index <- which.min(order_book[order_type == "ask", price])
      best_order <- order_book[order_type == "ask"][best_order_index]
    } else {
      best_order_index <- which.max(order_book[order_type == "bid", price])
      best_order <- order_book[order_type == "bid"][best_order_index]
    }
    
    if (nrow(best_order) == 0) {
      print("❌ No more matching limit orders available.")
      break  # Exit if no more orders to match
    }
    
    trade_volume <- min(remaining_quantity, best_order$quantity)
    trade_price <- best_order$price
    
    print(paste("✅ Matched with order at", trade_price, "for", trade_volume, "BTC"))
    
    # Record the trade
    new_trade <- data.table(
      trade_id = ifelse(nrow(trade_log) == 0, 1, max(trade_log$trade_id) + 1),
      timestamp = Sys.time(),
      trade_price = trade_price,
      trade_volume = trade_volume,
      trade_type = order_type
    )
    
    trade_log <<- rbind(trade_log, new_trade)
    
    # Update Order Book
    if (trade_volume == best_order$quantity) {
      order_book <<- order_book[-best_order_index, ]  # Fully filled -> remove
      print("✅ Order fully filled and removed from order book.")
    } else {
      order_book[best_order_index, quantity := quantity - trade_volume]  # Partial fill
      print(paste("✅ Order partially filled. Remaining:", order_book[best_order_index, quantity], "BTC"))
    }
    
    # Reduce remaining quantity
    remaining_quantity <- remaining_quantity - trade_volume
  }
  
  print("✅ Trade execution complete!")
  print("Updated Order Book:")
  print(order_book)
  print("Updated Trade Log:")
  print(trade_log)
  print("==============================")
}

# ------------
#Example: A market buy order for 1 BTC
# 🟢 

print(sum(order_book$quantity))
print(order_book)

execute_market_order("buy", 50)  # Should fill multiple orders
print(sum(order_book$quantity))  # Should decrease accordingly
plot_order_book(order_book)  # Should reflect order removal
#To do: check why I have a negative quantity :C

#Example: executing a limit buy and sell order Net zero
# 🟢 
# Add a limit buy order
new_limit_order <- data.table(
  price = 50500,
  quantity = 2,
  order_type = "bid",
  order_id = max(order_book$order_id, na.rm = TRUE) + 1,
  timestamp = Sys.time()
)
order_book <- rbind(order_book, new_limit_order)

market_state$current_price
