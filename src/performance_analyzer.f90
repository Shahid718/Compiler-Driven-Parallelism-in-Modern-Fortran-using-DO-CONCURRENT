!-------------------------------------------------------------------------------
!
!  Module       : performance_module
!  Purpose      : Performance monitoring, timing, and metrics collection
!                 for the Cahn-Hilliard phase-field simulation code.
!
!  Author       : Shahid Maqbool
!  Date         : 7 July 2026
!  Version      : 1.0.0
!  License      : MIT
!
!  Usage        : use performance_module
!                 call print_performance_report()
!
!  Dependencies :
!    precision_module  - Provides sp, dp, i_sp precision types
!    phase_field_mod   - Provides PhaseFieldGrid type for grid information
!-------------------------------------------------------------------------------
module performance_module
    use precision_module
    use phase_field_module
    implicit none
    !===========================================================================
    !  PUBLIC VARIABLES
    !===========================================================================

    ! Performance Metrics (calculated from timer module data)
    real(dp), public :: update_rate = 0.0_dp
    
    !===========================================================================
    !  INTERFACE BLOCKS
    !===========================================================================
    interface
		module subroutine print_performance_report(grid, nsteps)
			class(PhaseFieldGrid), intent(in) :: grid
			integer(i_sp), intent(in)         :: nsteps
		end subroutine print_performance_report     
    end interface
    
end module performance_module