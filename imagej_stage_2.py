from ij import IJ, ImagePlus, ImageStack

from ij import WindowManager as WindowManager

import fiji.plugin.trackmate.Settings as Settings
import fiji.plugin.trackmate.Model as Model
import fiji.plugin.trackmate.SelectionModel as SelectionModel
import fiji.plugin.trackmate.TrackMate as TrackMate
import fiji.plugin.trackmate.Logger as Logger
import fiji.plugin.trackmate.detection.DetectorKeys as DetectorKeys
import fiji.plugin.trackmate.detection.DogDetectorFactory as DogDetectorFactory
import fiji.plugin.trackmate.tracking.LAPUtils as LAPUtils
import fiji.plugin.trackmate.visualization.hyperstack.HyperStackDisplayer as HyperStackDisplayer
import fiji.plugin.trackmate.features.FeatureFilter as FeatureFilter
import fiji.plugin.trackmate.features.FeatureAnalyzer as FeatureAnalyzer
import fiji.plugin.trackmate.features.spot.SpotContrastAndSNRAnalyzerFactory as SpotContrastAndSNRAnalyzerFactory
import fiji.plugin.trackmate.action.ExportStatsToIJAction as ExportStatsToIJAction
import fiji.plugin.trackmate.io.TmXmlReader as TmXmlReader
import fiji.plugin.trackmate.action.ExportTracksToXML as ExportTracksToXML
import fiji.plugin.trackmate.features.ModelFeatureUpdater as ModelFeatureUpdater
import fiji.plugin.trackmate.features.SpotFeatureCalculator as SpotFeatureCalculator
import fiji.plugin.trackmate.features.spot.SpotContrastAndSNRAnalyzer as SpotContrastAndSNRAnalyzer
import fiji.plugin.trackmate.features.spot.SpotIntensityAnalyzerFactory as SpotIntensityAnalyzerFactory
import fiji.plugin.trackmate.features.track.TrackSpeedStatisticsAnalyzer as TrackSpeedStatisticsAnalyzer
import fiji.plugin.trackmate.util.TMUtils as TMUtils
import fiji.plugin.trackmate.features.spot.SpotMorphologyAnalyzerFactory as SpotMorphologyAnalyzerFactory
from fiji.plugin.trackmate.providers import DetectorProvider
from fiji.plugin.trackmate.providers import TrackerProvider
from fiji.plugin.trackmate.providers import SpotAnalyzerProvider
from fiji.plugin.trackmate.providers import EdgeAnalyzerProvider
from fiji.plugin.trackmate.providers import TrackAnalyzerProvider
from util.opencsv import CSVWriter
from java.io import FileWriter, File
from java.lang.reflect import Array
from java.lang import String, Class  

import os, csv

def main():
	directory = "/"
	inpath = directory + "data"
	outpath = directory + "tracking_data"
	filetype = "tracks.xml"
	output_filetype = ".csv"

	for filename in os.listdir(inpath): # Iterate through files in path to determine those appropriate
		infile = os.path.join(inpath, filename)
		outfile = os.path.join(outpath, filename[:-4] + output_filetype)

		if os.path.isfile(infile):
			if filename.endswith(filetype) and not os.path.isfile(outfile):
				print("--" + filename + "--")
				print("Loading xml file...")
				TrackMate_main(infile, outfile)

	print("------Done------")


#------------------main END------------------#

  
def TrackMate_main(infile, outfile):
	file = File(infile)
	
	# We have to feed a logger to the reader.
	logger = Logger.IJ_LOGGER
	
	#-------------------
	# Instantiate reader
	#-------------------
	
	reader = TmXmlReader(file)
	if not reader.isReadingOk():
		sys.exit(reader.getErrorMessage())
	#-----------------
	# Get a full model
	#-----------------
	
	# This will return a fully working model, with everything
	# stored in the file. Missing fields (e.g. tracks) will be 
	# null or None in python
	model = reader.getModel()
	model.setLogger(Logger.IJ_LOGGER)
	# model is a fiji.plugin.trackmate.Model
	
	
	#---------------------------------------
	# Building a settings object from a file
	#---------------------------------------
	
	# We start by creating an empty settings object
	settings = Settings()
	
	# Then we create all the providers, and point them to the target model:
	detectorProvider        = DetectorProvider()
	trackerProvider         = TrackerProvider()
	spotAnalyzerProvider    = SpotAnalyzerProvider()
	edgeAnalyzerProvider    = EdgeAnalyzerProvider()
	trackAnalyzerProvider   = TrackAnalyzerProvider()
	
	reader.readSettings(settings, detectorProvider, trackerProvider, spotAnalyzerProvider, edgeAnalyzerProvider, trackAnalyzerProvider)
	
	 
	#----------------
	# Save results
	#----------------
	
	# The feature model, that stores edge and track features.
	fm = model.getFeatureModel()
	
	f = open(outfile, 'wb')
	
	for id in model.getTrackModel().trackIDs(True):
		track = model.getTrackModel().trackSpots(id)
		for spot in track:
			sid = spot.ID()
			# Fetch spot features directly from spot. 
			x=spot.getFeature('POSITION_X')
			y=spot.getFeature('POSITION_Y')
			t=spot.getFeature('FRAME')
			q=spot.getFeature('QUALITY')
			snr=spot.getFeature('SNR') 
			mean=spot.getFeature('MEAN_INTENSITY')
			
			semiaxislength_c=spot.getFeature('ELLIPSOIDFIT_SEMIAXISLENGTH_C')
			if semiaxislength_c is None:
				semiaxislength_c = 0
			
			semiaxislength_b=spot.getFeature('ELLIPSOIDFIT_SEMIAXISLENGTH_B')
			if semiaxislength_b is None:
				semiaxislength_b = 0
			
			phi_b=spot.getFeature('ELLIPSOIDFIT_AXISPHI_B')
			if phi_b is None:
				phi_b = 0
			
			data = Array.newInstance(Class.forName("java.lang.String"), 9)
			#String[] entries = "first#second#third".split("#");
			data[0] = str(sid)
			data[1] = str(id)
			data[2] = str(x)
			data[3] = str(y)
			data[4] = str(t)
			data[5] = str(semiaxislength_c)
			data[6] = str(semiaxislength_b)
			data[7] = str(phi_b)
			data[8] = str(mean)
			
			
			# create csv writer
			writer = csv.writer(f)
			
			row = [data[0], data[1], data[2], data[3], data[4], data[5],data[6], data[7], data[8]]
			writer.writerow(row)


	f.close()
	print('Saved ' + str(model.getTrackModel().nTracks(True)) + ' tracks.')
#------------------TrackMate_main END------------------#


if __name__ in ['__builtin__', '__main__']:
	main()