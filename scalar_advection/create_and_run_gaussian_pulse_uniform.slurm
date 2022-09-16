#!/bin/bash

#SBATCH --job-name=gp_uni
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
input_template=scalar_advection_uniform.i

declare -a methods=("godunov_ppm" "godunov_ppm_nolim" "godunov_weno_z" "godunov_bds" "godunov_bds_nolim" "mol_central")  
declare -a use_godunov=("true" "true" "true" "true" "true" "false")  
declare -a godunov_type=("ppm" "ppm_nolim" "weno_z" "bds" "bds" "ppm")  
declare -a amr_exec=($godunov_exec $godunov_exec $godunov_exec $godunov_exec "/home/dbeckers/amr-wind/build_bds_nolim/amr_wind" $mol_central_exec)  

u=1
v=0
x0=0.25
y0=0.0
amplitude=1.0
x_width=0.01
y_width=0
x_wavenumber=0
y_wavenumber=0
shape=gaussianpulse
stop_time=0.5
CFL=0.45

case_dir=${shape}_CFL_${CFL}/uniform

for i in {0..5}; do 
    for n in {0..2}; do
        # create case variables
        nx=$((64*2**$n))
        ny=4
        nz=4
        Lx=1.0
        half_Lx=$(printf "%0.10f\n" $(bc -q <<< scale=10\;${Lx}*0.5))
        half_Ly=$(printf "%0.10f\n" $(bc -q <<< scale=10\;${Lx}*${ny}/${nx}*0.5))
        half_Lz=$(printf "%0.10f\n" $(bc -q <<< scale=10\;${Lx}*${nz}/${nx}*0.5))
        dx=$(echo "scale=10; ${Lx}/${nx}" | bc)
        dt=$(echo "scale=10; ${dx}/${u}*${CFL}" | bc)
        plot_interval_float=$(echo "scale=10; ${stop_time}/${dt}/30" | bc)
        printf -v plot_interval %.0f "$plot_interval_float"
    
        # create directories and files
        dir=$root_dir/${methods[$i]}/$case_dir/nx_${nx}
        input_file=scalar_advection.i
        echo "creating case method=${methods[$i]} nx=${nx} ny=${ny} nz=${nz}
        shape=${waveshape} dt=${dt}; use_godunov=${use_godunov[$i]}"
        mkdir -p $dir
        cp $root_dir/$input_template $dir/$input_file
     
        # change input file
        sed -i "/fixed_dt /s/=.*$/= $dt/" $dir/$input_file
        sed -i "/stop_time /s/=.*$/= $stop_time/" $dir/$input_file
        sed -i "/use_godunov /s/=.*$/= ${use_godunov[$i]}/" $dir/$input_file
        sed -i "/godunov_type /s/=.*$/= ${godunov_type[$i]}/" $dir/$input_file
        sed -i "/prob_lo /s/=.*$/= 0.0 -$half_Ly -$half_Lz/" $dir/$input_file
        sed -i "/prob_hi /s/=.*$/= $Lx $half_Ly $half_Lz/" $dir/$input_file
        sed -i "/plot_interval /s/=.*$/= $plot_interval/" $dir/$input_file
        sed -i "/n_cell /s/=.*$/= $nx $ny $nz/" $dir/$input_file
        sed -i "/max_grid_size /s/=.*$/= $nz/" $dir/$input_file
        sed -i "/blocking_factor /s/=.*$/= $nz/" $dir/$input_file
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
        srun -n $mpi_ranks -c 1 --cpu_bind=cores --output=stdout.txt ${amr_exec[$i]} $input_file
        cd $root_dir
    done
done
