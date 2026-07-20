!-------------------------------------------------------------------------------
!
!  Module       : precision_module
!  Purpose      : Define precision and range parameters for the entire program.
!                 Provides consistent precision types across all modules.
!
!  Author       : Shahid Maqbool
!  Date         : 7 July 2026
!  Version      : 1.0.0
!  License      : MIT
!
!  Description  :
!    This module defines standard precision types for integers and reals
!    using the ISO_FORTRAN_ENV intrinsic module. All other modules in the
!    project USE this module to ensure consistent precision throughout.
!
!  Features     :
!    Single precision real   : sp (32-bit, ~7 decimal digits)
!    Double precision real   : dp (64-bit, ~15 decimal digits)
!    Single precision integer: i_sp (32-bit, range: -2e9 to 2e9)
!    Double precision integer: i_dp (64-bit, range: -9e18 to 9e18)
!    ISO_FORTRAN_ENV standard compliance
!
!  Dependencies :
!    iso_fortran_env - Provides int32, int64, real32, real64 constants
!
!  Usage        :
!    use precision_module, only : sp, dp, i_sp, i_dp
!    real(sp) :: single_precision_var
!    real(dp) :: double_precision_var
!    integer(i_sp) :: single_precision_int
!    integer(i_dp) :: double_precision_int
!
!  Performance  :
!    - Use sp for memory-constrained applications (4 bytes/element)
!    - Use dp for high-precision calculations (8 bytes/element)
!    - Use i_sp for standard integer operations (4 bytes)
!    - Use i_dp for large integer ranges (8 bytes)
!-------------------------------------------------------------------------------

module precision_module
    use, intrinsic :: iso_fortran_env, only : real32, real64, int32, int64
    implicit none

    ! Integer kinds
    integer, parameter :: i_sp = int32
    integer, parameter :: i_dp = int64

    ! Available real kinds
    integer, parameter :: sp = real32
    integer, parameter :: dp = real64

    !-----------------------------------------------------------------
    ! Select the working precision for the entire application.
    ! Change only this line to switch precision.
    !-----------------------------------------------------------------
#ifdef USE_DOUBLE_PRECISION
    integer, parameter :: rk = dp
#else
    integer, parameter :: rk = sp
#endif

end module precision_module
