library(DBI)
library(RPostgres)

source("simulation_queries.R")


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


get_topic_attributes <- function(topic_name) {
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


get_simulated_medics <- function(
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
