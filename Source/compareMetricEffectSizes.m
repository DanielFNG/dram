% Script to compare metric effect sizes.

% The metric functions to call
metrics = {@calculateStepWidth, @calculateStepFrequency, @calculateROM, ...
    @calculateWNPPT, @calculateCoPD, @calculateCoPD, @calculateCoMD, ...
    @calculateCoMD, @calculateMoS, @calculateMoS, @calculateMoSCoM, ...
    @calculateMoSCoM, @calculateXPMoS};

% Metric arguments
args = {{}, {}, {'hip_flexion_r'}, {'hip_flexion_r'}, {'x'}, {'z'}, {'y'}, ...
    {'z'}, {'x', 'mean'}, {'z', 'mean'}, {'x', 'mean'}, {'z', 'mean'}, ...
    {'x', 'mean'}};

% Metric names for plotting purposes
names = {'step-width', 'step-freq', 'hip-rom', 'hip-pkt', 'cop-ap', ...
    'cop-ml', 'com-v', 'com-ml', 'mos-ap', 'mos-ml', 'moscom-ap', ...
    'moscom-ml', 'xpmos'};

% Compute Cohen's D for each metric - store results in an array.
n_metrics = length(metrics);
cohens = zeros(1, n_metrics);
for i=1:n_metrics
    metric_data = eml.compute(metrics{i}, args{i});
    metric_obj = MetricStats2D(names{i}, metric_data, 35, ...
        'speed', 'assistance', {'b', 'f', 's'}, {'n', 't', 'a'});
    cohens(i) = metric_obj.calcCohensD();
end

% Plot metric effect size comparison.
figure;
bar(cohens);

