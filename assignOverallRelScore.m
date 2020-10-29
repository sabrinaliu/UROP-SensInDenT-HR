function [relScores, valScores, conScores] = assignOverallRelScore(bpmEst, estScores, isPd)
    valScores = getValScore(bpmEst, isPd);
    conScores = getConsistencyScore(bpmEst);

    relScores = valScores .* conScores .* estScores;
end

function valScores = getValScore(bpmEst, isPd)
    if isPd
        templateScores = [50, 60, 80, 90, 100, 110, 120, NaN;
                          .4, .8, 1., .8, .60, .40, .20, .10];
    else
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
    consistencyScores = nan(1, numel(bpmEst));

    for i = 1:numel(bpmEst)
        start = max(1, i-6);
        recentStd = std(bpmEst(start:i), 'omitnan');
        score = max(1 - (recentStd - 5) / 50, 0);
        score = min(score, 1);
        consistencyScores(i) = score;
    end
end
