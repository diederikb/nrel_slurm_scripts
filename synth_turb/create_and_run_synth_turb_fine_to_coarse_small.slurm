#!/bin/bash

#SBATCH --job-name=synthturb_f2c
#SBATCH --account=hpacf
#SBATCH --nodes=2
#SBATCH --partition=debug
#SBATCH --time=1:00:00
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

restart=true

root_dir=$PWD
godunov_exec=/home/dbeckers/amr-wind/build_godunov/amr_wind
mol_central_exec=/home/dbeckers/amr-wind/build_central/amr_wind
if $restart
then
    input_template=synth_turb_refined_restart.i
else
    input_template=synth_turb_refined.i
fi

declare -a methods=("godunov_ppm" "godunov_ppm_nolim" "godunov_weno_z" "godunov_bds" "godunov_bds_nolim" "mol_central")  
declare -a use_godunov=("true" "true" "true" "true" "true" "false")  
declare -a godunov_type=("ppm" "ppm_nolim" "weno_z" "bds" "bds" "ppm")  
declare -a amr_exec=($godunov_exec $godunov_exec $godunov_exec $godunov_exec "/home/dbeckers/amr-wind/build_bds_nolim/amr_wind" $mol_central_exec)  

stop_time=50
duration=10
dt=-0.5
Lx=50
Ly=50
Lz=10

case_dir=fine_to_coarse_small_${Lx}_${Ly}_${Lz}

for i_method in {5..5}; do 
    for n in {0..0}; do 
        # create case variables
        nx=$((100*2**$n))
        ny=$nx
        nz=$((40*2**$n))
        half_Lx=$(printf "%0.10f\n" $(bc -q <<< scale=10\;${Lx}*0.5))
        half_Ly=$(printf "%0.10f\n" $(bc -q <<< scale=10\;${Ly}*0.5))
        half_Lz=$(printf "%0.10f\n" $(bc -q <<< scale=10\;${Lz}*0.5))
        plot_interval=$((50*2**$n))
        dx=$(echo "scale=10; ${Lx}/${nx}*0.5" | bc)
        restart_file=/scratch/dbeckers/synth_turb/godunov_ppm/${case_dir}/nx_${nx}/chk00700
        restart_file_esc=$(echo $restart_file | sed 's_/_\\/_g')
        echo "$restart_file"
    
        # create directories and files
        dir=$root_dir/${methods[$i_method]}/$case_dir/nx_${nx}
        input_file=synth_turb.i
        echo "creating case ${methods[$i_method]}/$case_dir/nx_${nx}"

        mkdir -p $dir
        cp $root_dir/$input_template $dir/$input_file
        ln -s $root_dir/turbulence.nc $dir/turbulence.nc

        # create refinement file
        staticbox_file=static_box.txt
        if [ -f "$dir/$staticbox_file" ]; then
            rm $dir/$staticbox_file
        fi
        touch $dir/$staticbox_file
        echo 1 >> $dir/$staticbox_file
        echo 1 >> $dir/$staticbox_file
        echo 0 -$half_Ly -$half_Lz $(echo "scale=10; ${half_Lx}-${dx}" | bc) $half_Ly $half_Lz >> $dir/$staticbox_file
     
        # change input file
        sed -i "/time.fixed_dt /s/=.*$/= $dt/" $dir/$input_file
        sed -i "/time.stop_time /s/=.*$/= $stop_time/" $dir/$input_file
        sed -i "/time.plot_interval /s/=.*$/= $plot_interval/" $dir/$input_file
        sed -i "/io.restart_file /s/=.*$/= $restart_file_esc/" $dir/$input_file
        sed -i "/incflo.use_godunov /s/=.*$/= ${use_godunov[$i_method]}/" $dir/$input_file
        sed -i "/incflo.godunov_type /s/=.*$/= ${godunov_type[$i_method]}/" $dir/$input_file
        sed -i "/geometry.prob_lo /s/=.*$/= 0 -$half_Ly -$half_Lz/" $dir/$input_file
        sed -i "/geometry.prob_hi /s/=.*$/= $Lx $half_Ly $half_Lz/" $dir/$input_file
        sed -i "/amr.n_cell /s/=.*$/= $nx $ny $nz/" $dir/$input_file
        sed -i "/amr.max_grid_size /s/=.*$/= 10/" $dir/$input_file
        sed -i "/amr.blocking_factor /s/=.*$/= 1/" $dir/$input_file
        sed -i "/SynthTurb.grid_spacing /s/=.*$/= $dx/" $dir/$input_file
        sed -i "/SynthTurb.duration /s/=.*$/= $duration/" $dir/$input_file

        # run case
        cd $dir
        srun -n $mpi_ranks -c 1 --cpu_bind=cores --output=stdout.txt ${amr_exec[$i_method]} $input_file
        cd $root_dir
    done
done




