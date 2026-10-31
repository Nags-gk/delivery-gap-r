# Download the DataCo CSV from a pinned mirror commit and verify its size. Source of record: Constante, Silva and
# Pereira (2019), Mendeley Data, CC BY 4.0. The file (~96 MB) is not committed.
url <- paste0("https://raw.githubusercontent.com/ashishpatel26/DataCo-SMART-SUPPLY-CHAIN-FOR-BIG-DATA-ANALYSIS/",
              "7a466e7a4e9a8705c9b7b081dc081d2d16907fbc/DataCoSupplyChainDataset.csv")
dest <- file.path("data", "DataCoSupplyChainDataset.csv")
expected <- 95729629
dir.create("data", showWarnings = FALSE)
if (!file.exists(dest) || file.size(dest) != expected) {
  options(timeout = 600)
  download.file(url, dest, mode = "wb", quiet = TRUE)
}
stopifnot("unexpected file size" = file.size(dest) == expected)
cat("ok:", dest, file.size(dest), "bytes\n")
