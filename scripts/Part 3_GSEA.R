###############################################
### Frontal Cortex TMT Analysis — PXD007160
### Full automated pipeline for R
### “GSEA_pipeline.R”

# 1. Початкові кроки — директорія + DE таблиці
# Встанови директорію setwd("тут твоя директорія файлами для аналізу по 5 батчах")
setwd("D:/Courses/2026_Genomics_Proteomics/gr6_Project/2026_Gr6_Project/Project PXD007160")

library(dplyr)
library(tibble)
library(fgsea)
library(msigdbr)
library(ggplot2)
library(org.Hs.eg.db)
library(AnnotationDbi)

DE_ADvsControl <- read.csv("DE_ADvsControl.csv")
DE_PDvsControl <- read.csv("DE_PDvsControl.csv")
DE_ADvsPD      <- read.csv("DE_ADvsPD.csv")

# 2. Сформувати рангові вектори для GSEA
prepare_gsea_vector <- function(DE_table) {
  DE_table %>%
    filter(!is.na(logFC), !is.na(P.Value)) %>%
    mutate(ranking_metric = -log10(P.Value) * sign(logFC)) %>%
    arrange(desc(ranking_metric)) %>%
    select(ProteinID, ranking_metric) %>%
    tibble::deframe()
}

gsea_ADvsControl <- prepare_gsea_vector(DE_ADvsControl)
gsea_PDvsControl <- prepare_gsea_vector(DE_PDvsControl)
gsea_ADvsPD      <- prepare_gsea_vector(DE_ADvsPD)

# Збережи у форматі .rnk (Broad GSEA Desktop)
write.table(gsea_ADvsControl, "GSEA_vector_ADvsControl.rnk",
            sep = "\t", quote = FALSE, col.names = FALSE)

write.table(gsea_PDvsControl, "GSEA_vector_PDvsControl.rnk",
            sep = "\t", quote = FALSE, col.names = FALSE)

write.table(gsea_ADvsPD, "GSEA_vector_ADvsPD.rnk",
            sep = "\t", quote = FALSE, col.names = FALSE)

# 3. Функція clean_mapping() — 100% робочий мапінг Uniprot → HGNC SYMBOL
clean_mapping <- function(stats_vector) {

  # 1. Мапінг Uniprot → SYMBOL
  map <- AnnotationDbi::select(
    org.Hs.eg.db,
    keys = names(stats_vector),
    columns = c("SYMBOL"),
    keytype = "UNIPROT"
  )
  
  # 2. Прибираємо NA
  map <- map[!is.na(map$SYMBOL), ]
  
  # 3. Прибираємо псевдогени (закінчуються на P)
  map <- map[!grepl("P$", map$SYMBOL), ]
  
  # 4. Прибираємо символи з цифрами всередині (часто не HGNC)
  map <- map[grepl("^[A-Z]+[0-9]*$", map$SYMBOL), ]
  
  # 5. Підтягуємо статистику
  mapped <- stats_vector[map$UNIPROT]
  names(mapped) <- map$SYMBOL
  
  # 6. Агрегація дублікатів
  df <- data.frame(
    SYMBOL = names(mapped),
    stat = as.numeric(mapped)
  )
  
  df_agg <- df %>%
    group_by(SYMBOL) %>%
    summarise(stat = mean(stat), .groups = "drop")
  
  stats_final <- df_agg$stat
  names(stats_final) <- df_agg$SYMBOL
  
  sort(stats_final, decreasing = TRUE)
}

# Використовуємо clean_mapping()
stats_ADvsControl <- clean_mapping(gsea_ADvsControl)
stats_PDvsControl <- clean_mapping(gsea_PDvsControl)
stats_ADvsPD <- clean_mapping(gsea_ADvsPD)

# 4. Запускаємо GSEA
# Завантаження GO BP та Reactome gene sets
m_df <- msigdbr(
  species = "Homo sapiens",
  collection = "C5",
  subcollection = "BP"
)

gs_GO <- split(m_df$gene_symbol, m_df$gs_name)


# Функція для запуску GSEA + збереження CSV
run_gsea <- function(stats_vector, pathways) {
  fgseaRes <- fgsea(
    pathways = pathways,
    stats = stats_vector,
    minSize = 10,
    maxSize = 500
  )
  fgseaRes[order(fgseaRes$padj), ]
}

