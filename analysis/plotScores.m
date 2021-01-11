
allRef = [];
allPdEst = [];
allPdScore = [];
allCorrEst = [];
allCorrScore = [];
for id = 1:20
    currEstimates = allEstimates(id);
    allRef = [allRef currEstimates.refBpm currEstimates.refBpm currEstimates.refBpm];
    
    currSensors = currEstimates.estBpm;
    currSigQual = currEstimates.relScr;
    
    allPdEst = [allPdEst reshape(currSensors(1:3, :).', [1, numel(currSensors(1:3,:))])];
    allCorrEst = [allCorrEst reshape(currSensors(4:6, :).', [1, numel(currSensors(4:6,:))])];
    
    for i = 1:6
        currScores = assignOverallRelScore(currSensors(i,:), currSigQual(i,:), i < 4);
        
        if i < 4
            allPdScore = [allPdScore currScores];
        else
            allCorrScore = [allCorrScore currScores];
        end
    end
end

f = 4;
if ishandle(f)
    clf(f)
end
figure(f)
subplot(2, 1, 1)
blandAltman(allRef, allPdEst, allPdScore)
hold on
% plot(x, yhigh, x, ylow)
title("Peak Detection Estimator for MI Sensors on All Patients", "FontSize", 20)
caxis([0, 1])

subplot(2, 1, 2)
blandAltman(allRef, allCorrEst, allCorrScore)
hold on
% plot(x, yhigh, x, ylow)
title("Autocorrelation/ AMDF Estimator for MI Sensors on All Patients", "FontSize", 20)
caxis([0, 1])