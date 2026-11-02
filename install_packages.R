pkgs <- c("terra", "ranger", "mgcv", "gbm", "pROC", "ggplot2")
install.packages(setdiff(pkgs, rownames(installed.packages())))
