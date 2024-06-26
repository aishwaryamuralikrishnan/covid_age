#USA CDC vaccination data by Age and Sex, National and Jurisdictional 
# Data are cumulative and since 13.Dec.2020
library(here)
source(here("Automation/00_Functions_automation.R"))

library(lubridate)
library(dplyr)
library(tidyverse)
library(xlsx)
# assigning Drive credentials in the case the script is verified manually

if (!"email" %in% ls()){
  email <- "mumanal.k@gmail.com"
}


# info country and N drive address

ctr          <- "USA_Vaccine_states" # it's a placeholder
dir_n        <- "N:/COVerAGE-DB/Automation/Hydra/"


#make folder on hydra
if (!dir.exists(paste0(dir_n, "Data_sources/", ctr))){
  dir.create(paste0(dir_n, "Data_sources/", ctr))
}

# Drive credentials
drive_auth(email = Sys.getenv("email"))
gs4_auth(email = Sys.getenv("email"))


## read in Vaccination data ## =================

## Source Web: https://data.cdc.gov/Vaccinations/COVID-19-Vaccination-Age-and-Sex-Trends-in-the-Uni/5i5k-6cmh

us_vacc <- data.table::fread("https://data.cdc.gov/api/views/5i5k-6cmh/rows.csv?accessType=DOWNLOAD&bom=true&format=true")


## processing the data ================

cat_to_select <- c("Female_Ages_<2yrs", 
                   "Female_Ages_2-4_yrs",
                   "Female_Ages_5-11_yrs", 
                   "Female_Ages_12-17_yrs", 
                   "Female_Ages_18-24_yrs", 
                   "Female_Ages_25-39_yrs", 
                   "Female_Ages_40-49_yrs", 
                   "Female_Ages_50-64_yrs",
                   "Female_Ages_65-74_yrs", 
                   "Female_Ages_75+_yrs",
                   "Male_Ages_<2yrs", 
                   "Male_Ages_2-4_yrs",
                   "Male_Ages_5-11_yrs", 
                   "Male_Ages_12-17_yrs", 
                   "Male_Ages_18-24_yrs", 
                   "Male_Ages_25-39_yrs", 
                   "Male_Ages_40-49_yrs", 
                   "Male_Ages_50-64_yrs",
                   "Male_Ages_65-74_yrs", 
                   "Male_Ages_75+_yrs")

