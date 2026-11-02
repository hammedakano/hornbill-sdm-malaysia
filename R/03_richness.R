# Stack binary maps into predicted hornbill richness and map hotspots.
suppressPackageStartupMessages({ library(terra); library(ggplot2) })
files <- list.files("outputs/species", "_binary.tif$", full.names = TRUE)
rich <- sum(rast(files))
writeRaster(rich, "outputs/hornbill_richness.tif", overwrite = TRUE, datatype = "INT1U")

d <- as.data.frame(rich, xy = TRUE, na.rm = TRUE); names(d)[3] <- "richness"
g <- ggplot(d, aes(x, y, fill = richness)) + geom_raster() +
  scale_fill_viridis_c(option = "magma", direction = -1, name = "Predicted\nspecies") +
  coord_equal() + labs(x = "Longitude", y = "Latitude",
                       title = paste0("Predicted hornbill richness (", length(files), " species)")) +
  theme_bw(base_size = 10)
ggsave("outputs/figures/hornbill_richness.png", g, width = 6, height = 6.5, dpi = 200)

ca <- cellSize(rich, unit = "km")
tab <- do.call(rbind, lapply(0:length(files), function(k)
  data.frame(species_count = k, area_km2 = round(global((rich == k) * ca, "sum", na.rm = TRUE)[1, 1]))))
write.csv(tab, "outputs/tables/richness_area.csv", row.names = FALSE)

# Per-species suitability panel
sfiles <- list.files("outputs/species", "_suitability.tif$", full.names = TRUE)
dd <- do.call(rbind, lapply(sfiles, function(f) {
  x <- as.data.frame(rast(f), xy = TRUE, na.rm = TRUE); names(x)[3] <- "suit"
  x$species <- gsub("_", " ", sub("_suitability.tif", "", basename(f))); x
}))
g2 <- ggplot(dd, aes(x, y, fill = suit)) + geom_raster() +
  scale_fill_viridis_c(name = "Suitability", limits = c(0, 1)) +
  facet_wrap(~species, ncol = 4) + coord_equal() + labs(x = NULL, y = NULL) +
  theme_bw(base_size = 8) + theme(strip.text = element_text(face = "italic"), axis.text = element_blank())
ggsave("outputs/figures/suitability_by_species.png", g2, width = 10, height = 6, dpi = 200)
