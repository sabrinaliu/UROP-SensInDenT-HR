function [relScores, valScores, conScores] = assignOverallRelScore(bpmEst, estScores, isPd)
% Input:
%   bpmEst: 1xn matrix storing all the heart rate estimates. Each row is
%   one estimator (consisting of a sensor and estimatory type), each column
%   is all estimates for that time segment.
%   estScores: 1xn matrix storing all the estimator reliability scores were
%   calculated based on properties of each estimator
%   isPd: boolean storing if each row used peak detection or if
%   it did not (and used autocorrelation instead).
% Output:
%   relScores: 1xn matrix storing the final reliability score for each
%   estimator at each time segment
%   valScores: 1xn matrix storing the intermediate value scores
%   conScores: 1xn matrix storing the intermediate consistency scores

    valScores = getValScore(bpmEst, isPd);
    conScores = getConsistencyScore(bpmEst);

    relScores = valScores .* conScores .* estScores;
end

function valScores = getValScore(bpmEst, isPd)
% Calculate value scores based on whether the heart rate estimate is within
% a feasible human heartrate range. Likelihood also based on previous
% observations of the bias of each estimator

    if isPd
        % Peak detection tends to over estimate, so more penalty assigned
        % to higher values
        templateScores = [50, 60, 80, 90, 100, 110, 120, NaN;
                          .4, .8, 1., .8, .60, .40, .20, .10];
    else
        % Autocorrelation tends to under estimate, so more penalty assigned
        % to lower values
        templateScores = [50, 55, 60, 80, 90, 100, 110, 120, NaN;
                          .1, .2, .6, 1., .8, .60, .40, .20, .10];
    end

    valScores = nan(1, numel(bpmEst));

    [~, numThresholds] = size(templateScores);
    for i = 1:numThresholds-1
        currThresh = templateScores(1, i);
        valScores(isnan(valScores) & bpmEst < currThresh) = templateScores(2, i);
    end
    valScores(isnan(valScores)) = templateScores(2, numThresholds);
end

function consistencyScores = getConsistencyScore(bpmEst)
% Calculate consistency scores based on how stable the heart rate estimates
% within the previous preceding segments
    consistencyScores = nan(1, numel(bpmEst));

    for i = 1:numel(bpmEst)
        start = max(1, i-6);
        recentStd = std(bpmEst(start:i), 'omitnan');
        score = max(1 - (recentStd - 5) / 50, 0); % scaling
        score = min(score, 1); % ensure max score is 1
        consistencyScores(i) = score;
    end
end
