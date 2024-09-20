###############################################################################
###############################################################################
####  BEGIN OF OAUTH FUNCTIONS
###############################################################################
###############################################################################

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

###############################################################################
###############################################################################
########################################  END OF OAUTH FUNCTIONS
###############################################################################
###############################################################################

###############################################################################
###############################################################################
####  BEGIN OF TIMESTAMPS FUNCTIONS
###############################################################################
###############################################################################

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

###############################################################################
###############################################################################
########################################  END OF TIMESTAMPS FUNCTIONS
###############################################################################
###############################################################################

###############################################################################
###############################################################################
####  BEGIN OF ECG FUNCTIONS
###############################################################################
###############################################################################



#process ECG data into a DF
process_data <- function(out) {
  if (out$status == 0) {
    # Generate timestamps
    start_date <- as.POSIXct(out$body$heart_rate$date, origin = "1970-01-01", tz = "UTC")
    timestamps <- seq(from = 0, by = 1/out$body$sampling_frequency, length.out = length(out$body$signal))
     # Create a dataframe
    df <- tibble::tibble(
      start_date = start_date,
      Timestamp = timestamps,
      Value = out$body$signal
    )
    return(df)
  } else {
    stop("Status is not 0")
  }
}

#fetch all ECG data and store into a list of DF
fetch_ecg_signals <- function(ecg.signalIDs, access_token) {
  ecg_list <- list()  # Initialize an empty list to store the ECG dataframes
  
  for (i in seq_along(ecg.signalIDs)) {
    # Fetch the ECG data for the current signalid
    req <- httr::GET(url = "https://wbsapi.withings.net/v2/heart", 
                     query = list(access_token = access_token, 
                                  action = "get", signalid = ecg.signalIDs[i]))
    httr::stop_for_status(req)  # Stop if there's an error in the API request
    
    # Extract and process the API response
    out <- httr::content(req, as = "text", encoding = "utf-8")
    out <- jsonlite::fromJSON(out)
    
    ECGraw.date<-as.POSIXct(out$body$heart_rate$date, tz = "", 
                            origin = "1970-01-01") %>% format("%d/%m/%Y %H:%M%:%S")
    # Process the raw ECG data and store in the list
    ecg_list[[i]] <- process_data(out)
    
    # Optionally print progress
    print(paste("Fetched and processed ECG signal", i, "of", length(ecg.signalIDs)))
  }
  
  return(ecg_list)  # Return the list of ECG dataframes
}
###############################################################################
###############################################################################
########################################  END OF ECG FUNCTIONS
###############################################################################
###############################################################################

###############################################################################
###############################################################################
####    BEGIN OF INTRADAY ACTIVITY FUNCTIONS
###############################################################################
###############################################################################


