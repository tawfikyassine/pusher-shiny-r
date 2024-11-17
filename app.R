library(shiny)
library(httr)
library(digest)  # For generating HMAC signature
library(dplyr)
library(jsonlite)
library(openssl)

# sourcefunction to send events
source("send_pusher_event.R", local = TRUE)$value

# Replace these with your Pusher credentials
pusher <- list(
  cluster = "eu",
  app_id = "app key",
  key = "key",
  secret = "secret",
  channel = "channel name"
)

ui <- fluidPage(
  tags$head(
    # Include the Pusher JavaScript library
    tags$script(src = "https://js.pusher.com/8.2.0/pusher.min.js"),
    # JavaScript to listen for Pusher events
    tags$script(HTML(sprintf("
      // Configure Pusher
      var pusher = new Pusher('%s', {
        cluster: '%s'
      });

      // Subscribe to the channel and bind event
      var channel = pusher.subscribe('%s');
      channel.bind('any-event-name', function(data) {
        alert(JSON.stringify(data));
      });
    ", pusher$key, pusher$cluster, pusher$channel)))
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
