/*
 * Macro template to process multiple images in a folder
 */

basePath = getDirectory("Input directory");

inPath = basePath + "raw_images/";
outPath = basePath + "data/";

suffix = ".avi";
// Pixel length (microns): camera pixel size (4.2 microns) / (objective magnification (40x) * C mount (0.5x)) = 0.21
pixel_length = 0.21;

processFolder(inPath);

function processFolder(inPath) {
	list = getFileList(inPath);
	for (i = 0; i < list.length; i++) {
		if(endsWith(list[i], "/"))
			processFolder("" + inPath + list[i]);
		if(endsWith(list[i], suffix))
			processFile(inPath, outPath, list[i]);
	}
}

function processFile(inPath, outPath, file) {

	if (endsWith(file, suffix)){
		filename = substring(file, 0, lengthOf(file) - lengthOf(suffix));
	} else {
		filename = file;
	}

	format = ".tif";
	formatlog = ".log";
	savename = filename;

	//Flow settings
	flow_run = 0; //Value set to 1 by filename ending in _F
	
	//Stabilization settings
	stab_run = 0; //1 to run, 0 to skip
	pyramid = 1;
	temp_up_coef = 0.90;
	iterations = 500;
	error = 0.000000000001;
	
	//Normalization settings
	norm_run = 1; //1 to run, 0 to skip
	block_radius_x = 15;
	block_radius_y = 15;
	sd = 15;
	
	//Background subtraction settings
	sub_run = 1; //1 to run, 0 to skip
	rolling = 20;
	
	//Inverting settings
	inv_run = 1; //1 to run, 0 to skip
	
	//Addition of _F to the filename will run drift adjustment over stabilization.
	//Find point in ROI Manager beforehand and save as InPath + "/ROI/RoiSet_" + filename + ".zip"
	
	//Load image and find number of frames
	run("AVI...", "open=" + inPath + filename + suffix + " use convert");
	getDimensions(width, height, channels, slices, frames);
	NoFrames = channels * slices * frames;
	frame = 1/Stack.getFrameRate();
	run("Properties...", "channels=1 slices=1 frames=" + NoFrames + " unit=micron pixel_width=" + pixel_length + " pixel_height=" + pixel_length + " voxel_depth=1.00 frame=[" + frame + " sec]");
	
	// Save as Tiff
	suffix = format;
	saveAs("Tiff", inPath + filename + suffix);
	selectWindow(filename + suffix);
	run("Close");
	open(inPath + filename + suffix);

	//Better visualisation of image
	//run("Brightness/Contrast...");
	//run("Enhance Contrast", "saturated=0.35");
	
	//Check if flow detected
	if (endsWith(filename, "_F")){
		flow_run = 1;
		stab_run = 0;
		run("ROI Manager...");
		roiManager("Open", inPath + "ROI/RoiSet_" + filename + ".zip");
	}

	//Stabilization: duplicate of top right corner image opened and log file created to be applied to the whole image
	if (stab_run == 1){
		//makeRectangle(604, 0, 784, 678);
		makeRectangle(186, 248, 248, 267);
		run("Duplicate...", "title=" + filename + "_dup" + " duplicate frames=1-" + NoFrames);
		run("Image Stabilizer","transformation=Translation maximum_pyramid_levels=" + pyramid + " template_update_coefficient=" + temp_up_coef + " maximum_iterations=" + iterations + " error_tolerance=" + error + " log_transformation_coefficients");

		selectWindow(filename + suffix);
		run("Select None");
		run("Image Stabilizer Log Applier", " ");

		logname = filename + "_dup";
		logname = substring(logname, 0, indexOf(logname, "."));
		selectWindow(logname + formatlog);
		saveAs("Text", outPath + filename + formatlog);
		run("Close");

		selectWindow(filename + suffix);
		savename = savename + "_stab";
	}

	//Normalization: local contrast normalized across all frames
	if (norm_run == 1){
		run("Normalize Local Contrast", "block_radius_x=" + block_radius_x + " block_radius_y=" + block_radius_y + " standard_deviations=" + sd + " center stretch stack");
		savename = savename + "_norm";
	}

	//Background subtraction: normalization of contrast/brightness across each image
	if (sub_run == 1){
		selectWindow(filename + suffix);
		run("Subtract Background...", "rolling=" + rolling + " light disable stack");
		savename = savename + "_sub";
	}

	//Inversion: tracker works better with dark background and bright spots
	if (inv_run == 1){
		run("Invert", "stack");
		savename = savename + "_inv";
	}
	
	//Adjust for flow if applicable
	if (flow_run == 1){
		run("Multi DriftCorrection");
		savename = savename + "_norm2_flow";
	
		selectWindow("ROI Manager");
		run("Close");
	}
	saveAs("Tiff", outPath + savename + format);

	//Closes all images and cleans up memory (should go below ~100Mb after running)
	run("Close All");
	run("Collect Garbage");
}
