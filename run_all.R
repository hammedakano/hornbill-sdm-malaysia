t0 <- Sys.time()
for (s in c("R/01_prepare_data.R", "R/02_model_species.R", "R/03_richness.R")) { message("\n== ", s); source(s) }
message("\nDone in ", round(difftime(Sys.time(), t0, units = "mins"), 1), " min")
