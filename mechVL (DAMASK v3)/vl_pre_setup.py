#!/usr/bin/env python
import sys
import vl_general
import numpy as np
import argparse
import ast
import re


# This section must be updated by the user
# ================================================================
# # Machine config
omp_num_threads = 12
mpi_name = 4

# Run post_processing after the jobs are done?
post_process = True  # True  # True: yes, False: no (default)
py_file_name = "vl_bt_post.py"  # name of the post-processing file

# Test setup
# strate = 0.01  # strain-rate
# strain = 0.0003  # strain [X]: the code asks for deformation time and not strain
# def_time = float(np.round(strain / strate, decimals=3))
# def_time = [1, 20]  # deformation time (in second)
# n_steps = [10,90] # number of increments
# note that the length of n_steps must be the same as of def_time.
# out_every_n = 1
# n_tests = 3  # for uniaxial tests, use only 1 integer as the number of tests
# NOTE:
# 1- n_test values are only for quadrants. 4 tests will be performed along the axes
# 2- out_every_n indicates the intevals between each reported state from DAMASK.
# For example, out_every_n = 2 means that DAMASK spits the results every 2 steps.


# Material data
# NOTE: current code can only work with "n_constituents = 1"
n_constituents = 1
#Name the phase and choose the phase's material properties
phase_name_1 = 'Ferrite'
material_file_1 = 'material_phase_Ferrite.yaml'
phase_name_2 = 'Carbide'
material_file_2 = 'material_phase_Carbide.yaml'
#Choose the Dream3D file
filename_dream3d='RVE.dream3d'
#homogenization_method = "SX"
homogenization_method = 'direct'
geometry_name = "geometry"  # NOTE: for now, DO NOT change this line


# RVE setup
# NOTE: if the RVE is generated separately,
# (1) name it "geometry.vti",
# (2) call this file without the flags "-g" or "--rve",
# (3) don't care about the following lines.
#n_grains = 20
#cell_num = 16
#size = np.ones(3) * 1e-5
#cells = [cell_num, cell_num, cell_num]
#size[2] = size[2] / 4
#cells[2] = int(cells[2] / 4)
#filename_dream3d='RVE.dream3d'


