library(tidyverse)
library(magrittr)
library(here)

base_folder <- file.path("Collection Procedures", "Original (Overleaf Export)") %>%
  here()

new_proc_folder <- file.path("Collection Procedures", "Documentation")

# Handle all image files
doc_files <- base_folder %>%
  list.files(., full.names = F, recursive = T) %>%
  extract(!grepl("*.zip", .) & !grepl("*.pdf", .))

file_df <- data_frame(path = doc_files,
           filename = basename(doc_files),
           folder = str_remove(doc_files, filename) %>% str_remove("/")) %>%
  mutate(
    new_folder = str_replace_all(folder, "[[:punct:] ]{1,}", "-") %>%
      str_replace("-$", "") %>%
      tools::toTitleCase(),
    new_filename = str_replace_all(filename, "main.tex", paste0(new_folder, ".tex")) %>%
      str_replace_all(., "title_page_1.tex", paste0(new_folder, ".tex")) %>%
      str_replace_all(., "[[:punct:] ]{1,}\\.tex$", ".tex"),
    file_hash = sapply(path, function(x) openssl::md5(file(file.path(base_folder, x))) %>% as.character)
  )

if (!dir.exists(here(new_proc_folder))) {
  dir.create(here(new_proc_folder))
}
file.copy(from = file.path(base_folder, file_df$path),
          to = file.path(here(new_proc_folder), file_df$new_filename),
          overwrite = T)

# Knit all tex files to pdf:
tex_files <- list.files(here(new_proc_folder), "*.tex$", full.names = T)
wd <- setwd(here("Collection Procedures/Documentation"))
sapply(tex_files, tinytex::latexmk, clean = T)

