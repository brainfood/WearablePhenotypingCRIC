#Load libraries required for the package
suppressPackageStartupMessages(library(dplyr, quietly = TRUE))
suppressPackageStartupMessages(library(tibble, quietly = TRUE))
suppressPackageStartupMessages(library(tidyr, quietly = TRUE))
suppressPackageStartupMessages(library(readr, quietly = TRUE))
suppressPackageStartupMessages(library(lubridate, quietly = TRUE))


#' Aggregate data over given time interval
#'
#' @param input_data A tbl() or data.frame containing DateTime and Value columns
#'   to scale.
#' @param aggregate_interval Unit of time over which to aggregate. This argument
#'   should be one of "secs", "mins", "hours", "days", (default: "hours").
#' @param aggregate_function Function to use when aggregating data over the
#'   given time interval. Currently accepts "mean" or "sum" (default: "mean").
#'   Either choice uses the na.rm=TRUE option to remove NA values during the
#'   calculation.
#'
#' @return
#' @export
#'
#' @examples
aggregate_data_by_time <- function(input_data,
                                   aggregate_interval="hours",
                                   aggregate_function="mean") {
    
    if(!(aggregate_interval %in% c("secs", "mins", "hours", "days"))) {
        stop("Unrecognized value \"",aggregate_interval,"\" entered for aggregate_interval.\n",
             "       Must be one of \"secs\", \"mins\", \"hours\", \"days\".")
    }
    if(!(aggregate_function %in% c("mean", "sum"))) {
        stop("Unrecognized value \"",aggregate_function,"\" entered for aggregate_function.\n",
             "       Must be one of \"mean\", \"sum\".")
    }
    
    #Store original order of column names
    original_colnames = colnames(input_data)
    
    input_data %>% 
        mutate(DateTime =
                   case_when(
                       aggregate_interval == "secs" ~ ymd_hms(format(DateTime, "%Y:%m:%d %H:%M:%S"), tz = tz(DateTime)),
                       aggregate_interval == "mins" ~ ymd_hm(format(DateTime, "%Y:%m:%d %H:%M"), tz = tz(DateTime)),
                       aggregate_interval == "hours" ~ ymd_h(format(DateTime, "%Y:%m:%d %H"), tz = tz(DateTime)),
                       aggregate_interval == "days" ~ ymd(format(DateTime, "%Y:%m:%d"), tz = tz(DateTime))
                   )) %>% 
        group_by_at(vars(-Value)) %>% 
        summarize_at(vars(Value), funs(UQ(aggregate_function)), na.rm=TRUE) %>% 
        ungroup() %>% 
        select_at(.vars = original_colnames)
}


#Read and process command-line arguments for this script:
args = commandArgs(TRUE)
zephyr_directory = args[1]
interval = args[2]

setwd(zephyr_directory)

#Extract subject ID from directory
subjectID = gsub(".*/([^/]+)(/)?","\\1", zephyr_directory)

#Get name of file with aggregated Zephyr data
zephyr_filename = list.files(pattern = "Aggregated_data.ZephyrBioPatch\\..*\\.txt")

#Read file, aggregate data by the minute, represent time as an index
zephyr_data = 
    read_tsv(zephyr_filename,
             col_types = 
                 cols(
                     DateTime = col_datetime(format = ""),
                     Measurement = col_character(),
                     Value = col_double()
                 )) %>% 
    aggregate_data_by_time(aggregate_interval = interval) %>% 
    mutate(Measurement = factor(Measurement)) %>% 
    #Represent time as minutes since 00:00 on the first measurement day.
    #This will allow us to line up all of the different data streams (and
    #data from different subjects, if we want to at some point).
    mutate(Start_time = ymd_hm(paste(format(min(DateTime, na.rm = TRUE), "%Y:%m:%d"), "00:00"),
                               tz=tz(DateTime)),
           TimeIndex = as.integer(difftime(DateTime, Start_time, units = "min"))) %>% 
    select(-DateTime, -Start_time) %>% 
    spread(Measurement, Value) %>% 
    arrange(TimeIndex) %>% 
    mutate(TimeSubjectIndex = paste0(TimeIndex, "_", subjectID)) %>% 
    select(-TimeIndex) %>% 
    select(TimeSubjectIndex, everything()) %>% 
    write_tsv(paste("Formatted_for_variance_explained.ZephyrBioPatch", subjectID,
                    paste0("agg_by_", interval), "txt", sep="."))
