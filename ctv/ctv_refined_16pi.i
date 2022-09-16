#¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨#
#            SIMULATION STOP            #
#.......................................#
time.stop_time               =   0.2   # Max (simulated) time to evolve

#¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨#
#         TIME STEP COMPUTATION         #
#.......................................#
time.fixed_dt         =   0.005        # Use this constant dt if > 0

#¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨#
#            INPUT AND OUTPUT           #
#.......................................#
time.plot_interval  =  20   # Steps between plot files
time.checkpoint_interval =   -1  # Steps between checkpoint files
io.output_default_variables = 0
io.outputs = density p
io.derived_outputs = "components(velocity,0,1)" "components(gp,0,1)"
#¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨#
#               PHYSICS                 #
#.......................................#
incflo.use_godunov      = 1
incflo.godunov_type = "plm"
transport.viscosity = 0.0001
transport.laminar_prandtl = 1.0
turbulence.model = Laminar


#¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨#
#        ADAPTIVE MESH REFINEMENT       #
#.......................................#
amr.n_cell              =   32 32 4   # Grid cells at coarsest AMRlevel
amr.max_level           =   1           # Max AMR level in hierarchy 
amr.max_grid_size       =   4 4 4  # Max grid size at AMR levels
amr.blocking_factor     =   4            # Blocking factor for grids

tagging.labels = static
tagging.static.type = CartBoxRefinement
tagging.static.static_refinement_def = static_box.txt

#¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨#
#              GEOMETRY                 #
#.......................................#
geometry.prob_lo        =   0.  0.  0.  # Lo corner coordinates
geometry.prob_hi        =   1.  1.  1.  # Hi corner coordinates
geometry.is_periodic    =   1   1   1   # Periodicity x y z (0/1)

#¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨#
#          INITIAL CONDITIONS           #
#.......................................#
incflo.physics = ConvectingTaylorVortex
CTV.u0 = 0.0
CTV.v0 = 0.0
CTV.alpha = 50.2654824574
CTV.beta = 50.2654824574
CTV.A = 0.01989436789
CTV.activate_pressure = false
