library(DBI)
library(RPostgres)
library(testthat)
library(data.table)

source("R/simulation_queries.R")

tryCatch(
  {
    print("Connecting to Database…")
    con <- dbConnect(RPostgres::Postgres(),
      dbname = "research_studio_prod_dev",
      host = "localhost",
      port = 5432,
      user = "postgres",
      password = "postgres"
    )

    print("Database Connected!")
  },
  error = function(cond) {
    print("Unable to connect to Database.")
  }
)


nps <- function (list_of_scores) {
  
  scores <- na.omit(list_of_scores)
  if (length(scores) == 0) return(NA)
  
  stopifnot(all(scores >= 0 & scores <=10))

  n <- length(scores)
  promotors <- sum(scores >= 9)
  detractors <- sum(scores <= 6)
  round(100 * (promotors - detractors)/n, 2)
}

get_topic_attributes <- function (topic_name) {
  migraine_borg_tag_ids <- c(
    4240,
    6598,
    4033,
    6446,
    4241,
    6290,
    6287,
    4789,
    4034,
    5393,
    6286,
    5874,
    6291,
    4242,
    6284,
    4696,
    6289,
    1333,
    2415,
    5436,
    2855,
    4032,
    4545,
    4546,
    4547,
    4544,
    7277,
    6285,
    6445,
    4054,
    1062,
    1334,
    1086,
    1332,
    5940,
    731
  )


  topics <- list()

  topics[["migraine"]] <- migraine_borg_tag_ids

  return(topics[[topic_name]])
}


get_simulated_medics <- function (
    lng,
    lat,
    topic_name,
    workplace_type,
    km_radius) {
  stopifnot(workplace_type %in% c("practice", "clinic"))

  if (workplace_type == "practice") {
    workplace_types <- c("pratice", "practice_group")
  } else if (workplace_type == "clinic") {
    workplace_types <- c(
      "clinic_group",
      "clinic",
      "department",
      "sub_department",
      "center"
    )
  }
  
  cat(glue::glue("Querying medics for topic {topic_name} in a radius of {km_radius}km around lat: {lat} lng: {lng} working at {workplace_type} \n\n"))

  borg_tag_ids <- get_topic_attributes(topic_name = topic_name)

  # stringify vectors
  borg_tag_ids <- toString(borg_tag_ids)
  workplace_types <- toString(paste0("'", workplace_types, "'"))

  current_medic_simulation_query <- as.character(
    glue::glue(medic_simulation_query)
  )

  simulated_medics <- dbGetQuery(con, current_medic_simulation_query)

  return(simulated_medics)
}


run_location_simulation <- function (lng, lat) {
  
  
  medics = list()
  summary = NULL
  
  for (workplace_type in c('practice', 'clinic')) {
    medics[[workplace_type]] = list()
    
    for (radius in c(5, 10, 50, 100)) {
      result = get_simulated_medics(lng = lng,
                                    lat = lat,
                                    topic_name = "migraine", 
                                    workplace_type = workplace_type,
                                    km_radius = radius
                                    
                                 
      )
      
      if (nrow(result) > 0) {
        
        n_medics = length(unique(result$medic_id))
        avg_distance = round(mean(result$distance_in_km), 2)
        n_nps = length(na.omit(result$count_nps))
        n_nps_st_0 = sum(result$medic_nps < 0, na.rm = T)
        n_nps_ge_0_and_st_50 = sum(result$medic_nps >= 0 & result$medic_nps < 50, na.rm = T)
        n_nps_ge_50 = sum(result$medic_nps >= 50, na.rm = T)
        avg_n_tags = mean(result$count_tags, na.rm = T)
        max_n_tags = max(result$count_tags, na.rm = T)
        median_n_tags = median(result$count_tags, na.rm = T)
        
      } else {
        
        n_medics = 0
        avg_distance = NA
        n_nps = NA
        n_nps_st_0 = NA
        n_nps_ge_0_and_st_50 = NA
        n_nps_ge_50 = NA
        avg_n_tags = NA
        max_n_tags = NA
        median_n_tags = NA
        
      }
      
      summary = rbind(summary,
                      data.table("SearchRadius in km" = radius, 
                                 "Workplace Type" = workplace_type, 
                                 "Ø Air distance" = avg_distance,
                                 "# Medics" = n_medics, 
                                 "# NPS" = n_nps,
                                 "# NPS < 0" = n_nps_st_0, 
                                 "# NPS >= 0 and < 50" = n_nps_ge_0_and_st_50, 
                                 "# NPS >= 50" = n_nps_ge_50, 
                                 "Ø # matching tags" = avg_n_tags,
                                 "max # matching tags" = max_n_tags,
                                 "median # matching tags" = median_n_tags)
      )
      
      medics[[workplace_type]][[radius]] = result
    }
  }
  
  return(list(summary = summary,
              medics = medics))
}

