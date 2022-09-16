#!/bin/bash

#SBATCH --job-name=ctv_uniform
#SBATCH --account=hpacf
#SBATCH --nodes=2
#SBATCH --time=1:00:00
#SBATCH --partition=debug
#SBATCH --output=out.%x_%j

source ~/.bash_profile

module load gcc
module load mpt

ranks_per_node=36
mpi_ranks=$(($SLURM_JOB_NUM_NODES * $ranks_per_node))
export OMP_NUM_THREADS=1  # Max hardware threads = 4
export OMP_PLACES=threads
export OMP_PROC_BIND=spread

npi=16
nu="1e-4"
root_dir=$PWD
input_template=ctv_uniform_${npi}pi.i
n_plot_files=4

declare -a methods=("godunov_ppm" "godunov_ppm_nolim" "godunov_weno_z" "godunov_bds" "mol_central")  
declare -a use_godunov=("true" "true" "true" "true" "false")  
declare -a godunov_type=("ppm" "ppm_nolim" "weno_z" "bds" "ppm")  
declare -a amr_exec=("/home/dbeckers/amr-wind/build_bds/amr_wind" "/home/dbeckers/amr-wind/build_bds/amr_wind" "/home/dbeckers/amr-wind/build_bds/amr_wind" "/home/dbeckers/amr-wind/build_bds/amr_wind" "/home/dbeckers/amr-wind/build_central/amr_wind")  

vel_angles=($(seq 0 5 45))
for i_angle in "${!vel_angles[@]}"; do 

    vel=1.0
    #vel_angle=0 #degrees
    vel_angle=${vel_angles[$i_angle]} #degrees
    pi=$(echo "scale=14; 4*a(1)" | bc -l)
    u=$(echo "scale=14; ${vel}*c(${vel_angle}*${pi}/180)" | bc -l)
    v=$(echo "scale=14; ${vel}*s(${vel_angle}*${pi}/180)" | bc -l)
    CFL=0.9
    stop_time=1.0
    
    case_dir=${vel_angle}_degrees_CFL_${CFL}_16pi/uniform

    for i_method in {0..1}; do 
        for n in {1..2}; do 
            # create case variables
            nx=$((32*2**$n))
            ny=$nx
            nz=4
            Lx=1.0
            Ly=1.0
            half_Lx=$(printf "%0.10f\n" $(bc -q <<< scale=10\;${Lx}*0.5))
            half_Ly=$(printf "%0.10f\n" $(bc -q <<< scale=10\;${Ly}*0.5))
            half_Lz=$(printf "%0.10f\n" $(bc -q <<< scale=10\;${Lx}*${nz}/${nx}*0.5))
            plot_interval=$((4*2**$n))
            dx=$(echo "scale=10; ${Lx}/${nx}" | bc)
            # max velocity = CTV velocity + u0 = 1 + 1 = 2;
            dt=$(echo "scale=10; ${dx}/(1+${u})*${CFL}" | bc)
            plot_interval_float=$(echo "scale=10; ${stop_time}/${dt}/${n_plot_files}" | bc)
            output_frequency_float=$(echo "scale=10; ${stop_time}/${dt}/30" | bc)
            printf -v plot_interval %.0f "$plot_interval_float"
            printf -v output_frequency %.0f "$output_frequency_float"
        
            # create directories and files
            dir=$root_dir/${methods[$i_method]}/$case_dir/nx_${nx}
            input_file=ctv.i
            echo "creating case method=${methods[$i_method]} nx=${nx} ny=${ny} nz=${nz}
            shape=${waveshape} dt=${dt}"
            mkdir -p $dir
            cp $root_dir/$input_template $dir/$input_file
            
            # change input file
            sed -i "/fixed_dt /s/=.*$/= $dt/" $dir/$input_file
            sed -i "/stop_time /s/=.*$/= $stop_time/" $dir/$input_file
            sed -i "/use_godunov /s/=.*$/= ${use_godunov[$i_method]}/" $dir/$input_file
            sed -i "/godunov_type /s/=.*$/= ${godunov_type[$i_method]}/" $dir/$input_file
            sed -i "/geometry.prob_lo /s/=.*$/= -$half_Lx -$half_Ly -$half_Lz/" $dir/$input_file
            sed -i "/geometry.prob_hi /s/=.*$/= $half_Lx $half_Ly $half_Lz/" $dir/$input_file
            sed -i "/plot_interval /s/=.*$/= $plot_interval/" $dir/$input_file
            sed -i "/n_cell /s/=.*$/= $nx $ny $nz/" $dir/$input_file
            sed -i "/max_grid_size /s/=.*$/= $nz/" $dir/$input_file
            sed -i "/output_frequency /s/=.*$/= $output_frequency/" $dir/$input_file
            sed -i "/viscosity /s/=.*$/= ${nu}/" $dir/$input_file
            sed -i "/CTV.u0 /s/=.*$/= ${u}/" $dir/$input_file
            sed -i "/CTV.v0 /s/=.*$/= ${v}/" $dir/$input_file
    
            # run case
            cd $dir
            srun -n $mpi_ranks -c 1 --cpu_bind=cores --output=stdout.txt ${amr_exec[$i_method]} $input_file
            cd $root_dir
        done
    done
done
