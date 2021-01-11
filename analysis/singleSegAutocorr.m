
id = 20;
seg = 10;
sensor = 3;

excp = find(patient(id).phase>0);
time = patient(id).time(excp);
ecg = patient(id).ref_ecg(excp);
rppg = patient(id).rppg(:, excp);
phases = patient(id).phase(excp);

segCuts = splitData(phases);

currRange = (segCuts(seg):segCuts(seg+1)-1);

filtered = removeArtifacts(rppg(sensor, currRange));
[bpmEstimate, ~, corrVals] = autocorrelation(filtered);
disp(bpmEstimate)

f2 = 4;
if ishandle(f2)
    clf(f2)
end
figure(f2)
subplot(2, 1, 1)
plot(time(currRange), filtered)
xlabel("Time (s)")
ylabel("Filtered RPPG Signal")
title("Patient " + num2str(id) + " Sensor " + num2str(sensor) + " Segment " + num2str(seg))
set(gca, "FontSize", 20)

subplot(2, 1, 2)
plot(corrVals(1,:), corrVals(2,:))
xlabel("Lag (BPM)")
ylabel("Autocorrelation * AMDF")
set(gca, "FontSize", 20)