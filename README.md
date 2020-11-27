# Cell tracking and analysis protocol v2.0

## Software required
Fiji/ImageJ 2.0.0
Matlab

Change RAM allocation in Fiji from Edit/Options/Memory&Threads (>10GB ideally).

## File naming Scheme
“strain\_position\_media\_replicate\_video\_experiment-.avi”

Where position is bottom, middle or top (section of capillary imaged), replicate is biological replicate and video is technical replicate

## ImageJ script 1 (batch): imagej\_stage\_1.ijm
Select a folder and run below on all files in it.
Runs steps 1-6 with the standard settings (steps 2 and 6 are skipped where unnecessary).
Step 6 is run (and Step 2 skipped) when filename ends in ‘\_F’. 
Set ROIs manually using position of non-swimming particle in same plane as swimmers. 
Select all points and save these in subfolder ROI within video folder (RoiSet\_[filename].zip).


### 1. Fiji/ImageJ importing (.avi -> .tif)
File/Open – convert to grayscale

File/Save as/Tiff…

Image/Adjust/“Brightness/Contrast” – adjust to better visualise cells

### 2. Normalization
Plugin/Integral Image Filters/Normalise local contrast
- Block radius x: 15
- Block radius y: 15
- SD: 15 (check with preview)
- Centre: Yes
- Stretch: Yes

### 3. Subtract background
Process/Subtract background
- Radius (cell size ~10px, test with higher (20) to start with and check with preview)
- Light background: Yes
- Disable smoothing: Yes

### 4. Invert Image
Edit/Invert (software is designed for dark background)

### 5. Adjust for flow (run only if flow detected)
Analyse/Tools/ROI Manager
Find non-swimming particle that follows flow and is visible for the whole video.
Mark position with “Point Tool” in first frame, last frame and 1-3 extra frames throughout the video.
The more positions marked, the more accurate the adjustment but the longer it will take.

Plugin/Multi DriftCorrection (run with ROI Manager window open with points loaded)


## Final tweaks (manual)
Can be skipped if the images seem clear.
Alter brightness/contrast (as above) to the point where cells are clearly visible with little noise.

Process/Noise/Remove outliers (can help with non-surface videos)
- Radius: 0-2
- Threshold: 0
- Which outliers: Bright

If batch analysing data, save again. 

## TrackMate (basic)
Monitor memory with Plugins/Utilities/Monitor Memory… 

Garbage collect with Plugins/Utilities/Collect Garbage – in lower Utilities menu (close completely when this doesn’t work due to memory leak)

Image/Properties (check image properties match)
- Channels (c): 1
- Slices (z): 1
- Frames (x): ~600
- Pixel width: 0.21 microns
- Pixel height: 0.21 microns
- Voxel depth: 1
- Frame interval: 0.10 sec

Plugin/Tracking/TrackMate
- Check properties match above

Detector: LoG detector
- Blob: 2 microns
- Threshold: 1 (test with different values, want to include as many positives as possible)
- Median filter: No
- Subpixel localization: Yes

No initial thresholding.
The Quality metric tends to be less useful since it is designed for circular spots.

Viewer: Hyperstack displayer (check cells).
Set cropping if adjusting for flow (go to last frame and remove the black column).
Check both Quality and Standard deviation for clear bimodal distribution and select the higher group from the one which is clearest.

Tracker: Linear motion LAP tracker
- Max search radius: 10 (maximum movement distance per frame, 100um/s)
- Initial search radius: 10 (as above for initiating new track)
- Gap closing frame: 1 (cell can undetected for 1 frame and still be on the same track)

Filter tracks to remove artefacts.
Try to keep immobile bacteria for swimming fraction calculations. 
- Spots in track: >10 (remove tracks shorter than 1 second)
- Mean quality: >1.5 (remove spurious tracks from out of focus cells usually at the edges; and/or use X/Y location)

Save log with default name.
Skip to ImageJ script 2.

## TrackMate Part 1 (if removing non-motile particles)
Monitor memory with Plugins/Utilities/Monitor Memory… 

Garbage collect with Plugins/Utilities/Collect Garbage – in lower Utilities menu (close completely when this doesn’t work due to memory leak)

Image/Properties (check image properties match)
- Channels (c): 1
- Slices (z): 1
- Frames (x): ~600
- Pixel width: 0.21 microns
- Pixel height: 0.21 microns
- Voxel depth: 1
- Frame interval: 0.10 sec

Plugin/Tracking/TrackMate
- Check properties match above

Detector: LoG detector
- Blob: 2 microns
- Threshold: 1 (test with different values, want to include as many positives as possible)
- Median filter: No
- Subpixel localization: Yes

No initial thresholding.
The Quality metric tends to be less useful since it is designed for circular spots. 

Viewer: Hyperstack displayer (check cells)
Set cropping if adjusting for flow (go to last frame and remove the black column).
Check both Quality and Standard deviation for clear bimodal distribution and select the higher group from the one which is clearest.