# Function to fetch intraday activity for a single day
fetch_intraday_activity <- function(access_token, date, data_fields) {
  # Convert the date to Unix timestamps for the start and end of the day
  UnixStartDay <- as.POSIXct(paste(date, "00:00:00"), format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
  UnixStartDay <- as.numeric(unclass(UnixStartDay))
  
  UnixEndDay <- as.POSIXct(paste(date, "23:59:59"), format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
  UnixEndDay <- as.numeric(unclass(UnixEndDay))
  
  # Make the API request for the 24-hour period
  req <- httr::GET("https://wbsapi.withings.net/v2/measure?action=getintradayactivity", 
                   query = list(access_token = access_token,
                                startdate = UnixStartDay, 
                                enddate   = UnixEndDay,
                                data_fields = data_fields))
  
  # Extract and process the response
  out <- httr::content(req, as = "text", encoding = "utf-8")
  out <- jsonlite::fromJSON(out)
  
  if (out$status == 0) {
    out$body$series <- lapply(out$body$series, function(x) x[!sapply(x, is.null)])
    out$body$series <- dplyr::bind_rows(out$body$series, .id = "timestamp")
    out$body$series$timestamp <- as.POSIXct(as.numeric(out$body$series$timestamp), tz = "", origin = "1970-01-01")
    return(out$body$series)
  } else {
    return(NULL)  # Return NULL if the API request fails
  }
}

# Loop over the time period and collect data for each day
fetch_ALL_intraday_activity <- function(startdate, enddate, access_token, data_fields) {
  all_days_activity <- list()
  
  # Loop through each day in the date range
  for (single_date in seq(as.Date(startdate), as.Date(enddate), by = "day")) {
    single_date<-as.Date(single_date)
    print(paste("Fetching data for", single_date))
    day_activity <- fetch_intraday_activity(access_token, single_date, data_fields)
    
    # Append the day's activity data to the list
    if (!is.null(day_activity)) {
      all_days_activity[[as.character(single_date)]] <- day_activity
    }
  }
  
  # Combine all days' activity data into a single dataframe
  if (length(all_days_activity) > 0) {
    intraDayActivity.df <- dplyr::bind_rows(all_days_activity, .id = "date")
    return(intraDayActivity.df)
  } else {
    return(NULL)  # Return NULL if no data was fetched
  }
}
###############################################################################
###############################################################################
########################################  END OF INTRADAY ACTIVITY FUNCTIONS
###############################################################################
###############################################################################


###############################################################################
###############################################################################
####  BEGIN OF SLEEP FUNCTIONS
###############################################################################
###############################################################################

# Function to fetch sleep data for a single day
fetch_sleep_data <- function(access_token, date, data_fields) {
  # Convert the date to Unix timestamps for the start and end of the day
  UnixStartDay <- as.POSIXct(paste(date, "00:00:00"), format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
  UnixStartDay <- as.numeric(unclass(UnixStartDay))
  
  UnixEndDay <- as.POSIXct(paste(date, "23:59:59"), format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
  UnixEndDay <- as.numeric(unclass(UnixEndDay))
  
  # Make the API request for sleep data for the 24-hour period
  req <- httr::GET("https://wbsapi.withings.net/v2/sleep?action=get", 
                   query = list(access_token = access_token,
                                startdate = UnixStartDay, 
                                enddate = UnixEndDay,
                                data_fields = data_fields))
  
  httr::stop_for_status(req)  # Check if the request was successful
  
  # Extract and process the response
  out <- httr::content(req, as = "text", encoding = "utf-8")
  out <- jsonlite::fromJSON(out)
  
  if (out$status == 0 && "series" %in% names(out$body) && length(out$body$series) > 0) {
    # Flatten the JSON data
    sleep.df <- jsonlite::flatten(out$body$series)
    
    # Convert startdate and enddate to POSIXct
    sleep.df$startdate <- as.POSIXct(sleep.df$startdate, tz = "", origin = "1970-01-01")
    sleep.df$enddate <- as.POSIXct(sleep.df$enddate, tz = "", origin = "1970-01-01")
    
    # Arrange by startdate
    sleep.df <- dplyr::arrange(sleep.df, startdate)
    
    # Separate heart rate columns
    sleep.hr_columns <- grep("^hr\\.", names(sleep.df), value = TRUE)
    
    # Gather heart rate data into long format
    sleep.df <- sleep.df %>%
      select(startdate, enddate, state, model, all_of(sleep.hr_columns)) %>%
      tidyr::gather(key = "timestamp", value = "heart_rate", all_of(sleep.hr_columns)) %>%
      dplyr::filter(!is.na(heart_rate))
    
    # Convert timestamp to POSIXct
    sleep.df$timestamp <- as.numeric(sub("hr\\.", "", sleep.df$timestamp))
    sleep.df$timestamp <- as.POSIXct(sleep.df$timestamp, tz = "", origin = "1970-01-01")
    
    
    # Convert state to a readable factor
    sleep.df$state <- factor(sleep.df$state,
                             levels = c(0, 1, 2, 3),
                             labels = c("Awake", "LightSleep", "DeepSleep", "REM"))
    
    return(sleep.df)
  } else {
    return(NULL)  # Return NULL if the API request fails
  }
}

# Function to fetch a sleep data over time span
fetch_ALL_sleep_data <- function(startdate, enddate, access_token, data_fields) {
  all_days_sleep <- list()
  
  # Loop through each day in the date range
  for (single_date in seq(as.Date(startdate), as.Date(enddate), by = "day")) {
    single_date<-as.Date(single_date)
    print(paste("Fetching sleep data for", single_date))
    day_sleep_data <- fetch_sleep_data(access_token, single_date, data_fields)
    
    # Append the day's sleep data to the list
    if (!is.null(day_sleep_data)) {
      all_days_sleep[[as.character(single_date)]] <- day_sleep_data
    }
  }
  
  # Combine all days' sleep data into a single dataframe
  if (length(all_days_sleep) > 0) {
    weekly_sleep_data <- dplyr::bind_rows(all_days_sleep, .id = "date")
    return(weekly_sleep_data)
  } else {
    return(NULL)  # Return NULL if no data was fetched
  }
}
###############################################################################
###############################################################################
####  END OF SLEEP FUNCTIONS
###############################################################################
###############################################################################
