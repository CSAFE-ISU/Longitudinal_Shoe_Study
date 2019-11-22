DATA TITLE: Longitudinal Shoe Study: TekScan Mat Scanner Data
PROJECT TITLE: CSAFE Longitudinal Shoe Study

== AUTHORS ==
Author: Susan Vanderplas
ORCID: 0000-0002-3803-0972
  Institution: University of Nebraska Lincoln
  Email: svanderplas2@unl.edu

Author: Alicia Carriquiry
Institution: Center for Statistics and Applications in Forensic Evidence and Statistics Department, Iowa State University

Author: James Kruse
Institution: Department of Sociology, Iowa State University

Author: Guillermo Basulto-Elias
Institution: Institute for Transportation, Iowa State University

Author: Stacy Renfro
Institution: Center for Statistics and Applications in Forensic Evidence, Iowa State University


== ASSOCIATED PUBLICATIONS and RESOURCES: ==
Center for Statistics and Applications in Forensic Evidence Website: https://forensicstats.org/
Github repository for documentation: https://github.com/CSAFE-ISU/Longitudinal_Shoe_Study


== Overview ==
Scans of shoe prints obtained following the CSAFE mat scan procedure.

== FILE DIRECTORY ==
----- FILE LIST-----
- Method_Image_Replicate_Codebook.csv: Contains descriptions of the metadata encoded in each file name.
- Variable_Codebook.csv: Contains descriptions of the auxiliary data collected along with the images (survey results, participant height and weight, number of steps, etc.)

- ShoePressureScanFiles.zip
Contains the scans of the shoe prints taken with the mat scan methodology. Images are named with respect to the following convention:
  `{ID#}_{Date}_{Method}_{Image#}_{Rep#}_{ID of technician(s)}` where:
  - ID# is a 6 digit number followed by {RL} indicating right (R), or left (L) shoe. The first three digits are the shoe ID and the second three digits are a checksum.
  - Date, in yyyymmdd format, indicating the date the data was collected (not the date the shoes were turned in for data collection).
  - Method_Image_Replicate: these fields are hierarchically determined - the meaning of the values for image and replicate depend on the method.
  - Method: 2 = 2D Scanner
  - Image: 1 image each
  - Replicate: 2 reps per shoe
  - ID of technician(s): Some methods require that one individual wear the shoe, another individual assists with the data collection, and (in some cases) a third individual digitizes the information. In those cases names are separated by underscores.
Also contains 3 separate comma separated data files:
  - Shoe-info.csv, which contains information relating to the specific shoe (size, model, color, wearer characteristics)
  - Visit-info.csv, which contains information relating to the specific data collection visit (e.g. survey answers, pedometer readings)
  - Image-info.csv, which contains information relating to the specific image (collection method, replicate number, workers involved in the collection)


== DATA COLLECTION METHODS ==
The study consists of 160 pairs of shoes:
  - Two models (Nike Winflo 4 or Adidas Seeley)
  - Four possible sizes for each model
Each pair of shoes was worn for at least 10,000 steps per week over a 6-month period, with multiple measurements of the shoe soles taken initially and during three check-in periods spaced at approximately 5 week intervals, though for this method, data was only collected for the initial period.

Prints and measurements for this data set were taken using the following equipment:  Tekscan Mat Scanner. This method is documented in the CSAFE Longitudinal Shoe Study Collection Procedures Collection (DOI: http://doi.org/10.25380/iastate.8016341), specifically the following documents:
  - Tekscan_Mat_Scanner.pdf


== LICENSING ==
This work is licensed under a Creative Commons Attribution 4.0 International License. (https://creativecommons.org/licenses/by/4.0/)



## Study Description

The study consists of 160 pairs of shoes:
- Two models (Nike Winflo 4 or Adidas Seeley)
- Four possible sizes for each model

Each pair of shoes was worn for at least 10,000 steps per week over a 6-month period, with multiple measurements of the shoe soles taken initially and during three check-in periods spaced at approximately 5 week intervals.

Measurements were taken using the following equipment: TekScan Mat Scanner (initial visit only)

## Image-Specific Metadata

Images are named with respect to the following convention:
`{ID#}_{Date}_{Method}_{Image#}_{Rep#}_{ID of technician(s)}` where:

- ID# is a 6 digit number followed by {RL} indicating the shoe
- The first three digits are the shoe ID
- The second three digits are a checksum
- R = right shoe, L = left shoe
- Date, in yyyymmdd format, indicating the date the data was collected (not the date the shoes were turned in for data collection)
- Method_Image_Replicate: these fields are hierarchically determined - the meaning of the values for image and replicate depend on the method.
  - Method: 1 = Matscan
  - Image:
    1. avi (video)
    2. csv/excel file with data from all frames
    3. JPEG (single frame)
    4. csv/excel file with single frame
    5. movie recording (not transferred)
  - Replicate:
    - 1-3: Right, barefoot
    - 4-6: Left, barefoot
    - 7-9: Right, with shoe
    - 10-12: Left, with shoe
- ID of technician(s): Some methods require that an individual wear the shoe, another individual collect the data; in those cases names are separated by underscores.

The images are accompanied by 3 CSV files describing the shoes, visit (information collected from surveys along with the shoes), and individual images.

The codebooks contain descriptions of the variables in each of the CSV files as well as a more extensive description of the Method_Image_Replicate coding described above.
