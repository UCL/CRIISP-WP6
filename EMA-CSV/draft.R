# Required libraries
library(tidyverse)
library(lubridate)
library(ggplot2)


# Read the CSV data
data <- read.csv("../../../Downloads/Book1.csv", na.strings = "")
data <- read.csv("../../../Downloads/basic_v0.csv", na.strings = "",sep = ";")

# Convert Unix timestamp to datetime
data<-data %>%
  mutate(
    datetime = as_datetime(timeStampStart),
    date = date(datetime),
    Mood_dec = Mood_smiley/10
  )


data_1c<-data %>% filter(alias=="PipRooke")

data_1c <- data_1c %>%
  arrange(datetime) %>%
  mutate(day_count = as.numeric(date - min(date, na.rm = TRUE)),
    is_weekend = wday(date) %in% c(1, 7)
    )



# Create basic time series plots
ggplot(data_1c, aes(x = datetime)) +
  # Add horizontal line for mood inflection point
  geom_hline(yintercept = 5, linetype = "dashed", color = "gray50", alpha = 0.5) +
  # Original plot elements
  geom_line(aes(y = Mood_dec, color = "Mood")) +
  geom_line(aes(y = Stress_sliderNeutralPos, color = "Stress")) +
  geom_line(aes(y = Pain.intensity_sliderNeutralPos, color = "Pain")) +
  scale_color_manual(values = c("Mood" = "blue", "Stress" = "red", "Pain" = "green")) +
  scale_y_continuous(breaks = 0:10, limits = c(0,10)) +
  scale_x_datetime(date_breaks = "1 day", date_labels = "%Y-%m-%d") +
  labs(title = "Mood, Stress, and Pain Over Time",
       y = "Score",
       x = "Date/Time",
       caption = "Low mood < 5, Good mood > 5") +
  theme_minimal()

ggplot(data_1c, aes(x = day_count)) +
  # Add horizontal line for mood inflection point
  geom_hline(yintercept = 5, linetype = "dashed", color = "gray50", alpha = 0.5) +
  # Smooth lines with less smoothening
  geom_smooth(aes(y = Mood_dec, color = "Mood"), 
              method = "loess", span = 0.2, se = FALSE) +
  geom_smooth(aes(y = Stress_sliderNeutralPos, color = "Stress"), 
              method = "loess", span = 0.2, se = FALSE) +
  geom_smooth(aes(y = Pain.intensity_sliderNeutralPos, color = "Pain"), 
              method = "loess", span = 0.2, se = FALSE) +
  # Add points for actual data
  geom_point(aes(y = Mood_dec, color = "Mood"), alpha = 0.3) +
  geom_point(aes(y = Stress_sliderNeutralPos, color = "Stress"), alpha = 0.3) +
  geom_point(aes(y = Pain.intensity_sliderNeutralPos, color = "Pain"), alpha = 0.3) +
  scale_color_manual(values = c("Mood" = "blue", "Stress" = "red", "Pain" = "green")) +
  scale_y_continuous(breaks = 0:10, limits = c(0,10)) +
  scale_x_continuous(breaks = function(x) seq(floor(min(x)), ceiling(max(x)), by = 1)) +
  labs(title = "Mood, Stress, and Pain intensity Over Time",
       y = "Score",
       x = "Days from Start",
       caption = "Low mood < 5, Good mood > 5") +
  theme_minimal()

##################################
#################################
# Split the pain locations into separate rows
pain_locations <- data_1c %>%
  select(datetime, Pain.location_bodyParts) %>%
  separate_rows(Pain.location_bodyParts, sep = ",") %>%
  mutate(Pain.location_bodyParts = trimws(Pain.location_bodyParts))

# Overall frequency of pain locations
pain_freq <- pain_locations %>%
  count(Pain.location_bodyParts, sort = TRUE) %>%
  mutate(percentage = n/sum(n)*100)

# Print overall frequencies
#print("Overall Pain Location Frequencies:")
#print(pain_freq)

