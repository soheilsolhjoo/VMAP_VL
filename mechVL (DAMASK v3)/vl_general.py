#!/usr/bin/env python
# print(
#     'VL_BT is the Mechanical Virtul Lab's Biaxial Test module, which uses DAMASK3 as the solver.'
# )
import shutil

# import os
import damask
import numpy as np
import csv
from pathlib import Path
from glob import glob
import numpy.ma as ma
from numpy.ma import masked_array


# Tensor inversion
def inversion(l, fill=0):
    return [
        inversion(i, fill) if isinstance(i, list) else fill if i == "x" else "x"
        for i in l
    ]


# Creates a list of angles for performing the biaxial tests
# based on the inputs: # of tests (n_tests) and the quadrant (quad_num)
def directions_per_quadrant(n_tests, QUADRANT_CONST):
    return 90 * (
        1 / (n_tests + 1) * (np.linspace(1, n_tests, n_tests)) + QUADRANT_CONST
    )


# Converting polar coordinates to Cartesian ones
def pol2cart(phi):
    x = np.cos(np.radians(phi))
    y = np.sin(np.radians(phi))
    x, y = np.around([x, y], decimals=3)
    return (x, y)


# Finding a proper consequtive directory name
def directory_finder(UB_test, i):
    if UB_test == "UT":
        vl_directory = f"vlut_{i}"
    elif UB_test == "BT":
        vl_directory = f"vlbt_{i}"
    dir_path = Path(vl_directory)
    if dir_path.is_dir():
        i = directory_finder(UB_test, i + 1)
    return i


# Moving file_name to folder vl_directory
def mv_files(file_name, vl_directory):
    command = [file_name, f"./{vl_directory}/{file_name}"]
    shutil.move(command[0], command[1])


def pre_mv_files(UB_test, geometry_name, n_tests, vl_directory):
    Path(vl_directory).mkdir(parents=True, exist_ok=True)
    mv_files("material.yaml", vl_directory)
    if UB_test == "UT":
        file_list = glob(f"{geometry_name}_*.vti")
        for f_name in file_list:
            mv_files(f_name, vl_directory)
        mv_files(f"load_1.yaml", vl_directory)
    elif UB_test == "BT":
        # mv_files(f"{geometry_name}.vti", vl_directory)
        shutil.copy(f"{geometry_name}.vti", vl_directory)
        for i in range(sum(n_tests) + 4):
            mv_files(f"load_{i+1}.yaml", vl_directory)
    else:
        raise ValueError(
            "UB_test must be assigned as UT or BT for uniaxial and multiaxial test, respectively."
        )
    # mv_files("jobs.sh", vl_directory)


# Generates a geometry file, called geometry.vti
#def geometry_generator(size, n_grains, cells, geometry_name="geometry"):
def geometry_generator(filename_dream3d, geometry_name="geometry"):
    #seeds = damask.seeds.from_random(size, n_grains, cells)
    #grid = damask.Grid.from_Voronoi_tessellation(cells, size, seeds)
    #grid = damask.Grid.renumber(grid)
    # geometry= f'Polycystal_{N_grains}_{cells[0]}x{cells[1]}x{cells[2]}'
    grid=damask.Grid.load_DREAM3D(filename_dream3d)
    #grid=grid.canvas([10,10,10])
    grid.save(geometry_name)


# Generates 'material.yalm'
# CURRENT LIMITATION: it accepts only 1 phase
def material_generator(n_constituents, phase_name_1,material_file_1,
    phase_name_2,
    material_file_2,
    homogenization_method,
    filename_dream3d,
):
    config_material = damask.ConfigMaterial.load_DREAM3D(filename_dream3d)
    config_material['homogenization'][homogenization_method] = {
        "N_constituents": n_constituents,
        "mechanical": {"type": "pass"},
    }
    config_material['phase'][phase_name_1] = damask.ConfigMaterial.load(material_file_1)
    config_material['phase'][phase_name_2] = damask.ConfigMaterial.load(material_file_2)
    #O_A = damask.Rotation.from_random(n_grains)
    #config_material = config_material.material_add(
       # homogenization=homogenization_method, phase=phase_name, O=O_A
   # )
    config_material.save()


