#!/anaconda3/envs/xml/bin/python
# -*- coding: utf-8 -*-
"""
Created on Fri Oct  4 11:59:37 2019

@author: aroney
"""

#%% Imports
import xml.etree.ElementTree as ET
import os

base_directory = '/Users/aroney/Documents/Microscopy/NOBACKUP/'
input_directory = '20-11-13_M6.3/data'

os.chdir(base_directory + input_directory)

#%% Function
def remove_and_export(base_name):
    spots = base_name + '-initial_spots.xml'
    spots_tree = ET.parse(spots)
    spots_root = spots_tree.getroot()
    
    tracks = base_name + '-nonmotile_tracks.xml'
    tracks_root = ET.parse(tracks).getroot()
    
    # xml: Model: FilteredTracks
    filtered_tracks = set([])
    for child in tracks_root[1][3]:
        filtered_tracks.add(child.attrib['TRACK_ID'])
        
    # xml: Model: AllTracks
    filtered_spots = set([])
    for child in tracks_root[1][2]:
        if child.attrib['TRACK_ID'] in filtered_tracks:
            for grandchild in child:
                filtered_spots.add(grandchild.attrib['SPOT_SOURCE_ID'])
                filtered_spots.add(grandchild.attrib['SPOT_TARGET_ID'])
                
    # xml: Model: AllSpots
    for child in spots_root[1][1]:
        # SpotsInFrame: Spot
        for grandchild in reversed(child):
            if grandchild.attrib['ID'] in filtered_spots:
                child.remove(grandchild)
                                
    spots_tree.write(base_name + '-motile_spots.xml')

#%% Batch run
files = os.listdir()
for file in files:
    if file.endswith('-initial_spots.xml'):
        base_name = file[0:-18]
        if base_name + '-nonmotile_tracks.xml' in files:
            remove_and_export(base_name)
        else:
            print('File ' + file + ' has no matching *-nonmotile_tracks.xml')
    elif file.endswith('-nonmotile_tracks.xml'):
        base_name = file[0:-21]
        if base_name + '-initial_spots.xml' not in files:
            print('File ' + file + ' has no matching *-initial_spots.xml')
