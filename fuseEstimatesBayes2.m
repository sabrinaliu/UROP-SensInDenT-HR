function [finalEst, chosenProbs] = fuseEstimatesBayes2(estimates)
% Given mxn matrix of estimates where each row is an estimate from one
% sensor/estimator and n is the number of segment cuts for this patient,
% return the best estimate

    [numEst, numSegs] = size(estimates);

    finalEst = nan(1, numSegs);
    chosenProbs = zeros(1, numSegs);
    probsAll = nan(numEst, numSegs);
    samples = (40:0.1:140);
    for k = 1:numSegs
        mu = nan(1, numEst);
        sd = nan(1, numEst);
        start = 1;
%         start = max(1, k - 6);
        for l = 1:numEst
            segs = k - start;
            mu(l) = mean(estimates(l, start:k), 'all', 'omitnan');
            sd(l) = std(estimates(l, start:k), [], 'all', 'omitnan') ...
                * sqrt((numEst*segs-1)/chi2inv(.005, numEst*segs-1));
        end

        probs = ones(1, numEst);
        for i = 1:numEst
            for l = 1:numEst
                probs(i) = probs(i) * normpdf(estimates(i, k), mu(l), sd(l));
            end
        end

        currDistribution = ones(1, numel(samples));
        for i = 1:numel(samples)
            for l = 1:numEst
                currDistribution(i) = currDistribution(i) * normpdf(samples(i), mu(l), sd(l));
            end
        end

        probsAll(:, k) = probs ./ sum(currDistribution .* 0.1);

        threshold = .03;
        goodEst = estimates(probsAll(:,k)>threshold, k);
        finalEst(k) = median(goodEst, 'omitnan');
        if isnan(finalEst(k))
            continue
        end

        [~, idx] = min(abs(goodEst - finalEst(k)));
        goodProbs = probsAll(probsAll(:, k)>threshold, k);
        chosenProbs(k) = min(.1, goodProbs(idx));
%         chosenProbs(k) = k;
    end

%     for k = 1:60
%         if std(estimates(:, max(1,k-6):k)) > 10
%             finalEst(k) = NaN;
%             chosenProbs(k) = 0;
%         end
%     end

%     finalEst(chosenProbs < 10) = NaN;
%     chosenProbs(chosenProbs < 10) = 0;
end
