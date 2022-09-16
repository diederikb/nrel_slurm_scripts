#!/bin/bash

#SBATCH --job-name=2dgp_f2c
#SBATCH --account=hpacf
#SBATCH --nodes=1
#SBATCH --time=1:00:00
#SBATCH --partition=debug
#SBATCH --output=out.%x_%j

source ~/.bash_profile

module load gcc
module load mpt
module load netcdf-c

ranks_per_node=36
mpi_ranks=$(($SLURM_JOB_NUM_NODES * $ranks_per_node))
export OMP_NUM_THREADS=1  # Max hardware threads = 4
export OMP_PLACES=threads
export OMP_PROC_BIND=spread

root_dir=$PWD
godunov_exec=/home/dbeckers/amr-wind/build_godunov/amr_wind
mol_central_exec=/home/dbeckers/amr-wind/build_central/amr_wind
input_template=scalar_advection_refined.i

declare -a methods=("godunov_ppm" "godunov_ppm_nolim" "godunov_weno_z" "godunov_bds" "godunov_bds_nolim" "mol_central")  
declare -a use_godunov=("true" "true" "true" "true" "true" "false")  
declare -a godunov_type=("ppm" "ppm_nolim" "weno_z" "bds" "bds" "ppm")  
declare -a amr_exec=($godunov_exec $godunov_exec $godunov_exec $godunov_exec "/home/dbeckers/amr-wind/build_bds_nolim/amr_wind" $mol_central_exec)  

vel_angles=($(seq 0 5 45))
for i_angle in "${!vel_angles[@]}"; do 

    vel=1.0
    #vel_angle=0 #degrees
    vel_angle=${vel_angles[$i_angle]} #degrees
    pi=$(echo "scale=14; 4*a(1)" | bc -l)
    u=$(echo "scale=14; ${vel}*c(${vel_angle}*${pi}/180)" | bc -l)
    v=$(echo "scale=14; ${vel}*s(${vel_angle}*${pi}/180)" | bc -l)
    x0=$(echo "scale=14; 0.5-0.25*c(${vel_angle}*${pi}/180)" | bc -l)
    y0=$(echo "scale=14; -0.25*s(${vel_angle}*${pi}/180)" | bc -l)
    amplitude=1.0
    x_width=0.01
    y_width=0.01
    x_wavenumber=0
    y_wavenumber=0
    shape=twodimgaussianpulse
    stop_time=0.5
    CFL=0.45
    
    case_dir=${shape}_${vel_angle}_degrees_CFL_${CFL}/fine_to_coarse
    
    for i_method in {0..5}; do 
        for n in {0..2}; do 
            # create case variables
            nx=$((64*2**$n))
            ny=$nx
            nz=4
            Lx=1.0
            half_Lx=$(printf "%0.10f\n" $(bc -q <<< scale=10\;${Lx}*0.5))
            half_Ly=$(printf "%0.10f\n" $(bc -q <<< scale=10\;${Lx}*${ny}/${nx}*0.5))
            half_Lz=$(printf "%0.10f\n" $(bc -q <<< scale=10\;${Lx}*${nz}/${nx}*0.5))
            dx=$(echo "scale=10; ${Lx}/${nx}*0.5" | bc)
            dt=$(echo "scale=10; ${dx}/${u}*${CFL}" | bc)
            plot_interval_float=$(echo "scale=10; ${stop_time}/${dt}/30" | bc)
            printf -v plot_interval %.0f "$plot_interval_float"
        
            # create directories and files
            dir=$root_dir/${methods[$i_method]}/$case_dir/nx_${nx}
            input_file=scalar_advection.i
            echo "creating case ${methods[$i_method]}/$case_dir/nx_${nx}"
    
            mkdir -p $dir
            cp $root_dir/$input_template $dir/$input_file
    
            # create refinement file
            staticbox_file=static_box.txt
            if [ -f "$dir/$staticbox_file" ]; then
                rm $dir/$staticbox_file
            fi
            touch $dir/$staticbox_file
            echo 1 >> $dir/$staticbox_file
            echo 1 >> $dir/$staticbox_file
            echo 0 -$half_Ly -$half_Lz $(echo "scale=10; $half_Lx-$dx" | bc) $half_Ly $half_Lz >> $dir/$staticbox_file
         
            # change input file
            sed -i "/time.fixed_dt /s/=.*$/= $dt/" $dir/$input_file
            sed -i "/time.stop_time /s/=.*$/= $stop_time/" $dir/$input_file
            sed -i "/time.plot_interval /s/=.*$/= $plot_interval/" $dir/$input_file
            sed -i "/incflo.use_godunov /s/=.*$/= ${use_godunov[$i_method]}/" $dir/$input_file
            sed -i "/incflo.godunov_type /s/=.*$/= ${godunov_type[$i_method]}/" $dir/$input_file
            sed -i "/geometry.prob_lo /s/=.*$/= 0.0 -$half_Ly -$half_Lz/" $dir/$input_file
            sed -i "/geometry.prob_hi /s/=.*$/= $Lx $half_Ly $half_Lz/" $dir/$input_file
            sed -i "/amr.n_cell /s/=.*$/= $nx $ny $nz/" $dir/$input_file
            sed -i "/amr.max_grid_size /s/=.*$/= $nz/" $dir/$input_file
            sed -i "/amr.blocking_factor /s/=.*$/= $nz/" $dir/$input_file
            sed -i "/scalaradvection.u /s/=.*$/= $u/" $dir/$input_file
            sed -i "/scalaradvection.v /s/=.*$/= $v/" $dir/$input_file
            sed -i "/scalaradvection.x0 /s/=.*$/= $x0/" $dir/$input_file
            sed -i "/scalaradvection.y0 /s/=.*$/= $y0/" $dir/$input_file
            sed -i "/scalaradvection.amplitude /s/=.*$/= $amplitude/" $dir/$input_file
            sed -i "/scalaradvection.x_width /s/=.*$/= $x_width/" $dir/$input_file
            sed -i "/scalaradvection.y_width /s/=.*$/= $y_width/" $dir/$input_file
            sed -i "/scalaradvection.x_wavenumber /s/=.*$/= $x_wavenumber/" $dir/$input_file
            sed -i "/scalaradvection.y_wavenumber /s/=.*$/= $y_wavenumber/" $dir/$input_file
            sed -i "/scalaradvection.shape /s/=.*$/= $shape/" $dir/$input_file
    
            # run case
            cd $dir
            srun -n $mpi_ranks -c 1 --cpu_bind=cores --output=stdout.txt ${amr_exec[$i_method]} $input_file
            cd $root_dir
        done
    done
done
