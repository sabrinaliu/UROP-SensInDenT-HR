addpath('/Users/sabrinaliu/SuperUROP/matLabFiles/heartRate/finalCode/util')

allEstimates = struct;
percentInRange = NaN(20, 4); % 4 cols for pd fuse, corr fuse, pd individual, corr individual
coverage = NaN(20, 2); % 2 cols for pd and corr
for id = 1:20
    disp(id)
    tic
    
    excp = find(patient(id).phase>0);
    time = patient(id).time(excp);
    ecg = patient(id).ref_ecg(excp);
    rppg = patient(id).rppg(:, excp);
    phases = patient(id).phase(excp);
    
    segCuts = splitData(phases);
    numSegs = numel(segCuts)-1;
    
    refBpm = getRefBpm(ecg, segCuts);
    estBpm = NaN(6, numSegs);
    relScr = NaN(6, numSegs);
    isNoData = false(1, numSegs);
    for i = 1:numSegs
        currRange = (segCuts(i):segCuts(i+1)-1);
        
        if checkNoData(rppg(:, currRange))
            isNoData(i) = true;
            continue
        end
        
        for sensor = 1:3
            filtered = removeArtifacts(rppg(sensor, currRange));
            [estBpm(sensor,i), relScr(sensor,i)] = peakDetection(filtered);
            [estBpm(sensor+3,i), relScr(sensor+3,i)] = autocorrelation(filtered);
        end
    end
    
    fuseBpm = NaN(2,numSegs);
    fuseBpm(1,:) = fuseEstimatesRelScore(estBpm, relScr, [true(1, 3) false(1,3)]);
    fuseBpm(2,:) = fuseEstimatesBayes(estBpm);
    
    allEstimates(id).numSegs = numSegs;
    allEstimates(id).refBpm = refBpm;
    allEstimates(id).estBpm = estBpm;
    allEstimates(id).relScr = relScr;
    allEstimates(id).fuseBpm = fuseBpm;
    allEstimates(id).isNoData = sum(isNoData);
    
    coverage(id, :) = sum(~isnan(fuseBpm), 2);
    
    percentInRange(id, 1) = sum(abs(fuseBpm(1,:) - refBpm) < 5);
    percentInRange(id, 2) = sum(abs(fuseBpm(2,:) - refBpm) < 5);
    
    possibleRight = false(2, numSegs);
    for sensor = 1:3
        possibleRight(1,:) = possibleRight(1,:) | abs(estBpm(sensor,:) - refBpm) < 5;
        possibleRight(2,:) = possibleRight(2,:) | abs(estBpm(sensor+3,:) - refBpm) < 5;
    end
    percentInRange(id, 3:4) = sum(possibleRight, 2);
    
    toc
end

bestSingleEstRight = NaN(20, 1);
bestSingleEstCoverage = NaN(20, 1);
for id = 1:20
    refBpm = allEstimates(id).refBpm;
    estBpm = allEstimates(id).estBpm;
    
    for i = 1:6
        currRight = sum(abs(estBpm(i,:)-refBpm) < 5);
        if isnan(bestSingleEstRight(id)) || currRight > bestSingleEstRight(id)
            bestSingleEstRight(id) = currRight;
            bestSingleEstCoverage(id) = sum(~isnan(estBpm(i,:)));
        end
    end
end

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
title("Reliability Score Fusion for All Patients")

subplot(2, 1, 2)
blandAltman(allRef, allBayesEst)
title("Bayesian Fusion for All Patients")