# CHI Paper download Scripts
Both scripts need to be executed sequentially.
- ACM_Lister processes all defined .bib files from the data folder (Data\Bibliography-Files) into CSVs, adding keywords and sessions.
The CSVs are saved in the same folder.
- ACM_downloaderV2 reads these CSVs from the same folder and downloads the HTML from the link in the second column. 
The download creates year folders where the script is located (here), in which the HTMLs will be saved.