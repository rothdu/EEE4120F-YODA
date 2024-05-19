rm -f ../data/timing/openclcomplex.csv
for i in 1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288 1048576 2097152 4194304 8388608 16777216 33554432 67108864 134217728 268435456
do
    output="$i,"
    for j in 1 2 3 4 5
    do
        rm -f encryption
        g++ -std=c++20 encryption.cpp -D ADVANCED -D DATA_ONLY -D DATALENGTH=$i -o encryption -lOpenCL
        SCRIPT="./encryption"
        output+="$($SCRIPT),"
    done
    output="${output%,}"
    echo $output >> ../data/timing/openclcomplex.csv
done
rm -f encryption

