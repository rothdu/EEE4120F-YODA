rm -f openCLresults.csv
for i in 1 4 16 64 256 1024 2048 4096 10000
do
    for j in 1 2 3 4 5 6
    do
        rm -f multiplication.out
        g++ multiplication.cpp -D DATA_ONLY -D SIZE=$i -o multiplication.out -lOpenCL
        ./multiplication.out >> openCLresults.csv
    done
done
rm -f multiplication.out
