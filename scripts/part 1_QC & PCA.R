### PIPELINE ДЛЯ PCA (TMT, Proteome Discoverer)
setwd("D:/Courses/2026_Genomics_Proteomics/gr6_Project/2026_Gr6_Project/to check script part 1_QC, PCA")

# Packages
packages <- c(
  "tidyverse", "limma", "pheatmap", "FactoMineR", "factoextra"
)

for (p in packages) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, dependencies = TRUE)
  }
  library(p, character.only = TRUE)
}

# Read ProteinGroups
files <- list.files(pattern = "frontal_batch[0-9]+__Proteins\\.txt",
                    full.names = TRUE)

prot_list <- lapply(files, function(f){
  batch <- str_extract(basename(f), "batch[0-9]+")
  read_tsv(f) %>% mutate(batch = batch)
})

prot_all <- bind_rows(prot_list)

# Read SDRF (metadata)
sdrf <- read_tsv("sdrf.tsv")
names(sdrf)

# Фільтр даних - ділянки мозку
sdrf_fc <- sdrf %>%
  filter(str_detect(`comment[data file]`, "frontal_cortex"))

# Правильний channel_map для колонок з точними назвами з grep:
channel_map <- tibble(
  tmt_channel = c(
    "F1: 126, Control",
    "F1: 127N, Sample",
    "F1: 127C, Sample",
    "F1: 128N, Sample",
    "F1: 128C, Sample",
    "F1: 129N, Sample",
    "F1: 129C, Sample",
    "F1: 130N, Sample",
    "F1: 130C, Sample",
    "F1: 131, Sample"
  ),
  sample_id = c(
    "Control_126",
    "Sample_127N",
    "Sample_127C",
    "Sample_128N",
    "Sample_128C",
    "Sample_129N",
    "Sample_129C",
    "Sample_130N",
    "Sample_130C",
    "Sample_131"
  )
)

# Витягуємо інтенсивності + #Peptides
df <- prot_all %>%
  select(Accession, `# Peptides`, starts_with("Abundance:")) %>%
  rename_with(~str_replace(.x, "Abundance: ", ""), starts_with("Abundance:"))

# Перейменовуємо канали → sample_id
df <- df %>%
  rename_with(
    ~ channel_map$sample_id[match(., channel_map$tmt_channel)],
    intersect(colnames(.), channel_map$tmt_channel)
  )

# Вибираємо один рядок на білок (найбільше пептидів)
df_unique <- df %>%
  group_by(Accession) %>%
  slice_max(`# Peptides`, n = 1, with_ties = FALSE) %>%
  ungroup()

# Створюємо числову матрицю
mat <- df_unique %>%
  select(Accession, all_of(channel_map$sample_id)) %>%
  column_to_rownames("Accession") %>%
  as.matrix()
colnames(mat)

# log2
mat <- log2(mat + 1)

# замінюємо NA
mat[!is.finite(mat)] <- min(mat[is.finite(mat)], na.rm = TRUE)

# прибираємо білки з нульовою варіацією
mat <- mat[apply(mat, 1, sd) > 0, ]

## QC перед PCA
# Перевірка кількості NA по білках
protein_na <- rowSums(!is.finite(mat))
summary(protein_na)

# Видаляємо білки з >50% NA
threshold_protein <- ncol(mat) * 0.5
mat <- mat[protein_na < threshold_protein, ]

# Перевірка кількості NA по зразках
sample_na <- colSums(!is.finite(mat))
print(sample_na)

# Автоматично видаляємо зразки з >20% NA
threshold_sample <- nrow(mat) * 0.2
bad_samples <- names(sample_na[sample_na > threshold_sample])

if (length(bad_samples) > 0) {
  message("Видаляю погані зразки: ", paste(bad_samples, collapse = ", "))
  mat <- mat[, !(colnames(mat) %in% bad_samples)]
}

# Перевірка SD по білках
protein_sd <- apply(mat, 1, sd)
summary(protein_sd)

# Видаляємо білки з SD = 0
mat <- mat[protein_sd > 0, ]

# Перевірка SD по зразках
sample_sd <- apply(mat, 2, sd)
print(sample_sd)

# Автоматично видаляємо зразки з SD < 0.1 (аномально плоскі)
flat_samples <- names(sample_sd[sample_sd < 0.1])

if (length(flat_samples) > 0) {
  message("Видаляю зразки з аномально низькою варіацією: ", paste(flat_samples, collapse = ", "))
  mat <- mat[, !(colnames(mat) %in% flat_samples)]
}

# Перевірка outlier‑ів PCA (попередній PCA)
pca_pre <- prcomp(t(mat), scale. = TRUE)
pc1 <- pca_pre$x[, 1]

# Виявляємо outlier‑ів за правилом 3 SD
pc1_mean <- mean(pc1)
pc1_sd <- sd(pc1)
outliers <- names(pc1[abs(pc1 - pc1_mean) > 3 * pc1_sd])

if (length(outliers) > 0) {
  message("Видаляю PCA‑outlier‑и: ", paste(outliers, collapse = ", "))
  mat <- mat[, !(colnames(mat) %in% outliers)]
}

# PCA
pca <- prcomp(t(mat), scale. = TRUE)

# таблиця для PCA
# Створюємо таблицю зразків із матриці
sample_annot <- tibble(
  sample_id = colnames(mat)
)

# Додаємо діагнози вручну (Ping et al. 2018)
sample_annot <- sample_annot %>%
  mutate(condition = case_when(
    sample_id == "Control_126" ~ "Control",
    sample_id == "Sample_127N" ~ "Control",
    sample_id == "Sample_130C" ~ "Control",
    sample_id == "Sample_131"  ~ "Control",
    
    sample_id == "Sample_127C" ~ "AD",
    sample_id == "Sample_128N" ~ "AD",
    sample_id == "Sample_128C" ~ "AD",
    
    sample_id == "Sample_129N" ~ "PD",
    sample_id == "Sample_129C" ~ "PD",
    sample_id == "Sample_130N" ~ "PD",
    
    TRUE ~ NA_character_
  ))

# Побудувати PCA‑dataframe
pca_df <- as.data.frame(pca$x) %>%
  rownames_to_column("sample_id") %>%
  left_join(sample_annot, by = "sample_id")

# Побудова PCA‑графіка
ggplot(pca_df, aes(PC1, PC2, color = condition)) +
  geom_point(size = 4) +
  theme_bw(base_size = 16)

ggsave("PCA_disease.png", width = 8, height = 6, dpi = 300)
write_tsv(pca_df, "PCA_coordinates.tsv")


# зробити вісь X широкою і читабельною
ggplot(pca_df, aes(PC1, PC2, color = condition)) +
  geom_point(size = 4) +
  theme_bw(base_size = 18) +
  theme(
    plot.margin = margin(20, 40, 20, 40),
    axis.text.x = element_text(size = 14, margin = margin(t = 12)),
    axis.title.x = element_text(size = 16)
  )
# збереження:
ggsave("PCA_disease_big.png", width = 10, height = 8, dpi = 300)
