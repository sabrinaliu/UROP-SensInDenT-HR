function [bpmEstimate, relScore, allVals] = autocorrelation(inputData)
% Given a subsection of the data, estimates the frequency for the
% subsection

    fs = 250;
    numSamples = numel(inputData);

    fmin = 40/60;
    fmax = 140/60;
    Nmin = floor(fs / fmax);
    Nmax = ceil(fs / fmin);

    scorrResults = NaN(1, Nmax-Nmin+1);
    amdfResults = NaN(1, Nmax-Nmin+1);
    for N = Nmin:Nmax
        relevantData = inputData(1:numSamples-N);
        laggedData = inputData(N+1:end);

        scorrResults(N-Nmin+1) = sum(relevantData .* laggedData) / (numSamples - N);
        amdfResults(N-Nmin+1) = (numSamples - N) / sum(abs(relevantData - laggedData));
    end

    fuseResults = scorrResults .* amdfResults;
    scorrResults = fuseResults;

    [~, bestNIdces] = findpeaks(scorrResults);
    if numel(bestNIdces) == 0
        bpmEstimate = NaN;
        allVals = [fs ./ (Nmin:Nmax) .* 60; scorrResults];
        relScore = 0;
        return
    end

    bestNs = bestNIdces - 1 + Nmin;

    bestBpms = fs ./ bestNs .* 60;
    bpmEstimate = max(bestBpms);
    relScore = assignRelScore(scorrResults);

    allVals = [fs ./ (Nmin:Nmax) .* 60; scorrResults];
end

function relScore = assignRelScore(scorrResults)
    fs = 250;
    fmax = 140/60;
    Nmin = floor(fs / fmax);

    [~, bestNIdces] = findpeaks(scorrResults);
    if numel(bestNIdces) == 0
        relScore = 0;
        return
    end

    bestNs = bestNIdces - 1 + Nmin;
    bestBpms = fs ./ bestNs .* 60;
    chosenBpm = max(bestBpms);

    relevantNIdces = bestNIdces;
    if numel(bestBpms) > 1
        for i = 1:numel(bestBpms)
            ratio = chosenBpm / bestBpms(i);
            if abs(ratio - round(ratio)) > 0.1
                relevantNIdces(i) = NaN;
            end
        end
    end

    relevantNIdces = rmmissing(relevantNIdces);
    relScore = sum(abs(scorrResults(relevantNIdces))) / sum(abs(scorrResults));
    relScore = min(1, relScore * 80); % factor to scale w/ pd
end
