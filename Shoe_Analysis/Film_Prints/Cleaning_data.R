#!/usr/bin/Rscript

library(EBImage)
library(ShoeScrubR)
library(tidyverse)
library(future)
plan(multicore)

base_dir <- "/home/srvander/Projects/CSAFE/2018_Longitudinal_Shoe_Project/Shoe_Analysis/Film_Prints"

imgs <- list.files(file.path(base_dir, "aligned_with_mask", "image"), full.names = T)
composite <- list.files(file.path(base_dir, "aligned_with_mask", "aligned_composite"), full.names = T)

# set.seed(21094270)
# df <- tibble(
#   file = sample(composite, 10),
#   img = purrr::map(file, readImage),
#   useful_frame = purrr::map(img, ~.[,,3]),
#   data = purrr::map(useful_frame, image_to_df, filter_val = NULL)
# )
#
# df2 <- df %>% select(file, data) %>% unnest(c(data)) %>% group_by(file) %>%
#   summarize(mean = mean(value), sd = sd(value), n = length(data), black_pixels = sum(data == 0))

# shoe_summary <- tibble(file = composite) %>%
#   mutate(stats = furrr::future_map(file, function(x) {
#     z <- readImage(x)[,,3]
#     z2 <- bwlabel(1 - z)
#     region_sizes <- table(z2[z2 != 0])
#
#     tibble(mean = mean(z), sd = sd(z), n = length(z), black_pixels = sum(z == 0),
#            mean_region_size = mean(region_sizes), sd_region_size = sd(region_sizes), n_regions = length(region_sizes))
#   })) %>%
#   unnest(c(stats))
# write.csv(shoe_summary, file.path(base_dir, "summary_stats.csv"))


shoe_list <- read_csv("Clean_Data/shoe-info.csv")

shoe_summary <- read_csv(file.path(base_dir, "summary_stats.csv"))[,-1] %>%
  mutate(date = str_extract(file, "\\d{8}") %>% lubridate::ymd(),
         file = as.character(file),
         basename = basename(file),
         shoe_id = str_extract(basename, "\\d{6}[LR]"),
         iteration = str_extract(basename, "5_\\d_\\d_") %>% str_remove("^5_") %>% str_remove("_1_"),
         pair_id = str_extract(shoe_id, "^\\d{3}")) %>%
  left_join(select(shoe_list, pair_id = ShoeID, Brand, Size, WearerID)) %>%
  group_by(shoe_id, iteration) %>%
  arrange(date) %>%
  mutate(visit = row_number()) %>%
  mutate(people = str_extract(str_to_lower(basename), "(csafe_)?[A-z]{1,}_[A-z]{1,}_[A-z]{0,}\\.tif") %>% str_remove("csafe_") %>% str_remove("\\.tif") %>% str_replace_all("_{1,}", "_"))

shoe_summary %>%
  filter(iteration %in% c("1", "2")) %>%
  mutate(Size = factor(Size, levels = c("7 W", "7.5 W", "8 W", "8.5 W", "10 M", "10.5 M"),
                       ordered = T)) %>%
ggplot(aes(x = visit, y = black_pixels, group = interaction(shoe_id, iteration))) +
  geom_line(alpha = .2) + facet_grid(Brand~Size) +
  scale_y_continuous("Number of black pixels (thresholded image)")


shoe_summary %>%
  filter(iteration %in% c("1", "2")) %>%
  mutate(Size = factor(Size, levels = c("7 W", "7.5 W", "8 W", "8.5 W", "10 M", "10.5 M"),
                       ordered = T)) %>%
  ggplot(aes(x = visit, y = n_regions, group = interaction(shoe_id, iteration))) +
  geom_line(alpha = .2) + facet_grid(Brand~Size) +
  scale_y_continuous("Number of black pixels (thresholded image)")

shoe_summary %>%
  mutate(people = str_replace_all(people, c("^_" = "", "boekohff" = "boekhoff", "byrson|byson" = "bryson", "jekruse|kruse|kurse" = "kruse", "hdzwart|zwart" = "hdzwart", "hanrahahn" = "hanrahan"))) %>%
  extract(people, into = c("people1", "people2", "people3"), regex = "([A-z]*)_([A-z]*)_([A-z]*)?") %>%
  ggplot(aes(x = factor(visit), y = mean, color = people3, group = interaction(shoe_id, iteration))) +
  geom_jitter() + facet_wrap(~Brand)
