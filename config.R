# Settings for the hornbill SDM pipeline.
MIN_RECORDS  <- 25        # species with fewer thinned records are not modelled
N_BACKGROUND <- 10000
BUFFER_KM    <- 50        # study area = land within this distance of any hornbill record
COR_CUTOFF   <- 0.7
BLOCK_DEG    <- 0.5       # about 55 km spatial blocks
K_FOLDS      <- 5
SEED         <- 2026
CANDIDATES   <- c("tempMin", "preciptn", "altitude", "roughness", "northness", "tempAvg")
