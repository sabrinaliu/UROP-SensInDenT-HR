% addpath('/Users/sabrinaliu/SuperUROP/matLabFiles/heartRate/finalCode/util')
% 
% allEstimates = struct;
% percentInRange = NaN(20, 2); % 2 cols for pd fuse, corr fuse
% coverage = NaN(20, 2); % 2 cols for pd and corr
% for id = 1:20
%     disp(id)
%     tic
%     
%     excp = find(patient(id).phase>0);
%     time = patient(id).time(excp);
%     ecg = patient(id).ref_ecg(excp);
%     rppg = patient(id).rppg(:, excp);
%     phases = patient(id).phase(excp);
%     
%     segCuts = splitData(phases);
%     numSegs = numel(segCuts)-1;
%     
%     refBpm = getRefBpm(ecg, segCuts);
%     estBpm = NaN(6, numSegs);
%     relScr = NaN(6, numSegs);
%     isNoData = false(1, numSegs);
%     % Calculate estimators for each segment
%     for i = 1:numSegs
%         currRange = (segCuts(i):segCuts(i+1)-1);
%         
%         if checkNoData(rppg(:, currRange))
%             isNoData(i) = true;
%             continue
%         end
%         
%         for sensor = 1:3
%             filtered = removeArtifacts(rppg(sensor, currRange));
%             [estBpm(sensor,i), relScr(sensor,i)] = peakDetection(filtered);
%             [estBpm(sensor+3,i), relScr(sensor+3,i)] = autocorrelation(filtered);
%         end
%     end
%     
%     % Try both methods of fusion: using reliability scores and Bayes
%     fuseBpm = NaN(2,numSegs);
%     fuseBpm(1,:) = fuseEstimatesRelScore(estBpm, relScr);
%     fuseBpm(2,:) = fuseEstimatesBayes(estBpm);
%     
%     % Store results in allEstimates
%     allEstimates(id).numSegs = numSegs;
%     allEstimates(id).refBpm = refBpm;
%     allEstimates(id).estBpm = estBpm;
%     allEstimates(id).relScr = relScr;
%     allEstimates(id).fuseBpm = fuseBpm;
%     allEstimates(id).isNoData = sum(isNoData);
%     
%     % Calculate coverage
%     coverage(id, :) = sum(~isnan(fuseBpm), 2);
%     
%     % Calculate % of segments where estimate within 5bpm of reference
%     percentInRange(id, 1) = sum(abs(fuseBpm(1,:) - refBpm) < 5);
%     percentInRange(id, 2) = sum(abs(fuseBpm(2,:) - refBpm) < 5);
%     
%     toc
% end

% Concatenate all estimates to create Bland-Altman for all points
allRef = [];
allRelEst = [];
allBayesEst = [];
for id = 1:20
    currRef = allEstimates(id).refBpm;
    currEst = allEstimates(id).fuseBpm;
    
    allRef = [allRef currRef];
    allRelEst = [allRelEst currEst(1,:)];
    allBayesEst = [allBayesEst currEst(2,:)];
end

f1 = 1;
if ishandle(f1)
    clf(f1)
end
figure(f1)
subplot(2, 1, 1)
blandAltman(allRef, allRelEst)
title("Reliability Score Fusion for All Patients", "FontSize", 20)

subplot(2, 1, 2)
blandAltman(allRef, allBayesEst)
title("Bayesian Fusion for All Patients", "FontSize", 20)


% Concatenate all individual estimator points
allRef = [];
allPdEst = [];
allPdScore = [];
allCorrEst = [];
allCorrScore = [];
percentInRange = NaN(20, 2); % 2 cols for pd, corr
coverage = NaN(20, 2); 
for id = 1:20
    currRef = allEstimates(id).refBpm;
    currPdEst = allEstimates(id).estBpm(1:3,:);
    currPdRelScr = allEstimates(id).relScr(1:3,:);
    currCorrEst = allEstimates(id).estBpm(4:6,:);
    currCorrRelScr = allEstimates(id).relScr(4:6,:);
    
    currRef = [currRef currRef currRef];
    currPdEst = reshape(currPdEst.', [1, numel(currPdEst)]);
    currPdRelScr = reshape(currPdRelScr.', [1, numel(currPdRelScr)]);
    currCorrEst = reshape(currCorrEst.', [1, numel(currCorrEst)]);
    currCorrRelScr = reshape(currCorrRelScr.', [1, numel(currCorrRelScr)]);
    
    allRef = [allRef currRef];
    allPdEst = [allPdEst currPdEst];
    allPdScore = [allPdScore currPdRelScr];
    allCorrEst = [allCorrEst currCorrEst];
    allCorrScore = [allCorrScore currCorrRelScr];
    
%     Calculate % of segments where estimate within 5bpm of reference
    coverage(id, 1) = sum(~isnan(currPdEst));
    coverage(id, 2) = sum(~isnan(currCorrEst));
    percentInRange(id, 1) = sum(abs(currRef - currPdEst) < 5);
    percentInRange(id, 2) = sum(abs(currRef - currCorrEst) < 5);
end

f2 = 2;
if ishandle(f2)
    clf(f2)
end
figure(f2)
subplot(2, 1, 1)
blandAltman(allRef, allPdEst, allPdScore)
title("Peak Detection Estimator for All Sensors on All Patients", "FontSize", 20)
ylim([-80 80])

subplot(2, 1, 2)
blandAltman(allRef, allCorrEst, allCorrScore)
title("Autocorrelation/ AMDF Estimator for All Sensors on All Patients", "FontSize", 20)