library(mrdwabmisc)
library(tidyverse)
library(lubridate)
library(ggplot2)

getwd()
setwd("/users/acofi/Documents/Data_Analysis/Cousera/Portfolio & Case Study/Case Study #1")

#use read_csv function to import the 12 csv files as dataframes.
`202007` <- read_csv("Raw Data/202007-divvy-tripdata.csv")
`202008` <- read_csv("Raw Data/202008-divvy-tripdata.csv")
`202009` <- read_csv("Raw Data/202009-divvy-tripdata.csv")
`202010` <- read_csv("Raw Data/202010-divvy-tripdata.csv")
`202011` <- read_csv("Raw Data/202011-divvy-tripdata.csv")
`202012` <- read_csv("Raw Data/202012-divvy-tripdata.csv")
`202101` <- read_csv("Raw Data/202101-divvy-tripdata.csv")
`202102` <- read_csv("Raw Data/202102-divvy-tripdata.csv")
`202103` <- read_csv("Raw Data/202103-divvy-tripdata.csv")
`202104` <- read_csv("Raw Data/202104-divvy-tripdata.csv")
`202105` <- read_csv("Raw Data/202105-divvy-tripdata.csv")
`202106` <- read_csv("Raw Data/202106-divvy-tripdata.csv")



# start_station_id and end_station_id are a double for the first 5 files and they are a character for the rest.
`202007` <- mutate(`202007`, start_station_id = as.character(start_station_id), end_station_id = as.character(end_station_id))
`202008` <- mutate(`202008`, start_station_id = as.character(start_station_id), end_station_id = as.character(end_station_id))
`202009` <- mutate(`202009`, start_station_id = as.character(start_station_id), end_station_id = as.character(end_station_id))
`202010` <- mutate(`202010`, start_station_id = as.character(start_station_id), end_station_id = as.character(end_station_id))
`202011` <- mutate(`202011`, start_station_id = as.character(start_station_id), end_station_id = as.character(end_station_id))

str(`202007`)
str(`202008`)
str(`202010`)
str(`202011`)
str(`202012`)
str(`202101`)
str(`202102`)
str(`202103`)
str(`202104`)
str(`202105`)
str(`202106`)

#combine rows in each dataframe into one tibble.

all_trips <- bind_rows(`202007`, `202008`, `202009`, `202010`, `202011`, `202012`, `202101`, `202102`, `202103`, `202104`, `202105`, `202106`)

#remove data columns that will not be used 
all_trips <- all_trips %>%
  select(-c(start_lat, start_lng, end_lat, end_lng))

#inspect Data
colnames(all_trips)
nrow(all_trips)
dim(all_trips)
head(all_trips)
str(all_trips)
summary(all_trips)

#add columns for date, month, day, and year for further aggregation
all_trips$date <- as.Date(all_trips$started_at)
all_trips$month <- format(as.Date(all_trips$date), format="%m")
all_trips$day <- format(as.Date(all_trips$date, "%d"))
all_trips$year <- format(as.Date(all_trips$date), "%Y")
all_trips$day_of_week <- format(as.Date(all_trips$date), "%A")

#add "ride_length" calc in minutes and convert the column to numeric for calculations
all_trips$ride_length <-  difftime(all_trips$ended_at, all_trips$started_at)
all_trips$ride_length <- as.numeric(as.character(all_trips$ride_length))/60

#inspect ranges of ride_length and unique values of character columns to validate data
summary(all_trips)
unique(all_trips$rideable_type)
unique(all_trips$member_casual)
unique(all_trips$start_station_name)

#new version is created where incorrect data where the ride_length is negative and missing(since NA<0 is NA) or where the bikes were checked for quality by Divvy are removed
all_trips_v2 <- all_trips %>%
  filter(!(start_station_name %in% c("WATSON TESTING - DIVVY", 
                                     "HUBBARD ST BIKE CHECKING (LBS-WH-TEST)", 
                                     "Base - 2132 W Hubbard Warehouse") | 
             end_station_name %in% c("WATSON TESTING - DIVVY", 
                                     "HUBBARD ST BIKE CHECKING (LBS-WH-TEST)", 
                                     "Base - 2132 W Hubbard Warehouse") | 
             all_trips$ride_length<0))
#day_of_week must be put in order first before aggregation can be done
all_trips_v2$day_of_week <- ordered(all_trips_v2$day_of_week,
                                    levels=c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"))
#order months starting at 07 since July represents the first month in the data
all_trips_v2$month <- ordered(all_trips_v2$month,
                                    levels=c("07", "08", "09", "10", "11", "12", "01", "02", "03", "04", "05", "06"))

#descriptive analysis of ride_length
summary(all_trips_v2$ride_length)

#comparing members and casual users ride duration statistics
duration_stats <- all_trips_v2 %>%
  group_by(member_casual) %>%
  summarize(min_duration=min(ride_length),
            median_duration=median(ride_length),
            mean_duration=mean(ride_length),
            max_duration =max(ride_length))

#create aggregate data frame grouped by user type, date, month, and day of the week to save for visualization in Tableau to look at quarterly, monthly, and weekday trends
aggregate_by_day  <- all_trips_v2 %>% 
  group_by(member_casual, day, month, day_of_week) %>% #group by user type and day
  summarize(numb_of_rides = n(), #calculate number of rides and average duration
            avg_duration = mean(ride_length)) %>%
  arrange(member_casual, day) #sort  
 #boxplot of avg_duration statistic grouped by user type 
#hiding 3 outlier points for casual members between 250-450 min
ggplot(aggregate_by_day, aes(member_casual, avg_duration)) + geom_boxplot() + coord_cartesian(ylim=c(10, 70))

#aggregate average ride duration and num of rides for each day of week for members vs casual users from aggregate_by_day data frame
aggregation_dayofweek  <- aggregate_by_day %>% 
  group_by(member_casual, day_of_week) %>% #group by usertype and weekday
  summarize(numb_of_rides = sum(numb_of_rides), #calculate number of rides and average duration
            avg_duration = mean(avg_duration)) %>%
  arrange(member_casual, day_of_week) #sort
#visualize the number of rides by rider type and day of week
  ggplot(data=aggregation_dayofweek, aes(x=day_of_week, y=numb_of_rides, fill=member_casual)) + geom_col(position="dodge")
#visualization for average duration
  ggplot(data= aggregation_dayofweek, aes(x=day_of_week, y=avg_duration, fill=member_casual)) + geom_col(position="dodge")

  
  
#aggregate number of rides and average duration each month by user type
  aggregation_month  <- aggregate_by_day %>% 
    group_by(member_casual, month) %>% #group by usertype and month
    summarize(numb_of_rides = sum(numb_of_rides), #calculate number of rides and average duration
              avg_duration = mean(avg_duration)) %>%
    arrange(member_casual, month) #sort
#visualize the number of rides by rider type
ggplot(data=aggregation_month, aes(x=month, y=numb_of_rides, group=member_casual, color=member_casual)) + geom_line()
#visualization for average duration
ggplot(data= aggregation_month, aes(x=month, y=avg_duration, group=member_casual, color=member_casual)) + geom_line()
  
  

#export aggregation dfs to csv files
write.csv(aggregate_by_day, file="C:/Users/acofi/Documents/Data_Analysis/Cousera/Portfolio & Case Study/Case Study #1/R_aggregation_day.csv")
































