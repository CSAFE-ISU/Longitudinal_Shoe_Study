#!/usr/bin/Rscript

library(EBImage)
library(ShoeScrubR)
library(tidyverse)
library(RNiftyReg)
library(future)
plan(multicore)

align_scaled_matrix <- function(im1_scaled, im2_scaled, scale, ...) {

  args <- list(...)
  if (!"init" %in% names(args) & length(dim(im1_scaled)) == 2) args$init = diag(c(1, 1, 1, 1))
  if (!"estimateOnly" %in% names(args)) args$estimateOnly = T

  # if (length(dim(im1_scaled)) > 2) {
  #   # args$sourceMask <- 1 - im1_scaled[,,1]
  #   # colorMode(args$sourceMask) <- 0
  #   args$source <- 1 - im1_scaled[,,2]
  #   colorMode(args$source) <- 0
  # } else {
    args$source <- 1 - im1_scaled
  # }

  # if (length(dim(im2_scaled)) > 2) {
  #   # args$targetMask <- 1 - im2_scaled[,,1]
  #   # colorMode(args$targetMask) <- 0
  #   args$target <- 1 - im2_scaled[,,2]
  #   colorMode(args$target) <- 0
  # } else {
    args$target <- 1 - im2_scaled
  # }
  args$scope <- "rigid"

  res <- do.call(niftyreg, args)

  scale_mat <- matrix(1, nrow = 4, ncol = 4)
  scale_mat[1:2,4] <- scale

  res$forwardTransforms[[1]] <- res$forwardTransforms[[1]]*scale_mat
  res$reverseTransforms[[1]] <- res$reverseTransforms[[1]]*scale_mat

  im1transmat <- matrix(0, nrow = 3, ncol = 2)
  im1transmat[1:2,] <- t(res$reverseTransforms[[1]][1:2, 1:2])
  im1transmat[3, 1:2] <- res$reverseTransforms[[1]][1:2, 4]

  list(matrix = im1transmat, alignment_result = res)
}

align_images_matrix <- function(im1, im2, affine_mat) {

  im1trans <- EBImage::affine(im1, m = affine_mat, output.dim = dim(im1)[1:2], bg.col = img_mode(im1))

  end_dim <- pmax(dim(im1trans), dim(im2))

  pad1dim <- end_dim - dim(im1trans)
  pad2dim <- end_dim - dim(im2)

  im1trans <- im1trans %>% img_pad(right = pad1dim[1], bottom = pad1dim[2], value = img_mode(.))
  im2trans <- im2 %>% img_pad(right = pad2dim[1], bottom = pad2dim[2], value = img_mode(.))

  list(im1 = im1trans, im2 = im2trans)
}


fft2d_fix <- function(im1, im2) {
  i1 <- fft(im1)
  i2 <- fft(im2)
  ecp <- i1*Conj(i2)
  ifft <- Re(fft(ecp/sqrt(ecp * Conj(ecp)), inv = T))
  imdim <- floor(pmax(dim(im1), dim(im2))/3)

  ifft_max <- max(ifft[1:imdim[1],1:imdim[2]])

  c(which(rowSums(ifft == ifft_max) == 1), which(colSums(ifft == ifft_max) == 1))
}

fft2d_angle <- function(im1, im2) {
  # Resample images to polar coordinates

  im1df <-
}

align_imgs <- function(im1, im2, ...) {
  scale <- ceiling(max(pmax(dim(im1), dim(im2)))/2048)
  max_dims <- pmax(dim(im1), dim(im2))
  im1_scaled <- img_resize(im1, w = round(dim(im1)[1]/scale), h = round(dim(im1)[2]/scale))
  im2_scaled <- img_resize(im2, w = round(dim(im2)[1]/scale), h = round(dim(im2)[2]/scale))
  alignment_res <- align_scaled_matrix(
    im1_scaled, im2_scaled, scale = scale, ...)

  aligned <- align_images_matrix(im1, im2, alignment_res$matrix)
  var1 <- var(as.numeric(aligned[[1]] - aligned[[2]]))
  if (var1 > .0001) {
    shift_fix <- fft2d_fix(aligned$im1, aligned$im2)
    tmat <- c(1, 0, 0, 1, -shift_fix) %>% matrix(nrow = 3, ncol = 2, byrow = T)

    # Only shift if it's less than 1/3 of any given dimension
    if (sum(abs(tmat) > floor(max_dims/3)) > 0) {
      tmat <- matrix(c(1, 0, 0, 1, 0, 0), nrow = 3, ncol = 2, byrow = T)
    }

    aligned2 <- align_images_matrix(aligned$im1, aligned$im2, tmat)
    var2 <- var(as.numeric(aligned2[[1]] - aligned2[[2]]))
    # Only keep if it's an improvement
    if (var2 < var1) {
      list(im1 = aligned2$im1, im2 = aligned2$im2,
           matrix = alignment_res$matrix,
           fine_matrix = tmat,
           alignment_result = alignment_res$alignment_result)
    } else {
      list(im1 = aligned$im1, im2 = aligned$im2, matrix = alignment_res$matrix,
           alignment_result = alignment_res$alignment_result)
    }
  } else {
    list(im1 = aligned$im1, im2 = aligned$im2, matrix = alignment_res$matrix,
         alignment_result = alignment_res$alignment_result)
  }
}

