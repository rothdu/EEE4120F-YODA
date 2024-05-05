"""
Golden measure for rotating-key XOR encryption
"""

import pandas as pd
import numpy as np
import os

# dataPath = "..data/rotating-xor.csv"
nBits = 32
dataPath = "rotating-xor.csv"
key = 0xb4317385

def main():
    # used for truncating values to nBits length
    truncator = np.power(2, nBits) - 1
    
    # read CSV and truncate all data values to 32 bits exactly
    csvPath = os.fsencode(dataPath)
    df = pd.read_csv(os.fsdecode(csvPath), converters={'INPUT': lambda x: int(x, 16)})
    df["INPUT"] = np.bitwise_and(df["INPUT"], truncator) 
    
    # Generate arr of shifted keys
    keyArr = np.full(len(df["INPUT"]), np.bitwise_and(key, truncator))
    shifts = np.mod(np.arange(len(keyArr)), nBits)
    keyArr = np.bitwise_and(np.left_shift(keyArr, shifts), truncator)  + \
    np.right_shift(keyArr, nBits - shifts)
    
    # XOR each data piece with relevant key data
    df["GOLDEN"] = np.bitwise_xor(df["INPUT"], keyArr)
    
    # output to CSV
    # still need to double check that it doesn't overwrite the data or something
    df.to_csv("outcsv.csv")

if __name__ == "__main__":
    main()
