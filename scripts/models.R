library(SuperLearner)
library(randomForest)
library(gbm)
library(nnet)
library(gam)
library(ipred)
library(BART)
library(xgboost)
library(data.table)


compute_r2 <- function(preds, y) {
  num <- (y - preds)^2 |> sum()
  denom <- (y - mean(y))^2 |> sum()
  r_squared <- 1 - num / denom
  return(r_squared)
}

# Helper for fitting a superlearner for the simulation plots.
# Copied from scripts/slearn.R
fit_superlearner <- function(obs, outcome) {
  gam_learners <- create.Learner(
    "SL.gam",
    tune = list(deg.gam = c(2, 3, 4))
  )
  bag_learners <- create.Learner(
    "SL.ipredbagg",
    tune = list(cp = c(0.0, 0.1, 0.01))
  )
  nn_learners <- create.Learner(
    "SL.nnet",
    tune = list(size = c(2, 3, 4, 5))
  )
  loess_learners <- create.Learner(
    "SL.loess",
    tune = list(span = c(0.75, 0.5, 0.25, 0.1))
  )

  all_learners <- c(
    gam_learners$names,
    nn_learners$names,
    bag_learners$names,
    loess_learners$names,
    "SL.randomForest",
    "SL.xgboost",
    "SL.glm",
    "SL.polymars"
  )

  y_train <- obs[[outcome]]
  x_train <- obs[, .(X)]
  sl_fit <- SuperLearner(
    Y = y_train,
    X = x_train,
    family = gaussian(),
    SL.library = all_learners,
    cvControl = list(V = 10),
    method = "method.NNLS"
  )
  return(list(
    fit = sl_fit,
    x_train = x_train,
    y_train = y_train
  ))
}
