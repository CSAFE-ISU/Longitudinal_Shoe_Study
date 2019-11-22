Longitudinal Shoe Study
================

## Study Description

The study consists of 160 pairs of shoes:
- Two models (Nike Winflo 4 or Adidas Seeley)
- Four possible sizes for each model

Each pair of shoes was worn for at least 10,000 steps per week over a 6-month period, with multiple measurements of the shoe soles taken initially and during three check-in periods spaced at approximately 5 week intervals. 

Measurements were taken using the following equipment:

- TekScan Mat Scanner (initial visit only)
- Everspry EverOS 2D Digital Scanner
- EinScan+ Pro 3D Scanner
- Digital Camera (photograph of the sole)
- Powder and Adhesive Film
- Powder and Paper
- Powder and Vinyl flooring


## Image-Specific Metadata

Images are named with respect to the following convention:
{ID#}_{Date}_{Method}_{Image#}_{Rep#}_{ID of technician(s)}

where:
- ID# is a 6 digit number followed by {RL} indicating the shoe
    - The first three digits are the shoe ID
    - The second three digits are a checksum
    - R = right shoe, L = left shoe
- Date, in yyyymmdd format, indicating the date the data was collected (not the date the shoes were turned in for data collection)
- Method_Image_Replicate
    1. Matscan
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
    2. 2D Digital Scan
        - Image: 
            1. Detailed scan
            2. Walking scan
        - Replicate: two per image type
    3. 3D Scan (STL format)
        - Image:
            1. Handheld scan
            2. Turntable scan
        - Replicate: two or three reps per shoe, depending on whether the shoe is part of the higher-replicate subset
    4. Digital Camera
        - Image: two images per shoe
        - Replicate: one replicate per shoe/image
    5. Film and Powder
        - Image: 
            1. Detail
            2. Press
        - Replicate: one replicate per shoe
    6. Paper and Powder
        - Image: 
            1. Detail
            2. Walking
            3. Stomp
            4. Smudge
        - Replicate: one per shoe
    7. Vinyl Photograph
        - Image: 1 image each
        - Replicate: 2 reps per shoe
- ID of technician(s): Some methods require that an individual wear the shoe, another individual collect the data; in those cases names are separated by underscores. 

## Visit-level Metadata
(Visit-info.csv)

- Shoe ID: 3 digit (may be left-padded with 0s)
- Activities: listed, and estimated hours spent per week
- Number of Steps: Cumulative, as measured by the pedometer. Notes are provided to indicate "rollover" events (when the pedometer flipped from 999999 to 0). In some cases, pedometers were accidentally reset, and numbers are approximate/estimated.
- Hours Worn per week: an additional column is included with the number range rounded to a reasonable interval for comparison purposes.
- Activity time estimates are reported in hours (approximately)


## Shoe-level Metadata
(Shoe-info.csv)

- Shoe ID: 3 digit (may be left-padded with 0s)
- Wearer ID: An ID indicating the wearer. Some participants wore two separate pairs of shoes, one of each model. 
- Weight: self-reported weight in pounds (reported at the initial visit)
- Height: Height in feet (decimal)

