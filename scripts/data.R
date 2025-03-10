library(data.table)

fn1 <- function(x) {
  -2 * (x < -3) + 2.55 * (x > -2) - 2 * (x > 0) +
    4 * (x > 2) - 1 * (x > 3)
}
fn2 <- function(x) 6 + 0.4 * x - 0.36 * x^2 + 0.005 * x^3
fn3 <- function(x) 2.83 * sin((pi / 2) * x)
fn4 <- function(x) 4 * sin(3 * pi * x) * (x > 0)

# Simulation function
simulate <- function(n = 100) {
  data.table(id = 1:n, X = runif(n, -4, 4), U = rnorm(n)) |>
    _[
      ,
      let(
        Y1 = fn1(X) + U,
        Y2 = fn2(X) + U,
        Y3 = fn3(X) + U,
        Y4 = fn4(X) + U
      )
    ]
}

get_seed <- function() {
  return(1234)
}
