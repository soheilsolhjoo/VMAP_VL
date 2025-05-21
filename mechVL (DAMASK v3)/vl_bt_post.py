#!/usr/bin/env python
import argparse
import os
import sys
import vl_general

# import vl_bt
import numpy as np
from numpy.linalg import eigvals
import csv
from scipy.optimize import minimize
from math import sqrt
import pyspark
from pyspark.sql.types import StructType
import pandas as pd

file_name = "VL_BT.csv"
ys_components = []
enforce_2d = True
YC_ = ""
yc_co = 0
m = 0  # to be used in yld91 and yld2004 criteria
m_flag = True


class structtype:
    pass


def fit_yc(yc_model, yc_m=6, x0=[], method="Nelder-Mead"):
    global YC_
    global yc_co
    global m
    global m_flag

    m = yc_m

    if yc_model == "hill48":
        m = 2
        m_flag = False
        c_size = 3
        if len(x0) != c_size:
            c0 = c_size * [0.5]
        yc_co = 1
        YC_ = hill48

    elif yc_model == "yld91":
        c_size = 3
        if len(x0) != c_size:
            c0 = c_size * [1]
        if m_flag:
            c0.extend([m])
        yc_co = 2
        YC_ = yld91

    elif yc_model == "yld2004":
        c_size = 12
        if len(x0) != c_size:
            c0 = c_size * [1]
        if m_flag:
            c0.extend([m])
        yc_co = 4
        YC_ = yld2004

    # available fitting methods:
    # Nelder-Mead, Powell, CG, BFGS, L-BFGS-B, TNC, COBYLA, SLSQP, trust-constr
    c = minimize(objective, x0=c0, method=method)
    return c


def objective(c):
    global ys_components
    global YC_
    global yc_co
    global m
    global m_flag

    y0 = ys_components[0][0]
    
    obj = 0.0
    for i in ys_components:
        j=[]
        for x in i:
            j.append(x/y0)
        #obj += (abs(YC_(i, c)) - yc_co * y0**m) ** 2
        #obj += abs(YC_(i, c)-1)
       # print(type(i))
       # print(i)
        #print(type(y0))
        #print(y0)
        #print(ys_components)
        #print(m)
        #print(j)
        #print(type(j))
        #j = i/y0
        
        obj += (abs(YC_(j, c)) - yc_co * 1**m) ** 2
        #obj += (abs(YC_(j, c)) - 1) ** 2

    if m_flag:
        m = c[-1]

    return obj


def hill48(ys_com, c):
    #x, y = ys_com
    x=ys_com[0]
    y=ys_com[1]
    H, F, G = c
    yc = H * y**2 + F * (-x) ** 2 + G * (x - y) ** 2

    return yc


def yld91(ys_com, c):
    global m
    global m_flag

    x, y = ys_com
    if m_flag:
        c1, c2, c3, c_m = c
    else:
        c1, c2, c3 = c

    sxx = (+c3 * (x - y) + c2 * x) / 3
    syy = (-c3 * (x - y) + c1 * y) / 3
    szz = -(sxx + syy)
    S12 = sqrt(((sxx - syy) / 2) ** 2)
    S1 = (sxx + syy) / 2 + S12
    S2 = (sxx + syy) / 2 - S12
    S3 = szz

    if m_flag:
        yc = pow(abs(S1 - S2), c_m) + pow(abs(S2 - S3), c_m) + pow(abs(S3 - S1), c_m)
    else:
        yc = pow(abs(S1 - S2), m) + pow(abs(S2 - S3), m) + pow(abs(S3 - S1), m)

    return yc


def yld2004(ys_com, c):
    global m
    global m_flag

    x, y = ys_com
    if m_flag:
        c1, c2, c3, c4, c5, c6, c8, c9, c10, c11, c12, c13, c_m = c
    else:
        c1, c2, c3, c4, c5, c6, c8, c9, c10, c11, c12, c13 = c

    xx = 1 / 3 * (2 * x - y)
    yy = 1 / 3 * (x - 2 * y)
    zz = -1 / 3 * (x + y)
    xy = 0
    #  Transformed matrices components
    tcsxx = -c1 * yy - c2 * zz
    tcsyy = -c3 * xx - c4 * zz
    tcszz = -c5 * xx - c6 * yy
    tcsxy = 0
    tdsxx = -c8 * yy - c9 * zz
    tdsyy = -c10 * xx - c11 * zz
    tdszz = -c12 * xx - c13 * yy
    tdsxy = 0
    # Principal values of the transformed matrices
    tc = np.array([[tcsxx, tcsxy, 0], [tcsxy, tcsyy, 0], [0, 0, tcszz]])
    td = np.array([[tdsxx, tdsxy, 0], [tdsxy, tdsyy, 0], [0, 0, tdszz]])
    Pc = eigvals(tc)
    Pd = eigvals(td)
    Sc1 = Pc[0]
    Sc2 = Pc[1]
    Sc3 = Pc[2]
    Sd1 = Pd[0]
    Sd2 = Pd[1]
    Sd3 = Pd[2]
    if m_flag:
        yc = (
            0
            + pow(abs(Sc1 - Sd1), c_m)
            + pow(abs(Sc1 - Sd2), c_m)
            + pow(abs(Sc1 - Sd3), c_m)
            + pow(abs(Sc2 - Sd1), c_m)
            + pow(abs(Sc2 - Sd2), c_m)
            + pow(abs(Sc2 - Sd3), c_m)
            + pow(abs(Sc3 - Sd1), c_m)
            + pow(abs(Sc3 - Sd2), c_m)
            + pow(abs(Sc3 - Sd3), c_m)
        )
    else:
        yc = (
            0
            + pow(abs(Sc1 - Sd1), m)
            + pow(abs(Sc1 - Sd2), m)
            + pow(abs(Sc1 - Sd3), m)
            + pow(abs(Sc2 - Sd1), m)
            + pow(abs(Sc2 - Sd2), m)
            + pow(abs(Sc2 - Sd3), m)
            + pow(abs(Sc3 - Sd1), m)
            + pow(abs(Sc3 - Sd2), m)
            + pow(abs(Sc3 - Sd3), m)
        )

    return yc


