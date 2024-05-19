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

    dfs = (gsdf, gcdf, osdf, ocdf, vsdf, vcdf)

    # dfs = (gsdf, gcdf)
    for df in dfs:
        df["Min"] = df.iloc[:, 1:].min(axis=1)
    




    fig, ax = plt.subplots(1, 1)

    minLen = np.minimum(gsdf.shape[0], osdf.shape[0])
    openclSpeedup = np.divide(gsdf["Min"][:minLen], osdf["Min"][:minLen])
    ax.plot(gsdf["#Blocks"][:minLen], openclSpeedup, c="g", label="OpenCL")

    minLen = np.minimum(gsdf.shape[0], vsdf.shape[0])
    verilogSpeedup = np.divide(gsdf["Min"][:minLen], vsdf["Min"][:minLen])
    ax.plot(gsdf["#Blocks"][:minLen], verilogSpeedup, c="b", label="FPGA")


    ax.legend()

    plt.xscale("log", base=2)
    plt.yscale("log")
    plt.xticks(gsdf["#Blocks"][::2])
    plt.grid(True)

    plt.title("Speedup of the OpenCL and FPGA implementations vs golden standard\nBasic encryption algorithm")
    plt.xlabel("Number of blocks encrypted")
    plt.ylabel("Speedup")

    fig.savefig("simplespeedup.png")

    plt.close()


    fig, ax = plt.subplots(1, 1)

    minLen = np.minimum(gcdf.shape[0], ocdf.shape[0])
    openclSpeedup = np.divide(gcdf["Min"][:minLen], ocdf["Min"][:minLen])
    ax.plot(gcdf["#Blocks"][:minLen], openclSpeedup, c="g", label="OpenCL")

    minLen = np.minimum(gcdf.shape[0], vcdf.shape[0])
    verilogSpeedup = np.divide(gcdf["Min"][:minLen], vcdf["Min"][:minLen])
    ax.plot(gcdf["#Blocks"][:minLen], verilogSpeedup, c="b", label="FPGA")

    ax.legend()

    plt.xscale("log", base=2)
    plt.yscale("log")
    plt.xticks(gcdf["#Blocks"][::2])
    plt.grid(True)

    plt.title("Speedup of the OpenCL and FPGA implementations vs golden standard\nAdvanced encryption algorithm")
    plt.xlabel("Number of blocks encrypted")
    plt.ylabel("Speedup")

    fig.savefig("complexspeedup.png")

    plt.close()


    

def getDf(path):
    df = pd.read_csv(path, header=0)
    return df

if __name__ == "__main__":
    main()