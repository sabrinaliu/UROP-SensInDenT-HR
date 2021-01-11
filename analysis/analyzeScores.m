pdAvg = NaN(20, 3);
corrAvg = NaN(20, 3);

for id = 1:20
   currRelScores = allEstimates(id).relScr;
   for sensor = 1:3
       pdAvg(id, sensor) = mean(currRelScores(sensor,:), "omitnan");
       corrAvg(id, sensor) = mean(currRelScores(sensor+3,:), "omitnan");
   end
end

% diffAvg = pdAvg - corrAvg;
diffAvg = pdAvg ./ corrAvg;