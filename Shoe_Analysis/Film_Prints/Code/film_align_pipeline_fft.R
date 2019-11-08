library(EBImage)
library(ShoeScrubR)
library(tidyverse)

set.seed(3142095)

img_output_dir <- "~/Projects/CSAFE/2018_Longitudinal_Shoe_Project/Shoe_Analysis/Film_Prints/FFT_aligned/"
lss_dir <- "/lss/research/csafe-shoeprints/ShoeImagingPermanent"

# For a bunch of images...
full_imglist <- list.files(lss_dir,
                           pattern = "00[4-9]\\d{3}[L]_\\d{8}_5_._1_.*_.*_.*", full.names = T)
dir <- "aligned_with_mask/image"
# if (!dir.exists(dir)) dir.create(dir)
#
# file.copy(full_imglist, file.path(dir, basename(full_imglist)))
imglist <- file.path(dir, basename(full_imglist))

shoe_info <- read_csv("~/Projects/CSAFE/2018_Longitudinal_Shoe_Project/Clean_Data/shoe-info.csv") %>%
  filter(ShoeID %in% str_sub(basename(imglist), 1, 3)) %>%
  select(ShoeID, Brand, Size) %>%
  mutate(Size = str_remove(Size, "[ MW]") %>% parse_number()) %>%
  crossing(tibble(Mask_foot = c("R", "L"), Shoe_foot = c("L", "R")), ppi = c(200, 300)) %>%
  mutate(mask = purrr::pmap(list(Brand, Size, Mask_foot, ppi = ppi), shoe_mask))


scan_info <- tibble(
  file = imglist,
  ShoeID = str_extract(basename(file), "^\\d{3}"),
  Shoe_foot = str_extract(basename(file), "\\d{6}[RL]") %>% str_remove_all("\\d"),
  date = str_extract(basename(file), "\\d{8}") %>% parse_date(format = "%Y%m%d"),
  rep = str_extract(basename(file), "5_[12]_1") %>% str_remove("5_|_1")
) %>%
  left_join(unique(select(shoe_info, ShoeID, Brand, Size, Shoe_foot))) %>%
  mutate(
    img = purrr::map(file, EBImage::readImage, all = F),
    img = purrr::map(img, EBImage::channel, "luminance"),
    img = purrr::map(img, t),
    im_dim = purrr::map(img, dim)
  ) %>%
  mutate(
    clean_file = file.path("aligned_with_mask/clean_img", basename(file)),
    clean =  purrr::map(clean_file, EBImage::readImage, all = F),
    clean = purrr::map(clean, EBImage::channel, "luminance"),
    clean = purrr::map(clean, t)
  )


align_scan_data <- select(scan_info, ShoeID, Shoe_foot, date, rep, Brand, Size, clean) %>%
  mutate(rep = paste0("clean", str_sub(rep, 1, 1))) %>%
  tidyr::spread(key = rep, value = clean) %>%
  mutate(aligned = purrr::map2(clean1, clean2, fft_align, signal = 0))

align_scan_data <- left_join(
  align_scan_data,
  select(scan_info, ShoeID, Shoe_foot, date, rep, Brand, Size, img) %>%
    mutate(rep = paste0("img", str_sub(rep, 1, 1))) %>%
    tidyr::spread(key = rep, value = img)
)

align_scan_data <- align_scan_data %>%
  mutate(im2angle = purrr::map_dbl(aligned, "rot_img_2_by"),
         im2trans = purrr::map(aligned, "translate_img_2_by")) %>%
  mutate(
    fix_align = purrr::map2(img1, img2, ShoeScrubR:::pad_img_match),
    fix_align = purrr::pmap(
      list(imlist = fix_align, angle = im2angle, vv = im2trans),
      function(imlist, angle, vv) {
        imdim <- dim(imlist[[1]])
        im2 <- imlist[[2]] %>%
          img_rotate(angle = angle, bg.col = 1, output.dim = imdim,
                     output.origin = round(imdim/2)) %>%
          img_translate(v = pmax(0, vv), bg.col = 1, output.dim = imdim)
        im1 <- imlist[[1]] %>%
          img_translate(v = -pmin(0, vv), bg.col = 1, output.dim = imdim)
        list(im1, im2)
      })
  )

par(mfrow = c(2, 9))
purrr::walk(align_scan_data$fix_align, plot_imlist)

sample_dist <- function(imlist, N = 1) {
  fcn <- function(imlist) mean((sample(imlist[[1]], size = length(imlist[[1]])) - imlist[[2]])^2)
  replicate(N, fcn(imlist), simplify = "vector")
}

pct_corresp <- function(imlist, middle_pct = c(1/2, 2/3), show_plot = T, equalize = F) {
  imdim <- dim(imlist[[1]])
  im_center <- round(imdim/2)
  middle_rad <- round(imdim * middle_pct/2) # "radius" from center
  start <- im_center - middle_rad
  end <- im_center + middle_rad
  idx <- mapply(seq, from = start, to = end, by = 1)

  if (equalize) {
    imlist_eq <- lapply(imlist, equalize)
  } else {
    imlist_eq <- imlist
  }

  # Crop down to central part of shoe
  imlist_eq <- lapply(imlist_eq, function(x) x[idx[[1]], idx[[2]]])


  # Difference between the equalized images
  sq_diff_img <- (imlist_eq[[1]] - imlist_eq[[2]])^2

  # Normalization - how much pixel-wise variation is there in each image
  # Best possible "alignment" sans spatial context:
  ordered_ssq <- mean((sort(imlist_eq[[1]]) - sort(imlist_eq[[2]]))^2)
    # Random chance "alignment" sans spatial context:
  random_ssq <- mean(sample_dist(imlist_eq))

  if (show_plot) plot(equalize(normalize(sq_diff_img)))

  tibble(image_sq_diff = mean(sq_diff_img), ordered_ssq = ordered_ssq, random_ssq = random_ssq, sqdiffimg = sq_diff_img)
}

par(mfrow = c(2, 9))
res <- purrr::map_df(align_scan_data$fix_align, pct_corresp, show_plot = T, equalize = F)
res <- bind_cols(align_scan_data[,1:5], res)
res <- res %>%
  mutate(shoe_date = paste0(ShoeID, Shoe_foot, " ", date),
         shoe_date = factor(shoe_date, levels = rev(shoe_date), ordered = T)) %>%
  mutate(prop = (image_sq_diff - ordered_ssq)/(random_ssq - ordered_ssq))

ggplot(data = res) +
  geom_segment(aes(x = ordered_ssq, xend = random_ssq, y = shoe_date, yend = shoe_date)) +
  geom_point(aes(x = image_sq_diff, y = shoe_date))
