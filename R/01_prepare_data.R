# Environmental stack, cleaned occurrences and background points.
source("config.R"); source("R/functions.R")
suppressPackageStartupMessages(library(terra))
set.seed(SEED)

env <- rast(file.path("data/env", c("altitude.tif", "preciptn.tif", "roughness1.tif",
                                    "tempAvg.tif", "tempMin.tif", "aspect1.tif")))
names(env) <- c("altitude", "preciptn", "roughness", "tempAvg", "tempMin", "aspect")
# Aspect is circular, so use northness (cos of aspect) instead
env$northness <- cos(env$aspect * pi / 180)
env <- env[[c("altitude", "preciptn", "roughness", "tempAvg", "tempMin", "northness")]]
land <- !is.na(env$altitude)

occ <- read.csv("data/raw/hornbill_occurrences.csv")
names(occ) <- c("species", "lon", "lat")
n_raw <- table(occ$species)
occ <- occ[occ$species != "Upupa epops", ]           # hoopoe, not a hornbill
occ <- occ[!is.na(extract(env$altitude, as.matrix(occ[, c("lon", "lat")]))[, 1]), ]  # Peninsular Malaysia only
occ <- do.call(rbind, lapply(split(occ, occ$species), function(d) {
  cbind(species = d$species[1], thin_one_per_cell(d[, c("lon", "lat")], env))
}))
n_thin <- table(occ$species)
modelled <- names(n_thin)[n_thin >= MIN_RECORDS]

# Study area: land within BUFFER_KM of any hornbill record. This keeps background
# points in places that were actually surveyed (a target-group style correction
# for sampling bias) and leaves out Sumatra and southern Thailand, which have no
# records in this dataset.
allpts <- vect(occ, geom = c("lon", "lat"), crs = "EPSG:4326")
area <- aggregate(buffer(allpts, BUFFER_KM * 1000))
land <- mask(land, area); land[land == 0] <- NA
env <- mask(env, land)
bg <- spatSample(land, size = N_BACKGROUND, method = "random", na.rm = TRUE, xy = TRUE, values = FALSE)
bg <- data.frame(lon = bg[, 1], lat = bg[, 2])
bg_env <- extract(env, as.matrix(bg))
vars <- select_uncorrelated(cbind(bg, bg_env), CANDIDATES, COR_CUTOFF)
message("Predictors retained: ", paste(vars, collapse = ", "))

summary_tab <- data.frame(species = names(n_raw), records_all_malaysia = as.integer(n_raw))
summary_tab$records_peninsula_thinned <- as.integer(n_thin[summary_tab$species])
summary_tab$records_peninsula_thinned[is.na(summary_tab$records_peninsula_thinned)] <- 0
summary_tab$modelled <- summary_tab$species %in% modelled
write.csv(summary_tab[order(-summary_tab$records_peninsula_thinned), ],
          "outputs/tables/records_by_species.csv", row.names = FALSE)

writeRaster(env, "outputs/env_stack.tif", overwrite = TRUE)
saveRDS(list(occ = occ, bg = cbind(bg, bg_env), vars = vars, modelled = modelled), "outputs/model_data.rds")
