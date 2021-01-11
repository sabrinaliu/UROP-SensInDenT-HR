function [bpmEstimate, relScore, finalFoundPks] = peakDetection(inputData)
% Given a subsection of data from one sensor, estimates the heart rate 
% frequency for the subsection
% Output:
%   bpmEstimate: float that is the heart rate estimate for this section
%   relScore: float in range [0, 1] that is the signal quality reliability
%   score corresponding to this estimate
%   finalFoundPeaks: 1xp float vector that stores the indices of the p peaks
%   identified by the procedure

    fs = 250;

    [pks, pkIdces] = findpeaks(inputData);
    numPks = numel(pks);
    if numPks <= 1
        bpmEstimate = NaN;
        finalFoundPks = [];
        relScore = 0;
        return
    end

    % calculate the height (distance from peak to valley) to left and right
    % of each peak
    heights = nan(2, numPks);
    for i = 1:numPks-1
        currRange = (pkIdces(i):pkIdces(i+1));
        vl = findpeaks(-1*inputData(currRange));
        vl = -1*vl;

        heights(2, i) = pks(i) - vl;
        heights(1, i+1) = pks(i+1) - vl;
    end

    heights(1, 1) = pks(1) - min(inputData(1:pkIdces(1)));
    heights(2, numPks) = pks(numPks) - min(inputData(pkIdces(numPks):end));
    
    % based on the skew of each peak (comparing left and right height),
    % decide if a peak is extraneous
    canMerge = zeros(1, numPks); % 0 if balance, -1 merge left, 1 merge right

    canMerge(heights(2,:) ./ heights(1,:) > 2) = -1; % very right skewed
    canMerge(heights(1,:) ./ heights(2,:) > 1) = 1; % left skewed

    finalPks = pks;
    finalPkIdces = pkIdces;
    for i = 2:numPks
        if canMerge(i) == -1 && canMerge(i-1) == 1
            finalPks(i) = NaN;
            finalPkIdces(i) = NaN;
        end
    end
    noDupPks = rmmissing(finalPks);
    noDupPkIdces = rmmissing(finalPkIdces);

    % MAD procedure to further identify any extraneous peaks
    foundPks = NaN(2, numel(noDupPks));

    pkIntervals = diff(noDupPkIdces);
    medPkInterval = median(pkIntervals);
    mad = median(abs(pkIntervals - medPkInterval));

    for i = 1:numel(noDupPkIdces)-1
        if abs(noDupPkIdces(i+1)-noDupPkIdces(i)-medPkInterval) < 2*mad
            foundPks(1, i) = noDupPkIdces(i);
            foundPks(2, i) = noDupPks(i);
        end
    end
    foundPks(1, end) = noDupPkIdces(end);
    foundPks(2, end) = noDupPks(end);
    foundPks = rmmissing(foundPks, 2);

    if isempty(foundPks)
        bpmEstimate = NaN;
        relScore = 0;
        return
    end

    % MAD procedure to add back any missed peaks
    finalFoundPks = []; % only stores idces
    for i = 1:numel(foundPks(1, :))-1
        finalFoundPks = [finalFoundPks foundPks(1, i)];

        currTimeDiff = foundPks(1, i+1) - foundPks(1, i);
        appNumIntervals = round(currTimeDiff / medPkInterval);

        if appNumIntervals <= 1
            % Don't need to add anymore peaks
            continue
        end

        recoveredPks = NaN(1, appNumIntervals - 1);
        prevPeak = foundPks(1, i);
        targetHeight = foundPks(2, i);
        for j = 1:appNumIntervals-1
            expected = round(prevPeak + medPkInterval);

            possibleIdces = pkIdces(abs(expected-pkIdces) < mad);

            if isempty(possibleIdces)
                recoveredPks(j) = expected;
                prevPeak = expected;
                continue
            end

            [~, bestPeakIdx] = min(abs(targetHeight - inputData(possibleIdces)));
            recoveredPks(j) = possibleIdces(bestPeakIdx);
            prevPeak = possibleIdces(bestPeakIdx);
        end

        finalFoundPks = [finalFoundPks recoveredPks];
    end

    finalFoundPks = [finalFoundPks foundPks(1, end)];
    finalFoundPks = rmmissing(finalFoundPks);

    bpmEstimate = assignBpmToTime(finalFoundPks, fs);
    relScore = assignSigQual(finalFoundPks, inputData);
end

function output = assignBpmToTime(peakIndices, fs)
    output = fs / mean(diff(peakIndices)) * 60;
end

function meanCorr = assignSigQual(peakIndices, inputData)
    % Assign signal quality score to the estimate
    % Calculates by aligning the segments centered on the identified peaks
    % and calculating how much the segments deviate from each other
    % Expect morphology of each heart beat similar, so expect less
    % deviation for more reliable estimates
    
    numPks = numel(peakIndices);
    if numPks <= 1
        meanCorr = 0;
        return
    end
    numPts = numel(inputData);

    diffLengths = diff(peakIndices);
    medInterval = median(diffLengths);

    halfMedInt = floor(medInterval / 2);
    segs = zeros(numPks, 2*halfMedInt+1);

    % find segments of medInterval width around each peak
    skippedPks = 0;
    for i =1:numPks
        currPkIdx = peakIndices(i);
        startPt = currPkIdx - halfMedInt;
        endPt = currPkIdx + halfMedInt;

        if startPt < 1 || endPt > numPts
            % skip peaks close to beginning or end of segment
            skippedPks = skippedPks + 1;
            continue
        end

        segs(i, :) = inputData(startPt:endPt);
    end
    
    % find the mean segment values
    meanSegs = mean(segs, 'omitnan');

    % compute correlation of each individual segment to the mean segment
    totalCorr = 0;
    for i = 1:numPks
        currCorr = corrcoef(segs(i, :), meanSegs);
        if isnan(currCorr(1,2))
            continue
        end
        totalCorr = totalCorr + currCorr(1,2);
    end

    % find the average correlation as the reliability score
    meanCorr = min(1, max(0, totalCorr / (numPks - skippedPks)));
end
