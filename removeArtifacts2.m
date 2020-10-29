function filtered = removeArtifacts2(original)
% Given the original signal (i.e. patient(id).rppg(1)), return a new signal
% that has been  filtered for artifacts for heart rate estimation
% By default, assumes isRppg = True
    if nargin < 2
        isRppg = true;
    end

    fs = 250;
    fmin = 40/60;
    fmax = 140/60;
    Nmax = ceil(fs/fmin);

    numSamples = numel(original);

    miniWin = 5 * fs; % 1.5s window length
    smoothedData = nan(1, numSamples);
    for winStart = 1:miniWin:numSamples
        winEnd = min(winStart+miniWin-1, numSamples);
        currSection = original(winStart:winEnd);

        currDeriv = diff(currSection);
        currRms = rms(currDeriv);

        removeIdcs = currDeriv < -1.5*currRms | 1.5*currRms < currDeriv;
        currSection(removeIdcs) = NaN;
        currSection(removeIdcs+1) = NaN;
        currSampPts = (winStart:winEnd);
        currSampPts(isnan(currSection)) = NaN;

        currSection = rmmissing(currSection);
        currSampPts = rmmissing(currSampPts);

        newSection = pchip(currSampPts, currSection, (winStart:winEnd)); % interpolate pts
        smoothedData(winStart:winEnd) = newSection;
    end

    smoothedData = sgolayfilt(smoothedData, 2, 45); % smoothing

    % Bandpass filter to potential range for heart rate and remove baseline
    Wn = [fmin, fmax] ./ fs .* 2;
    [b, a] = butter(3, Wn);
    filtered = filtfilt(b, a, smoothedData);
    %     filtered = bandpass(smoothedData, [fmin, fmax], fs);

    baseline = movmean(filtered, floor(1.5*Nmax), 'omitnan');
    filtered = filtered - baseline;
end
