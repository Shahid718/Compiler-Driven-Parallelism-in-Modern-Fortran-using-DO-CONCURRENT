!-------------------------------------------------------------------------------
!
!  Module      : error_status_module
!  Purpose     : Centralized error handling utilities for memory allocation.
!
!  Author      : Shahid Maqbool
!  Date        : 7 July 2026
!  Version     : 1.0.0
!  License     : MIT
!
!  This module provides simple and consistent runtime error checking for
!  dynamic memory allocation used throughout the phase-field solver.
!
!-------------------------------------------------------------------------------
module error_status_module
    use, intrinsic :: iso_fortran_env, only : error_unit
    use precision_module, only : i_sp
    implicit none
contains
    !-------------------------------------------------------------------------
    ! Check the status returned by an ALLOCATE statement.
    ! Abort the program if memory allocation fails.
    !-------------------------------------------------------------------------
    subroutine check_allocation_status(istat)
        integer(i_sp), intent(in) :: istat

        if (istat /= 0_i_sp) then
            write(error_unit,'(A)')      'ERROR: Memory allocation failed.'
            write(error_unit,'(A,I0)')   'Allocation status code : ', istat
            error stop
        endif
    end subroutine check_allocation_status

end module error_status_module