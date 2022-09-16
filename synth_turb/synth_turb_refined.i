#¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨#
#            SIMULATION STOP            #
#.......................................#
time.stop_time               =   800     # Max (simulated) time to evolve
time.max_step                =   10000          # Max number of time steps

#¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨#
#         TIME STEP COMPUTATION         #
#.......................................#
time.fixed_dt         =   -4.0      # Use this constant dt if > 0
time.cfl              =   0.5       # CFL factor

#¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨#
#            INPUT AND OUTPUT           #
#.......................................#
io.derived_outputs = q_criterion
io.outputs = synth_turb_forcing
time.plot_interval            =  10        # Steps between plot files
time.checkpoint_interval      =  100       # Steps between checkpoint files

incflo.initial_iterations = 3

#¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨#
#               PHYSICS                 #
#.......................................#
incflo.gravity        =  0.0  0.0 0.0  # Gravitational force (3D)
incflo.density        =  1.0           # Reference density
incflo.velocity = 1.0 0.0 0.0
incflo.use_godunov = 1
incflo.godunov_type = "weno_z"

transport.viscosity = 1.8375e-5
turbulence.model = Laminar

incflo.physics = FreeStream SyntheticTurbulence

FreeStream.velocity_type = ConstValue

ConstValue.velocity.value = 1.0 0.0 0.0

SynthTurb.turbulence_file = turbulence.nc
SynthTurb.wind_direction = 270.0
SynthTurb.grid_location =  0.0 0.0 0.0
SynthTurb.mean_wind_type = "ConstValue"
SynthTurb.grid_spacing = 2.0
SynthTurb.time_offset = 0.0
SynthTurb.duration = 200

ICNS.source_terms = SynthTurbForcing

#¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨#
#        ADAPTIVE MESH REFINEMENT       #
#.......................................#
amr.n_cell              = 200 200 116 # Grid cells at coarsest AMRlevel
amr.max_level           = 1           # Max AMR level in hierarchy
amr.blocking_factor           = 4           # Max AMR level in hierarchy
amr.max_grid_size           = 4           # max amr level in hierarchy
amr.n_error_buf           = 0           # max amr level in hierarchy
tagging.labels = static
tagging.static.type = CartBoxRefinement
tagging.static.static_refinement_def = static_box.txt

#¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨#
#              GEOMETRY                 #
#.......................................#
geometry.prob_lo        =   0       -400.     -230  # Lo corner coordinates
geometry.prob_hi        =   800.    400.      230.  # Hi corner coordinates
geometry.is_periodic    =   0   1   1   # Periodicity x y z (0/1)
# Boundary conditions
xlo.type = "mass_inflow"
xlo.density = 1
xlo.velocity = 1.0 0.0 0.0
xhi.type = "pressure_outflow"
incflo.verbose =   0

