# # v1---------------
# library(ggplot2)
# library(data.table)
# 
# MarketSimulation <- function(initial_price = 100, time_steps = 120) {
#   order_book <- list(
#     bids = data.table(price = numeric(), volume = numeric()),
#     asks = data.table(price = numeric(), volume = numeric())
#   )
#   
#   price_history <- data.table(
#     time = integer(),
#     price = numeric(),
#     bid = numeric(),
#     ask = numeric(),
#     volume = numeric()
#   )
#   
#   current_price <- initial_price
#   
#   generate_orders <- function() {
#     n_orders <- sample(5:15, 1)
#     
#     # Generate limit buy orders close to market price
#     buy_prices <- rnorm(n_orders, mean = current_price * 0.99, sd = current_price * 0.01)
#     buy_volumes <- runif(n_orders, 10, 100)
#     
#     # Generate limit sell orders close to market price
#     sell_prices <- rnorm(n_orders, mean = current_price * 1.01, sd = current_price * 0.01)
#     sell_volumes <- runif(n_orders, 10, 100)
#     
#     # Add to order book
#     order_book$bids <<- rbind(order_book$bids, data.table(price = buy_prices, volume = buy_volumes))
#     order_book$asks <<- rbind(order_book$asks, data.table(price = sell_prices, volume = sell_volumes))
#     
#     # Sort bids (descending) and asks (ascending)
#     setorder(order_book$bids, -price)
#     setorder(order_book$asks, price)
#   }
#   
#   auction_match <- function() {
#     if (nrow(order_book$bids) == 0 || nrow(order_book$asks) == 0) {
#       return(list(price = current_price, volume = 0))
#     }
#     
#     # Best bid and ask
#     best_bid <- order_book$bids$price[1]
#     best_ask <- order_book$asks$price[1]
#     
#     if (best_bid >= best_ask) {
#       # Trade happens at midpoint
#       trade_price <- (best_bid + best_ask) / 2
#       trade_volume <- min(order_book$bids$volume[1], order_book$asks$volume[1])
#       
#       # Remove matched orders
#       order_book$bids <- order_book$bids[-1]
#       order_book$asks <- order_book$asks[-1]
#       
#       return(list(price = trade_price, volume = trade_volume))
#     } else {
#       return(list(price = current_price, volume = 0))
#     }
#   }
#   
#   step <- function(t) {
#     generate_orders()
#     
#     result <- auction_match()
#     trade_price <- result$price
#     trade_volume <- result$volume
#     
#     if (!is.na(trade_price)) {
#       current_price <<- trade_price
#     }
#     
#     # Record market state
#     best_bid <- if (nrow(order_book$bids) > 0) order_book$bids$price[1] else NA
#     best_ask <- if (nrow(order_book$asks) > 0) order_book$asks$price[1] else NA
#     
#     price_history <<- rbind(
#       price_history,
#       data.table(
#         time = t,
#         price = current_price,
#         bid = best_bid,
#         ask = best_ask,
#         volume = trade_volume
#       )
#     )
#   }
#   
#   simulate <- function() {
#     for (t in 1:time_steps) {
#       step(t)
#     }
#     price_history
#   }
#   
#   list(simulate = simulate)
# }
# 
# # Run Simulation
# set.seed(42)
# sim <- MarketSimulation(initial_price = 100)
# results <- sim$simulate()
# 
# # Visualization
# ggplot(results, aes(x = time)) +
#   geom_line(aes(y = price), color = "blue") +
#   geom_ribbon(aes(ymin = bid, ymax = ask), alpha = 0.2, fill = "grey") +
#   geom_point(aes(y = price, size = volume), color = "darkblue", alpha = 0.5) +
#   labs(title = "Auction-Based Market Simulation - Price", x = "Time", y = "Price") +
#   theme_minimal()
# 
# # v2---------------
# 
# # Version 2: Market Simulation with Market Impact
# 
# library(ggplot2)
# library(data.table)
# 
# MarketSimulationV2 <- function(initial_price = 100, time_steps = 120, impact_factor = 0.0001) {
#   order_book <- list(
#     bids = data.table(price = numeric(), volume = numeric()),
#     asks = data.table(price = numeric(), volume = numeric())
#   )
#   
#   price_history <- data.table(
#     time = integer(),
#     price = numeric(),
#     bid = numeric(),
#     ask = numeric(),
#     volume = numeric()
#   )
#   
#   current_price <- initial_price
#   
#   generate_orders <- function() {
#     n_orders <- sample(5:15, 1)
#     
#     buy_prices <- rnorm(n_orders, mean = current_price * 0.99, sd = current_price * 0.01)
#     buy_volumes <- runif(n_orders, 10, 100)
#     
#     sell_prices <- rnorm(n_orders, mean = current_price * 1.01, sd = current_price * 0.01)
#     sell_volumes <- runif(n_orders, 10, 100)
#     
#     order_book$bids <<- rbind(order_book$bids, data.table(price = buy_prices, volume = buy_volumes))
#     order_book$asks <<- rbind(order_book$asks, data.table(price = sell_prices, volume = sell_volumes))
#     
#     setorder(order_book$bids, -price)
#     setorder(order_book$asks, price)
#   }
#   
#   auction_match <- function() {
#     if (nrow(order_book$bids) == 0 || nrow(order_book$asks) == 0) {
#       return(list(price = current_price, volume = 0))
#     }
#     
#     best_bid <- order_book$bids$price[1]
#     best_ask <- order_book$asks$price[1]
#     
#     if (best_bid >= best_ask) {
#       trade_volume <- min(order_book$bids$volume[1], order_book$asks$volume[1])
#       price_impact <- impact_factor * trade_volume
#       
#       trade_price <- if (order_book$bids$volume[1] > order_book$asks$volume[1]) {
#         (best_bid + best_ask) / 2 + price_impact
#       } else {
#         (best_bid + best_ask) / 2 - price_impact
#       }
#       
#       if (order_book$bids$volume[1] > order_book$asks$volume[1]) {
#         order_book$bids$volume[1] <- order_book$bids$volume[1] - trade_volume
#         order_book$asks <- order_book$asks[-1]
#       } else {
#         order_book$asks$volume[1] <- order_book$asks$volume[1] - trade_volume
#         order_book$bids <- order_book$bids[-1]
#       }
#       
#       order_book$bids <- order_book$bids[volume > 0]
#       order_book$asks <- order_book$asks[volume > 0]
#       
#       return(list(price = trade_price, volume = trade_volume))
#     } else {
#       return(list(price = current_price, volume = 0))
#     }
#   }
#   
#   step <- function(t) {
#     generate_orders()
#     
#     result <- auction_match()
#     trade_price <- result$price
#     trade_volume <- result$volume
#     
#     if (!is.na(trade_price)) {
#       current_price <<- trade_price
#     }
#     
#     best_bid <- if (nrow(order_book$bids) > 0) order_book$bids$price[1] else NA
#     best_ask <- if (nrow(order_book$asks) > 0) order_book$asks$price[1] else NA
#     
#     price_history <<- rbind(
#       price_history,
#       data.table(
#         time = t,
#         price = current_price,
#         bid = best_bid,
#         ask = best_ask,
#         volume = trade_volume
#       )
#     )
#   }
#   
#   simulate <- function() {
#     for (t in 1:time_steps) {
#       step(t)
#     }
#     price_history
#   }
#   
#   list(simulate = simulate)
# }
# 
# set.seed(55)
# sim_v2 <- MarketSimulationV2(initial_price = 100, impact_factor = 0.25)
# results_v2 <- sim_v2$simulate()
# 
# ggplot(results_v2, aes(x = time)) +
#   geom_line(aes(y = price), color = "blue") +
#   geom_ribbon(aes(ymin = bid, ymax = ask), alpha = 0.2, fill = "grey") +
#   geom_point(aes(y = price, size = volume), color = "darkblue", alpha = 0.5) +
#   labs(title = "Market Impact Simulation - Price (v2)", x = "Time", y = "Price") +
#   theme_minimal()
# 
