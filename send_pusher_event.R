# Load required libraries
library(digest)
library(jsonlite)
library(httr)
library(openssl)

send_pusher_event <- function(cluster, app_id, key, secret, channel, event_name = "update_in_job", list_data = list()) {
  # Input variables
  auth_timestamp <- as.character(as.integer(Sys.time()))
  auth_version <- "1.0"
  
  # Convert the data list to JSON
  data_json <- toJSON(list_data, auto_unbox = TRUE)
  data_json <- gsub('"', '\\\\"', data_json)
  
  # Create the body using the variables
  body <- sprintf('{"name":"%s","channels":["%s"],"data":"%s"}', event_name, channel, data_json)
  
  # Generate MD5 hash of the body
  body_md5 <- digest(body, algo = "md5", serialize = FALSE)
  
  # Create the string to sign
  string_to_sign <- paste0(
    "POST\n/apps/", app_id,
    "/events\nauth_key=", key,
    "&auth_timestamp=", auth_timestamp,
    "&auth_version=", auth_version,
    "&body_md5=", body_md5
  )
  
  # Generate HMAC-SHA256 auth signature
  auth_signature <- sha256(string_to_sign, secret)
  
  # API URL
  url <- sprintf(
    "http://api-%s.pusher.com/apps/%s/events?auth_key=%s&auth_timestamp=%s&auth_version=%s&body_md5=%s&auth_signature=%s",
    cluster, app_id, key, auth_timestamp, auth_version, body_md5, auth_signature
  )
  
  # Make the HTTP POST request
  response <- POST(
    url = url,
    body = body,
    encode = "json",
    add_headers(`Content-Type` = "application/json")
  )
  
  # Check the response status
  if (http_status(response)$category == "Success") {
    cat("Request successful!\n")
    print(content(response, "text"))
    return(TRUE)
  } else {
    cat("Request failed with status:", http_status(response)$message, "\n")
    print(content(response, "text"))
    return(FALSE)
  }
}


# Define the pusher configuration as a list
pusher <- list(
  cluster = "eu",
  app_id = "app id",
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
  list_data = list(progress = 20, details = "job finished successfully.") # Example data
)
  
