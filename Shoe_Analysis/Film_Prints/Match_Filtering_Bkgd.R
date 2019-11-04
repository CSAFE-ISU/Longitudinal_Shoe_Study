library(EBImage)
library(ShoeScrubR)
library(tidyverse)

lss_dir <- "/lss/research/csafe-shoeprints/ShoeImagingPermanent"
full_imglist <- list.files("/lss/research/csafe-shoeprints/ShoeImagingPermanent/",
                           pattern = "00[4-9]\\d{3}[L]_\\d{8}_5_._1_.*_.*_.*", full.names = T)
blank_imglist <- list.files(".", pattern = ".tiff", full.names = T)

mag <- function(x) Re(x * Conj(x))

blank_imgs <- tibble(
  file = blank_imglist,
  img = purrr::map(file, readImage)
) %>%
  mutate(
    img_hanning = ShoeScrubR:::hanning_list(img),
    fourier = ShoeScrubR:::fft_list(img_hanning)
  )

shoe <- readImage(full_imglist[[1]])
shoe_fft <- ShoeScrubR:::fft_list(ShoeScrubR:::hanning_list(list(shoe)))



par(mfrow = c(2, 2))
plot(normalize(log(mag(shoe_fft[[1]]))))
plot(shoe)
plot(normalize(log(mag(blank_imgs$fourier[[7]]))))
plot(normalize(log(mag(blank_imgs$fourier[[4]]))))


bkgd_pattern <- bkgd_offset <- readImage("film_mask_multi_200dpi.tiff")
bkgd_pattern <- bkgd_pattern/sum(bkgd_pattern)
bkgd_offset_big <- dilate(bkgd_offset, makeBrush(7, "disc"))

bkgd_offset_filt <- bkgd_offset - (1 - bkgd_offset_big)


bkgd_offset_filt[bkgd_offset_filt == 1] <- 1/sum(bkgd_offset_filt == 1)
bkgd_offset_filt[bkgd_offset_filt == -1] <- -1/sum(bkgd_offset_filt == -1)

tmp <- filter2(1 - equalize(shoe), flop(bkgd_pattern), boundary = .5)

clahe(tmp[,1:2600], 200, 200)

clahe(filter2(tmp[,1:2600], makeBrush(51, "Gaussian")), 200, 200)
