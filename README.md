# Skew-adaptive conformal prediction

> Paulo C. Marques F. and Helton Graziadei

https://arxiv.org/abs/2605.16145

### Abstract

We develop a skew-adaptive extension of split conformal prediction for regression. The method starts from an asymmetric interval family centered at a point prediction and uses the gauge approach to deduce the conformity score induced by this family. The inverse hyperbolic sine transform of signed scaled residuals provides the training target for an additional predictive model, whose role is to learn how predictive uncertainty should tilt across the feature space. The resulting procedure preserves the finite-sample marginal validity of split conformal prediction under exchangeability, while producing intervals that adapt to both local scale and local skewness. We also develop a calibration-sample-based estimator for comparing the expected relative future width of the skew-adaptive and classical scaled-score intervals after the training stage has been completed. Experiments on a variety of datasets indicate gains in prediction interval efficiency over the scaled-score construction and conformalized quantile regression, and also show that the proposed estimator closely matches the corresponding average width ratio observed on the test sample.
