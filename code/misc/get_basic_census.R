## these are helper functions to grab commonly desired census data
## at the bottom is a function that calls all the others

census_vap <- function(geo, state = NULL, county = NULL, year){
  library(tidycensus)
  library(tidyverse)

  vap <- get_acs(geography = geo,
                 variables = c(ym1 = "B01001_003",
                               ym2 = "B01001_004",
                               ym3 = "B01001_005",
                               ym4 = "B01001_006",
                               yw1 = "B01001_027",
                               yw2 = "B01001_028",
                               yw3 = "B01001_029",
                               yw4 = "B01001_030"),
                 summary_var = "B01001_001", state = state, county = county, year = year) %>%
    group_by(GEOID) %>%
    summarize(under18 = sum(estimate),
              pop = mean(summary_est)) %>%
    mutate(vap = pop - under18) %>%
    select(-under18, -pop) %>%
    ungroup()
}

census_race_ethnicity <- function(geo, state = NULL, county = NULL, year){
  library(tidycensus)
  library(tidyverse)
  race_ethnicity <- get_acs(geography = geo,
                            variables = c(nh_white = "B03002_003",
                                          nh_black = "B03002_004",
                                          latino = "B03002_012",
                                          latino_black = "B03002_014"),
                            summary_var = c(population = "B03002_001"),
                            state = state, county = county, year = year) %>%
    mutate(estimate = estimate / summary_est) %>%
    select(-ends_with("moe")) %>%
    rename(population = summary_est) %>%
    spread(variable, estimate)
}

census_income <- function(geo, state = NULL, county = NULL, year){
  library(tidycensus)
  library(tidyverse)
  income <- get_acs(geography = geo,
                    variables = c(medincome = "B19013_001"),
                    state = state, county = county, year = year) %>%
    select(-variable, -moe) %>%
    rename(median_income = estimate)
}

census_education <- function(geo, state = NULL, county = NULL, year){
  library(tidycensus)
  library(tidyverse)
  education <- get_acs(geography = geo,
                       variables = c("B15002_012",
                                     "B15002_013",
                                     "B15002_014",
                                     "B15002_015",
                                     "B15002_016",
                                     "B15002_017",
                                     "B15002_028",
                                     "B15002_029",
                                     "B15002_030",
                                     "B15002_031",
                                     "B15002_032",
                                     "B15002_033",
                                     "B15002_034",
                                     "B15002_035"),
                       summary_var = "B15002_001",
                       state = state, county = county, year = year) %>%
    group_by(GEOID, NAME) %>%
    summarize(some_college = sum(estimate / summary_est))
}

census_unemployment <- function(geo, state = NULL, county = NULL, year){
  library(tidycensus)
  library(tidyverse)
  unemployment <- get_acs(geography = geo,
                          variables = c(lf = "B23025_003",
                                        unem = "B23025_005"),
                          output = "wide",
                          state = state, county = county, year = year) %>%
    mutate(unem = unemE / lfE) %>%
    select(GEOID, NAME, unem)
}

census_median_age <- function(geo, state = NULL, county = NULL, year){
  library(tidycensus)
  library(tidyverse)
  median_age <- get_acs(geography = geo,
                        variables = c(median_age = "B01002_001"),
                        state = state, county = county, year = year, output = "wide") %>%
    select(GEOID, median_age = median_ageE)
}

census_non_citizen <- function(geo, state = NULL, county = NULL, year){
  library(tidycensus)
  library(tidyverse)
  
  non_citizen <- get_acs(geography = geo,
                         variables = c(non_citizen = "B05001_006"),
                         summary_var = "B05001_001",
                         state = state, county = county, year = year) %>%
    dplyr::mutate(share_non_citizen = estimate / summary_est) %>%
    dplyr::select(GEOID, share_non_citizen)
}

census_movers <- function(geo, state = NULL, county = NULL, year){
  library(tidycensus)
  library(tidyverse)
  movers <- get_acs(geography = geo,
                    variables = c(tot = "B07001_001",
                                  not_moved = "B07001_017"),
                    state = state, county = county, year = year, output = "wide") %>%
    mutate(share_moved = 1 - (not_movedE / totE)) %>%
    select(GEOID, share_moved)
}

census_no_car <- function(geo, state = NULL, county = NULL, year){
  library(tidycensus)
  library(tidyverse)
  no_car <- get_acs(geography = geo,
                    variables = c(tot = "B08201_001",
                                  no_car = "B08201_002"),
                    state = state, county = county, year = year, output = "wide") %>%
    mutate(share_no_car = no_carE / totE) %>%
    select(GEOID, share_no_car)
}

get_basic_census_stats <- function(geo, state = NULL, county = NULL, year){

  vap <- census_vap(geo = geo, state = state, county = county, year = year)

  race_ethnicity <- census_race_ethnicity(geo = geo, state = state, county = county, year = year)

  income <- census_income(geo = geo, state = state, county = county, year = year)

  education <- census_education(geo = geo, state = state, county = county, year = year)

  unemployment <- census_unemployment(geo = geo, state = state, county = county, year = year)

  median_age <- census_median_age(geo = geo, state = state, county = county, year = year)

  non_citizen <- census_non_citizen(geo = geo, state = state, county = county, year = year)

  movers <- census_movers(geo = geo, state = state, county = county, year = year)

  no_car <- census_no_car(geo = geo, state = state, county = county, year = year)

  census <- list(race_ethnicity, income, education, vap, unemployment, median_age, non_citizen, movers, no_car) %>%
    reduce(left_join)

  return(census)
}
