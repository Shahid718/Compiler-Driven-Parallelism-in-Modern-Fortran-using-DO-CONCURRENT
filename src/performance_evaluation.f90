!
!  Submodule    : performance_sub
!  Purpose      : Implementation of performance monitoring procedures
!                 for the Cahn-Hilliard phase-field simulation.
!
!  Author       : Shahid Maqbool
!  Date         : 7 July 2026
!  Version      : 1.0.0
!  License      : MIT
!
!  Parent Module : performance_module
!
!  Dependencies :
!    timer module  - Provides elapsed_time
!
!  Procedures Implemented :
!    print_performance_report()  - Print formatted report
!-------------------------------------------------------------------------------
submodule (performance_module) performance_sub
    use timer_module
    implicit none

contains
    !-----------------------------------------------------------------------------
    !  module procedure : print_performance_report
    !  Description      : Print a comprehensive, formatted performance report
    !                     including system configuration, timing results,
    !                     performance metrics, and analysis.
    !
    !  Output           : Formatted report to stdout
    !  Format           : Box-drawing characters
    !-----------------------------------------------------------------------------
    module procedure print_performance_report
		real(dp) :: elapsed_time, mlups
		elapsed_time = get_wall_time()
		
        write(output_unit, '(A)') '   +----------------------------------------------------------------------+'
        write(output_unit, '(A)') '   |                     PERFORMANCE REPORT                               |'
        write(output_unit, '(A)') '   +----------------------------------------------------------------------+'
        write(output_unit, '(A, I0, A, I0)') '    Grid size           : ', grid%nx, ' x ', grid%ny
        write(output_unit, '(A, I0)') '    Time steps          : ', nsteps
        write(output_unit, '(A, I0)') '    Total updates       : ', int(nsteps, i_dp) * int(grid%nx, i_dp) * int(grid%ny, i_dp)
		write(output_unit,'(A,F0.3)') '    Computed Time       : ', elapsed_time 
		write(output_unit,'(A,F0.3)') '    MLUPS               : ', int(nsteps, i_dp) * int(grid%nx, i_dp) * int(grid%ny, i_dp) / (elapsed_time*1.0e6_dp)
        write(output_unit, '(A)') '    -----------------------------------------------------------------------'       
    end procedure print_performance_report

end submodule performance_sub