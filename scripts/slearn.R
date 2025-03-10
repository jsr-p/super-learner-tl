library(SuperLearner)
library(randomForest)
library(gbm)
library(nnet)
library(gam)
library(ipred)
library(BART)
library(xgboost)
library(data.table)
library(polspline)

source("scripts/data.R")


# Define all learners
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
  "SL.xgboost",
  "SL.randomForest",
  "SL.glm",
  "SL.polymars"
)

get_preds <- function(mod) {
  preds <- predict(mod)$pred |> as.vector()
  return(preds)
}
compute_r2 <- function(preds, y) {
  num <- (y - preds)^2 |> sum()
  denom <- (y - mean(y))^2 |> sum()
  r_squared <- 1 - num / denom
  return(r_squared)
}

predict_models <- function(
    obs,
    outcome,
    sl_fit) {
  y_train <- obs[[outcome]]
  x_train <- obs[, .(X)]
  best_learner <- names(which.min(sl_fit$cvRisk))
  # Predictions
  preds_sl <- predict(sl_fit, newdata = x_train)
  preds_all <- preds_sl$library.predict
  df_preds <- preds_all |> as.data.frame() # prediction base learners
  res <- cbind(
    df_preds,
    data.frame(
      # superlearner and discrete learner predictions
      superlearner = preds_sl$pred,
      discrete_learner = preds_all[, best_learner]
    )
  ) |> as.data.table()
  r2_res <- res[, lapply(.SD, compute_r2, y = y_train)] |>
    _[, outcome := outcome]
  return(r2_res)
}

fit_model <- function(obs, outcome) {
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
}

# Estimate models on the four outcomes; then simulate 100 rounds
# of data and predict the outcomes using the fitted models
set.seed(get_seed())
obs <- simulate(100)
fitted_models <- lapply(
  c("Y1", "Y2", "Y3", "Y4"),
  fit_model,
  obs = obs
)
fitted_models <- setNames(fitted_models, c("Y1", "Y2", "Y3", "Y4"))

sim_round <- function() {
  obs <- simulate(100)
  return(rbindlist(
    lapply(
      c("Y1", "Y2", "Y3", "Y4"),
      \(outcome) predict_models(
        obs = obs,
        outcome = outcome,
        sl_fit = fitted_models[[outcome]]
      )
    )
  ))
}

num_rounds <- 100
results <- lapply(
  1:num_rounds,
  function(i) {
    cat(sprintf("Simulating round: %02d/100 \n", i))
    sim_round()
  }
)

df_all <- rbindlist(results)
write.csv(df_all, "output/slearn_results.csv", row.names = FALSE)
