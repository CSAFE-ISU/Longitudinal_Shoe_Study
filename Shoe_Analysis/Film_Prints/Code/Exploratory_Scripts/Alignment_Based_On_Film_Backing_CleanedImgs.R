library(EBImage)
library(ShoeScrubR)
library(tidyverse)

set.seed(3142095)

img_output_dir <- "~/Projects/CSAFE/2018_Longitudinal_Shoe_Project/Shoe_Analysis/Film_Prints/FFT_aligned/"
lss_dir <- "/lss/research/csafe-shoeprints/ShoeImagingPermanent"

# For a bunch of images...
full_imglist <- list.files(lss_dir,
                           pattern = "00[4-9]\\d{3}[L]_\\d{8}_5_._1_.*_.*_.*", full.names = T)
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
    im_dim = purrr::map(img, dim)
  )

align_scan_data <- select(scan_info, ShoeID, Shoe_foot, date, rep, Brand, Size, img) %>%
  mutate(rep = paste0("img", str_sub(rep, 1, 1))) %>%
  tidyr::spread(key = rep, value = img) %>%
  mutate(aligned = purrr::map2(img1, img2, fft_align, signal = 0))


# shoe_misalign_plots <- function(dfrow) {
#   res <- dfrow$aligned[[1]]$res
#   res <- purrr::map(res, ~img_pad_to_size(., ceiling(dim(res[[1]])/100) * 100, value = 1))
#   res_equal <- purrr::map(res, equalize)
#   png(filename = file.path(img_output_dir,
#                            sprintf("FFT_Aligned_Equalized_Clean_Img_%s%s_%s.png",
#                                    dfrow$ShoeID, dfrow$Shoe_foot, dfrow$date)),
#       width = 600*4, height = 2*600*2, units = "px", res = 300)
#   layout(matrix(c(1, 2, 3, 6, 1, 4, 5, 6), nrow = 2, byrow = T))
#   ShoeScrubR:::plot_imlist(res)
#   title(main = sprintf("FFT Aligned\nCleaned Shoe\n%s%s,\n%s", dfrow$ShoeID, dfrow$Shoe_foot, dfrow$date))
#   plot(res[[1]])
#   title(main = "Original Print")
#   plot(res_equal[[1]])
#   title(main = "Contrast Equalized")
#   plot(res[[2]])
#   plot(res_equal[[2]])
#   ShoeScrubR:::plot_imlist(res_equal)
#   title(main = "Contrast Equalized\nFFT Aligned Shoe")
#   dev.off()
# }
#
# misaligned <- c(2, 3, 4, 6, 7, 8, 13, 14, 16, 18)
# purrr::map(misaligned, ~shoe_misalign_plots(align_scan_data[.,]))

align_scan_data_inv <- select(scan_info, ShoeID, Shoe_foot, date, rep, Brand, Size, img) %>%
  mutate(img = purrr::map(img, ~1 - .)) %>%
  mutate(rep = paste0("img", str_sub(rep, 1, 1))) %>%
  tidyr::pivot_wider(names_from = rep, values_from = img) %>%
  mutate(aligned = purrr::map2(img1, img2, fft_align, signal = 1))

par(mfrow = c(4, 9))
purrr::walk(align_scan_data$aligned[1:9], ~ShoeScrubR:::plot_imlist(.$res))
purrr::walk(align_scan_data_inv$aligned[1:9], ~ShoeScrubR:::plot_imlist(.$res))
purrr::walk(align_scan_data$aligned[10:18], ~ShoeScrubR:::plot_imlist(.$res))
purrr::walk(align_scan_data_inv$aligned[10:18], ~ShoeScrubR:::plot_imlist(.$res))


shoe_misalign_plots <- function(dfrow) {
  res <- dfrow$aligned[[1]]$res
  res <- purrr::map(res, ~img_pad_to_size(., ceiling(dim(res[[1]])/100) * 100, value = 1))
  res_equal <- purrr::map(res, equalize)
  png(filename = file.path(img_output_dir,
                           sprintf("FFT_Aligned_Equalized_Clean_Img_Inv_%s%s_%s.png",
                                   dfrow$ShoeID, dfrow$Shoe_foot, dfrow$date)),
      width = 600*4, height = 2*600*2, units = "px", res = 300)
  layout(matrix(c(1, 2, 3, 6, 1, 4, 5, 6), nrow = 2, byrow = T))
  ShoeScrubR:::plot_imlist(res)
  title(main = sprintf("FFT Aligned\nCleaned Shoe\n%s%s,\n%s", dfrow$ShoeID, dfrow$Shoe_foot, dfrow$date))
  plot(res[[1]])
  title(main = "Original Print")
  plot(res_equal[[1]])
  title(main = "Contrast Equalized")
  plot(res[[2]])
  plot(res_equal[[2]])
  ShoeScrubR:::plot_imlist(res_equal)
  title(main = "Contrast Equalized\nFFT Aligned Shoe")
  dev.off()
}

misaligned <- c(2, 3, 4, 6, 7, 8, 13, 14, 16, 18)
purrr::map(misaligned, ~shoe_misalign_plots(align_scan_data[.,]))

