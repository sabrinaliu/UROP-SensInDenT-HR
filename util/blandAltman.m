function blandAltman(ref, exp, relScore)
% Given sequence of reference values and sequence of experimental values,
% make Bland-Altman plot

    err = exp - ref;

    if nargin < 3
        scatter(ref, err)
    else
        scatter(ref, err, [], relScore)
        colorbar
    end


    ax = gca;
    ax.XAxisLocation = 'origin';

    hold on

    mu = mean(err, 'omitnan');
    sig = std(err, 'omitnan');
    yline(mu, '--g', "Mean: " + num2str(mu));
    yline(mu + sig*1.96, '-.r', "+1.96sd: " + num2str(mu + sig*1.96));
    yline(mu - sig*1.96, '-.r', "-1.96sd: " + num2str(mu - sig*1.96));
    xlabel('Reference')
    ylabel('Estimate - Reference')

end
