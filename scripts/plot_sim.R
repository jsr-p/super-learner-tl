library(data.table)
library(dplyr)
library(ggplot2)

source("scripts/data.R")
source("scripts/models.R")


set.seed(get_seed())

x_grid <- seq(-4, 4, length.out = 2000)
df_grid <- data.frame(X = x_grid)
dt_sim <- simulate(n = 100)

print(paste("Estimating super learner for each outcome..."))
sls <- lapply(
  c("Y1", "Y2", "Y3", "Y4"),
  function(outcome) {
    sl_fit <- fit_superlearner(dt_sim, outcome)
    sl <- sl_fit$fit
    preds <- data.frame(
      Y = predict(sl, newdata = df_grid)$pred,
      Simulation = outcome,
      X = df_grid$X
    )
    r2 <- compute_r2(
      preds = sl$SL.predict |> as.vector(),
      y = sl_fit$y_train
    )
    return(list(
      preds = preds,
      coef = sl$coef,
      sl = sl,
      x_train = sl_fit$x_train,
      y_train = sl_fit$y_train,
      r2 = r2
    ))
  }
)

r2s <- lapply(sls, function(x) x$r2)

# extracts coefficients
coefs <- lapply(sls, function(x) x$coef)
coefs_df <- as.data.frame(do.call(cbind, coefs))
colnames(coefs_df) <- c("Y1", "Y2", "Y3", "Y4")

write.csv(coefs_df, "output/vdlsim_coefs.csv")

preds <- rbindlist(lapply(sls, function(x) x$preds))

dt_plot <- data.table(
  X = rep(x_grid, 4),
  Y = c(fn1(x_grid), fn2(x_grid), fn3(x_grid), fn4(x_grid)),
  Simulation = rep(c("Y1", "Y2", "Y3", "Y4"), each = length(x_grid))
)
simp_plot <- melt(
  dt_sim[, .(
    X, Y1, Y2, Y3, Y4
  )],
  id.vars = "X",
  variable.name = "Simulation",
  value.name = "Y"
)


plot_sim <- function(preds = NULL) {
  p <- ggplot() +
    geom_line(
      data = dt_plot,
      aes(X, Y, color = "True Curve"),
      linewidth = 1
    ) +
    geom_point(
      data = simp_plot,
      aes(X, Y, color = "Data Points"),
      alpha = 0.5
    )

  if (!is.null(preds)) {
    p <- p + geom_line(
      data = preds,
      aes(X, Y, color = "Super Learner"),
      linewidth = 1
    )
  }

  p <- p +
    facet_wrap(
      ~Simulation,
      ncol = 2,
      scales = "free",
      labeller = labeller(Simulation = c(
        "Y1" = "Simulation 1",
        "Y2" = "Simulation 2",
        "Y3" = "Simulation 3",
        "Y4" = "Simulation 4"
      ))
    ) +
    labs(
      y = "Y",
      x = "X",
      color = ""
    ) +
    theme_minimal() +
    theme(
      text = element_text(size = 14),
      axis.title = element_text(size = 15),
      strip.text = element_text(face = "bold", size = 18),
      legend.position = "bottom",
      legend.text = element_text(size = 13),
      plot.background = element_rect(fill = "white", color = NA)
    ) +
    scale_color_manual(
      values = c(
        "True Curve" = "blue",
        "Super Learner" = "red",
        "Data Points" = "black"
      )
    ) +
    scale_x_continuous(breaks = seq(-4, 4, 1))

  return(p)
}

p <- plot_sim()
ggsave("figs/vdlsim.png", p, width = 10, height = 6, dpi = 300, bg = "white")
p <- plot_sim(preds = preds)
ggsave("figs/vdlsim_fit.png", p, width = 10, height = 6, dpi = 300, bg = "white")


# Inspect
# Close to 0.8 using true regression function.
simulate(n = 10000) |>
  _[, .(
    1 - sum((Y1 - fn1(X))^2) / sum((Y1 - mean(Y1))^2)
  )]
# ~5; Var(Y) s.t. R^2 = 0.8
simulate(n = 10000) |>
  _[, lapply(.SD, var), .SDcols = c("Y1", "Y2", "Y3", "Y4")]
