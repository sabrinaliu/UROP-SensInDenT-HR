function [bpmEstimate, relScore, allVals] = autocorrelation(inputData)
% Input:
%   inputData: 1xn float matrix, where n is the number of samples, storing
%   a single sensor's data for the current time segment
% Output:
%   bpmEstimate: float that represents the autocorrelation estimate for
%   this time segment in beats per minute 
%   relScore: float that represents the signal quality reliability score 
%   corresponding to this estimate, computed by looking at the 
%   autocorrelation associated with the bpmEstimate's lag 
%   allVals: 1xm float matrix, where m is the number of discrete lags that 
%   were computed, that stores all computed autocorrelations

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
    % Given the correlation results, returns reliability score based on how
    % much larger in magnitude the correlation peaks are
    
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
    chosenBpm = max(bestBpms); % bpm estimate is the max peak

    % Due some peaks being taller than others, will sometimes try to line
    % up large peaks and underestimate the heart rate, includes these
    % integer multiple peaks when consider how reliable is estimate
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
    relScore = min(1, relScore * 100); % factor to scale w/ pd
end
