#!/bin/bash
cd ./tmp/

# Setting up some initial variables
echo "Which year is being organized?"
read year
echo "What letter of $year is being organized?"
read letter

# Removing or organization of pictures
echo "Should pictures be removed or organized? (rm/org)"
read rmPics
if [[ $rmPics = "rm" ]]; then
  rm *.png
elif [[ $rmPics = "org" ]]; then
  mkdir pictures
  mv *.png ./pictures/
else echo "Invalid input"; exit 1
fi

# Removing or organization of pdfs
echo "Should pdfs be removed or organized? (rm/org)"
read rmPdfs
if [[ $rmPdfs = "rm" ]]; then
  rm *.pdf
elif [[ $rmPdfs = "org" ]]; then
  mkdir pdfs
  mv *.pdf ./pdfs/
else echo "Invalid input"; exit 1
fi

# List of text files
textFiles=(`ls *.txt`)

# Removing cover and title pages
echo "How many cover and title pages are there?"
read introNoise
introNoiseFiles=(`echo "${textFiles[@]}" | grep -o "text-${year}${letter}-000[0-${introNoise}].txt"`)
for i in ${introNoiseFiles[@]}; do
  rm $i
done

textFiles=(`ls *.txt`)

echo "What is the last page of content?"
read lastContent
lastContent="$(($lastContent + 1))"
lastPage=${textFiles[-1]}
lastPage=(`echo "${lastPage}" | grep -o "[0-9]*"`)
lastPage=${lastPage[-1]}
backNoise=(`seq ${lastContent} ${lastPage}`)

for i in ${backNoise[@]}; do
  tmpDel=(`echo ${textFiles[@]} | grep -o "text-${year}${letter}-$i.txt"`)
  rm ${tmpDel[@]}
done

# Updating list of text files
textFiles=(`ls *.txt`)

# Filerting register data
echo "Should the register be seperated from the rest? (y/n)"
read sepRegister

if [[ $sepRegister = "y" ]]
then
  mkdir register
  echo "What is the last page of the register?"
  read lastpageRegister
  if [ $lastpageRegister -gt 99 ]; then
    sequenceEnd=(`seq 100 ${lastpageRegister}`)
    firstTen=(`echo "${textFiles[@]}" | grep -o "text-$year$letter-000[0-9].txt"`)
    firstHundred=(`echo "${textFiles[@]}" | grep -o "text-$year$letter-00[0-9][0-9].txt"`)
    hundredToEnd=()
    for i in ${sequenceEnd[@]}; do
      hundredToEnd+=(`echo "${textFiles[@]}" | grep -o "text-$year$letter-0$i.txt"`)
    done

    mv ${firstTen[@]} ./register
    mv ${firstHundred[@]} ./register
    mv ${hundredToEnd[@]} ./register

  elif [ $lastpageRegister -lt 100 ]; then
    firstTen=(`echo "${textFiles[@]}" | grep -e "000[0-9]"`)
    tenToEnd=(`echo "${textFiles[@]}" | grep -e "00[1-${lastpageRegister[1]}][0-${lastpageRegister[2]}]"`)
    for i in ${firstTen[@]}; do
      mv $i ./register
    done
    for i in ${tenToEnd[@]}; do
      mv $i ./register
    done
  else echo "Invalid input"; exit 1
  fi
fi

textFiles=(`ls *.txt`)

mkdir text
mv ${textFiles[@]} ./text/

cd ..

mv tmp/* ./storting/s$year/s$year$letter/
