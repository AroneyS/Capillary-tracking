directory = uigetdir();
cd(directory)

minnumbspots=10;  %minimum number of points in a trajectory

file_list = dir('*.csv');
files = file_list.name;
count = size(file_list);

for i=1:count(1)
        loadstr = file_list(i).name; %.csv file name
        root = strsplit(loadstr, '.csv');
        savestr = string(strcat(root(1), '.mat')); %output file name

        loadtrackmate_orientation_function(minnumbspots, loadstr, savestr)
        disp(strcat(savestr, '... completed'))
end