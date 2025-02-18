Methods Description
================
Nick Golding
07/12/2021

### Overview

This document describes the methods used to delineate plausible values
of the intrinsic transmissibility and immune evasion of the Omicron
variant of SARS-CoV-2. It is structured in three parts: - A summary of
Bayesian implementation of the model of vaccine efficacy - The extension
of this Bayesian model to available data on Omicron - Details on model
fitting by MCMC using the greta R package

### Vaccine efficacy model

The core of this analysis is a Bayesian implementation of a predictive
model of vaccine efficacy documented and validated in [Khoury et
al. (2020)](https://doi.org/10.1038/s41591-021-01377-8) and [Cromer et
al. (2021)](https://doi.org/10.1016/S2666-5247(21)00267-6). The original
publications estimate parameters by maximum likelihood, and focus on
predicting vaccine efficacies for different combinations of vaccine dose
and product, the outcome against which efficacy is measured, and the
SARS-CoV-2 variant, based on neutralising antibody titres. See those
publications for detailed analysis and validation.

This model assumes that each immune individual *i* in a population has
some neutralisation level*n*<sub>*i*, *v*</sub> to variant *v*, given by
the common (ie. base 10) logarithm of the titre of neutralising
antibody, relative to the mean neutralisation level produced by
infection with wild-type SARS-CoV-2. This indexing on wild-type
convalescent neutralisation levels enables comparability between studies
and across variants. The individual’s neutralisation level is assumed to
be drawn from a normal distribution with mean
*μ*<sub>*s*, *d*, *v*</sub> differing based on the source of their
immunity *s* (e.g. the vaccine dose or product), the number of days *d*
post-peak immunity (ie. the degree of waning) adnd the variant, and with
variance *σ*<sup>2</sup> giving the inter-individual variation in
neutralisation levels - assumed to be constant across variants, sources
of immunity, and levels of waning:

*n*<sub>*i*, *v*</sub> ∼ *N*(*μ*<sub>*s*, *d*, *v*</sub>, *σ*<sup>2</sup>)

For each individual and for each type of outcome *o* (e.g. death, severe
disease, infection, onward transmission) the probability that the
outcome is averted *E*<sub>*i*, *o*</sub> (the vaccine is effective for
that outcome) is given by a sigmoid function, parameterised by a
threshold neutralisation level *n*<sub>*o*, 50</sub> at which 50% of
outcome events are prevented, and a slope parameter *k* determining the
steepness of this relationship. Crucially, these parameters are assumed
to independent of the variant and source of immunity, enabling
prediction of vaccine efficacy to new situations.

*E*<sub>*o*</sub>(*n*<sub>*i*, *v*</sub>) = 1/(1 + *e*<sup> − *k*(*n*<sub>*i*, *v*</sub> − *n*<sub>*o*, 50</sub>)</sup>)

Note that this model can equivalently be interpreted as there being a
different deterministic threshold for each different *event* whereby
that outcome would occur in the absence of vaccination, and would not
occur if the neutralisation level is above the random threshold, where
the random thresholds are drawn from a logistic distribution with
location parameter *n*<sub>*o*, 50</sub> and scale parameter 1/*k*.

At the population level, the efficacy of immunity against a given
outcome from a given variant in a cohort with mean neutralisation level
*μ*<sub>*s*, *d*, *v*</sub> is the average probability over the whole
population of the outcome being averted. This is computed by integrating
the sigmoid function with respect to the normal distribution of
neutralisation levels. This integral has no closed form, so must be
computed by numerical approximation (Gauss-Legendre quadrature).

*P*<sub>*s*, *d*, *o*, *v*</sub> = ∫<sub> − ∞</sub><sup>∞</sup>*E*<sub>*o*</sub>(*n*<sub>*v*</sub>)*f*(*n*<sub>*v*</sub>\|*μ*<sub>*s*, *d*, *v*</sub>, *σ*<sup>2</sup>)*d**n*<sub>*v*</sub>

The mean neutralisation level *μ*<sub>*s*, *d*, *v*</sub> for a cohort
with immunity source *s* and number of days *d* since peak immunity from
that source is assumed to follow exponential decay with half-life of *H*
days, from a peak mean neutralisation level against that variant of
*μ*<sub>*s*, *v*</sub><sup>\*</sup> for each source:

*μ*<sub>*s*, *d*</sub> = *l**o**g*10(10<sup>*μ*<sub>*s*, *v*</sub><sup>\*</sup></sup>*e*<sup> − *d*/*H*</sup>)

