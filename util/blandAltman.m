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
    set(gca,'FontSize',14)

    hold on

    mu = mean(err, 'omitnan');
    sig = std(err, 'omitnan');
    yline(mu, '--g', "Mean: " + num2str(mu), "FontSize", 12);
    yline(mu + sig*1.96, '-.r', "+1.96sd: " + num2str(mu + sig*1.96), "FontSize", 12);
    yline(mu - sig*1.96, '-.r', "-1.96sd: " + num2str(mu - sig*1.96), "FontSize", 12);
    xlabel('Reference', "FontSize", 16)
    ylabel('Estimate - Reference', "FontSize", 16)

end