# Generates load cases
# NOTE: strate = strate rate
def load_case_generator(UB_test, def_time, strate, n_tests, n_steps, out_every_n=2):
    strate_list = []  # list of all strain rate (F_dot) cases
    # load_case = damask.Config(solver={"mechanical": "spectral_basic"}, loadstep=[])

    # [removed] Calculate the deformation time
    # def_time = float(np.round(strain / strate, decimals=3))

    # Round def_time
    if isinstance(def_time, list):
        def_time = [float(np.round(x, decimals=3)) for x in def_time]
    else:
        def_time = float(np.round(def_time, decimals=3))

    if UB_test == "UT":
        strate_list = [[strate, "x"]]

        load_case = damask.Config(solver={"mechanical": "spectral_basic"}, loadstep=[])
        loadstep = []
        for i in range(len(def_time)):    
            loadstep = loadstep_generator(
                strate_list[0], def_time[i], n_steps[i], out_every_n
            )
            load_case["loadstep"].append(loadstep)
        load_case.save(f"load_1.yaml")

    elif UB_test == "BT":
        # Ensure that def_time and n_steps each have only 1 element
        if isinstance(def_time, list):
            def_time = def_time[0]
        if isinstance(n_steps, list):
            n_steps = n_steps[0]

        # 4 mandatory tests along s11 and s22 directions (tension and compression)
        phi_range = list(np.linspace(0, 360, 5))
        phi_range.pop()
        # Find other requested directions in each quadrant
        QUADRANT_CONST = [0, 1, 2, 3]  # constants for different quadrants
        phi_quad = list(map(directions_per_quadrant, n_tests, QUADRANT_CONST))
        # Convert the each element to a list
        for i in range(4):
            phi_quad[i] = phi_quad[i].tolist()
        # Convert the list of lists to a list
        phi_quad = sum(phi_quad, [])
        # Extend the main phi_range with new list
        phi_range.extend(phi_quad)
        phi_range = np.round(phi_range, decimals=3)
        # Sort phi_range
        phi_range.sort()
        # Convert the angles to Cartesian coordinates
        for i in range(len(phi_range)):
            strate_list.append(pol2cart(phi_range[i]))
        # Convert tuples to lists
        strate_list = [list(coord) for coord in strate_list]
        # Scale the strate list with the assigned strate
        strate_list = list(strate * np.array(strate_list))
        # Convert the np.array to python list
        strate_list = np.array(np.round(strate_list, decimals=3)).tolist()
        # Update the strate_list for directions along x-y axes
        strate_list = [["x" if sx == 0 else sx for sx in s12] for s12 in strate_list]
        # Save load_case files
        counter = 1
        for i in strate_list:
            load_case = damask.Config(solver={"mechanical": "spectral_basic"}, loadstep=[])
            #loadstep = loadstep_generator(i, def_time/8, int(n_steps/2), out_every_n)
            #load_case["loadstep"].append(loadstep)
            loadstep = loadstep_generator(i, def_time, n_steps, out_every_n)
            load_case["loadstep"].append(loadstep)
            load_case.save(f"load_{counter}.yaml")
            counter += 1
    else:
        raise ValueError(
            "UB_test must be assigned as UT or BT for uniaxial and multiaxial test, respectively."
        )


def loadstep_generator(i, def_time, n_steps, out_every_n):

    #dot_F = [[0, i[0], "x"], [i[0], 0, "x"], ["x", "x", "x"]]
    dot_F = [[i[0], 0, 0], [0, i[1], 0], [0, 0, "x"]]
    # load_case = damask.Config(solver={"mechanical": "spectral_basic"}, loadstep=[])
    loadstep = {
        "boundary_conditions": {"mechanical": {"dot_F": dot_F, "P": inversion(dot_F)}},
        "discretization": {"t": def_time, "N": n_steps},
        "f_out": out_every_n,
    }
    # load_case["loadstep"].append(loadstep)
    return loadstep


# Rotate a geometry file
# This function is written together with Kegu Lu (kegu.lu@rug.nl)
def rotate_geometry(geometry_name, n_tests: int):
    # Load the geometry file
    grid = damask.Grid.load(geometry_name)
    cell_num = grid.cells

    # When the enlarged RVE is rotated, the total volume of the RVE becomes larger and some part of the backgroud is blank.
    # Sometimes, after rotation, the cell's number along x or y axis is odd. In order to find the center of enlarged RVE， we should make the cells even. So, add one if the cell number is odd.
    def add_one_if_odd(num):
        if num % 2 != 0:
            return num + 1
        else:
            return num

    # The function "OffsetVector" is used to define the vector of Offset for the "Canvas" function.
    def OffsetVector(grid_to_cut, cell_num):
        grid_size = []
        for i in range(3):
            grid_size.append(add_one_if_odd(grid_to_cut.cells[i]))

        offset_vector = []
        for i in range(3):
            offset_vector.append((grid_size[i] - cell_num[i]) / 2)
        return offset_vector

    # Use "mirror" method to enlarge the RVE 4 times in x and y directions
    master_grid = grid.mirror("xy", True).mirror("xy", True)
    # grid = grid.mirror('xy',True)
    # Cut the enlarged RVE to the 3 time of original RVE
    master_grid = master_grid.canvas(
        [3 * cell_num[0], 3 * cell_num[1], cell_num[2]], [0, 0, 0]
    )
    # Assign directions and rotate accordingly. Then, cut geometry to the original size.
    for degree in np.linspace(0, 90, n_tests):
        theta = np.deg2rad(degree)
        # Rotate the master_grid
        rotated_grid = master_grid.rotate(
            damask.Rotation.from_Euler_angles(np.array([theta, 0, 0])), fill=False
        )
        # Cut the rotated_grid
        rotated_grid = rotated_grid.canvas(
            cell_num, OffsetVector(rotated_grid, cell_num)
        )
        # Save the rotated_grid
        rotated_grid.save(f"geometry_{degree}")
    # Remove the original geometry file
    # os.remove(f"{geometry_name}.vti")


