time.stop_time               = 0.5           # Max (simulated) time to evolve
time.fixed_dt               = 0.8         

incflo.use_godunov                     = true
incflo.godunov_type                     = ppm

time.plot_interval            =   40         # Steps between plot files
time.checkpoint_interval           =  -100         # Steps between checkpoint files

transport.viscosity = 0.0
turbulence.model = Laminar

tagging.labels = static
tagging.static.type = CartBoxRefinement
tagging.static.static_refinement_def = static_box.txt

amr.max_level           =   1
amr.n_cell              =   512 8 8     # Grid cells at coarsest AMRlevel
amr.max_grid_size       =   8 8 8  # Max grid size at AMR levels
amr.blocking_factor     =   1            # Blocking factor for grids
amr.n_error_buf     =   0            # Blocking factor for grids

geometry.prob_lo        =  0.  -0.0078125  -0.0078125   # Lo corner coordinates
geometry.prob_hi        =  1.0  0.0078125  0.0078125 # Hi corner coordinates

geometry.is_periodic    =   1   1   1   # Periodicity x y z (0/1)

incflo.physics = ScalarAdvection
scalaradvection.u = 1
scalaradvection.v = 0
scalaradvection.x0 = 0.25
scalaradvection.y0 = 0.5
scalaradvection.amplitude = 1.0
scalaradvection.x_width = 0.01
scalaradvection.y_width = 0
scalaradvection.x_wavenumber = 0
scalaradvection.y_wavenumber = 0
scalaradvection.shape = gaussian_pulse
scalaradvection.output_fname = error.log

incflo.diffusion_type   = 2             # 0 = Explicit, 1 = Crank-Nicolson, 2 = Implicit

incflo.verbose          =   1           # incflo_level
mac_proj.verbose        =   0           # MAC Projector
nodal_proj.verbose      =   0           # Nodal Projector
time.use_force_cfl = false
