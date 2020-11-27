function [track] = meanSquaredDisplacement(track, frametime)
    % Linear: Brownian motion
    % Non-linear increasing: directed motion
    % Non-linear decreasing: constrained
    % Intercept: measurement error

    scale_points = track.scale_points(1:min(floor(2/frametime), length(track.scale_points)));
    data = [track.splinex(scale_points), track.spliney(scale_points)];
    len = size(data, 1);
    dt_count = floor(min(len/4, 100));
    % see Single-particle tracking: the distribution of diffusion coefficients. Saxton MJ 1997 (doi: 10.1016/S0006-3495(97)78820-9)
    if dt_count == 1 % hack to stop error on <10 point tracks that will be removed anyway
        dt_count = 2;
    end
    
    track.msd.mean = zeros(dt_count, 1);
    track.msd.sd = zeros(dt_count, 1);
    track.msd.n = zeros(dt_count, 1);
    for interval = 1:dt_count
       distances = data(1+interval:end,1:2) - data(1:end-interval,1:2);
       displacements = distances / frametime;
       squaredDisplacements = sum(displacements.^2,2); % dx^2+dy^2

       track.msd.mean(interval) = mean(squaredDisplacements);
       track.msd.sd(interval) = std(squaredDisplacements);
       track.msd.n(interval) = length(squaredDisplacements);
    end
    lm = fitlm(1:length(track.msd.mean), track.msd.mean);
    track.msd.intercept = lm.Coefficients.Estimate(1);
    track.msd.slope = lm.Coefficients.Estimate(2);
end
