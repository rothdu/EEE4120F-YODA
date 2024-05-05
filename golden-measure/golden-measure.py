"""
Golden measure for rotating-key XOR encryption
"""

import pandas as pd
import numpy as np
import os

def main():
    csvPath = os.fsencode("../data/rotating-xor.csv")
    df = pd.read_csv(os.fsdecode(csvPath), converters={'INPUT': lambda x: int(x, 16)})
    df["INPUT"] = df["INPUT"].astype(np.uint32)
    key = np.uint32(0xB431)
    print(np.binary_repr(key))
    
    keyArr = np.full(len(df["INPUT"]), key, dtype=np.uint32)
    shifts = np.mod(np.arange(len(keyArr)), np.uint32(32))
    printBinaryRepr(keyArr)
    keyArr = np.left_shift(keyArr, shifts) + \
    np.right_shift(keyArr, np.uint32(32) - shifts)

    printBinaryRepr(keyArr)


def printBinaryRepr(arr):
    for i in arr:
        print(np.binary_repr(i))

if __name__ == "__main__":
    main()