# Writing bash file 'jobs.sh'
def jobs_generator(
    UB_test,
    n_tests,
    OMP_NUM_THREADS,
    MPI_NP,
    vl_directory,
    post_process=False,
    py_file_name="",
):
    f = open("jobs.sh", "w+")
    f.write("#!/bin/bash\n")
    f.write(f"OMP_NUM_THREADS={OMP_NUM_THREADS}\n")

    if UB_test == "UT":
        degree = np.linspace(0, 90, n_tests)

        f.write(f"cd ./{vl_directory}\n")
        for i in range(n_tests):
            geometry = f"geometry_{degree[i]}"
            command = [
                "mpiexec",
                "-np",
                f"{MPI_NP}",
                "DAMASK_grid",
                "--load",
                f"load_1.yaml",
                "--geom",
                f"{geometry}.vti",
                "\n",
            ]
            f.write(" ".join(command))
    elif UB_test == "BT":
        f.write(f"cd ./{vl_directory}\n")
        geometry = "geometry"
        for i in range(sum(n_tests) + 4):
            command = [
                "mpiexec",
                "-np",
                f"{MPI_NP}",
                "DAMASK_grid",
                "--load",
                f"load_{i+1}.yaml",
                "--geom",
                f"{geometry}.vti",
                "\n",
            ]
            f.write(" ".join(command))
        n_tests = sum(n_tests) + 4
        if post_process:
            if vl_directory != "":
                vl_directory = ".."
            # f.write(f"python3 ./{vl_directory}/{py_file_name} -n {sum(n_tests)+4}")
            f.write(f"python3 ./{vl_directory}/{py_file_name} -n {n_tests}")
    f.close()


# # Extend jobs.sh to run post_process_files within the subdirectory
# def add_postprocess_to_jobs_sh(py_file_name):
#     f = open("jobs.sh", "w+")
#     f.write(f"python3 ./../{py_file_name}")
#     f.close()


# Identifying yield stress components at zero plastic deformation energy
def ys_identifier(n_tests):
    ys_components = []  # list of identified stress components of yield surface
    for i in range(sum(n_tests) + 4):
        # load the results
        results = damask.Result(f"geometry_load_{i+1}.hdf5")

        ## IDENTIFY and LIST Yield Stress (YS) components
        ## from the maximum of the 2nd gradient of total shear stress
        # ====
        # calculate the 2nd gradient of the total shear stress
        plastic_shear = [np.average(g) for g in results.place("gamma_sl").values()]

        # find the index of the maximum
        ys_idx = np.argmax(np.diff(plastic_shear, n=2))
        
        print(ys_idx)
        #ys_idx = 5
        # add Cauchy stress
        results.add_stress_Cauchy()

        # list the added Cuachy stresses
        Cauchy_stress = list(results.place("sigma").values())
        ys = [sum(i_Cauchy) / len(i_Cauchy) for i_Cauchy in zip(*Cauchy_stress[ys_idx])]

        # select the required elements: s11 s22 s12
        ys_components.append(
            np.round([ys[0][0], ys[1][1], np.mean([ys[0][1], ys[1][0]])], decimals=2)
        )
       # ys_components.append(
         #   np.round([ys_1[0][0], ys_1[1][1], np.mean([ys_1[0][1], ys_1[1][0]])], decimals=2)
        #)
        print(ys_components)
        #Delete the components, which includes NaN
        ys_components = [arr for arr in ys_components if not np.any(np.isnan(arr))]
    return np.array(ys_components).tolist()


# Exporting YS to file 'VL_BT_YS.csv'
def ys_export(ys_components, filename):
    ys_components_csv = np.round(
        np.divide(ys_components, ys_components[0][0]), decimals=2
    )
    ys_components_csv[0][0] = ys_components[0][0]
    with open(filename, "w+") as VL_BT_CSV:
        csvWriter = csv.writer(VL_BT_CSV, delimiter=",")
        csvWriter.writerows(ys_components_csv)


def main():
    print("The functions are supposed to be called from other files.")


if __name__ == "__main__":
    main()
