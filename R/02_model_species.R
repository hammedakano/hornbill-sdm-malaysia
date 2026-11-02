# Per-species validation, ensemble and suitability maps.
source("config.R"); source("R/functions.R")
suppressPackageStartupMessages(library(terra))
md <- readRDS("outputs/model_data.rds"); vars <- md$vars
env <- rast("outputs/env_stack.tif")
unlink("outputs/species", recursive = TRUE); dir.create("outputs/species", showWarnings = FALSE)

cv_all <- list(); ens_tab <- list()
for (sp in md$modelled) {
  message("== ", sp)
  pres <- md$occ[md$occ$species == sp, c("lon", "lat")]
  pe <- extract(env, as.matrix(pres))
  dat <- rbind(cbind(pres, occ = 1, pe), cbind(md$bg[, c("lon", "lat")], occ = 0, md$bg[, names(env)]))
  dat <- dat[complete.cases(dat), ]
  f_r <- random_folds(nrow(dat), K_FOLDS, SEED)
  f_s <- spatial_block_folds(dat$lon, dat$lat, BLOCK_DEG, K_FOLDS, SEED)
  cv <- rbind(cross_validate(dat, vars, f_r, "Random"), cross_validate(dat, vars, f_s, "Spatial block"))
  cv$species <- sp; cv_all[[sp]] <- cv

  s <- aggregate(auc ~ model, cv[cv$scheme == "Spatial block", ], mean)
  s$w <- pmax(s$auc - 0.5, 0); s$w[s$auc < 0.7] <- 0
  if (sum(s$w) == 0) { message("  no model reached AUC 0.7; skipped"); next }
  s$w <- s$w / sum(s$w)
  fits <- lapply(setNames(s$model[s$w > 0], s$model[s$w > 0]), fit_model, df = dat, vars = vars)
  ens <- Reduce(`+`, lapply(names(fits), function(m) predict_raster(fits[[m]], env, vars) * s$w[s$model == m]))
  p_occ <- extract(ens, as.matrix(pres))[, 1]
  th <- unname(quantile(p_occ, 0.10, na.rm = TRUE))
  fn <- gsub(" ", "_", sp)
  writeRaster(ens, file.path("outputs/species", paste0(fn, "_suitability.tif")), overwrite = TRUE)
  writeRaster(ens >= th, file.path("outputs/species", paste0(fn, "_binary.tif")), overwrite = TRUE, datatype = "INT1U")
  ens_tab[[sp]] <- data.frame(species = sp, n_presence = nrow(pres),
                              ensemble_auc_spatial = round(sum(s$auc * s$w), 3),
                              models_used = paste(s$model[s$w > 0], collapse = " "),
                              threshold_p10 = round(th, 3))
}
cv_all <- do.call(rbind, cv_all)
write.csv(cv_all, "outputs/tables/cv_by_fold.csv", row.names = FALSE)
write.csv(do.call(rbind, ens_tab), "outputs/tables/ensemble_by_species.csv", row.names = FALSE)
summ <- aggregate(auc ~ species + scheme, cv_all, function(x) round(mean(x), 3))
write.csv(reshape(summ, idvar = "species", timevar = "scheme", direction = "wide"),
          "outputs/tables/cv_summary_by_species.csv", row.names = FALSE)
