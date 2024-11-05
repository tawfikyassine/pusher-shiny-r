library(shiny)
library(httr)
library(digest)  # For generating HMAC signature
library(dplyr)
library(jsonlite)

# Replace these with your Pusher credentials
pusher_app_id <- "YOUR_APP_ID"
pusher_key <- "YOUR_APP_KEY"
pusher_secret <- "YOUR_APP_SECRET"
pusher_cluster <- "YOUR_APP_CLUSTER"

# make any channel name like public.username
pusher_channel <- "any-channel-name"

# Function to send an event using the Pusher REST API
send_pusher_event <- function(event_name="default", list_data = list()) {
  # Pusher API endpoint
  url <- paste0("https://api-", pusher_cluster, ".pusher.com/apps/", pusher_app_id, "/events")
  
  # Data payload
  data <- list(
    name = event_name,
    channels = list(pusher_channel),
    data = toJSON(list_data, auto_unbox = TRUE)
  )
  
  # JSON-encoded body as a string for hashing
  data_json <- toJSON(data, auto_unbox = TRUE)
  body_md5 <- digest::digest(data_json, algo = "md5", serialize = FALSE)
  
  # Timestamp and authentication signature
  timestamp <- as.integer(Sys.time())
  auth_signature <- digest::hmac(
    pusher_secret,
    paste0(
      "POST\n/apps/", pusher_app_id, "/events\n",
      "auth_key=", pusher_key, "&auth_timestamp=", timestamp,
      "&auth_version=1.0&body_md5=", body_md5
    ),
    algo = "sha256"
  )
  
  # Query parameters
  query <- list(
    auth_key = pusher_key,
    auth_timestamp = timestamp,
    auth_version = "1.0",
    body_md5 = body_md5,
    auth_signature = auth_signature
  )
  
  # Send request with Content-Type header
  response <- httr::POST(
    url,
    query = query,
    body = data_json,
    encode = "json",
    add_headers(`Content-Type` = "application/json")
  )
  
  # Check response
  if (httr::status_code(response) == 200) {
    return(TRUE)
  } else {
    print(httr::content(response, as = "text"))
    return(FALSE)
  }
}

ui <- fluidPage(
  tags$head(
    # Include the Pusher JavaScript library
    tags$script(src = "https://js.pusher.com/7.0/pusher.min.js"),
    # JavaScript to listen for Pusher events
    tags$script(HTML(sprintf("
      // Configure Pusher
      var pusher = new Pusher('%s', {
        cluster: '%s',
        encrypted: true
      });

      // Subscribe to the channel and bind event
      var channel = pusher.subscribe('%s');
      channel.bind('any-event-name', function(data) {
        alert('Received event: ' + data.message);
      });
    ", pusher_key, pusher_cluster, pusher_channel)))
  ),
  
  # App UI
  actionButton("send_event", "Send Event")
)

server <- function(input, output, session) {
  observeEvent(input$send_event, {
    # data is optional
    # by default it is :
    data <- list()
    #but you can pass any data you want to the client side like :
    data <- list(message = "hi how are you", test = TRUE, my_best_variable=":)")
    # Trigger event via Pusher REST API
    send_pusher_event(event_name= "any-event-name", data)
  })
}

shinyApp(ui = ui, server = server)
