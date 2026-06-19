######################################### 
# GO/KEGG enrichment для AD та PD

# Пакети для enrichment
library(clusterProfiler)
BiocManager::install("org.Hs.eg.db")
library(org.Hs.eg.db)
library(dplyr)

# Підготовка списків білків (ProteinID → EntrezID)
# Завантажуємо таблиці DE
sig_ADvsControl <- readRDS("sig_ADvsControl.rds")
sig_PDvsControl <- readRDS("sig_PDvsControl.rds")

# Конвертація ProteinID → EntrezID
AD_entrez <- bitr(
  sig_ADvsControl$ProteinID,   # ← ТУТ МИ ВИКОРИСТОВУЄМО ЦЮ КОЛОНКУ
  fromType = "UNIPROT",
  toType = "ENTREZID",
  OrgDb = org.Hs.eg.db
)
# Подивитись, які ID були успішно конвертовані
AD_entrez
# Подивитись, які ID НЕ конвертувалися
unmapped_AD <- setdiff(sig_ADvsControl$ProteinID, AD_entrez$UNIPROT)
unmapped_AD
# Ти побачиш список тих білків, які не знайшли EntrezID.

# обрізати isoforms (для  вирішення проблеми конвертації)
sig_ADvsControl$ProteinID_clean <- sub("-.*", "", sig_ADvsControl$ProteinID)

AD_entrez <- bitr(
  sig_ADvsControl$ProteinID_clean,
  fromType = "UNIPROT",
  toType = "ENTREZID",
  OrgDb = org.Hs.eg.db
)

PD_entrez <- bitr(
  sig_PDvsControl$ProteinID,   # ← І ТУТ ТАК САМО
  fromType = "UNIPROT",
  toType = "ENTREZID",
  OrgDb = org.Hs.eg.db
)

#Перевірити:
AD_entrez
PD_entrez

# обрізати isoforms
sig_PDvsControl$ProteinID_clean <- sub("-.*", "", sig_PDvsControl$ProteinID)

PD_entrez <- bitr(
  sig_PDvsControl$ProteinID_clean,
  fromType = "UNIPROT",
  toType = "ENTREZID",
  OrgDb = org.Hs.eg.db
)

#Перевірити:
PD_entrez

# GO Biological Process enrichment
# AD
ego_AD <- enrichGO(
  gene          = AD_entrez$ENTREZID,
  OrgDb         = org.Hs.eg.db,
  keyType       = "ENTREZID",
  ont           = "BP",
  pAdjustMethod = "BH",
  pvalueCutoff  = 0.05,
  qvalueCutoff  = 0.05,
  readable      = TRUE
)

# PD
ego_PD <- enrichGO(
  gene          = PD_entrez$ENTREZID,
  OrgDb         = org.Hs.eg.db,
  keyType       = "ENTREZID",
  ont           = "BP",
  pAdjustMethod = "BH",
  pvalueCutoff  = 0.05,
  qvalueCutoff  = 0.05,
  readable      = TRUE
)

# Подивитися перші рядки:
head(ego_AD)
head(ego_PD)

# Перетворити в таблицю:
as.data.frame(ego_AD)
as.data.frame(ego_PD)

# ЯК ЗБЕРЕГТИ РЕЗУЛЬТАТИ
write.csv(as.data.frame(ego_AD), "GO_BP_AD.csv", row.names = FALSE)
write.csv(as.data.frame(ego_PD), "GO_BP_PD.csv", row.names = FALSE)

# DOTPLOT (найкращий варіант)
library(enrichplot)
dotplot(ego_AD, showCategory = 15)
dotplot(ego_PD, showCategory = 15)

# ЗБЕРЕГТИ ВЕЛИКИЙ ГРАФІК У PNG (найкрасивіше)
png("GO_AD_dotplot.png", width = 3000, height = 2000, res = 300)
dotplot(ego_AD, showCategory = 15)
dev.off()

png("GO_PD_dotplot.png", width = 3000, height = 2000, res = 300)
dotplot(ego_PD, showCategory = 15)
dev.off()

# KEGG enrichment
# AD
ekegg_AD <- enrichKEGG(
  gene          = AD_entrez$ENTREZID,
  organism      = "hsa",
  pvalueCutoff  = 0.05
)

# PD
ekegg_PD <- enrichKEGG(
  gene          = PD_entrez$ENTREZID,
  organism      = "hsa",
  pvalueCutoff  = 0.05
)

# Зберігаємо результати у CSV
write.csv(as.data.frame(ekegg_AD), "KEGG_AD.csv",    row.names = FALSE)
write.csv(as.data.frame(ekegg_PD), "KEGG_PD.csv",    row.names = FALSE)

# Побудувати dotplot
dotplot(ekegg_AD, showCategory = 15)
dotplot(ekegg_PD, showCategory = 15)

# ЗБЕРЕГТИ ВЕЛИКИЙ ГРАФІК У PNG (найкрасивіше)
png("KEGG_AD_dotplot.png", width = 3000, height = 2000, res = 300)
dotplot(ekegg_AD, showCategory = 15)
dev.off()

png("KEGG_PD_dotplot.png", width = 3000, height = 2000, res = 300)
dotplot(ekegg_PD, showCategory = 15)
dev.off()


