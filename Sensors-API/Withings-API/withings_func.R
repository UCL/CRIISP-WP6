
# Function to request a new authorization code and exchange it for tokens
request_new_tokens <- function() {
    auth_url <- ""
    scopes <- "user.metrics,user.info,user.activity"
    
    auth_url <- paste0(
      "https://account.withings.com/oauth2_user/authorize2?",
      "response_type=code",
      "&client_id=", client_id,
      "&scope=", URLencode(scopes),
      "&redirect_uri=", URLencode(CallBackURL),
      "&state=", "asdf1234"
    )
    
    browseURL(auth_url)
  
    authCode <- readline(prompt = "Enter the authorization code from the redirect URL: ")
  
    paramsRet <- list(
      action = 'requesttoken',
      grant_type = 'authorization_code',
      client_id = client_id,
      client_secret = client_secret,
      code = authCode,
      redirect_uri = CallBackURL
    )
  
    response <- POST(TokenURL, body = paramsRet, encode = "form")
    tokens <- httr::content(response, as = "parsed", type = "application/json")
  
    access_token<-tokens$body$access_token
    refresh_token<-tokens$body$refresh_token
  
    # Save new tokens back to the configuration file
    writeLines(c(
      paste0('client_id <- "', client_id, '"'),
      paste0('client_secret <- "', client_secret, '"'),
      paste0('refresh_token <- "', refresh_token, '"')
    ), Participant_id)
    
    return(list(access_token = access_token, refresh_token = refresh_token))
}

# Function to refresh the existing token
refresh_existing_token <- function(refresh_token) {
  paramsRef <- list(
    action = 'requesttoken',
    grant_type = 'refresh_token',
    client_id = client_id,
    client_secret = client_secret,
    refresh_token = refresh_token
  )
  
  response <- POST(TokenURL, body = paramsRef, encode = "form")
  tokens <- httr::content(response, as = "parsed", type = "application/json")
  
  access_token<-tokens$body$access_token
  refresh_token<-tokens$body$refresh_token
  
  # Save new refresh token back to the configuration file if it has changed
  writeLines(c(
    paste0('client_id <- "', client_id, '"'),
    paste0('client_secret <- "', client_secret, '"'),
    paste0('refresh_token <- "', refresh_token, '"')
  ), Participant_id)
  
  return(list(access_token = access_token, refresh_token = refresh_token))
}

convert_to_ISOdate <- function(col_name) {
  if (grepl("\\.\\d{10}$", col_name)) {
    #extract the datafield name
    date_field<- sub("\\..*$", "", col_name)
    # Extract the Unix timestamp from the column name
    timestamp <- as.numeric(sub(".*\\.", "", col_name))
    
    # Convert the Unix timestamp to a human-readable date
    date <- as.POSIXct(timestamp, origin = "1970-01-01", tz = "")
    
    # Create a new column name with the human-readable date
    new_col_name <- paste0(date_field,".",format(date, format = "%Y%m%d-%H:%M:%S"))
    
    return(new_col_name)
  } else {
    return(col_name)
  }
}

convert_date <- function(date, output_type = c("numeric", "Date"), tz="") {
  
  output_type <- match.arg(output_type, c("numeric", "Date"))
  
  # Always convert from character to date
  if( any(class(date) == "character" )) { date = as.Date(date) }
  
  if( output_type == "numeric" ) {
    
    # If to numeric, date --> POSIXct --> numeric
    
    if( any(class(date) == "Date" )) { date = as.POSIXct(date, tz=tz,
                                                         origin="1970-01-01") }
    if( any(class(date) == "POSIXct")) { date = as.numeric(date) }
    
  } else if( output_type == "Date" ) {
    
    # If to date, POSIXct --> Date
    
    if( any(class(date) == "POSIXct")) { date = as.Date(date) }
    
  }
  
  return(date)
}

#process ECG data into a DF
process_data <- function(out) {
  if (out$status == 0) {
    # Generate timestamps
    start_date <- as.POSIXct(out$body$heart_rate$date, origin = "1970-01-01", tz = "UTC")
    timestamps <- seq(from = start_date, by = 1/out$body$sampling_frequency, length.out = length(out$body$signal))
    
    # Create a dataframe
    df <- tibble::tibble(
      Timestamp = timestamps,
      Value = out$body$signal
    )
    return(df)
  } else {
    stop("Status is not 0")
  }
}

