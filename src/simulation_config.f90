!-------------------------------------------------------------------------------
!
!  Module       : sim_config_module
!  Purpose      : Load and report simulation parameters for the Cahn-Hilliard
!                 phase-field solver from a Fortran namelist file, with
!                 sensible defaults when no file is supplied.
!
!  Author       : Shahid Maqbool
!  Date         : 17 July 2026
!  Version      : 1.0.0
!  License      : MIT
!
!  Description  :
!    Batch/HPC runs (SLURM, PBS, ...) have no interactive stdin, so every
!    physical and numerical parameter needed to reproduce a run must be
!    settable from a config file rather than hardcoded in the driver or
!    typed at a prompt. This module owns that single source of truth.
!
!  Namelist Format (&simulation ... /) :
!    Nx, Ny            - Grid dimensions               (default 500, 500)
!    dx, dy            - Grid spacing                  (default 1.0, 1.0)
!    c0, noise         - Initial concentration / noise  (default 0.4, 0.02)
!    A                 - Free energy coefficient        (default 1.0)
!    dt, mobility,
!    grad_coef         - Time integration parameters    (default 0.01, 1.0, 0.5)
!    nsteps            - Number of time steps           (default 2000)
!    print_interval    - Steps between progress prints  (default 100)
!    seed              - RNG seed, 0 = non-deterministic (default 0)
!    output_file       - Binary output filename          (default 'ch.dat')
!
!  Usage        :
!    type(sim_config) :: cfg
!    call load_config(cfg, 'run.nml')   ! or omit filename to keep defaults
!    call print_config(cfg)
!
!-------------------------------------------------------------------------------
module sim_config_module
    use precision_module
    use, intrinsic :: iso_fortran_env, only : output_unit, error_unit
    implicit none
    private
    public :: sim_config, load_config, print_config

    !-----------------------------------------------------------------------------
    !  Type Definition : sim_config
    !  Description     : Complete set of physical and numerical parameters
    !                    needed to reproduce a simulation run.
    !-----------------------------------------------------------------------------
    type :: sim_config
        integer(i_sp)       :: Nx             = 500_i_sp
        integer(i_sp)       :: Ny             = 500_i_sp
        real(rk)            :: dx             = 1.0_rk
        real(rk)            :: dy             = 1.0_rk
        real(rk)            :: c0             = 0.4_rk
        real(rk)            :: noise          = 0.02_rk
        real(rk)            :: A              = 1.0_rk
        real(rk)            :: dt             = 0.01_rk
        real(rk)            :: mobility       = 1.0_rk
        real(rk)            :: grad_coef      = 0.5_rk
        integer(i_sp)       :: nsteps         = 2000_i_sp
        integer(i_sp)       :: print_interval = 100_i_sp
        integer(i_sp)       :: seed           = 0_i_sp
        character(len=256)  :: output_file    = 'ch.dat'
    end type sim_config

contains

    !-----------------------------------------------------------------------------
    !  subroutine : load_config
    !  Description : Populate cfg from a &simulation namelist file. Any field
    !               not present in the file keeps its current cfg value, so
    !               partial config files are valid. If filename is omitted,
    !               cfg is left at its type defaults.
    !
    !  Arguments   :
    !    cfg      - Configuration to populate (intent: inout)
    !    filename - Path to namelist file (intent: in, optional)
    !
    !  Error Handling :
    !    A missing file or malformed namelist prints a warning and falls
    !    back to the defaults already held in cfg, rather than aborting -
    !    a bad config file should not be fatal when defaults are usable.
    !-----------------------------------------------------------------------------
    subroutine load_config(cfg, filename)
        type(sim_config), intent(inout) :: cfg
        character(len=*), intent(in), optional :: filename
        integer :: unit_no, ios
        integer(i_sp)      :: Nx, Ny, nsteps, print_interval, seed
        real(rk)           :: dx, dy, c0, noise, A, dt, mobility, grad_coef
        character(len=256) :: output_file
        namelist /simulation/ Nx, Ny, dx, dy, c0, noise, A, dt, mobility, &
                               grad_coef, nsteps, print_interval, seed, output_file

        if (.not. present(filename)) return

        ! Seed the namelist locals with the current cfg values so any field
        ! absent from the file simply retains its existing/default value.
        Nx = cfg%Nx;  Ny = cfg%Ny;  dx = cfg%dx;  dy = cfg%dy
        c0 = cfg%c0;  noise = cfg%noise;  A = cfg%A
        dt = cfg%dt;  mobility = cfg%mobility;  grad_coef = cfg%grad_coef
        nsteps = cfg%nsteps;  print_interval = cfg%print_interval
        seed = cfg%seed;  output_file = cfg%output_file

        open(newunit=unit_no, file=trim(filename), status='old', &
             action='read', iostat=ios)
        if (ios /= 0) then
            write(error_unit, '(A)') '  ## WARNING: Could not open config file: '//trim(filename)
            write(error_unit, '(A)') '  ## WARNING: Falling back to default parameters.'
            return
        end if

        read(unit_no, nml=simulation, iostat=ios)
        close(unit_no)
        if (ios /= 0) then
            write(error_unit, '(A)') '  ## WARNING: Malformed &simulation namelist in '//trim(filename)
            write(error_unit, '(A)') '  ## WARNING: Falling back to default parameters.'
            return
        end if

        cfg%Nx = Nx;  cfg%Ny = Ny;  cfg%dx = dx;  cfg%dy = dy
        cfg%c0 = c0;  cfg%noise = noise;  cfg%A = A
        cfg%dt = dt;  cfg%mobility = mobility;  cfg%grad_coef = grad_coef
        cfg%nsteps = nsteps;  cfg%print_interval = print_interval
        cfg%seed = seed;  cfg%output_file = output_file
    end subroutine load_config

    !-----------------------------------------------------------------------------
    !  subroutine : print_config
    !  Description : Echo the active configuration to stdout so every run
    !               logs the parameters needed to reproduce it.
    !-----------------------------------------------------------------------------
    subroutine print_config(cfg)
        type(sim_config), intent(in) :: cfg
        write(output_unit, '(A,I0,A,I0)') &
            '   Grid size      : ', cfg%Nx, ' x ', cfg%Ny
        write(output_unit, '(A,F0.4,A,F0.4)') &
            '   Grid spacing   : dx = ', cfg%dx, ', dy = ', cfg%dy
        write(output_unit, '(A,F0.4,A,F0.4)') &
            '   Initial state  : c0 = ', cfg%c0, ', noise = ', cfg%noise
        write(output_unit, '(A,F0.4)') &
            '   Free energy A  : ', cfg%A
        write(output_unit, '(A,F0.5,A,F0.4,A,F0.4)') &
            '   Integration    : dt = ', cfg%dt, ', mobility = ', cfg%mobility, &
            ', grad_coef = ', cfg%grad_coef
        write(output_unit, '(A,I0)') &
            '   Time steps     : ', cfg%nsteps
        if (cfg%seed > 0_i_sp) then
            write(output_unit, '(A,I0)') '   RNG seed       : ', cfg%seed
        else
            write(output_unit, '(A)')    '   RNG seed       : non-deterministic'
        end if
        write(output_unit, '(A)') &
            '   Output file    : '//trim(cfg%output_file)
    end subroutine print_config

end module sim_config_module
