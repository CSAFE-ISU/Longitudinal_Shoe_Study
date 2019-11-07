library(EBImage)
library(ShoeScrubR)
library(tidyverse)

set.seed(3142095)

img_output_dir <- "/home/srvander/Projects/CSAFE/2018_Longitudinal_Shoe_Project/Shoe_Analysis/Film_Prints"
lss_dir <- "/lss/research/csafe-shoeprints/ShoeImagingPermanent"

# For a bunch of images...
full_imglist <- list.files("/lss/research/csafe-shoeprints/ShoeImagingPermanent/",
                           pattern = "\\d{6}[LR]_\\d{8}_5_._1_.*_.*_.*", full.names = T)
dir <- "/tmp/film-prints"
if (!dir.exists(dir)) dir.create(dir)

file.copy(full_imglist, file.path(dir, basename(full_imglist)))
imglist <- file.path(dir, basename(full_imglist))

shoe_info <- read_csv("~/Projects/CSAFE/2018_Longitudinal_Shoe_Project/Clean_Data/shoe-info.csv") %>%
  filter(ShoeID %in% str_sub(basename(imglist), 1, 3)) %>%
  select(ShoeID, Brand, Size) %>%
  mutate(Size = str_remove(Size, "[ MW]") %>% parse_number()) %>%
  crossing(tibble(Mask_foot = c("R", "L"), Shoe_foot = c("L", "R")), ppi = c(200, 300)) %>%
  mutate(mask = purrr::pmap(list(Brand, Size, Mask_foot, ppi = ppi), shoe_mask))

rgb_align <- function(df) {
  thresh_intersect <- 1 - thresh((1 - df$img)*df$mask, w = 5, h = 5, offset = 0.02)
  rgbImage(1 - df$mask, df$img, thresh_intersect)
}

## Preprocess Shoes

dirpath <- file.path(img_output_dir, "aligned_with_mask")
for (i in imglist) {
  if (!file.exists(file.path(dirpath, "clean_img", basename(i)))) {
    scan_info <- tibble(
      file = i,
      ShoeID = str_extract(basename(file), "^\\d{3}"),
      Shoe_foot = str_extract(basename(file), "\\d{6}[RL]") %>% str_remove_all("\\d"),
      date = str_extract(basename(file), "\\d{8}") %>% parse_date(format = "%Y%m%d"),
      rep = str_extract(basename(file), "5_[12]_1") %>% str_remove("5_|_1")
    ) %>%
      left_join(unique(select(shoe_info, ShoeID, Brand, Size, Shoe_foot))) %>%
      mutate(
        img = purrr::map(file, EBImage::readImage, all = F),
        img = purrr::map(img, EBImage::channel, "luminance"),
        im_dim = purrr::map(img, dim)
      )
    if (max(scan_info$im_dim[[1]]) < 5000) {
      scan_info <- scan_info %>%
        mutate(ppi = purrr::map_dbl(im_dim, est_ppi_film)) %>%
        left_join(shoe_info) %>%
        mutate(align = purrr::map2(img, mask, rough_align))%>%
        mutate(aligned_img = purrr::map(align, "img"),
               aligned_img_thresh = purrr::map(aligned_img, ~thresh(., w = 250, h = 250)),
               aligned_mask = purrr::map2(align, aligned_img_thresh,
                                          ~(1 - .y) * ((round(.x$mask + .x$exag_img) >= 1))),
               clean_img = purrr::map2(aligned_img, aligned_mask,
                                       ~(normalize(.x)*(.y != 0) + (.y==0)) %>%
                                         normalize()),
               clean_img = purrr::map2(clean_img, align, ~{
                 tmp <- .y$mask %>% dilate(makeBrush(51, "disc"))
                 (tmp ==1 )*.x + (tmp != 1)
               }))


      tiff::writeTIFF(t(scan_info$aligned_img[[1]]), file.path(dirpath, "image", basename(i)), bits.per.sample = 16L)
      tiff::writeTIFF(t(scan_info$align[[1]]$exag_img), file.path(dirpath, "exaggerated_mask", basename(i)))
      tiff::writeTIFF(t(scan_info$align[[1]]$mask), file.path(dirpath, "mask", basename(i)))
      tiff::writeTIFF(t(rgb_align(scan_info$align[[1]])), file.path(dirpath, "aligned_composite", basename(i)))
      tiff::writeTIFF(t(scan_info$aligned_img_thresh[[1]] - 0.0), file.path(dirpath, "aligned_img_thresh", basename(i)))
      tiff::writeTIFF(t(scan_info$aligned_mask[[1]]), file.path(dirpath, "composite_mask", basename(i)))
      tiff::writeTIFF(t(scan_info$clean_img), file.path(dirpath, "clean_img", basename(i)), bits.per.sample = 16L)
    } else {
      message("Image ", i, " is too big (", scan_info$im_dim[[1]], ") to be automatically handled.")
    }
  }
}

