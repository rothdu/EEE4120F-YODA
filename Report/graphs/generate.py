import pandas as pd
import numpy as np
import matplotlib.pyplot as plt


def main():
    goldenSimplePath = "../../data/timing/goldensimple.csv"
    goldenComplexPath = "../../data/timing/goldencomplex.csv"
    openclSimplePath = "../../data/timing/openclsimple.csv"
    openclComplexPath = "../../data/timing/openclcomplex.csv"
    verilogSimplePath = "../../data/timing/verilogsimple.csv"
    verilogComplexPath = "../../data/timing/verilogcomplex.csv"
    gsdf = getDf(goldenSimplePath)
    gcdf = getDf(goldenComplexPath)
    osdf = getDf(openclSimplePath)
    ocdf = getDf(openclComplexPath)
    vsdf = getDf(verilogSimplePath)
    vcdf = getDf(verilogComplexPath)

    # dfs = (gsdf, gcdf, osdf, ocdf, vsdf, vcdf)

    dfs = (gsdf, gcdf)
    for df in dfs:
        df["Min"] = gsdf.iloc[:, 1:].min(axis=1)
    
    openclSpeedup = np.divide(gsdf["Min"], osdf["Min"])
    verilogSpeedup = np.divide(gsdf["Min"], vsdf["Min"])

    fig, ax = plt.subplots(1, 1)

    ax.scatter(openclSpeedup, gsdf["#Blocks"], s=15, c="g", label="OpenCL")
    ax.scatter(verilogSpeedup, gsdf["#Blocks"], s=15, c="b", label="FPGA")

    ax.legend(loc="upper left")

    fig.xscale("log", base=2)
    fig.yscale("log")
    fig.xticks(gsdf["#Blocks"])
    fig.grid(True)

    fig.title("Speedup of the OpenCL and FPGA implementations against the golden standard\nBasic encryption algorithm")
    fig.xlabel("Number of blocks encrypted")
    fig.ylabel("Speedup")

    fig.savefig("simplespeedup.png")

    fig.close()

    fig, ax = plt.subplots(1, 1)

    ax.scatter(openclSpeedup, gsdf["#Blocks"], s=15, c="g", label="OpenCL")
    ax.scatter(verilogSpeedup, gsdf["#Blocks"], s=15, c="b", label="FPGA")

    ax.legend(loc="upper left")

    fig.xscale("log", base=2)
    fig.yscale("log")
    fig.xticks(gsdf["#Blocks"])
    fig.grid(True)

    fig.title("Speedup of the OpenCL and FPGA implementations against the golden standard\nAdvanced encryption algorithm")
    fig.xlabel("Number of blocks encrypted")
    fig.ylabel("Speedup")

    fig.savefig("complexspeedup.png")

    fig.close()


    

def getDf(path):
    df = pd.read_csv(path, header=0)
    return df

def speedupGraph():

    fig, ax = plt.subplots(1, 1)

    ax.scatter(opencl, xaxis)

if __name__ == "__main__":
    main()