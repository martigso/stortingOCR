#!/bin/bash
echo "What year is going to be split?"
read year

echo "Which letter of the year?"
read letter

echo "What level of LAT should be used on this pdf? (e.g 20x20+10%)"
read lat

echo "Process number (1 if you only run 1)"
read process

rm -r tmp$process
mkdir tmp$process

echo "Old files removed ..."

echo "Starting up with $year$letter..."
pdftk "./storting/s$year/s$year$letter/s$year$letter.pdf" burst output ./tmp$process/pg_%0002d.pdf
echo "Pdfs split ..."

rm ./tmp$process/doc_data.txt

cd ./tmp$process
Rscript ../R/rename_files.R
echo "Files renamed ..."

pdfPage="$(ls pg*.pdf)"
pdfPage=(`echo "${pdfPage}" | grep -o "[0-9]*"`)

echo "Converting to 300x300 ..."
for i in ${pdfPage[@]}; do
  convert -density 300x300 -shave 10x100 "pg_$i.pdf" "initiala-$i.png"
done

initiala=(`ls initiala*`)
N_initiala=(`find -name "initiala*" | wc -l`)
N_initiala="$(($N_initiala - 1))"

sortedLength=(`seq 0 $N_initiala`)
unsortLength=(`echo "${initiala[@]}" | grep -o "[0-9]*"`)

echo "Doing LAT ..."
for i in ${sortedLength[@]}; do
	convert "${initiala[$i]}" -negate -lat ${lat} -negate "first-${unsortLength[$i]}.png"
done

first_lat10=(`ls first*`)

echo "Connected components original ..."
for i in ${sortedLength[@]}; do
    convert "${first_lat10[$i]}" -connected-components 4 -threshold 0 -negate "second-${unsortLength[$i]}.png"
done

second_lat10_cc=(`ls second*`)
echo "Connected components reduced noice ..."
for i in  ${sortedLength[@]}; do
  convert "${first_lat10[$i]}" -define connected-components:area-threshold=15 -connected-components 4 -threshold 0 -negate "third-${unsortLength[$i]}.png"
done

third_lat10_cc30=(`ls third*`)

echo "Drawing noise ..."
for i in ${sortedLength[@]}; do
  convert "${second_lat10_cc[$i]}" "${third_lat10_cc30[$i]}" -compose minus -composite "fourth-${unsortLength[$i]}.png"
done

fourth_diff=(`ls fourth*`)

echo "Removing drawn noise ..."
for i in ${sortedLength[@]}; do
    convert "${first_lat10[$i]}" \( -clone 0 -negate -fill white -colorize 100% \) "${fourth_diff[$i]}" -compose Blend -composite "final-${unsortLength[$i]}.png"
done


final=(`ls final*`)

for i in ${sortedLength[@]}; do
  convert "${final[$i]}" -fill black -opaque "#FF00FF" -morphology Erode Disk:0.5 "final-${unsortLength[$i]}.png"
done
echo "Image manipulation complete"

echo "Starting Tesseract ..."
for i in ${sortedLength[@]}; do
   echo " ... final-${unsortLength[$i]}.png"
   tesseract "final-${unsortLength[$i]}.png" "text-$year$letter-${unsortLength[$i]}" -l nor
done