gsea_res_ADvsControl <- run_gsea(stats_ADvsControl, gs_GO)
gsea_res_PDvsControl <- run_gsea(stats_PDvsControl, gs_GO)
gsea_res_ADvsPD      <- run_gsea(stats_ADvsPD, gs_GO)

# 5. Плоти GSEA. Таблиця топ шляхів
# Перед plotGseaTable потрібно прибрати pathways з NA leadingEdge:
gsea_clean <- gsea_res_ADvsControl[!is.na(gsea_res_ADvsControl$pathway)]
topPathways <- gsea_clean$pathway[1:5]
plotGseaTable(
  pathways = gs_GO[topPathways],
  stats = stats_ADvsControl,
  fgseaRes = gsea_clean
)

# зберегти plotGseaTable() 
png("GSEA_table_top5_ADvsControl.png", width = 2000, height = 1500, res = 200)

plotGseaTable(
  pathways = gs_GO[topPathways],
  stats = stats_ADvsControl,
  fgseaRes = gsea_res_ADvsControl
)

dev.off()

pdf("GSEA_table_top5_ADvsControl.pdf", width = 12, height = 10)
plotGseaTable(
  pathways = gs_GO[topPathways],
  stats = stats_ADvsControl,
  fgseaRes = gsea_res_ADvsControl
)
dev.off()

gsea_res_ADvsControl_export <- gsea_res_ADvsControl[, !"leadingEdge"]
write.csv(
  gsea_res_ADvsControl_export,
  "GSEA_GO_BP_ADvsControl.csv",
  row.names = FALSE
)
# Зберегти у RDS (повний об’єкт без втрат)
saveRDS(gsea_res_ADvsControl, "GSEA_GO_BP_ADvsControl.rds")

################################################### 
# --- PDvsControl ---

# очистити результати
gsea_clean_PD <- gsea_res_PDvsControl[!is.na(gsea_res_PDvsControl$pathway)]

# топ-5 шляхів
topPathways_PD <- gsea_clean_PD$pathway[1:5]

# PNG
png("GSEA_table_top5_PDvsControl.png", width = 2000, height = 1500, res = 200)
plotGseaTable(
  pathways = gs_GO[topPathways_PD],
  stats = stats_PDvsControl,
  fgseaRes = gsea_clean_PD
)
dev.off()

# PDF
pdf("GSEA_table_top5_PDvsControl.pdf", width = 12, height = 10)
plotGseaTable(
  pathways = gs_GO[topPathways_PD],
  stats = stats_PDvsControl,
  fgseaRes = gsea_clean_PD
)
dev.off()

# CSV без leadingEdge
gsea_res_PDvsControl_export <- gsea_res_PDvsControl[, !"leadingEdge"]
write.csv(
  gsea_res_PDvsControl_export,
  "GSEA_GO_BP_PDvsControl.csv",
  row.names = FALSE
)

# RDS з leadingEdge
saveRDS(gsea_res_PDvsControl, "GSEA_GO_BP_PDvsControl.rds")

################################################## 
# Ось блок для ADvsPD
# --- ADvsPD ---

# очистити результати
gsea_clean_ADPD <- gsea_res_ADvsPD[!is.na(gsea_res_ADvsPD$pathway)]

# топ-5 шляхів
topPathways_ADPD <- gsea_clean_ADPD$pathway[1:5]

# PNG
png("GSEA_table_top5_ADvsPD.png", width = 2000, height = 1500, res = 200)
plotGseaTable(
  pathways = gs_GO[topPathways_ADPD],
  stats = stats_ADvsPD,
  fgseaRes = gsea_clean_ADPD
)
dev.off()

# PDF
pdf("GSEA_table_top5_ADvsPD.pdf", width = 12, height = 10)
plotGseaTable(
  pathways = gs_GO[topPathways_ADPD],
  stats = stats_ADvsPD,
  fgseaRes = gsea_clean_ADPD
)
dev.off()

# CSV без leadingEdge
gsea_res_ADvsPD_export <- gsea_res_ADvsPD[, !"leadingEdge"]
write.csv(
  gsea_res_ADvsPD_export,
  "GSEA_GO_BP_ADvsPD.csv",
  row.names = FALSE
)

# RDS з leadingEdge
saveRDS(gsea_res_ADvsPD, "GSEA_GO_BP_ADvsPD.rds")

