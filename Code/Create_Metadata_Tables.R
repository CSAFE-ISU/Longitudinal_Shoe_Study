library(openxlsx)
library(tidyverse)
library(here)

shoeprint_data <- read.xlsx(here("shoeprints data.xlsx"), check.names = F, detectDates = T)

shoe_models <- shoeprint_data %>%
  mutate(Model = ifelse(Available.option == 1, Option.1.model.and.color, Option.2.model.and.color),
         Size = ifelse(Available.option == 1, Option.1.size, Option.2.size)) %>%
  select(ID, Cohort, Model, Size, Gender = `Tech..Men/Women`) %>%
  mutate(Brand = str_extract(Model, "Nike|Adidas"),
         Size = sprintf("%s %s", Size, Gender),
         Color = str_remove_all(Model, "((?:Nike|Adidas|.Men.|.Women.) )")) %>%
  select(-Model, -Gender) %>%
  mutate(ID = sprintf("%03d", as.numeric(ID)),
         Model = ifelse(Brand == "Nike", "Winflo 4", "Seeley")) %>%
  select(ShoeID = ID, Cohort, Brand, Model, Size, Color)


participant_data <- read.xlsx(here("PII/shoeprints_key.xlsx"), check.names = F, detectDates = T)

participants <- participant_data %>%
  mutate(WearerID = sapply(email, digest::digest) %>% factor(levels = unique(.)) %>% as.numeric()) %>%
  select(WearerID, ShoeID = ID, Weight_lbs = Weight, Height_ft = Height,
         Do.you.engage.in.any.of.the.activities.listed.bel:`As.a.study.participant,.how.often.do.you.anticipa`) %>%
  mutate(WearerID = sprintf("%03d", WearerID),
         ShoeID = sprintf("%03d", ShoeID))

left_join(shoe_models, participants) %>%
  write.csv(here("Clean_Data/shoe-info.csv"))


survey_data <- read.xlsx(here("Surveys/Organized surveys (Full and Clean).xlsx"),
                         check.names = T, detectDates = T, rows = 1:456) %>%
  mutate(ShoeID = sprintf("%03d", as.numeric(Participant.ID)),
         Timestamp = convertToDateTime(Timestamp)) %>%
  select(-starts_with("Participant.ID")) %>%
  select(32, 1:31) %>%
  set_names(str_replace(names(.), "Estimated.proportion.of.time.Shoes.were.worn.on.(.*)\\.\\.\\.Chart\\..\\.", "\\1_Clean")) %>%
  set_names(str_replace(names(.), "Estimated.proportion.of.time.shoes.were.worn.while.participating.in.(.*).since.your.last.visit.*", "\\1_Clean")) %>%
  set_names(c(names(.)[1:5], "Number.of.steps_Range1000", "Notes", "Hours.worn.per.week", "Hours.worn.per.week_Range10", "Percent.time.in.study.shoes.of.total.time.wearing.shoes", names(.)[11:32])) %>%
  set_names(tools::toTitleCase(names(.))) %>%
  set_names(str_replace(names(.), "\\.{1,}", "."))


write.csv(survey_data, here("Clean_Data/visit-info.csv"))

