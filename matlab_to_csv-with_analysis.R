########################################
### Packages and wrangling functions ###
########################################
library(R.matlab)
library(tidyverse)

remove_media_prefix <- function(string) {
  if (str_detect(string, "^[lb].{2}")) {
    remove_media_prefix(str_sub(string, start=2))
  } else {
    str_remove_all(string, "l")
  }
}

adjust_strain_name <- function(string) {
  case_when(
    string == "ptsNaP" ~ "ptsN*P",
    string == "ptsNa" ~ "ptsN*",
    string == "LM100" ~ "che1",
    string == "LM300" ~ "che12",
    string == "LM400" ~ "che2",
    TRUE ~ string
  )
}

load_matlab_file <- function(path_to_file, filename) {
  matlab_file <- readMat(file.path(path_to_file, filename), fixNames=FALSE)
  if (!length(matlab_file$analysed_data)) {
    matlab_data <- tibble(
      ts = list(),
      x = list(),
      y = list(),
      extract_velo = list(),
      locs = list(),
      spline_angle = list(),
      splinex_gof = list(),
      spliney_gof = list(),
      msd = list()
    )
  } else { # if no tracks present
    matlab_data <- matlab_file$analysed_data[,1,] %>%
      t() %>%
      as_tibble()
  }
  matlab_data <- matlab_data %>%
    select(
      ts,             # time coordinates (seconds)
      x,              # x-coordinates (microns)
      y,              # y-coordinates (microns)
      extract_velo,   # velocity from spline at track times
      locs,           # time coordinates of tumble peaks
      spline_angle,   # angle at tumble peak points
      splinex_gof,    # Goodness-of-fit for spline
                        # sse: Sum of squares due to error
                        # rsquare: R-squared (coefficient of determination)
                        # dfe: Degrees of freedom in the error
                        # adjrsquare: Degree-of-freedom adjusted coefficient of determination
                        # rmse: Root mean squared error (standard error)
      spliney_gof,    # As above
      msd             # mean squared displacement (mean, sd, n, intercept, slope)
                        # Single-particle tracking: the distribution of diffusion coefficients. Saxton MJ 1997 (doi: 10.1016/S0006-3495(97)78820-9)
                        # Linear: Brownian motion
                        # Non-linear increasing: directed motion
                        # Non-linear decreasing: constrained
                        # Intercept: measurement error
    )
  matlab_data
}



##########################
### Analysis functions ###
##########################
# Mark particles with at least velocity_frames_threshold of their points in a row less than velocity_threshold as captured
# Since these have likely connected to an immobile particle
velocity_threshold <- 10
velocity_frames_threshold <- 2
is.captured <- function(velocities) {
  frames_check <- velocities %>%
    map_lgl(~ . <= velocity_threshold) %>%
    rle() %>%
    with(max(lengths[values == TRUE])) %>%
    `>=`(velocity_frames_threshold)
  
  frames_check
}

# Mark particles with low spline rsquare values as low quality tracks
adjrsquare_threshold <- 0.98
is.low_quality <- function(x_gof, y_gof) {
  x_gof[,,]$adjrsquare < adjrsquare_threshold | y_gof[,,]$adjrsquare < adjrsquare_threshold
}

# Count number of tumbles per second
tumble_threshold = pi/4    # 45 degrees
count.tumbles <- function(angle) {
  tumbles <- angle[angle > tumble_threshold]
  length(tumbles)
}



#################
### Wrangling ###
#################
# Experiment example
chosen_folders <- c(here::here("example1"), here::here("example2"))
output_file <- "example_compiled.csv"


data <- tibble(path_to_file = chosen_folders) %>%
  mutate(filename = map(path_to_file, list.files, pattern=".*analysed.mat")) %>%
  unnest(cols=c(filename)) %>%
  mutate(names = map(filename, . %>%
                       str_extract("^.*(?=-.+-)") %>%
                       str_split("_") %>%
                       unlist()
  ),
  experiment          = map_chr(names, 6),
  strain              = map_chr(names, ~ adjust_strain_name(.[[1]])),
  media               = map_chr(names, ~ remove_media_prefix(.[[3]])),
  replicate           = as.integer(map_chr(names, 4)),
  position            = map_chr(names, 2),
  technical_replicate = as.integer(map(names, 5)),
  nonmotile           = map_lgl(filename, str_detect, pattern = "-.*non"),
  data                = map2(path_to_file, filename, load_matlab_file)
  ) %>%
  select(-names, -filename, -path_to_file)



################
### Analysis ###
################
# Analyse each images tracks individually
analysis <- data %>%
  mutate(data = map(data, ~ mutate(.,
                                   average_speed = map_dbl(extract_velo, mean),
                                   low_quality_track = map2_lgl(splinex_gof, spliney_gof, is.low_quality),
                                   captured_track = map_lgl(extract_velo, is.captured),
                                   tumble_count = map_dbl(spline_angle, count.tumbles),
                                   duration = map_dbl(ts, ~ .[length(.)] - .[1]),
                                   tumble_rate = map2_dbl(tumble_count, duration, ~ .x / .y)
  )))

# Check track counts
analysis %>%
  unnest(cols=data) %>%
  group_by(strain, media, nonmotile) %>%
  summarise(n=n()) %>%
  filter(nonmotile==FALSE) %>%
  print(n = Inf)


#####################
### Export as csv ###
#####################
analysis %>%
  unnest(cols=data) %>%
  select(-c(ts, x, y, extract_velo, locs, spline_angle, splinex_gof, spliney_gof, msd)) %>%
  write_csv(here::here("compiled_csv", output_file))


























