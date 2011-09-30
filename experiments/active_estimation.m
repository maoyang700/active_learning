in_train = false(num_observations, 1);
in_train(1) = true;

log_input_scale_prior_mean = -1.5;
log_input_scale_prior_variance = 0.5;

log_output_scale_prior_mean = 0;
log_output_scale_prior_variance = 1;

latent_prior_mean_prior_mean = 0;
latent_prior_mean_prior_variance = 1;

hypersamples.prior_means = ...
    [latent_prior_mean_prior_mean ...
     log_input_scale_prior_mean ...
     log_output_scale_prior_mean];

hypersamples.prior_variances = ...
    [latent_prior_mean_prior_variance ...
     log_input_scale_prior_variance ...
     log_output_scale_prior_variance];

hypersamples.values = find_ccd_points(hypersamples.prior_means, ...
    hypersamples.prior_variances);

hypersamples.mean_ind = 1;
hypersamples.covariance_ind = 2:3;
hypersamples.likelihood_ind = [];
hypersamples.marginal_ind = 1:3;

hyperparameters.lik = hypersamples.values(1, hypersamples.likelihood_ind);
hyperparameters.mean = hypersamples.values(1, hypersamples.mean_ind);
hyperparameters.cov = hypersamples.values(1, hypersamples.covariance_ind);

inference_method = @infEP;
mean_function = @meanConst;
covariance_function = @covSEiso;
likelihood = @likErf;

[~, inference_method, mean_function, covariance_function, likelihood] = ...
    check_gp_arguments(hyperparameters, inference_method, ...
                       mean_function, covariance_function, likelihood, ...
                       data, responses);

prior_covariances = zeros(num_observations, num_observations, ...
          size(hypersamples.values, 1));
for i = 1:size(hypersamples.values, 1)
  prior_covariances(:, :, i) = ...
  feval(covariance_function{:}, ...
        hypersamples.values(i, hypersamples.covariance_ind), ...
        data);
end

[purely_random_estimated_proportion...
 purely_random_proportion_variance ...
 purely_random_chosen] = ...
    purely_random_sampling_estimate(responses, in_train, num_evaluations);

disp(['purely random sampling: ' num2str(purely_random_estimated_proportion) ...
      ' +/- ' num2str(sqrt(purely_random_proportion_variance)) ...
      ', actual: ' num2str(actual_proportion)]);

[random_estimated_proportions ...
 random_proportion_variances ...
 random_chosen] = ...
    random_sampling_estimate(data, responses, in_train, prior_covariances, ...
                             num_evaluations, inference_method, ...
                             mean_function, covariance_function, ...
                             likelihood, hypersamples, num_f_samples);

disp(['random sampling: ' num2str(random_estimated_proportions(end)) ...
      ' +/- ' num2str(sqrt(random_proportion_variances(end))) ...
      ', actual: ' num2str(actual_proportion)]);

[uncertainty_estimated_proportions ...
 uncertainty_proportion_variances ...
 uncertainty_chosen] = ...
    uncertainty_sampling_estimate(data, responses, in_train, ...
    prior_covariances, num_evaluations, inference_method, mean_function, ...
    covariance_function, likelihood, hypersamples, num_f_samples);

disp(['uncertainty sampling: ' num2str(uncertainty_estimated_proportions(end)) ...
      ' +/- ' num2str(sqrt(uncertainty_proportion_variances(end))) ...
      ', actual: ' num2str(actual_proportion)]);

[optimal_estimated_proportions ...
 optimal_proportion_variances ...
 optimal_chosen] = ...
    optimal_sampling_estimate(data, responses, in_train, prior_covariances, ...
                              num_evaluations, inference_method, ...
                              mean_function, covariance_function, ...
                              likelihood, hypersamples, num_f_samples);

disp(['optimal sampling: ' num2str(optimal_estimated_proportions(end)) ...
      ' +/- ' num2str(sqrt(optimal_proportion_variances(end))) ...
      ', actual: ' num2str(actual_proportion)]);
