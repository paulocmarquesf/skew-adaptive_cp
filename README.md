```bibtex
@InProceedings{marquesf2026,
  title = {Skew-adaptive conformal prediction},
  author = {Paulo C. {Marques F.} and Helton Graziadei},
  booktitle = {Proceedings of the Fiteenth Symposium on Conformal and Probabilistic Prediction with Applications},
  pages = {82--100},
  year = {2026},
  editor = {Ahlberg, Ernst and Johansson, Ulf and Bostr{\"o}m, Henrik and Carlevaro, Alberto and Hallberg Szabadváry, Johan and Carlsson, Lars},
  volume = {329},
  series = {Proceedings of Machine Learning Research},
  month = {September},
  publisher = {PMLR},
  url = {https://proceedings.mlr.press/v329/c-marques-f-26a.html}
}
```

# Skew-adaptive conformal prediction

> Paulo C. Marques F. and Helton Graziadei

> https://proceedings.mlr.press/v329/c-marques-f-26a.html

**Abstract.** To account for predictive uncertainty in regression that may vary across the feature space not only in scale but also in asymmetry, we develop a skew-adaptive extension of split conformal prediction. The construction starts from an asymmetric interval family centered at a point prediction and uses the gauge approach to deduce the conformity score induced by this family. The inverse hyperbolic sine transform of signed scaled residuals provides the training target for an additional predictive model, whose role is to learn how predictive uncertainty should tilt across the feature space. The resulting procedure preserves the finite-sample marginal validity of split conformal prediction under exchangeability, while producing intervals that adapt to both local scale and local skewness. We also develop a calibration-sample-based estimator for comparing the expected relative future width of the skew-adaptive and classical scaled-score intervals. Experiments on a variety of datasets indicate gains in prediction interval efficiency over the scaled-score construction and conformalized quantile regression, and also show that the proposed estimator closely matches the corresponding average width ratio observed on the test sample.