def main():
    global ys_components
    # TODO: The following variables should be assigned by the user
    global file_name
    global enforce_2d
    global m_flag

    # PARSER
    parser = argparse.ArgumentParser()
    # Number of tests
    parser.add_argument(
        "-n",
        "--num",
        help="Number of tests that needs to be post-processed.",
        type=int,
        default=4,
    )
    n_tests = parser.parse_args().num - 4

    # Extract the points on Yield Surface, and save it as a csv file
    # IF the csv file does not exist
    if not os.path.isfile(file_name):
        # extract the ys_components and save them in a file
        ys_components = vl_general.ys_identifier([n_tests])
        vl_general.ys_export(ys_components, file_name)  # export YS into a csv file
    else:
        # read ys_component file
        with open(file_name, newline="") as f:
            reader = csv.reader(f)
            ys_components = list(reader)
    
    
    # Create the CSV file to store fit constant
    with open("BT_FitConstant.csv", mode='w', newline='') as file:
         writer = csv.writer(file)
         for _ in range(50):
             writer.writerow([1])

    
    if enforce_2d:
        # deleting 3rd column elements (s12)
        [data.pop(2) for data in ys_components]
        ys_components = np.round(
            np.array(ys_components, dtype=float), decimals=3
        ).tolist()

    # set the first component as 1
    Y0 = ys_components[0][0]
    #ys_components[0][0] = 1

    # available Yield Criteria: hill48, yld91, yld2004
    # x0 if not provided will be filled with [1] for each calibration parameter
    #
    # m (default = 6) is not required for hill48, and for the other two, if not provided,
    # it will be assumed as a fitting parameter.
    #
    # available fitting methods: (default = CG)
    # Nelder-Mead, Powell, CG, BFGS, L-BFGS-B, TNC, COBYLA, SLSQP, trust-constr

    fit_const = structtype()
    method = "Nelder-Mead"

    #data_csv = pd.read_csv("BT_FitConstant.csv")
    #data_csv['hill48'] = pd.Series(fit_const.hill48.x)
    fit_const.hill48 = fit_yc("hill48", method=method)
    print(f"hill48:    {fit_const.hill48.fun},  \t{fit_const.hill48.x}")
    with open("BT_fit.txt", "a") as file:
        file.write(f"hill48:    {fit_const.hill48.fun},  \t{fit_const.hill48.x}\n")
    data_csv = pd.read_csv("BT_FitConstant.csv")
    data_csv['hill48'] = pd.Series(fit_const.hill48.x)
    
    m_flag = False
    fit_const.yld91 = fit_yc("yld91", method=method)
    print(f"yld91:     {fit_const.yld91.fun},  \t{fit_const.yld91.x}")
    with open("BT_fit.txt", "a") as file:
        file.write(f"yld91:    {fit_const.yld91.fun},  \t{fit_const.yld91.x}\n")
    data_csv['yld91'] = pd.Series(fit_const.yld91.x)
    m_flag = True
    fit_const.yld91_m = fit_yc("yld91", yc_m=7, method=method)
    
    print(f"yld91_m:   {fit_const.yld91_m.fun},\t{fit_const.yld91_m.x}")
    # yc_m = fit_const.yld91_m.x[-1]
    with open("BT_fit.txt", "a") as file:
        file.write(f"yld91_m:    {fit_const.yld91_m.fun},  \t{fit_const.yld91_m.x}\n")
    data_csv['yld91_m'] = pd.Series(fit_const.yld91_m.x)
    
    m_flag = False
    fit_const.yld2004 = fit_yc("yld2004", method=method)
    print(f"yld2004:   {fit_const.yld2004.fun},\t{fit_const.yld2004.x}")
    with open("BT_fit.txt", "a") as file:
        file.write(f"yld2004:    {fit_const.yld2004.fun},  \t{fit_const.yld2004.x}\n")
    data_csv['yld2004'] = pd.Series(fit_const.yld2004.x)
    
    m_flag = True
    fit_const.yld2004_m = fit_yc("yld2004", yc_m=7, method=method)
    print(f"yld2004_m: {fit_const.yld2004_m.fun},\t{fit_const.yld2004_m.x}")
    with open("BT_fit.txt", "a") as file:
        file.write(
            f"yld2004_m:    {fit_const.yld2004_m.fun},  \t{fit_const.yld2004_m.x}\n"
        )
    data_csv['yld2004_m'] = pd.Series(fit_const.yld2004_m.x)
    data_csv.to_csv("BT_FitConstant.csv", index=False, sep=',')
if __name__ == "__main__":
    main()
