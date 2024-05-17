"""
Golden measure for rotating-key XOR encryption
"""

import pandas as pd
import numpy as np
import os

# dataPath = "..data/rotating-xor.csv"
nBits = 32
dataPath = "../data/rotating-xor.csv"
key = 0xB4352B93
truncator32 = 0xFFFFFFFF
truncator5 = 0b11111
complexEncrypt = True

def main(): 
    
    # read CSV and truncate all data values to 32 bits exactly
    csvPath = os.fsencode(dataPath)
    df = pd.read_csv(os.fsdecode(csvPath), converters={'INPUT': lambda x: int(x, 16)})
    df["INPUT"] = np.bitwise_and(df["INPUT"], truncator32) 
    
    # Generate arr of shifted keys
    keyArr = np.full(len(df["INPUT"]), np.bitwise_and(key, truncator32)) # create array of keys and ensure all are no longer than 32 bits
    shifts = np.mod(np.arange(len(keyArr)), nBits) # create array of shift amounts (mod32 to repeat every 32)
    if (complexEncrypt):
        shifts = np.bitwise_xor(shifts, np.bitwise_and(truncator5))

    keyArr = np.bitwise_or(np.bitwise_and(np.left_shift(keyArr, shifts), truncator32), \
    np.right_shift(keyArr, nBits - shifts)) # perform rotation on keys by shift amount
    
    if complexEncrypt:
        keyArr = np.power(keyArr, 2) # square
        keyArr = np.mod(keyArr, 4294967311) # mod the big prime number
        keyArr = np.bitwise_and(keyArr, truncator32) # truncate back down to 32 bits
    
    # XOR each data piece with relevant key data
    df["GOLDEN"] = np.bitwise_xor(df["INPUT"], keyArr)
    df["GOLDEN"] = df["GOLDEN"].apply("{:X}".format)
    df["INPUT"] = df["INPUT"].apply("{:X}".format)
    
    # output to CSV
    # still need to double check that it doesn't overwrite the data or something
    df.to_csv(dataPath, index=False)

if __name__ == "__main__":
    main()
