source("R/simulation_functions.R")

test_that("NPS 100", {
  expect_equal(nps(10), 100)
})

test_that("NPS 0", {
  expect_equal(nps(c(0, 10)), 0)
})

test_that("NPS -100", {
  expect_equal(nps(c(0, 0)), -100)
})

test_that("NPS 100", {
  expect_equal(nps(c(10, 10)), 100)
})

test_that("NPS 100", {
  expect_equal(nps(c(10, 10, NA)), 100)
})

test_that("NPS values >0 and <10", {
  expect_error(nps(c(10, -0.1)))
})

test_that("NA NPS", {
  expect_equal(nps(c(NA, NA)), NA)
})
