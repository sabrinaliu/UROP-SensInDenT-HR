function [finalEst, chosenProbs] = fuseEstimatesBayes(estimates)
% Input:
%   estimates: mxn matrix, where m is the number of estimates and n is the
%   number of time segments, stores the estimator outputs
% Output:
%   finalEst: 1xn matrix that stores the final fused estimates
%   chosenProbs: 1xn matrix that stores the computed probability
%   corresponding to each of the chosen final estimates

    [numEst, numSegs] = size(estimates);

    finalEst = nan(1, numSegs);
    chosenProbs = zeros(1, numSegs);
    probsAll = nan(numEst, numSegs);
    samples = (40:0.1:140);
    for k = 1:numSegs
        mu = nan(1, numEst);
        sd = nan(1, numEst);
        
        start = max(1, k - 6); % look at last minute (6 * 10s segments) of estimates
        for l = 1:numEst
            segs = k - start;
            mu(l) = mean(estimates(l, start:k), 'all', 'omitnan');
            
            % chi2 distribution to prevent sd from getting too small if too few estimates
            sd(l) = std(estimates(l, start:k), [], 'all', 'omitnan') ...
                * sqrt((numEst*segs-1)/chi2inv(.005, numEst*segs-1));
        end

        % update probability of each estimate based on each of the previous
        % estimates
        probs = ones(1, numEst);
        for i = 1:numEst
            for l = 1:numEst
                probs(i) = probs(i) * normpdf(estimates(i, k), mu(l), sd(l));
            end
        end

        % get the overall distribution for all the samples we have
        currDistribution = ones(1, numel(samples));
        for i = 1:numel(samples)
            for l = 1:numEst
                currDistribution(i) = currDistribution(i) * normpdf(samples(i), mu(l), sd(l));
            end
        end

        % normalize the probability of each estimate based on probability
        % of each sample
        probsAll(:, k) = probs ./ sum(currDistribution .* 0.1);

        % remove estimates whose probability is below a threshold,
        % indicating that they are unreliable
        threshold = .03;
        goodEst = estimates(probsAll(:,k)>threshold, k);
        finalEst(k) = median(goodEst, 'omitnan'); % find median of estimates above threshold
        if isnan(finalEst(k))
            continue
        end

        % for analysis, record probability of the final estimate that was
        % chosen
        [~, idx] = min(abs(goodEst - finalEst(k)));
        goodProbs = probsAll(probsAll(:, k)>threshold, k);
        chosenProbs(k) = min(.1, goodProbs(idx));
    end
end
