function [finalEst, chosenRelScr] = fuseEstimatesRelScore(estimates, relScores)
% Input:
%   estimates: 6xn matrix with all the estimator outputs applied to each
%   sensor at each time segment
%   relScores: 6xn matrix storing the signal quality reliability scores
%   that were calculated by each estimator
% Output:
%   finalEst: 1xn matrix that returns the final fused estimate for each
%   time segment
%   chosenRelScr: 1xn matrix that returns the final reliability score of the
%   final estimate for each time segment

    [numEst, numSegs] = size(estimates);
    sensors = numEst / 2; % assumes we have 2 estimators / sensor

    finalRelScores = nan(numEst, numSegs);
    valScores = nan(numEst, numSegs);
    for i = 1:numEst
        % estimates 1-3 are from peak detection, 4-6 from correlation
        [finalRelScores(i,:), valScores(i,:)] = assignOverallRelScore(estimates(i,:), relScores(i,:), i <= sensors);
    end

    partialRelScores = finalRelScores ./ valScores; % only signal quality * consistency
    finalRelScores = round(finalRelScores * 10);
    duplicates = nan(10*numEst, numSegs);
    for i = 1:numEst
        for j = 1:numSegs
            numDup = min(10, finalRelScores(i, j)); % Duplicate each estimate
            if numDup < 7 && partialRelScores(i, j) < .9
                % Filter out estimates with low reliability scores from
                % fusion process; also look at the reliability score
                % without the value score to reduce bias against segments
                % that actually have abnormally high/ low heart rates
                continue
            end
            duplicates(10*(i-1)+1:10*(i-1)+numDup, j) = estimates(i,j);
        end
    end

    finalEst = median(duplicates, 'omitnan');

    % For analysis, record what reliability score corresponds to each final
    % estimate that was chosen
    chosenRelScr = zeros(1, numSegs);
    for i = 1:numSegs
        if isnan(finalEst(i))
            continue
        end
        currEst = estimates(:,i);
        [~, idx] = min(abs(currEst - finalEst(i)));
        chosenRelScr(i) = min(1, sum(currEst(idx) == duplicates(:, i)) / 10);
    end
end
