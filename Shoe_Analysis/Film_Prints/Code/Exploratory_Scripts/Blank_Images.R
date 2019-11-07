library(EBImage)
library(ShoeScrubR)
library(tidyverse)

set.seed(3142095)

img_output_dir <- "~/Projects/CSAFE/2018_Longitudinal_Shoe_Project/Shoe_Analysis/Film_Prints/FFT_aligned/"
lss_dir <- "/lss/research/csafe-shoeprints/ShoeImagingPermanent"

# For a bunch of images...
full_imglist <- list.files("/lss/research/csafe-shoeprints/ShoeImagingPermanent/",
                           pattern = "00[4-9]\\d{3}[L]_\\d{8}_5_._1_.*_.*_.*", full.names = T)
dir <- "/tmp/film-prints"
if (!dir.exists(dir)) dir.create(dir)

file.copy(full_imglist, file.path(dir, basename(full_imglist)))
imglist <- file.path(dir, basename(full_imglist))


blank_imglist <- list.files(".", pattern = ".tiff", full.names = T)

blank_imgs <- tibble(
  file = blank_imglist,
  img = purrr::map(file, readImage)
  )

mag <- function(x) Re(x * Conj(x))

blank_imgs <- blank_imgs %>%
  mutate(
    img_hanning = ShoeScrubR:::hanning_list(img),
    fourier = ShoeScrubR:::fft_list(img_hanning)
  )

par(mfrow = c(4, 8))
purrr::walk(blank_imgs$img, ~plot(equalize(., levels = 512)))
purrr::walk(blank_imgs$img_hanning, ~plot(equalize(., levels = 512)))
purrr::walk(blank_imgs$fourier, ~plot(normalize(mag(.)^.1)))
purrr::walk(blank_imgs$fourier, ~plot(normalize(mag(.))))


res <- fft_align(blank_imgs$img_hanning[[7]], blank_imgs$img_hanning[[8]])

ShoeScrubR:::plot_imlist(purrr::map(res$res, equalize))

# Perform deconvolution of images in the frequency domain
bkgd_img <- fft(blank_imgs$img_hanning[[3]])

foreground_img <- fft(blank_imgs$img_hanning[[7]])

new_img <- fft(foreground_img/bkgd_img, inv = T)