The peak mean neutralisation level against a given variant is in turn
modelled as a log10 fold increase or decrease in neutralising antibody
titres that variant, relative to an index variant:

*μ*<sub>*s*, *v*</sub><sup>\*</sup> = *μ*<sub>*s*, 0</sub><sup>\*</sup> + *F*<sup>*v*</sup>

Where for the index variant *F*<sup>*v*</sup> = 0, for a variant with
immune escape relative to the index the *F*<sup>*v*</sup> &lt; 1, and
for a variant more susceptible to neutralisation than the index,
*F*<sup>*v*</sup> &gt; 1.

Among these model parameters, *μ*<sub>*s*, 0</sub><sup>\*</sup>,
*F*<sup>*v*</sup>, *H*, *σ*<sup>2</sup> can be estimated from
neutralisation assay experiments. The parameters *n*<sub>*o*, 50</sub>
(one per outcome) and *k* (one in total) must be learned by fitting the
model to data on population-level vaccine efficacy. In this Bayesian
implementation, the parameter *σ*<sup>2</sup> is kept fixed at the value
estimated by [Cromer et
al. (2021)](https://doi.org/10.1016/S2666-5247(21)00267-6),
*μ*<sub>*s*, 0</sub><sup>\*</sup>, *F*<sup>*v*</sup>, and *h* are given
informative priors based on estimates from [Khoury et
al. (2020)](https://doi.org/10.1038/s41591-021-01377-8) and [Cromer et
al. (2021)](https://doi.org/10.1016/S2666-5247(21)00267-6), and the
remaining parameters are given less informative priors. This enables the
model to update these parameters slightly based on the data, and fully
incorporate uncertainty in these parameters into predictions.

This model is fitted to estimates from [Andrews et
al. (2021a)](https://doi.org/10.1101/2021.09.15.21263583) of the
population-level efficacy of the Pfizer and AstraZeneca vaccines (two
doses) against clinical outcomes (death, severe disease, symptomatic
infection) from the Delta variant over different periods of time
post-administration, and estimates from [Pouwels et
al. (2021)](ttps://doi.org/10.1101/2021.09.28.21264260) and from [Eyre
et al. (2021)](https://doi.org/10.1101/2021.09.28.21264260) against
acquisition (symptomatic or asymptomatic) and onward transmission of
breakthrough infections, respectively, of the Delta variant.

The model likelihood for vaccine efficacy estimate *j* is defined as a
normal distribution over the logit-transformed estimate
VE<sub>*j*</sub>, with mean given by the logit-transformed predicted
efficacy for that combination of source, days post-administration,
outcome, and variant
*P*<sub>*s*<sub>*j*</sub>, *d*<sub>*j*</sub>, *o*<sub>*j*</sub>, *v*<sub>*j*</sub></sub>
and with variance given by the sum of the square of the standard error
of the estimate on the logit scale logit-SE<sub>*j*</sub><sup>2</sup>
(approximated from provided uncertainty intervals), and an additional
variance term *σ*<sub>ve</sub><sup>2</sup>, to represent any additional
errors in these estimates that may arise from inference on observational
data:

logit(VE<sub>*j*</sub>) ∼ *N*(logit(*P*<sub>*s*<sub>*j*</sub>, *d*<sub>*j*</sub>, *o*<sub>*j*</sub>, *v*<sub>*j*</sub></sub>), logit-SE<sub>*j*</sub><sup>2</sup> + *σ*<sub>ve</sub><sup>2</sup>)

All VE estimates covered events over a period of time, and
*d*<sub>*j*</sub> was taken as the midpoint of that period.

### Extension to Omicron

The vaccine efficacy model provides a method by which to map between
vaccine efficacies for different variants, outcomes, sources of
immunity, and degrees of waning. For a given value of the Omicron immune
escape parameter *F*<sup>O</sup> relative to Delta (with relative escape
parameter *F*<sup>*Δ*</sup> = 0) as an index variant, it is possible to
infer the degree of immune protection against acquisition and
transmission for a cohort with a given level of immunity. Combined with
the fraction of the population with some immunity, this enables
estimation of the reduction in transmission that could be expected, and
therefore the intrinsic transmissibility (*R*<sub>0</sub>) that the
variant must possess to explain observed rates of reproduction of the
virus. Given *F*<sup>O</sup> it is also possible to predict vaccine
efficacy against Omicron.

The parameter *F*<sup>O</sup> could be estimated directly from
neutralisation assays against Omicron. Since these are not yet
available, this analysis instead infers plausible values of
*F*<sup>O</sup> by treating it as a latent parameter in a Bayesian
model, and fitting the model to observational data on both reinfection
rates and reproduction rates of Delta and Omicron in South Africa. Note
that the aim of this analysis is not to provide a precise estimate of
any of these things, but to infer the range of values that are
consistent with available data, whilst accounting for and incorporating
as many sources of uncertainty as is possible.

Given the latent parameter *F*<sup>O</sup>, the model defines three
likelihoods over different sources of data:

-   estimates of the reinfection hazard ratio from [Pulliam et
    al. (2021)](https://www.medrxiv.org/content/10.1101/2021.11.11.21266068v2)
    for the recent period and for the period of the Delta wave

-   estimates of the current reproduction number of Delta from a
    presentation by [Carl Pearson,
    SACMC](https://twitter.com/cap1024/status/1466840869852651529)

-   estimates of the ratio of the reproduction numbers of Omicron
    compared to Delta (as estimated from SGTF vs non-SGTF case counts)
    from the same presentation

Broadly, these three parameters each inform three different unknowns in
the model: reinfection hazard ratios inform the degree of immune escape
of Omicron, relative to Delta; the reproduction number of Delta informs
the degree of immunity against Delta infection; and the ratio of
reproduction numbers informs the intrinsic transmissibility of Omicron
relative to Delta, after accounting for the degree of immune protection
against each. The likelihoods for these three sources of data are
detailed in turn below.

Note that all variables in the model that are uncertain and can
influence the estimates of transmissibility or immune escape are treated
as unknown parameters, even if thery are not quantities of interest or
if they are not identified from the data. This enables integration over
uncertainty in these parameters (ie. a Monte Carlo simulation) whilst
estimating parameters of interest.

#### Reinfection hazard ratios

[Pulliam et
al. (2021)](https://www.medrxiv.org/content/10.1101/2021.11.11.21266068v2)
provide modelled estimates over time of the ratio between two hazards
(rates of occurrence per unit time): the new infection hazard (rate of
new infections per person without previous infection), and the
reinfection hazard (rate of new infections among people who have had a
previous infection). These estiamtes are informed by data on sequential
infections from routine surveillance, and their model accounts for
imperfect and differential case ascertainment between the two groups.
They also provide an estimate of the ratio of these two hazards.

Since the force of infection will likely be the same for the two groups,
the ratio of the reinfection hazard to the infection hazard can be
interpreted as a proxy for the relative risk of infection between immune
and non-immune individuals. This can be loosely interpreted as an
estimate of one minus the efficacy of prior immunity against symptomatic
infection (because the detection process is likely dependent on clinical
presentation). Comparing the observed values of this parameter for the
recent period (approximately 0.3) and the Delta wave (approximately 0.1)
against the values predicted by the vaccine efficacy model for the
dominant variants for a given *F*<sup>O</sup> (and an assumed mean
neutralisation level among those with immunity) enables quantitative
inference about the degree of immune escape of Omicron relative to
Delta. Since this is a heavily modelled estimate and that vaccine
efficacy against symptomatic disease (to which the model is calibrated)
will be somewhat different from immunity against (detectable)
reinfection, a large degree of uncertainty is assigned to these
observations.

The likelihood for this data source is as follows:

*l**o**g*(*r̂*<sub>O</sub>) = *l**o**g*(1 − *P*<sub>*S*, *D*, symptoms, O</sub>) + *γ*

*l**o**g*(*r̂*<sub>*Δ*</sub>) = *l**o**g*(1 − *P*<sub>*S*, *D*, symptoms, *Δ*</sub>) + *γ*

*l**o**g*(*r*<sub>O</sub>) ∼ *N*(*l**o**g*(*r̂*<sub>O</sub>), *σ*<sub>*r*</sub><sup>2</sup>)

*l**o**g*(*r*<sub>*Δ*</sub>) ∼ *N*(*l**o**g*(*r̂*<sub>*Δ*</sub>), *σ*<sub>*r*</sub><sup>2</sup>)

where *l**o**g*(*r*<sub>*v*</sub>) denotes the log of the value, and
*l**o**g*(*r̂*<sub>*v*</sub>) the log of the expected value of the
reinfection hazard ratio during the period dominated by variant *v* (O
indicating Omicron and *Δ* Delta), computed from the log of one minus
the expected efficacy of prior immunity against symptomatic disease,
corrected by a log-offset parameter *γ* to absorb any multiplicative
bias in the hazard ratios (e.g. due to an incorrect specification of the
ascertainment parameters in the model used to infer the hazard ratios).
*P*<sub>*S*, *D*, symptoms, *v*</sub> is the population-level efficacy
against symptomatic disease from variant *v*, given immunity source *S*,
*D* days since peak immunity. This is defined by the parameters of the
vaccine effect model, *F*<sub>O</sub>, and a parameter
*μ*<sub>*s*, 0</sub><sup>\*</sup> for the baseline peak level of
immunity against the index variant (Delta), with standard half normal
prior to enforce that those with prior immunity must have had at minimum
the level of immunity conferred by a single wild-type infection. *D* has
a normal prior with mean of 120 days and standard deviation of 20 days,
to represent the average time since infection in the Delta wave.
*σ*<sub>*r*</sub> = 0.25 to reflect a significant degree of uncertainty
in the relationship between these estimates and the adjusted relative
risks, and *r*<sub>O</sub> = 0.3 and *r*<sub>*Δ*</sub> = 0.1, which were
read off Figure 5 in [Pulliam et
al. (2021)](https://www.medrxiv.org/content/10.1101/2021.11.11.21266068v2).

#### Delta reproduction number

Whilst the Delta variant is estimated to have the highest intrinsic
transmissibility of variants so far identified (estimates range from
6-8), estimates of the reproduction number in Gauteng Province, South
Africa at the time of the Omicron outbreak are largely just below 1,
indicating declining case counts. There were minimal lockdown or
distancing restrictions in place in Gauteng province during this time,
and [estimates of mobility](https://www.google.com/covid19/mobility/)
indicate that mixing rates are largely at or above baseline levels (with
the exception of visits to workplaces at a 7% reduction). The majority
of the reduction in transmission from R0 conditions in Gauteng is
therefore likely to be prior immunity from previous epidemic waves, with
some additional effect of vaccination. Given the multiple waves of
infections with different variants (wild-type, Beta, Delta), and
evidence of multiple renfections over this period (see Figure in
[Pulliam et
al. (2021)](https://www.medrxiv.org/content/10.1101/2021.11.11.21266068v2))
the level of immunity, and especially protection against Delta is likely
to be considerably higher than the protection provided by a single
infection against wild-type SARS-CoV-2. This degree of immunity can
therefore be inferred from an assumed R0 and estimate of the effective
reproduction number, given some assumptions about the fraction with any
immunity (*Q*) and the effect of human behaviour, public health and
social measures, and isolation of cases on transmission (*C*).

The likelihood on recent estimates of the reproduction number of Delta
in Gauteng Province is defined as as:

*R̂*<sub>eff</sub><sup>*Δ*</sup> = *R*<sub>0</sub><sup>*Δ*</sup> \* (1 − *C*) \* *I*<sup>*Δ*</sup>

*l**o**g*(*R*<sub>eff</sub><sup>*Δ*</sup>) ∼ *N*(*l**o**g*(*R̂*<sub>eff</sub><sup>*Δ*</sup>), *σ*<sub>*R*</sub><sup>2</sup>)

The reduction in transmission of the Delta variant due to immunity
*I*<sub>*Δ*</sub> is calculated as the product of the population-level
reductions due to the efficacy of immunity against acquisition
(*A*<sub>*Δ*</sub>) and onward transmission of breakthrough infections
(*T*<sub>*Δ*</sub>), each of which is calculated from the corresponding
immune efficacy for Delta, given the modelled level of peak immunity and
time since peak (as above) and the fraction of the population with
immunity *Q*.

*A*<sub>*Δ*</sub> = *Q*(1 − *P*<sub>*S*, *D*, acquisition, *Δ*</sub>) + (1 − *Q*)

*T*<sub>*Δ*</sub> = *Q*(1 − *P*<sub>*S*, *D*, transmission, *Δ*</sub>) + (1 − *Q*)

*I*<sub>*Δ*</sub> = *A*<sub>*Δ*</sub> \* *T*<sub>*Δ*</sub>

*Q* is assigned an informative normal prior with mean 0.8 and standard
deviation 0.05 (70-90% have some immunity), truncated to the unit
interval. To be conservative (leaning towards lower levels of immunity
effect and therefore higher intrinsic transmissibility), it is assumed
that *R*<sub>0, *Δ*</sub> = 6, at the lower end of international
estimates, and that *C* has a normal prior distribution with mean 0.2
(20% reduction in transmission), a standard deviation 0.1, and truncated
between 0 and 0.5 (maximum 50% reduction).
*R*<sub>eff</sub><sup>*Δ*</sup> = 0.8 and
*σ*<sub>*R*</sub><sup>2</sup> = 0.2 estimates are obtained from
[Pearson, SACMC
estimates](https://twitter.com/cap1024/status/1466840869852651529).

#### Reproduction number ratio

[Pearson, SACMC](https://twitter.com/cap1024/status/1466840869852651529)
provides a time-varying estimate of the ratio of the effective
reproduction number of Omicron to Delta in Gauteng Province, with
quantification of uncertainty. This estimate was computed from
timeseries of case counts with (assumed Omicron) and without (assumed
Delta) S-gene target failure. The expected reproduction number for each
variant can be computed as per *R̂*<sub>eff</sub><sup>*Δ*</sup> above and
the ratio computed, however since the non-immunity reduction term
1 − *C* contributes to both variants (those effects are likely to have
the same effect on both variant), this cancels out and gives the
following esxpression for the ration of reproduction numbers:

*R̂*<sub>eff</sub><sup>O</sup>/*R̂*<sub>eff</sub><sup>*Δ*</sup> = (*R*<sub>0</sub><sup>O</sup>/*R*<sub>0</sub><sup>*Δ*</sup>)(*I*<sub>*Δ*</sub>/*I*<sub>O</sub>)

*R*<sub>eff</sub><sup>O</sup>/*R*<sub>eff</sub><sup>*Δ*</sup> ∼ *N*(*R̂*<sub>eff</sub><sup>O</sup>/*R̂*<sub>eff</sub><sup>*Δ*</sup>, *σ*<sub>Reff</sub>)

*R*<sub>eff</sub><sup>O</sup>/*R*<sub>eff</sub><sup>*Δ*</sup> = 2.1 and
*σ*<sub>Reff</sub> = 0.41 to match the distribution from Pearson (across
estimates with the same and different generation intervals between
variants.

### Omicron vaccine efficacy estimates

[Andrews et al. (2021b)](https://doi.org/10.1101/2021.12.14.21267615)
provide estimates of vaccine efficacy against Omicron for different
products, numbers of doses, and periods post-vaccination. These
estimates provide direct information on the degree of immune escape of
Omicron versus Delta. The provided estimates for efficacy of AstraZeneca
vaccination against Omicron are however highly uncertain and have
negative point estimates, and the authors note that these estimates are
likely to be untrustworthy due to the fact that AstraZeneca vaccinees
are more likely to be vulnerable (and so more prone to clinical
disease). For this reason, estimates of efficacy of vaccination with the
AstraZeneca vaccine were excluded, as were any efficacy estimates
computed on fewer than 10 Omicron cases (e.g. Pfizer dose 2 in the
period immediately following vaccination). Estimates are also provided
of vaccine efficacy against Delta. Among Delta estimates, the majority
are likely to have been computed using the same underlying data as was
used to estimate the efficacies against clinical disease in the baseline
model, however the efficacy estimate for booster doses against Delta is
independent of these, and so we include this. These additional vaccine
efficacy estimates were used to inform the model with a likelihood
defined as described above.

### Fitting the model

The model is defined, fitted, and predicted from using the greta R
package. Inference is performed with 10 independent chains of
Hamiltonian Monte Carlo, each run for 1000 samples after 1000
(discarded) warmup iterations. Convergence is assessed by the potential
scale reduction factor statistic (1.01 or less for all parameters), the
effective sample size (greater than 500 for all parameters) and visual
inspection of trace plots.

These posterior samples are used to visualise the joint posterior
distribution over immune escape and transmissibility of Omicron,
relative to Delta, via a kernel density estimate over pairs of parameter
samples. Immune escape is calculated as:

1 − (1 − *I*<sub>O</sub>)/(1 − *I*<sub>*Δ*</sub>)

but with *Q* fixed at 1. Ie. it is the reduction in the effect of
immunity on transmission shown by Omicron, relative to Delta, in a fully
immune cohort.

The posterior distributions over vaccine efficacies for different
ourcomes, products, doses, and dregrees of waning are computed to
predict the range likely efficacies that might be expected with Omicron

For choices of prior distributions, see [here](R/build_neut_model.R) for
the main vaccine efficacy model and [here](R/add_omicron_model.R) for
extensions to inferring the transmissibility and immune escape of
Omicron. See [here](R/analysis) for more details of model fitting, and
an overview of the entire analysis.
