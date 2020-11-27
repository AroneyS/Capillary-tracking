directory = uigetdir();
cd(directory)

clear variables
thresholds.msd_slope = 1000;        % UNUSED slope of MSD for tracks under 2s
thresholds.msd_total = 10000;       % UNUSED total MSD after 2s
thresholds.tumble = deg2rad(2500);  % UNUSED (moved to R script) tumble radians/s cutoff in dtheta/dt vs t plot
thresholds.angle_bounds = 0.02;     % time before and after reorientation event to find total angle
coverage = 1000;                    % Number of spline smoothing points for each real point

frametime = 0.1;
file_list = dir('*tracks.mat');
count = size(file_list);
tic
for i=1:count(1)
    loadstr = file_list(i).name;
    load(loadstr)
    
    clear analysed_data
    for j=length(data):-1:1
        track = data(j);
        
        track = fit_track(track, frametime, coverage);
        track = tumble2(track, thresholds);
        track = meanSquaredDisplacement(track, frametime);
        
        track.spline_ts = [];
        track.splinex = [];
        track.spliney = [];
        track.spline_velo = [];
        track.spline_acc = [];
        track.spline_head = [];
        track.spline_dhead = [];
        
        analysed_data(j) = track;
        if mod(j, 10) == 0
            disp(['Track ', num2str(j), ' completed'])
        end
    end
    
    rootstr = strsplit(loadstr, '.mat');
    savestr = string(strcat(rootstr(1), '_analysed.mat'));
    if exist('analysed_data') == 0
        analysed_data = struct([]);
    end
    save(savestr,'analysed_data')
    disp(strcat(savestr, '... completed'))
end
toc