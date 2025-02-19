# Analyses to predict the effectiveness and waning of vaccines and previous infection against transmission and clinical outcomes of SARS-CoV-2 variants.

This repo contains analyses to:
 - fit a Bayesian model of the relationship between neutralising antibody titres and protective efficacies of vaccines and prior infection
 - use this model to predict VEs for other outcomes, vaccines, and waning
 - infer the plausible range of immune escape and intrinsic transmissibility for Omicron
 
This work is now under review in _Vaccine_ and available as a preprint at: https://doi.org/10.1101/2024.10.17.24314397 

See the preprint for detailed explanation of the analyses.

This model is a Bayesian implementation of the model described by [Khoury et al. 2020 Nature Medicine](https://doi.org/10.1038/s41591-021-01377-8) and used in [Cromer et al. 2021 Lancet Microbe](https://doi.org/10.1016/S2666-5247(21)00267-6). The code for that work can be found [here](https://github.com/InfectionAnalytics/COVID19-ProtectiveThreshold) and [here](https://github.com/InfectionAnalytics/SARS-CoV-2-Variants-and-Boosting---Lancet-Microbe). If you want to refer to the analyses in this repo, you should be citing them too.

The omicron analysis relies on detailed, rapid analyses of the ratio of reproduction numbers for Omicron and Delta ([here](https://twitter.com/cap1024/status/1466840869852651529)), and the increasing risk of reinfection ([here](https://www.medrxiv.org/content/10.1101/2021.11.11.21266068v2)) in South Africa, by South African scientists as part of [SACMC](https://sacovid19mc.github.io/).

It is also informed by vaccine effectiveness estimates against Delta and Omicron from the UK. VE estimates for Delta are presented in: [Andrews et al. (2021a)](https://doi.org/10.1101/2021.09.15.21263583) for the population-level effectiveness of the Pfizer and AstraZeneca vaccines (two doses) against clinical outcomes (death, severe disease, symptomatic infection) from the Delta variant over different periods of time post-administration, [Pouwels et al. (2021)](ttps://doi.org/10.1101/2021.09.28.21264260) and [Eyre et al. (2021)](https://doi.org/10.1101/2021.09.28.21264260) for the effectiveness against acquisition (symptomatic or asymptomatic) and onward transmission of breakthrough infections, respectively, of the Delta variant. VE estimates against Omicron are given in: [Andrews et al. (2021b)](https://www.medrxiv.org/content/10.1101/2021.12.14.21267615v1) and the [UK variant analyses](https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1046853/technical-briefing-34-14-january-2022.pdf).

To run the code in this repo, you will need to install the packages listed in `packages.R`, including the most recent Github version of [greta](https://github.com/greta-dev/greta). greta links to python and depends on TensorFlow so can be tricky to install. It's best to follow the instructions greta gives you, and look for help on the [greta forum](https://forum.greta-stats.org/) if you have any trouble.

Then you run the whole analysis using the `targets` package function `tar_make()` to run the whole analysis; fittng the model, producing validation statistics, producing plots, and outputting predictions. See [targets user manual](https://books.ropensci.org/targets/) for more details on how to use it.

Importantly, the `targets` workflow is set up such that data specific to this analysis are not coded in the core functionalities, so that you can easily adapt this framework to other data and use cases.

To use this workflow for other data, modify [R/get_neut_ratios_vaccine.R](R/get_neut_ratios_vaccine.R), [R/get_ve_estimates.R](R/get_ve_estimates.R), and [R/prep_ve_data_for_modelling.R](R/prep_ve_data_for_modelling.R) to talk to new data sources. Ensuing functions in the pipeline automatically extract the types of outcomes, immunity profiles, and pathogen strains from the input data, but you will need to doublecheck and modify any assumed relationships between immunity profiles (e.g., what would the relationship be between two doses of the same vaccine).

To implement the model without the Omicron extension, comment out the `add_omicron_model` target in the targets script, and any Omicron-specific outputs.

We provide a suite of functions for plotting the outcomes and parameter estimations from the model, you can use them, and make necessary modifications, following the example provided in the `targets.R` script.
