function [track] = fit_track(track, frametime, coverage)
    %fit_track Fit data with spline smoothed curve
    track.ts = frametime * track.t;
    track.duration = track.ts(end) - track.ts(1);
    
    % Splines
    endtime = length(track.x);
    t = linspace(1, endtime, (endtime-1)*coverage + 1);
    
    scale_points = find(floor(t)==t); %find integer points (original timepoints)
    track.scale_points = scale_points;
    ts = zeros(1, length(t));
    for i=1:length(t)  %splinet mapped to ts, with gaps
        if find(scale_points == i)
            ts(i) = track.ts(find(scale_points == i, 1));
        else
            above = find(scale_points > i, 1);
            below = find(scale_points > i, 1) - 1;
            t_above = t(scale_points(above));
            t_below = t(scale_points(below));
            ts(i) = (t(i) - t_below) / (t_above-t_below) * (track.ts(above)-track.ts(below)) + track.ts(below);
        end
    end
    ts = transpose(ts);
    track.spline_ts = ts;
    
    [splinex, track.splinex_gof, track.splinex_fit] = fit(track.ts, track.x, 'smoothingspline');
    [spliney, track.spliney_gof, track.spliney_fit] = fit(track.ts, track.y, 'smoothingspline');
    track.splinex = splinex(ts);
    track.spliney = spliney(ts);
    
    [splinex_velo, splinex_acc] = differentiate(splinex, ts);
    [spliney_velo, spliney_acc] = differentiate(spliney, ts);
    track.spline_velo = sqrt(splinex_velo.^2 + spliney_velo.^2);
    track.spline_acc = sqrt(splinex_acc.^2 + spliney_acc.^2); %amplitude for velocity
    track.extract_velo = track.spline_velo(scale_points);
    
    track.spline_head = atan2(spliney_velo, splinex_velo);  %atan2 for heading angle
    track.spline_head = unwrap(track.spline_head);
    track.spline_dhead = gradient(track.spline_head, ts); %change in heading over time
end