# Create a bar plot of pain locations
ggplot(pain_freq, aes(x = reorder(Pain.location_bodyParts, n), y = n)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(title = "Frequency of Pain Locations",
       x = "Location",
       y = "Count") +
  theme_minimal()

# Analyze pain locations over time
# Create weekly summaries
weekly_pain <- pain_locations %>%
  mutate(week = floor_date(datetime, "week")) %>%
  group_by(week, Pain.location_bodyParts) %>%
  summarise(count = n()) %>%
  ungroup()

# Create a heatmap of pain locations over time
ggplot(weekly_pain, aes(x = week, y = Pain.location_bodyParts, fill = count)) +
  geom_tile() +
  scale_fill_gradient(low = "white", high = "red") +
  labs(title = "Pain Locations Over Time (1Week period)",
       x = "Week",
       y = "Location",
       fill = "Frequency") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Calculate co-occurrence of pain locations
pain_matrix <- pain_locations %>%
  group_by(datetime) %>%
  summarise(locations = list(Pain.location_bodyParts)) %>%
  unnest(locations) %>%
  table() %>%
  crossprod()

# Print common pain location combinations
print("Common Pain Location Combinations:")
print(pain_matrix)

# Split pain locations into separate rows and create daily grouping
daily_pain <- data_1c %>%
  select(day_count, Pain.location_bodyParts) %>%
  separate_rows(Pain.location_bodyParts, sep = ",") %>%
  mutate(
    Pain.location_bodyParts = trimws(Pain.location_bodyParts),
  ) %>%
  group_by(day_count, Pain.location_bodyParts) %>%
  summarise(count = n()) %>%
  ungroup()

# Create an enhanced heatmap
ggplot(daily_pain, aes(x = day_count, y = Pain.location_bodyParts, fill = count)) +
  geom_tile() +
  scale_fill_gradient(low = "lightgrey", high = "red") +
  scale_x_continuous(breaks = function(x) seq(floor(min(x)), ceiling(max(x)), by = 1)) +
  labs(
    title = "Daily Pain Locations",
    x = "Date",
    y = "Location",
    fill = "Frequency"
  ) +
  theme_minimal()

# Split pain locations and create weighted intensity
daily_pain_weighted <- data_1c %>%
  select(day_count, Pain.location_bodyParts, Pain.intensity_sliderNeutralPos) %>%
  separate_rows(Pain.location_bodyParts, sep = ",") %>%
  mutate(
    Pain.location_bodyParts = trimws(Pain.location_bodyParts)
  ) %>%
  group_by(day_count, Pain.location_bodyParts) %>%
  summarise(
    # Count occurrences
    frequency = n(),
    # Calculate average pain intensity
    avg_intensity = mean(Pain.intensity_sliderNeutralPos, na.rm = TRUE),
    # Calculate weighted score: frequency * intensity
    weighted_score = frequency * avg_intensity
  ) %>%
  ungroup()

# Create weighted heatmap
ggplot(daily_pain_weighted, aes(x = day_count, y = Pain.location_bodyParts, fill = weighted_score)) +
  geom_tile() +
  scale_fill_gradient(low = "lightgrey", high = "red") +
  scale_x_continuous(breaks = function(x) seq(floor(min(x)), ceiling(max(x)), by = 1)) +
  labs(
    title = "Daily Pain Locations",
    x = "Days from Start",
    y = "Location",
    fill = "Pain Score\n(Frequency × Intensity)"
  ) +
  theme_minimal()



##########################
library(patchwork)  # For combining plots
# Prepare pain locations data
data_1c$date <- date(data_1c$datetime)

# Calculate daily averages
daily_averages <- data_1c %>%
  group_by(date) %>%
  summarise(
    Pain = mean(Pain.intensity_sliderNeutralPos, na.rm = TRUE),
    Stress = mean(Stress_sliderNeutralPos, na.rm = TRUE),
    Mood = mean(Mood_smiley, na.rm = TRUE) / 10  # Scale mood to be comparable
  ) %>%
  pivot_longer(cols = c(Pain, Stress, Mood),
               names_to = "Measure",
               values_to = "Value")

# Prepare pain locations data
daily_pain <- data_1c %>%
  select(datetime, date, Pain.location_bodyParts) %>%
  separate_rows(Pain.location_bodyParts, sep = ",") %>%
  mutate(Pain.location_bodyParts = trimws(Pain.location_bodyParts)) %>%
  group_by(date, Pain.location_bodyParts) %>%
  summarise(count = n(), .groups = 'drop')

# Create heatmap
p1 <- ggplot(daily_pain, aes(x = date, y = Pain.location_bodyParts, fill = count)) +
  geom_tile() +
  scale_fill_gradient(low = "lightgrey", high = "red") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_x_date(
    date_breaks = "1 day",
    date_labels = "%d-%m"
  ) +
  labs(title = "Pain Locations Over Time",
       x = NULL,
       y = "Location",
       fill = "Frequency")

# Create time series plot with all three measures
p2 <- ggplot(daily_averages, aes(x = date, y = Value, color = Measure)) +
  geom_line() +
  geom_point() +
  scale_color_manual(values = c("Pain" = "red", "Stress" = "purple", "Mood" = "blue")) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_y_continuous(limits = c(0,10),breaks=0:10)+
  scale_x_date(
    date_breaks = "1 day",
    date_labels = "%d-%m"
  ) +
  labs(title = "Daily Pain, Stress, and Mood",
       x = "Date",
       y = "Score")

# Combine plots vertically
p1 / p2 +
  plot_layout(heights = c(2, 1)) +  # Make heatmap larger than the time series
  plot_annotation(
    title = "Pain Patterns and Daily Measures",
    theme = theme_minimal()
  )







# Calculate daily averages with added interference measures
daily_averages <- data_1c %>%
  group_by(date) %>%
  summarise(
    Pain = mean(Pain.intensity_sliderNeutralPos, na.rm = TRUE),
    Stress = mean(Stress_sliderNeutralPos, na.rm = TRUE),
    Mood = mean(Mood_smiley, na.rm = TRUE) / 10,  # Scale mood to be comparable
    Activity_Interference = mean(Pain.interf..activity_sliderNeutralPos, na.rm = TRUE),
    Cognitive_Interference = mean(Pain.Interf..cog._sliderNeutralPos, na.rm = TRUE)
  ) %>%
  pivot_longer(cols = c(Pain, Stress, Mood, Activity_Interference, Cognitive_Interference),
               names_to = "Measure",
               values_to = "Value")

# Prepare pain locations data
daily_pain <- data_1c %>%
  select(datetime, date, Pain.location_bodyParts) %>%
  separate_rows(Pain.location_bodyParts, sep = ",") %>%
  mutate(Pain.location_bodyParts = trimws(Pain.location_bodyParts)) %>%
  group_by(date, Pain.location_bodyParts) %>%
  summarise(count = n(), .groups = 'drop')

# Create heatmap
p1 <- ggplot(daily_pain, aes(x = date, y = Pain.location_bodyParts, fill = count)) +
  geom_tile() +
  scale_fill_gradient(low = "lightgrey", high = "red") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_x_date(
    date_breaks = "1 day",
    date_labels = "%d-%m"
  ) +
  labs(title = "Daily Pain Locations Over Time",
       x = NULL,
       y = "Location",
       fill = "Frequency")

# Create time series plot with all five measures
p2 <- ggplot(daily_averages, aes(x = date, y = Value, color = Measure))  +
  geom_hline(yintercept = 5, linetype = "dashed", color = "gray50", alpha = 0.5) +
  geom_line(aes(linetype = Measure)) +
  geom_point() +
  scale_color_manual(values = c(
    "Pain" = "red", 
    "Stress" = "purple", 
    "Mood" = "blue",
    "Activity_Interference" = "orange",
    "Cognitive_Interference" = "green"
  )) +
  scale_linetype_manual(values = c(
    "Pain" = "solid",
    "Stress" = "solid",
    "Mood" = "solid",
    "Activity_Interference" = "dashed",
    "Cognitive_Interference" = "dashed"
  )) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_y_continuous(limits = c(0,10), breaks=0:10) +
  labs(title = "Daily averages overtime",
       x = "Date",
       y = "Score",
       caption = "Low mood < 5, Good mood > 5")

# Combine plots vertically
p1 / p2 +
  plot_layout(heights = c(2, 1)) +  # Make heatmap larger than the time series
  plot_annotation(
    title = "Pain Patterns and Daily Measures",
    theme = theme_minimal()
  )
 







##############################################################
##############################################################
###############  CORRELATION SUMMARIES  ######################
##############################################################
##############################################################

# Create correlation plot
cor_data <- data_1c %>%
  select(Mood_smiley, Stress_sliderNeutralPos, Pain.intensity_sliderNeutralPos) %>%
  cor(use = "complete.obs")

# Print correlations
print("Correlations:")
print(cor_data)

# Create scatterplots
# Mood vs Stress
ggplot(data_1c, aes(x = Stress_sliderNeutralPos, y = Mood_smiley)) +
  geom_point() +
  geom_smooth(method = "lm", se = TRUE) +
  labs(title = "Mood vs Stress",
       x = "Stress Level",
       y = "Mood Score") +
  theme_minimal()

# Mood vs Pain
ggplot(data_1c, aes(x = Pain.intensity_sliderNeutralPos, y = Mood_smiley)) +
  geom_point() +
  geom_smooth(method = "lm", se = TRUE) +
  labs(title = "Mood vs Pain Intensity",
       x = "Pain Intensity",
       y = "Mood Score") +
  theme_minimal()

# Stress vs Pain
ggplot(data_1c, aes(x = Pain.intensity_sliderNeutralPos, y = Stress_sliderNeutralPos)) +
  geom_point() +
  geom_smooth(method = "lm", se = TRUE) +
  labs(title = "Stress vs Pain Intensity",
       x = "Pain Intensity",
       y = "Stress Level") +
  theme_minimal()

# Summary statistics
summary_stats <- data_1c %>%
  summarize(
    mean_mood = mean(Mood_smiley, na.rm = TRUE),
    sd_mood = sd(Mood_smiley, na.rm = TRUE),
    mean_stress = mean(Stress_sliderNeutralPos, na.rm = TRUE),
    sd_stress = sd(Stress_sliderNeutralPos, na.rm = TRUE),
    mean_pain = mean(Pain.intensity_sliderNeutralPos, na.rm = TRUE),
    sd_pain = sd(Pain.intensity_sliderNeutralPos, na.rm = TRUE)
  )

print("Summary Statistics:")
print(summary_stats)