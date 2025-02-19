posterior_area_plots <- function(draws,
                                 select_pars,
                                 label) {

  plot_title <- ggtitle("Posterior distributions",
                        "with medians and 90% intervals")
  mcmc_areas(draws,
             pars = select_pars,
             prob = 0.9,
             point_est = "median") +
    plot_title +
    labs(y = "parameter") +
    scale_y_discrete(label = label)
}


