TYPE BMPHeader
fileType AS STRING * 2  'equals "BM" to identify this as a BMP
fileSize AS LONG   'the size of this file (equals LOF())
reserved AS LONG   'not used (perhaps in future)
offset AS LONG     'the offset into the file of the image data
headerSize AS LONG 'length of rest of header (always 40)
imgWidth AS LONG   'width of BMP in pixels
imgHeight AS LONG  'height in pixels
planes AS INTEGER  'number of color planes (should be 1)
BBP AS INTEGER     'bits per pixel (8 for 256 colors)
compression AS LONG'compression type (0 is none)
sizeImage AS LONG  'size of the image in bytes
XPPM AS LONG       'Pixels Per Meter on x-axis
YPPM AS LONG       'Pixels Per Meter on y-axis
ColorsUsed AS LONG 'number of colors used in bitmap
CImportant AS LONG 'number of "important" colors
END TYPE

SUB BMPSAVE (Filename$)
DIM header AS BMPHeader

BMP = FREEFILE
OPEN Filename$ FOR BINARY AS #BMP

header.fileType = "BM"
header.fileSize = LEN(header) + 1024 + 64000
header.offset = LEN(header) + 1024
header.headerSize = 40
header.imgWidth = 320
header.imgHeight = 200
header.planes = 1
header.BBP = 8
header.compression = 0
header.sizeImage = 64000
header.XPPM = 10
header.YPPM = 10
header.ColorsUsed = 256
header.CImportant = 256
PUT #BMP, 1, header  'get the header information

OUT &H3C7, 0
FOR iN = 0 TO 255
  R = INP(&H3C9) * 4
  G = INP(&H3C9) * 4
  B = INP(&H3C9) * 4
  C& = (R * 65536) + (G * 256) + B
  PUT #BMP, , C&
NEXT iN

FOR Y = 199 TO 0 STEP -1
  aRow$ = SPACE$(320)
  FOR X = 0 TO 319
    MID$(aRow$, X + 1, 1) = CHR$(POINT(X, Y))
  NEXT X
  PUT #BMP, , aRow$
NEXT Y

CLOSE #BMP

END SUB

