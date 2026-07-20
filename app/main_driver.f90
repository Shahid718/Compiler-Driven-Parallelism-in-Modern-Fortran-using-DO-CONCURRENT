!   Module      : Main Driver
!   Purpose     : Phase-field simulation using standard Fortran DO CONCURRENT 
!
!   Author      : Shahid Maqbool
!   Date        : 7 July 2026
!   Version     : 1.0.0
!   License     : MIT
!
!   Performance : Designed for shared-memory architectures
!   Memory      : Dynamic allocation with status checking
!	Precision   : Configurable working precision (rk)
!   i/O         : binary output format for performance
!
!   COMPILATION:
!                 Check ReadMe
!-------------------------------------------------------------------------------

program cahn_hilliard_driver
    !===========================================================================
    ! Module usage 
    !===========================================================================
    use precision_module
    use timer_module
    use utils_module 
    use phase_field_module
    use performance_module
    use sim_config_module
    implicit none

    type(PhaseFieldGrid) :: grid   ! Grid object (core simulation data structure)
    type(sim_config)     :: cfg    ! Run parameters (defaults or loaded from file)
    integer(i_sp)        :: tstep  ! Current time step counter (local, not global)
    integer              :: nargs
    character(len=256)   :: config_file

    !===========================================================================
    ! Code entry point - Display application banner
    !===========================================================================
    
    call display_banner()
    
    !===========================================================================
    ! Phase 1: Runtime configuration
    !===========================================================================
    
    call print_section('RUNTIME CONFIGURATION')
    call report_runtime_configuration ()
	
    !===========================================================================
    !  Phase 2: Grid Setup and Simulation Parameters
    !===========================================================================
    !
    !  Batch mode : a config file path on the command line supplies every
    !               parameter (required when running under a scheduler,
    !               where there is no stdin to prompt against).
    !  Interactive: no argument given -> prompt for grid dimensions only,
    !               all other parameters take their documented defaults.
    !===========================================================================

    call print_section('GRID SETUP')
    nargs = command_argument_count()
    if (nargs >= 1) then
        call get_command_argument(1, config_file)
        call load_config(cfg, trim(config_file))
        call grid%create_grid(Nx=cfg%Nx, Ny=cfg%Ny, dx=cfg%dx, dy=cfg%dy)
    else
        call load_config(cfg)                     ! defaults for everything but Nx, Ny
        call grid%create_grid_interactive()        ! interactive prompt, dx=dy=1.0
        cfg%Nx = grid%Nx
        cfg%Ny = grid%Ny
    end if
    call print_config(cfg)
    
    ! Initialize microstructure
    call print_section('MICROSTRUCTURE INITIALIZATION')
    call grid%init_microstructure(c0=cfg%c0, noise=cfg%noise, seed=cfg%seed)
    call print_success('Initial microstructure generated')
    
    !===========================================================================
    ! Phase 3: Simulation execution
    !===========================================================================
    
    call print_simulation_header()
   
    ! Display progress header
    write(output_unit, '(A)') ''
    write(output_unit, '(A)') '  Progress:'
    write(output_unit, '(A)') ''
    
	call timer_start()
    
    !===========================================================================
    ! Phase 4: Time integration (main computational kernel)
    !===========================================================================
	
	time_loop: do tstep = 1, cfg%nsteps
        ! =====================================================================
        ! Phase-field kernel - computational intensive part
        ! =====================================================================
        call grid%free_energy_derivative(A=cfg%A)
        call grid%laplace_evaluation()
        call grid%time_integration(dt=cfg%dt, mobility=cfg%mobility, grad_coef=cfg%grad_coef)

        if (mod(tstep, cfg%print_interval) == 0 .or. tstep == cfg%nsteps) then
            call progress_bar(tstep, cfg%nsteps, width=10, prefix='   Progress')
        end if
    end do time_loop
    !=========================================================================
    !  Phase 5: Stop Timers and Report
    !=========================================================================
    
    call timer_stop()
    
    !=========================================================================
    !  Phase 6: Write Output
    !=========================================================================
	
    call grid%output_results(filename=trim(cfg%output_file))
    
    !=========================================================================
    !  Phase 7: Performance Metrics
    !=========================================================================
    
	call print_performance_report(grid, cfg%nsteps)
	call display_completion_banner ()
    
end program cahn_hilliard_driver
