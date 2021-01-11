function [filtered, numArtifacts, hasArtifact] = removeArtifacts(original)
% Given the original signal (i.e. patient(id).rppg(1)), return a new signal
% that has been  filtered for artifacts for heart rate estimation
% Output:
%   filtered: 1xn float vector with filtered signal
%   numArtifacts: integer with number of points identified as a sharp spike
%   artifact
%   hasArtifact: 1xn boolean vector that identifies if each point was part
%   of an artifact that needed to be removed and interpolated
    
    fs = 250;
    fmin = 40/60;
    fmax = 140/60;
    Nmax = ceil(fs/fmin);

    numSamples = numel(original);

    hasArtifact = false(1, numel(original));
    numArtifacts = 0;
    
    % find sharp spikes in each mini window, remove them, and interpolate
    % what points should be there
    miniWin = 5 * fs; % 5s window length
    smoothedData = nan(1, numSamples);
    for winStart = 1:miniWin:numSamples
        winEnd = min(winStart+miniWin-1, numSamples);
        currSection = original(winStart:winEnd);

        currDeriv = diff(currSection);
        currRms = rms(currDeriv);

        % identify sharp spikes to remove
        removeIdcs = currDeriv < -1.5*currRms | 1.5*currRms < currDeriv;
        currSection(removeIdcs) = NaN;
        currSection(removeIdcs+1) = NaN;
        currSampPts = (winStart:winEnd);
        currSampPts(isnan(currSection)) = NaN;
        
        % for analysis: keep count of how many points removed
        hasArtifact(winStart:winEnd) = isnan(currSampPts);
        numArtifacts = numArtifacts + sum(isnan(currSampPts));

        currSection = rmmissing(currSection);
        currSampPts = rmmissing(currSampPts);

        newSection = pchip(currSampPts, currSection, (winStart:winEnd)); % interpolate pts
        smoothedData(winStart:winEnd) = newSection;
    end

    smoothedData = sgolayfilt(smoothedData, 2, 45); % smoothing

    % Bandpass filter to potential range for heart rate
    Wn = [fmin, fmax] ./ fs .* 2;
    [b, a] = butter(3, Wn);
    filtered = filtfilt(b, a, smoothedData);

    % Remove any baseline wandering/ center signal around 0
    baseline = movmean(filtered, floor(1.5*Nmax), 'omitnan');
    filtered = filtered - baseline;
end
