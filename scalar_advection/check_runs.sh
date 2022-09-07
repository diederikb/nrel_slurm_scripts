#! /bin/bash

# This script script goes through all directories for the different schemes and
# compiles the final run times and number of plt files in `$output_file`

declare -a methods=("godunov_ppm" "godunov_ppm_nolim" "godunov_weno_z" "godunov_bds_CFL" "godunov_bds_nolim_CFL" "mol_central")  
declare -a shapes=("twodimgaussianpulse")  
declare -a grid_types=("uniform" "fine_to_coarse")  
declare -a grid_sizes=(64 128 256)  
declare -a CFL=("0.45" "0.9" "1.0")  
vel_angles=($(seq 0 5 45))

output_file=report.txt

if [ -f $output_file ]; then
    rm $output_file
fi

touch $output_file

printf "%-70s" "case" >> $output_file
for i_method in {0..5}; do
    printf "%20s" "${methods[i_method]}" >> $output_file
done
printf "\n\n" >> $output_file
printf "%0.s-" {1..250} >> $output_file
printf "\n\n" >> $output_file

for i_shape in {0..0}; do
    for i_CFL in {0..2}; do
        for i_grid_type in {0..1}; do
            for i_grid_size in {0..2}; do 
                for i_angle in "${!vel_angles[@]}"; do 
                    case=${shapes[$i_shape]}_${vel_angles[$i_angle]}_degrees_CFL_${CFL[$i_CFL]}/${grid_types[$i_grid_type]}/nx_${grid_sizes[$i_grid_size]}
                    printf "%-70s" "$case" >> $output_file
                    for i_method in {0..5}; do
                        last_time=$(grep "Step:" ${methods[$i_method]}/$case/stdout.txt 2> /dev/null | tail -n 1 | awk '{print $NF}')
                        n_plt_files=$(ls -d ${methods[$i_method]}/$case/plt* 2> /dev/null | wc -l)
                        n_old_plt_files=$(ls -d ${methods[$i_method]}/$case/plt*.old* 2> /dev/null | wc -l)
                        if [ $n_old_plt_files -gt 0 ]; then
                            has_old_plt_files_marker="*"
                        else
                            has_old_plt_files_marker=""
                        fi
                        printf "%20s" "${has_old_plt_files_marker}${n_plt_files} ($last_time)" >> $output_file
                    done
                    echo "" >> $output_file
                done
                echo "" >> $output_file
                printf "%0.s-" {1..250} >> $output_file
                printf "\n\n" >> $output_file
            done
        done
    done
done
            
