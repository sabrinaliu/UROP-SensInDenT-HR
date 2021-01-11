addpath('/Users/sabrinaliu/SuperUROP/matLabFiles/heartRate/finalCode')

%% Exemplary artifact RPPG
id = 20;
seg = 5;
sensor = 3;

excp = find(patient(id).phase>0);
time = patient(id).time(excp);
ecg = patient(id).ref_ecg(excp);
rppg = patient(id).coil(:, excp);
phases = patient(id).phase(excp);

segCuts = splitData(phases);

currRange = (segCuts(seg):segCuts(seg+1)-1);

filtered = removeArtifacts(rppg(sensor, currRange));

f2 = 4;
if ishandle(f2)
    clf(f2)
end
figure(f2)
subplot(3, 1, 1)
plot(time(currRange), rppg(sensor, currRange))
xlabel("Time (s)")
ylabel("Amplitude (a.u.)")
title("Patient " + num2str(id) + " Sensor " + num2str(sensor) + " Segment " + num2str(seg) + " Original")
set(gca, "FontSize", 20)
% ylim([0.5e7, 2.25e7])

subplot(3, 1, 2)
plot(time(currRange), rppg(sensor, currRange))
xlabel("Time (s)")
ylabel("Amplitude (a.u.)")
title("Patient " + num2str(id) + " Sensor " + num2str(sensor) + " Segment " + num2str(seg)+ " Original, Zoomed in")
set(gca, "FontSize", 20)
% ylim([5.35e6, 5.45e6])

subplot(3, 1, 3)
plot(time(currRange), filtered)
xlabel("Time (s)")
ylabel("Amplitude (a.u.)")
title("Patient " + num2str(id) + " Sensor " + num2str(sensor) + " Segment " + num2str(seg) + " Filtered")
set(gca, "FontSize", 20)


% %% % of time with artifacts pre removal
% totalTime = zeros(1, 5);
% artifactTimes = zeros(4, 5);
% for id = 1:20
%     disp(id)
% 
%     excp = find(patient(id).phase>0);
%     time = patient(id).time(excp);
%     ecg = patient(id).ref_ecg(excp);
%     rppg = patient(id).rppg(:, excp);
%     phases = patient(id).phase(excp);
% 
%     segCuts = splitData(phases);
%     
%     for seg = 1:numel(segCuts)-1
%         currRange = (segCuts(seg):segCuts(seg+1)-1);
%         currPhase = phases(segCuts(seg));
%         
%         totalSegs(currPhase) = totalSegs(currPhase) + numel(currRange);
%         totalSegs(5) = totalSegs(5) + numel(currRange);
%         
%         allArtifact = true(1, numel(currRange));
%         for sensor = 1:3
%             [filtered, removedArtifact, hasArtifact] = removeArtifacts(rppg(sensor, currRange));
%             
%             if checkNoData(rppg(sensor, currRange))
%                 removedArtifact = numel(currRange);
%                 hasArtifact = true(1, numel(hasArtifact));
%             end
%             artifactTimes(sensor, currPhase) = artifactTimes(sensor, currPhase) + removedArtifact;
%             artifactTimes(sensor, 5) = artifactTimes(sensor, 5) + removedArtifact;
%             allArtifact = allArtifact & hasArtifact;
%         end
%         
%         artifactTimes(4, currPhase) = artifactTimes(4, currPhase) + sum(hasArtifact);
%         artifactTimes(4, 5) = artifactTimes(4, 5) + sum(hasArtifact);
%         
%     end 
% end
% 
% percents = round(artifactTimes ./ totalSegs .* 100, 2);
% 
% % id = 1;
% % excp = find(patient(id).phase>0);
% % time = patient(id).time(excp);
% % ecg = patient(id).ref_ecg(excp);
% % rppg = patient(id).rppg(:, excp);
% % if ishandle(4)
% %     clf(4)
% % end
% % figure(4)
% % for sensor  = 1:3
% %     subplot(3, 1, sensor)
% %     plot(time(currRange), rppg(sensor,currRange))
% % end

% %% Percent of time with artifacts post removal
% totalTime = zeros(1, 5);
% artifactTimes = zeros(4, 5);
% for id = 1:20
%     disp(id)
% 
%     excp = find(patient(id).phase>0);
%     estimates = allEstimateshrrppg(id).estBpm;
%     phases = patient(id).phase(excp);
% 
%     segCuts = splitData(phases);
%     
%     for seg = 1:numel(segCuts)-1
%         currRangeLength = segCuts(seg+1) - segCuts(seg);
%         currPhase = phases(segCuts(seg));
%         
%         totalSegs(currPhase) = totalSegs(currPhase) + currRangeLength;
%         totalSegs(5) = totalSegs(5) + currRangeLength;
%         
%         allArtifact = true;
%         for sensor = 1:3    
%             hasArtifact = isnan(estimates(sensor, seg)) && isnan(estimates(sensor, seg));
%             
%             if hasArtifact
%                 artifactTimes(sensor, currPhase) = artifactTimes(sensor, currPhase) + currRangeLength;
%             artifactTimes(sensor, 5) = artifactTimes(sensor, 5) + currRangeLength;
%             else
%                 allArtifact = false;
%             end
%         end
%         if allArtifact
%             artifactTimes(4, currPhase) = artifactTimes(4, currPhase) + currRangeLength;
%             artifactTimes(4, 5) = artifactTimes(4, 5) + currRangeLength;
%         end
%         
%     end 
% end
% 
% percents = round(artifactTimes ./ totalSegs .* 100, 2);
