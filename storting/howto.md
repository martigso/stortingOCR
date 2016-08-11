### How to organize pdfs

1. Download a pdf-file
2. Make a folder with *s* and the session year that was downloaded -- for 1945 the folder should have the name *s1945*
3. Make a subfolder in the year for the *letter* of the relevant session year -- the first pdf of 1945 has the letter *a*, so that the subfolder name should be *s1945a*, whereas the second is *s1945b* and so on.
4. Put the pdf in the subfolder and give it the same name as the subfolder -- *s1945a.pdf* should be placed in `./storting/s1945/s1945a/`
5. Open terminal in repository root, run `bash ./bash/universalNoiseReduction.sh` (run `chmod +x universalNoiseReduction.sh` if it is not executable), and follow the prompts.
6. When the image processing is done (this will take a while), run `bash ./bash/organizeText.sh` and follow the prompts.