vacc_processed <- us_vacc %>% 
  dplyr::mutate(Date = lubridate::mdy_hms(Date)) %>% 
  dplyr::select(Date, Location,
                Demographic_Category, 
                Administered_Dose1, Series_Complete_Yes,
                Booster_Doses, Second_Booster) %>% 
  dplyr::filter(Demographic_Category %in% cat_to_select) %>% 
  tidyr::separate(Demographic_Category, into = c("Sex", "trash1", "Age", "trash2", "yrs", sep = "_")) %>% 
  dplyr::mutate(Age = case_when(Age == "2yrs" ~ "0",
                                TRUE ~ Age),
                Sex = case_when(Sex == "Male" ~ "m",
                                Sex == "Female" ~ "f")
    # Administered_Dose1 = str_replace_all(Administered_Dose1, ",", ""),
    # Series_Complete_Yes = str_replace_all(Series_Complete_Yes, ",", ""),
    # Booster_Doses = str_replace_all(Booster_Doses, ",", ""),
    # Second_Booster = str_replace_all(Second_Booster, ",", ""),
    # Administered_Dose1 = as.integer(Administered_Dose1),
    # Series_Complete_Yes = as.integer(Series_Complete_Yes),
    # Booster_Doses = as.integer(Booster_Doses),
    # Second_Booster = as.integer(Second_Booster)
  ) %>% 
 dplyr::select(Date, Location, Age, Sex, 
               Administered_Dose1, Series_Complete_Yes,
               Booster_Doses, Second_Booster) %>% 
  tidyr::pivot_longer(cols = -c("Date", "Location", "Age", "Sex"),
               names_to = "Measure",
               values_to = "Value") %>% 
  dplyr::mutate(Value = parse_number(Value),
                AgeInt = case_when(Age == "0" ~ 2L,
                                   Age == "2" ~ 3L,
                                   Age == "5"  ~ 7L,
                                   Age == "12" ~ 6L,
                                   Age == "18" ~ 7L,
                                   Age == "25" ~ 15L,
                                   Age == "40" ~ 10L,
                                   Age == "50" ~ 15L,
                                   Age == "65" ~ 10L,
                                   Age == "75" ~ 30L), 
                Measure = case_when(Measure == "Administered_Dose1" ~ "Vaccination1",
                                    Measure == "Series_Complete_Yes" ~ "Vaccination2",
                                    Measure == "Booster_Doses" ~ "Vaccination3",
                                    Measure == "Second_Booster" ~ "Vaccination4"),
               Region= case_when(Location == "AK" ~ "Alaska",
                                 Location == "AL" ~ "Alabama",
                                 Location == "AR" ~ "Arkansas",
                                 Location == "AS" ~ "American Samoa",
                                 Location == "AZ" ~ "Arizona",
                                 Location == "BP2"~ "Bureau of Prisons",
                                 Location == "CA" ~ "California",
                                 Location == "CA."~ "California",
                                 Location == "CO" ~ "Colorado",
                                 Location == "CT" ~ "Connecticut",
                                 Location == "DC" ~ "District of Columbia",
                                #  Location == "DD2" ~ "Dept of Defense",
                                 Location == "DE" ~ "Delaware",
                                 Location == "FL" ~ "Florida",
                                 Location == "FM" ~ "Federated States of Micronesia",
                                 Location == "GA" ~ "Georgia",
                                 Location == "GU" ~ "Guam",
                                 Location == "HI" ~ "Hawaii",
                                 Location == "IA" ~ "Iowa",
                                 Location == "ID" ~ "Idaho",
                                #  Location == "IH2" ~ "Indian Health Services",
                                 Location == "IL" ~ "Illinois",
                                 Location == "IN" ~ "Indiana",
                                 Location == "KS" ~ "Kansas",
                                 Location == "KY" ~ "Kentucky",
                                 Location == "LA" ~ "Louisiana",
                                 Location == "MA" ~ "Massachusetts",
                                 Location == "MD" ~ "Maryland",
                                 Location == "ME" ~ "Maine",
                                 Location == "MH" ~ "Marshall Islands",
                                 Location == "MI" ~ "Michigan",
                                 Location == "MN" ~ "Minnesota",
                                 Location == "MO" ~ "Missouri",
                                 Location == "MP" ~ "Northern Mariana Islands",
                                 Location == "MS" ~ "Mississippi",
                                 Location == "MT" ~ "Montana",
                                 Location == "NC" ~ "North Carolina",
                                 Location == "ND" ~ "North Dakota",
                                 Location == "NE" ~ "Nebraska",
                                 Location == "NH" ~ "New Hampshire",
                                 Location == "NJ" ~ "New Jersey",
                                 Location == "NM" ~ "New Mexico",
                                 Location == "NV" ~ "Nevada",
                                 Location == "NY" ~ "New York State",
                                 Location == "OH" ~ "Ohio",
                                 Location == "OK" ~ "Oklahoma",
                                 Location == "OR" ~ "Oregon",
                                 Location == "PA" ~ "Pennsylvania",
                                 Location == "PR" ~ "Puerto Rico",
                                 Location == "PW" ~ "Palau",
                                 Location == "RI" ~ "Rhode Island",
                                 Location == "SC" ~ "South Carolina",
                                 Location == "SD" ~ "South Dakota",
                                 Location == "TN" ~ "Tennessee",
                                 Location == "TX" ~ "Texas",
                                 Location == "US" ~ "All",
                                 Location == "UT" ~ "Utah",
                                 Location == "VA" ~ "Virginia",
                                 Location == "VI" ~ "Virgin Islands",
                                 Location == "VT" ~ "Vermont",
                                 Location == "WA" ~ "Washington",
                                 Location == "WI" ~ "Wisconsin",
                                 Location == "WV" ~ "West Virginia",
                                 Location == "WY" ~ "Wyoming",
                                 Location == "NA" ~ "Unknown")) 



## Output Data

vacc_out <- vacc_processed %>% 
  mutate(Metric = "Count",
         Country = "USA",
         Date = as_date(Date),
         #Date = mdy(Date),
         Date = ddmmyyyy(Date),
         Code = case_when(Location == "US" ~ "US",
                          TRUE ~ paste0("US-", Location))) %>% 
  select(Country, Region, Code, Date, Sex, 
         Age, AgeInt, Metric, Measure, Value) %>% 
  sort_input_data()


#save output data

write_rds(vacc_out, paste0(dir_n, ctr, ".rds"))

# Update HYDRA 

log_update(pp = ctr, N = nrow(vacc_out))


# now archive new data 

data_source <- paste0(dir_n, "Data_sources/", ctr, "/vaccine_states_",today(), ".csv")

write_csv(vacc_out, data_source)



zipname <- paste0(dir_n, 
                  "Data_sources/", 
                  ctr,
                  "/", 
                  ctr,
                  "vaccine_states_",
                  today(), 
                  ".zip")

zip::zipr(zipname, 
          data_source, 
          recurse = TRUE, 
          compression_level = 9,
          include_directories = TRUE)

file.remove(data_source)

# END. 
