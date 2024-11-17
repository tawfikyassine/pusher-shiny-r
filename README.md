code to send event from server to pusher server which then will be sent to the web client
# server side
```r
# Load required libraries
library(digest)
library(jsonlite)
library(httr)
library(openssl)

# sourcefunction to send events
source("send_pusher_event.R", local = TRUE)$value

# Define the pusher configuration as a list
pusher <- list(
  cluster = "eu",
  app_id = "app key",
  key = "key",
  secret = "secret",
  channel = "channel name"
)

# Call the function using the pusher configuration
send_pusher_event(
  cluster = pusher$cluster,
  app_id = pusher$app_id,
  key = pusher$key,
  secret = pusher$secret,
  channel = pusher$channel,
  event_name = "job_finished", # Example event name
  list_data = list(progress = 20, details = "job finished successfully.") # Example data (optional)
)
```
# client side 
