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

align_imgs <- function(im1, im2, ...) {
  scale <- ceiling(max(pmax(dim(im1), dim(im2)))/2048)
  im1_scaled <- img_resize(im1, w = round(dim(im1)[1]/scale), h = round(dim(im1)[2]/scale))
  im2_scaled <- img_resize(im2, w = round(dim(im2)[1]/scale), h = round(dim(im2)[2]/scale))
  alignment_res <- align_scaled_matrix(
    im1_scaled, im2_scaled, scale = scale, ...)
  aligned <- align_images_matrix(im1, im2, alignment_res$matrix)

  list(
    im1 = aligned$im1, im2 = aligned$im2,
    matrix = alignment_res$matrix,
    alignment_result = alignment_res$alignment_result
  )
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

toGray <- function(x) {
  colorMode(x) <- 0
  return(x)
}

base_dir <- "/home/srvander/Projects/CSAFE/2018_Longitudinal_Shoe_Project/Shoe_Analysis/Film_Prints"

imgs <- list.files(file.path(base_dir, "aligned_with_mask", "aligned_composite"), full.names = T)

dirpath <- file.path(base_dir, "aligned_with_mask")

set.seed(21094270)
df <- tibble(file = imgs,
             base = basename(file)) %>%
  extract(base, into = c("shoe_id", "checksum", "foot", "date", "print_type", "rep", "person1", "person2", "person3"),
          regex = "(\\d{3})(\\d{3})([RL])_(\\d{8})_5_(\\d)_(\\d)_(?:csafe_)?([A-z]{1,}?)_{1,}([A-z]{1,}?)_{1,}([A-z]{0,}?)\\.tif", remove = F) %>%
  mutate(date = lubridate::ymd(date),
         print_type = as.numeric(print_type),
         rep = as.numeric(rep)) %>%
  select(shoe_id, foot, date, file) %>%
  group_by(shoe_id, foot, date) %>%
  nest(files = c(file)) %>%
  ungroup()

plan(multicore)

furrr::future_walk(df$files, function(files){
  im1 <- readImage(files$file[1]) %>% img_rotate(90) %>% img_autocrop(pad = 80) %>% normalize()
  im2 <- readImage(files$file[2]) %>% img_rotate(90) %>% img_autocrop(pad = 80) %>% normalize()

  joint_name <- files$file[1] %>% basename() %>% str_replace("5_[12]_1", "5_*_1")

  aligned <- align_imgs(1 - im1[,,3], 1 - im2[,,3])
  joint <- joint_img(list(im1 = aligned$im1, im2 = aligned$im2))

  joint_min <- pmin(joint[,,1], joint[,,2]) %>% toGray()
  joint_mean <- (toGray(joint[,,1]) + toGray(joint[,,2]))/2

  tiff::writeTIFF(joint_min, file.path(dirpath, "joint_min", joint_name), bits.per.sample = 16L)
  tiff::writeTIFF(joint_mean, file.path(dirpath, "joint_mean", joint_name), bits.per.sample = 16L)
})

