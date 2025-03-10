library(dplyr)
library(SuperLearner)
library(randomForest)
library(gbm)
library(nnet)
library(gam)
library(ipred)
library(BART)
library(xgboost)
library(data.table)
library(ggplot2)
library(data.table)
library(tmle)

source("scripts/models.R")

df <- fread("data/lalonde_data.csv") |>
  # Employed if positive earnings in 1978
  _[, Y := as.integer(re78 > 0)]

p <- ggplot(df, aes(x = re78, fill = factor(treat))) +
  geom_density(alpha = 0.5) +
  labs(x = "Income", y = "Density", fill = "Treatment") +
  ggtitle("Income in 1978 by Treatment") +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(hjust = 0.5, size = 18),
    plot.background = element_rect(fill = "white", color = NA)
  )
ggsave("figs/income_density.png", p, width = 8, height = 6, bg = "white")

# count treat/non-treat
df |>
  group_by(treat) |>
  summarise(n = n())

gam_learners <- create.Learner(
  "SL.gam",
  tune = list(deg.gam = c(2, 3, 4))
)
all_learners <- c(
  gam_learners$names,
  "SL.randomForest",
  "SL.xgboost",
  "SL.glm"
)


get_res <- function(tmle_fit) {
  tmle_fit <- tmle_fit$est
  res <- list(
    ATE = tmle_fit$ATE$psi,
    CI = tmle_fit$ATE$CI,
    pvalue = tmle_fit$ATE$pvalue
  )
  return(res)
}


# Define outcome (Y), treatment (A), and covariates (W)
Y <- df$Y
A <- df$treat
W <- df[, c(
  "age",
  "educ",
  "black",
  "hispan",
  "married",
  "nodegree",
  "re74",
  "re75"
)]
tmle_fit <- tmle(
  Y = Y, A = A, W = W,
  Q.SL.library = all_learners,
  g.SL.library = all_learners,
  family = "binomial",
)
summary(tmle_fit)
res <- get_res(tmle_fit)

# Estimate the effect of the treatment on the continuous outcome
Y_cont <- df$re78
tmle_fit_cont <- tmle(
  Y = Y_cont, A = A, W = W,
  Q.SL.library = all_learners,
  g.SL.library = all_learners,
  family = "gaussian",
)
summary(tmle_fit)
res_cont <- get_res(tmle_fit_cont)


# Convert res_cont to a dataframe
res_df <- rbind(
  data.frame(
    Estimate = c(res_cont$ATE, res_cont$CI, res_cont$pvalue),
    Type = c("ATE", "CI_Lower", "CI_Upper", "p-value")
  ) |> mutate(type = "cont"),
  data.frame(
    Estimate = c(res$ATE, res$CI, res$pvalue),
    Type = c("ATE", "CI_Lower", "CI_Upper", "p-value")
  ) |> mutate(type = "binary")
)
write.csv(res_df, "output/tmle_results.csv", row.names = FALSE)
weights <- data.frame(
  bin = tmle_fit$Qinit$coef,
  cont = tmle_fit_cont$Qinit$coef
)
write.csv(weights, "output/tmle_weights.csv")

print(tmle_fit$est$ATT$psi)
print(tmle_fit$est$ATE$psi) # additive effect
