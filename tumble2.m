function [track] = tumble2(track, thresholds)
    %Tumble2 rewrite of tumble analysis
    
    [track.peaks, track.locs] = findpeaks(abs(track.spline_dhead), track.spline_ts); %'MinPeakDistance'?
    
    % Thresholding moved to R script, using actual angle calculated below
    % (so not affected by spline coverage)
    %true = find(track.peaks_raw > thresholds.tumble);
    %track.peaks = track.peaks_raw(true);
    %track.locs = track.locs_raw(true);
    %track.peak_rate = length(track.peaks) / (track.duration);
    
    % Convert angle_bounds value in seconds to a number of points in spline_ts
    quarter = floor( thresholds.angle_bounds * ( length(track.spline_ts) / (track.duration) ) );
    track.spline_angle(1) = 0;
    for i = 1:length(track.locs)
        location = find(track.spline_ts == track.locs(i));
        lower = max(location - quarter, 1);
        upper = min(location + quarter, length(track.spline_ts));
        track.spline_angle(i) = abs(track.spline_head(upper) - track.spline_head(lower));
    end
end

