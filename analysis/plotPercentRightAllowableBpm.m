%% percent right pre fusion
bpms = (2:.1:7);
perRight = NaN(2, numel(bpms));

allRef = [];
allPd = [];
allCorr = [];
for id = 1:20
    currRef = allEstimates(id).refBpm;
    currPd = allEstimates(id).estBpm(1:3,:);
    currCorr = allEstimates(id).estBpm(4:6,:);
    
    allRef = [allRef currRef currRef currRef];
    allPd = [allPd reshape(currPd.', [1, numel(currPd)])];
    allCorr = [allCorr reshape(currCorr.', [1, numel(currCorr)])];
end

for bpmId = 1:numel(bpms)
    perRight(1, bpmId) = sum(abs(allPd - allRef) <= bpms(bpmId));
    perRight(2, bpmId) = sum(abs(allCorr - allRef) <= bpms(bpmId));
end

perRight(1,:) = round(perRight(1,:) ./ sum(~isnan(allPd)) .* 100, 1);
perRight(2,:) = round(perRight(2,:) ./ sum(~isnan(allCorr)) .* 100, 1);

coverage = NaN(1, 2);
coverage(1) = round(sum(~isnan(allPd)) / numel(allPd) * 100);
coverage(2) = round(sum(~isnan(allCorr)) / numel(allCorr) * 100);

f1 = 2;
if ishandle(f1)
    clf(f1)
end
figure(f1)
plot(bpms, perRight(1,:))
hold on
plot(bpms, perRight(2,:))
xlabel("Allowed Heart Rate Deviation (bpm)", "FontSize", 16)
ylabel("Percent Correct Estimates (of those that are not NaN)", "FontSize", 16)
legend("Peak Detection Estimator ("+num2str(coverage(1))+ "% Coverage)", "Autocorrelation/ AMDF Estimator ("+num2str(coverage(2))+ "% Coverage)", "FontSize", 16)
title("Accuracy of Heart Rate Estimation with RPPG and MI Sensors Pre Fusion", "FontSize", 20)

% %% percent right post fusion
% bpms = (2:1:7);
% perRight = NaN(2, numel(bpms));
% 
% allRef = [];
% allRel = [];
% allBay = [];
% for id = 1:20
%     currRef = allEstimates(id).refBpm;
%     currRel = allEstimates(id).fuseBpm(1,:);
%     currBay = allEstimates(id).fuseBpm(2,:);
% 
%     allRef = [allRef currRef];
%     allRel = [allRel currRel];
%     allBay = [allBay currBay];
% end
% 
% for bpmId = 1:numel(bpms)
%     perRight(1, bpmId) = sum(abs(allRel - allRef) <= bpms(bpmId));
%     perRight(2, bpmId) = sum(abs(allBay - allRef) <= bpms(bpmId));
% end
% 
% perRight(1,:) = round(perRight(1,:) ./ sum(~isnan(allRel)) .* 100, 1);
% perRight(2,:) = round(perRight(2,:) ./ sum(~isnan(allBay)) .* 100, 1);
% 
% coverage = NaN(1, 2);
% coverage(1) = round(sum(~isnan(allRel)) / numel(allRel) * 100);
% coverage(2) = round(sum(~isnan(allBay)) / numel(allRel) * 100);
% 
% 
% f1 = 2;
% if ishandle(f1)
%     clf(f1)
% end
% figure(f1)
% plot(bpms, perRight(1,:))
% hold on
% plot(bpms, perRight(2,:))
% xlabel("Allowed Heart Rate Deviation (bpm)", "FontSize", 16)
% ylabel("Percent Correct Estimates (of those that are not NaN)", "FontSize", 16)
% legend("Reliability Score Fusion ("+num2str(coverage(1))+ "% Coverage)", "Bayesian Fusion ("+num2str(coverage(2))+ "% Coverage)", "FontSize", 16)
% title("Accuracy of Heart Rate Estimation with RPPG and MI Sensors", "FontSize", 20)