# print(size)
# print(cells)
# ================================================================
def main():
    # PARSER
    parser = argparse.ArgumentParser()
    # Choose the directory in which files will be written.
    # This can be done with the flag "-s" or "--subdir"
    # (1)   If the flag is not raised, the function automatically create a subfolder
    #       with the name format of vlbt_#.
    # (2)   If the flag is raised but left empty,
    #       all files will be written in the main folder.
    # (3)   If a name is passed via th flag,
    #       a directory with the name will be created to store all files.
    parser.add_argument(
        "-sd",
        "--subdir",
        help="creates a folder and put the simulation file(s) there. \n \
            [default = auto]",
        nargs="?",
        const="",
        type=str,
        default="auto",
    )
    # Should the code generate an RVE?
    # see the comments on the section "RVE setup" for explanations
    parser.add_argument(
        "-g",
        "--rve",
        help="generates a random RVE and saves it as 'geometry.vti'.",
        action="store_true",
    )
    # Is the function called for Uniaxial or Biaxial Tests?
    parser.add_argument(
        "-ubt",
        "--ubt",
        help="assign whether to perfom uniaxial (UT) or biaxial (BT) tests. \n \
            [No default value]",
        type=str,
        required=True,
    )

    # Assign number of tests
    parser.add_argument(
        "-n",
        "--n_tests",
        help="the number of tests. \n \
            NOTE: for uniaxial tests, assign one integer,\n \
            and for biaxial tests, use [n1,n2,n3,n4], where ni is the number of tests in the ith quadrant.\n \
            [default = [3,0,0,0]: UT uses only the first element]",
        default=[3, 0, 0, 0],
    )
    # Assign strain-rate
    parser.add_argument(
        "-r",
        "--strain_rate",
        help="strain_rate. \n \
            [default = 0.01]",
        type=float,
        default=0.01,
    )
    # Assign report frequency
    parser.add_argument(
        "-f",
        "--freq",
        help="the frequency for saving DAMASK results. \n \
            [default = 2]",
        type=int,
        default=2,
    )
    # Assign increments
    parser.add_argument(
        "-i",
        "--inc",
        help="the number of increments. \n \
            NOTE: length of -i/--inc must be the same as of -t/--time \n \
            [default = [10,90]: UT uses only the first element]",
        default=[10, 90],
    )
    # # Assign deformation time
    # parser.add_argument(
    #     "-t",
    #     "--time",
    #     help = "the deformation time in second.\n \
    #         NOTE: length of -t/--time must be the same as of -i/--inc \n \
    #         [default = [1,20]: BT uses only the first element (if more than 1 is given)]",
    #     default = [1,20]
    # )
    group = parser.add_mutually_exclusive_group()
    # Assign deformation time
    group.add_argument(
        "-t",
        "--time",
        help="the deformation time in second.\n \
            NOTE: length of -t/--time must be the same as of -i/--inc \n \
            [default = [1,20]: BT uses only the first element (if more than 1 is given]",
        default=[1, 20],
    )
    # Assign deformation time
    group.add_argument(
        "-sn",
        "--strain",
        help="the deformation strain; only to be used for biaxial tests \n \
            NOTE: only one of -s/--strain or -t/--time can be assigned.\n \
                  In case that both are assigned, time will be calculated based on the given strain. \n \
                  [default = 0.0003]",
        type=float,
        default=0.0003,
    )

    args = parser.parse_args()
    n_tests = ast.literal_eval(args.n_tests)

    if args.strain:
        def_time = np.round(args.strain / args.strain_rate, decimals=3)
    else:
        def_time = ast.literal_eval(args.time)

    if not args.ubt:
        raise argparse.ArgumentTypeError(
            "flag -ubt/--ubt cannot be empty. It must be assigned as either UT or BT for uniaxial and multiaxial test, respectively."
        )

    if args.subdir == "auto":
        i = vl_general.directory_finder(args.ubt, 1)
        if args.ubt == "UT":
            vl_directory = f"vlut_{i}"
        elif args.ubt == "BT":
            vl_directory = f"vlbt_{i}"
    else:
        vl_directory = args.subdir

    # CALLs on pre-processing functions
    if args.rve:
        vl_general.geometry_generator(
            #size,
            #n_grains,
            #cells,
            filename_dream3d,
            geometry_name="geometry",
        )

    if args.ubt == "UT":
        vl_general.rotate_geometry(geometry_name, n_tests)
        def_time = ast.literal_eval(args.time)
    elif args.ubt == "BT":
        #vl_general.geometry_generator(size, n_grains, cells, geometry_name="geometry")
        vl_general.geometry_generator(filename_dream3d, geometry_name="geometry")
        if (not isinstance(n_tests, list)) or (
            isinstance(n_tests, list) and len(n_tests) != 4
        ):
            raise ValueError(
                "n_test is not in a correct format. For biaxial tests, it should be written as '[n1,n2,n3,n4]'."
            )
        if args.strain:
            def_time = np.round(args.strain / args.strain_rate, decimals=3)
        else:
            def_time = ast.literal_eval(args.time)

    vl_general.material_generator(
        #n_grains,
        #n_constituents,
        #phase_name,
        #material_file,
        #homogenization_method,
        n_constituents,
        phase_name_1,
        material_file_1,
        phase_name_2,
        material_file_2,
        homogenization_method,
        filename_dream3d,
    )

    vl_general.load_case_generator(
        args.ubt,
        def_time,
        args.strain_rate,
        n_tests,
        ast.literal_eval(args.inc),
        args.freq,
    )

    vl_general.jobs_generator(
        args.ubt,
        n_tests,
        omp_num_threads,
        mpi_name,
        vl_directory,
        post_process,
        py_file_name,
    )

    vl_general.pre_mv_files(
        args.ubt,
        geometry_name,
        n_tests,
        vl_directory,
    )


if __name__ == "__main__":
    main()