Hit next before saving to ensure the filtering is saved.
Save spots to file.
Suffix: -initial\_spots.xml.

Tracker: Simple LAP tracker
- No initial thresholding.
- Linking max distance: 2.0 (maximum movement distance per frame, set low to track non-motile cells)
- Gap-closing max distance: 2.0 (as above for gap-closing)
- Gap-closing max frame gap: 10 (maximum frames cell can be untracked)

Filter tracks to remove motile spots.
- Duration of track: >1 seconds
- Can remove obvious swimming tracks with track displacement

Hit next before saving to ensure the filtering is saved.
Save tracks to file.
Suffix: -nonmotile\_tracks.xml.

## Python Script 1 (batch): remove\_tracked_spots.py
Removes spots found in \*-nonmotile\_tracks.xml from \*-initial\_spots.xml, producing \*-motile\_spots.xml.
Effectively, this removes the nonmotile spots from interfering with motile tracks. 

## TrackMate Part 2 (if removing non-motile particles)
Plugins/Tracking/Load a trackmate file
Load generated files. Suffix: -motile\_spots.xml.

Tracker: Linear motion LAP tracker
- Max search radius: 10 (maximum movement distance per frame, 100um/s)
- Initial search radius: 10 (as above for initiating new track)
- Gap closing frame: 1 (cell can be undetected for 1 frame and still be on the same track)

Filter tracks to remove artefacts.
Try to keep immobile bacteria for swimming fraction calculations. 
- Spots in track: >10 (remove tracks shorter than 1 second)
- Mean quality: >2 (remove spurious tracks from out of focus cells usually at the edges; and/or use X/Y location)
- Track displacement: >2 (remove non-motile tracks that were not caught by Part 1)

Hit next before saving to ensure the filtering is saved.
Save tracks to file.
Suffix: -motile\_tracks.xml.

## ImageJ script 2 (batch): imagej\_stage\_2.py
Generates spreadsheets of trajectory data for Matlab scripts from manually run TrackMate.
If spot morphology was not tracked, semiaxislengths and phi are set to 0.

Edit:
- directory = base directory for paths
- inpath = path to ‘.xml’ files
- outpath = path to place output ‘.csv’ files

## Matlab script 1 (batch): loadtrackmate\_orientation.m
Run in Matlab.
Loads data from ‘[filename].csv’ to form data structure.
Runs ‘loadtrackmate\_orientation\_function.m’ on all the ‘.csv’ files in a directory.

Edit:
- minnumbspots = 10 (threshold for minimum number of points in a track, 1s at 10fps)

Output: 
- ‘[filename].mat’ (data structure)

## Matlab script 2 (batch): rhizobia\_general\_analysis.m
Run in Matlab.
Updates data structure from above with tumble and mean squared displacement analysis. 

Edit:
- Frametime = 0.1 (fps of images)
- thresholds.tumble = deg2rad(2500) (tumble radians/s cutoff in dtheta/dt vs t plot)
- thresholds.angle\_bounds = 0.02 (time before and after reorientation event to find total angle)
- coverage = 1000 (Number of spline smoothing points for each real point)

Output: 
- ‘[filename]\_analysed.mat’ (saved analysis with updated data structure)

## R script 1: matlab\_to\_csv-with\_analysis.R
Run in R.
Converts matlab '\*\_analysed.mat' files to '\*.csv'.

Edit (wrangling section):
- chosen_folders: vector of file.paths containing '\*\_analysed.mat' files
- output_file: name of compiled csv file

## Output files
### Used in R script
- ts: time coordinates (seconds)
- x: x-coordinates (microns)
- y: y-coordinates (microns)
- extract\_velo: velocity from spline at track times
- locs: time coordinates of peaks
- spline\_angle: angle at peak points
- msd: mean squared displacement (mean, sd, n, intercept, slope). Linear model fit statistics, linear indicates Brownian motion, non-linear increasing directed motion, non-linear decreasing constrained with the intercept estimating measurement error.

### Extra values
- t: frame coordinates
- minorleng: ellipsoid fit semi-axis length c
- majorleng: ellipsoid fit semi-axis length b
- phi: movement direction of cell
- meanintens: average intensity
- duration: duration of track (seconds)
- scale\_points: boundaries for spline values
- splinex\_gof: goodness of fit for x spline (sse, rsquare, dfe, adjrsquare, rmse)
- splinex\_fit: fit data for x spline (numobs, numparam, residuals, Jacobian, exitflag, p)
- spliney\_gof: goodness of fit for y spline (sse, rsquare, dfe, adjrsquare, rmse)
- spliney\_fit: fit data for y spline (numobs, numparam, residuals, Jacobian, exitflag, p)
- peaks: value of peaks detected in spline\_head

### Removed due to space constraints
- spline\_ts: time coordinates used for spline (seconds)
- splinex: x-coordinates for spline (microns)
- spliney: y-coordinates for spline (microns)
- spline\_velo: velocity across spline
- spline\_acc: acceleration across spline
- spline\_head: angle heading from spline
- spline\_dhead: change in spline.head
