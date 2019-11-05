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


match_pattern <- function(img, mask) {
  if (sum((mask - .5)^2 == .25) == length(mask)) { # mask is binary
    mask <- mask - (1 - dilate(mask, makeBrush(3, "disc")))
    mask[mask == 1] <- 1/sum(mask == 1)
    mask[mask == -1] <- -1/sum(mask == -1)
  }

  blur_radius <- round(sqrt(length(img))/65)
  brushSize <- round(sqrt(length(img))/70)*2 + 1
  brushSize2 <- round(sqrt(length(img))/28)*2 + 1

  tmp <- filter2(img, mask, boundary = 0)

  tmpblur <- gblur(tmp, blur_radius)

  blobs <- (normalize(equalize(dilate(tmpblur, makeBrush(brushSize, "disc")), range = range(tmpblur))) > .5)
  blobs_clean <- erode(blobs, makeBrush(brushSize2, "disc"))

  labeled_blobs <- EBImage::bwlabel(blobs_clean)

  regions <- bind_cols(
    data.frame(i = unique(labeled_blobs[labeled_blobs != 0])),
    computeFeatures.moment(labeled_blobs) %>% as.data.frame(),
    computeFeatures.shape(labeled_blobs) %>% as.data.frame()
  ) %>%
    filter(s.area > 10) %>%
    arrange(s.area, m.cx, m.cy)
}

compute_offset <- function(df, eps = c(5, 5)) { # eps in px
  stopifnot("m.cx" %in% names(df))

  # Calculate distances between x coordinates to try to get x periodicity
  xdists <- dist(df[,2]) %>%
    as.matrix() %>% as.data.frame() %>%
    mutate(df_row1 = 1:nrow(.)) %>%
    tidyr::pivot_longer(cols = -df_row1, names_to = "df_row2", values_to = "dist") %>%
    mutate_if(is.character, as.numeric) %>%
    filter(df_row1 < df_row2) %>%
    mutate(dist_row = 1:n()) %>%
    mutate(
      dist_min_diff = abs(dist - min(dist)),
      dist_div = ifelse(dist_min_diff <= eps[1],
                        1, min(dist[dist > eps[2]])),
      dist_mult = ifelse(dist_min_diff <= eps[1], 0, dist/dist_div),
      dist_mult_rd = round(dist_mult, 1),
      dist_mult_eps = abs(dist_mult_rd - dist_mult))

  xdel <- xdists %>% filter(dist_mult > 0) %>%
    summarize(xdel = mean(dist/dist_mult_rd)) %>% unlist() %>% as.numeric() %>% round()

  # Calculate distances between y coordinates to try to get y periodicity
  ydists <- dist(df[,3]) %>%
    as.matrix() %>% as.data.frame() %>%
    mutate(df_row1 = 1:nrow(.)) %>%
    tidyr::pivot_longer(cols = -df_row1, names_to = "df_row2", values_to = "dist") %>%
    mutate_if(is.character, as.numeric) %>%
    filter(df_row1 < df_row2) %>%
    mutate(dist_row = 1:n()) %>%
    mutate(
      dist_min_diff = abs(dist - min(dist)),
      dist_div = ifelse(dist_min_diff <= eps[2],
                        1, min(dist[dist > eps[2]])),
      dist_mult = ifelse(dist_min_diff <= eps[2], 0, dist/dist_div),
      dist_mult_rd = round(dist_mult, 1),
      dist_mult_eps = abs(dist_mult_rd - dist_mult))


  ydel <- ydists %>% filter(dist_mult > 0) %>%
    summarize(ydel = mean(dist/dist_mult_rd)) %>% as.numeric() %>% round()

  # get point closest to origin
  nmat <- as.matrix(df[,2:3])
  closest_point <- df[which.min(sqrt(rowSums(nmat^2))), 2:3]

  list(dx = xdel, dy = ydel, start = closest_point)
}

bkgd_pattern <- bkgd_offset <- readImage("film_mask_multi_200dpi.tiff")
bkgd_pattern <- bkgd_pattern/sum(bkgd_pattern)
bkgd_offset_big <- dilate(bkgd_offset, makeBrush(7, "disc"))

bkgd_offset_filt <- bkgd_offset - (1 - bkgd_offset_big)


bkgd_offset_filt[bkgd_offset_filt == 1] <- 1/sum(bkgd_offset_filt == 1)
bkgd_offset_filt[bkgd_offset_filt == -1] <- -1/sum(bkgd_offset_filt == -1)

match_pattern(1 - equalize(shoe), flop(bkgd_offset_filt))

match_pattern(bkgd_pattern, readImage("film_mask_minimal_200dpi.tiff"))

plot(1 - equalize(shoe))



plot(regions$m.cx, regions$m.cy)


get_dists <- filter2(bkgd_pattern, readImage("film_mask_minimal_200dpi.tiff"), 0)