joint_img <- function(x) {
  # print(dim(x$im1))
  # print(dim(x$im2))
  # print(dim(pmin(x$im1, x$im2)))
  if (length(dim(x$im1)) > 2 | length(dim(x$im2)) > 2) {
    rgbImage(x$im1[,,2], x$im2[,,2], pmin(x$im1, x$im2)[,,2])
  } else {
    rgbImage(x$im1, x$im2, pmin(x$im1, x$im2))
  }
}




base_dir <- "/home/srvander/Projects/CSAFE/2018_Longitudinal_Shoe_Project/Shoe_Analysis/Film_Prints"

imgs <- list.files(file.path(base_dir, "aligned_with_mask", "image"), full.names = T)
composite <- list.files(file.path(base_dir, "aligned_with_mask", "aligned_composite"), full.names = T)

set.seed(21094270)
df <- tibble(file = imgs,
             base = basename(file)) %>%
  extract(base, into = c("shoe_id", "checksum", "foot", "date", "print_type", "rep", "person1", "person2", "person3"),
          regex = "(\\d{3})(\\d{3})([RL])_(\\d{8})_5_(\\d)_(\\d)_(?:csafe_)?([A-z]{1,}?)_{1,}([A-z]{1,}?)_{1,}([A-z]{0,}?)\\.tif", remove = F) %>%
  mutate(date = lubridate::ymd(date),
         print_type = as.numeric(print_type),
         rep = as.numeric(rep)) %>%
  mutate_at(vars(matches("person")), str_to_lower) %>%
  mutate_at(vars(matches("person")), str_replace_all, c("boekohff" = "boekhoff", "byrson|byson" = "bryson", "jekruse|kruse|kurse" = "jekruse", "hdzwart|zwart" = "hdzwart", "hanrahahn" = "hanrahan")) %>%
  group_by(shoe_id, foot) %>%
  nest(files = c(file, base, date, print_type, rep, person1, person2, person3)) %>%
  ungroup() %>%
  sample_n(size = 3) %>%
  unnest(c(files)) %>%
  mutate(
    img = purrr::map(file, readImage),
    mask = purrr::map(str_replace(file, "/image/", "/composite_mask/"), readImage)
  )

df <- df %>%
  mutate(img = purrr::map2(img, mask, ShoeScrubR:::exaggerate_contrast)) %>%
  mutate(useful_frame = purrr::map(img, ~({
    colorMode(.) <- 0
    img_rotate(., 90) %>%
      img_autocrop()
  })))

df_wide <- df %>%
  select(-file, -base, -mask, -img) %>%
  pivot_wider(names_from = print_type, names_prefix = "print", values_from = useful_frame) %>%
  mutate(aligned = purrr::map2(print1, print2, align_imgs)) %>%
  mutate(joint = purrr::map(aligned, joint_img)) %>%
  mutate(diff = purrr::map(joint, ~({
    if (sum(.[,,1] != .[,,2]) > 0) {
      tmp <- normalize(.[,,1] - .[,,2])
    } else {
      tmp <- .[,,1]-.[,,2]
    }
    colorMode(tmp) <- 0
    tmp
  } )))

df_wide <- df_wide %>%
  mutate(var = purrr::map_dbl(diff, ~var(as.numeric(.)))) %>%
  mutate(var2 = purrr::map_dbl(joint, ~sqrt(var(as.numeric(.[,,1])) + var(as.numeric(.[,,2]))))) %>%
  mutate(var_fact = purrr::map2_dbl(var, var2, ~.x/.y))

df2 <- df %>%
  mutate(
    img = purrr::map(file, readImage)
  )

df2_wide <- df2 %>% select(-file, -base, -mask) %>%
  mutate(useful_frame = purrr::map(img, ~({
    x <- .#[,,3]
    colorMode(x) <- 0
    img_rotate(x, 90) %>%
      img_autocrop()
  }))) %>%
  select(-img) %>%
  pivot_wider(names_from = print_type, names_prefix = "print", values_from = useful_frame) %>%
  mutate(aligned = purrr::map2(print1, print2, align_imgs, precision = "double")) %>%
  mutate(joint = purrr::map(aligned, joint_img)) %>%
  mutate(diff = purrr::map(joint, ~({
    tmp <- normalize(.[,,1] - .[,,2])
    colorMode(tmp) <- 0
    tmp
  } )))

df2_wide <- df2_wide %>%
  mutate(var = purrr::map_dbl(diff, ~var(as.numeric(.)))) %>%
  mutate(var2 = purrr::map_dbl(joint, ~sqrt(var(as.numeric(.[,,1])) + var(as.numeric(.[,,2]))))) %>%
  mutate(var_fact = purrr::map2_dbl(var, var2, ~.x/.y))

par(mfrow = c(2, 9))
purrr::walk(c(df_wide$joint, df2_wide$joint), plot)

## Conclusion: the normalized image is aligned slightly better than the
## non-normalized method.

par(mfrow = c(2, 9))
purrr::walk2(c(df_wide$diff, df2_wide$diff), c(df_wide$var_fact, df2_wide$var_fact), function(x, y) {
  plot(x)
  text(x = 0, y = 0, labels = sprintf("var = %0.4f", y), adj = c(-0.5, -1))
})
