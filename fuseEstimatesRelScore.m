function [finalEst, chosenRelScr] = fuseEstimatesRelScore(estimates, relScores, isPd)
% Given a mxn matrix of estimates where each row is the estimate from one
% sensor/estimator and n is the number of segmentCuts for this patient, return a 1xn
% matrix that contains the fused estimate of the three

    [numEst, numSegs] = size(estimates);

    finalRelScores = nan(numEst, numSegs);
    valScores = nan(numEst, numSegs);
    for i = 1:numEst
        [finalRelScores(i,:), valScores(i,:)] = assignOverallRelScore(estimates(i,:), relScores(i,:), isPd(i));
    end

    partialRelScores = finalRelScores ./ valScores;
    finalRelScores = round(finalRelScores * 10);
    duplicates = nan(10*numEst, numSegs);
    for i = 1:numEst
        for j = 1:numSegs
            numDup = min(10, finalRelScores(i, j));
            if numDup < 8 && partialRelScores(i, j) < .9
                continue
            end
            duplicates(10*(i-1)+1:10*(i-1)+numDup, j) = estimates(i,j);
        end
    end

    finalEst = median(duplicates, 'omitnan');

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
