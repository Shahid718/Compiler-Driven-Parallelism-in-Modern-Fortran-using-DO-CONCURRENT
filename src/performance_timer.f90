!-------------------------------------------------------------------------------
!
!  Module       : timer_module
!  Purpose      : Unified wall-clock timer interface using
!				  SYSTEM_CLOCK or OMP_GET_WTIME.
!
!  Author      : Shahid Maqbool
!  Date        : 7 July 2026
!  Version     : 1.0.0
!  License     : MIT
!
!-------------------------------------------------------------------------------
module timer_module
    use, intrinsic :: iso_fortran_env, only : output_unit
    use precision_module
    implicit none
    !-----------------------------------------------------------------------------
    !  Module Constants
    !-----------------------------------------------------------------------------   
    ! Timer status codes
    integer, parameter :: TIMER_NOT_STARTED = 0
    integer, parameter :: TIMER_RUNNING     = 1
    integer, parameter :: TIMER_STOPPED     = 2
    
    !-----------------------------------------------------------------------------
    !  Timer Variables 
    !-----------------------------------------------------------------------------
    ! SYSTEM_CLOCK variables
    integer :: sys_clock_start = 0
    integer :: sys_clock_finish = 0
    integer :: sys_clock_rate = 0
    real(dp) :: elapsed_time = 0.0_dp   

    ! Timer status
    integer :: timer_status = TIMER_NOT_STARTED
    !-----------------------------------------------------------------------------
    !  Public Interface
    !-----------------------------------------------------------------------------
    public :: timer_start, timer_stop, timer_report, get_wall_time
contains

	!-----------------------------------------------------------------------------
	! Subroutine : timer_start
	! Purpose    : Initialize the wall-clock timer.
	!-----------------------------------------------------------------------------
    subroutine timer_start()     
		call system_clock(count=sys_clock_start, count_rate=sys_clock_rate)
		if (sys_clock_rate <= 0) then
			error stop "SYSTEM_CLOCK returned an invalid clock rate."
		end if        
        timer_status = TIMER_RUNNING
        write(output_unit, '(A)') '  Timer started...'
    end subroutine timer_start
	!-----------------------------------------------------------------------------
	! Subroutine : timer_stop
	! Purpose    : Stop the wall-clock timer and compute elapsed time.
	!-----------------------------------------------------------------------------
	subroutine timer_stop()
		if (timer_status == TIMER_NOT_STARTED) then
			write(output_unit,'(A)') &
				'  ## WARNING: Timer not started. Call timer_start() first.'
			return
		end if
		call system_clock(count=sys_clock_finish)

		elapsed_time = real(sys_clock_finish - sys_clock_start, dp) / &
                   real(sys_clock_rate, dp)
				   
		timer_status = TIMER_STOPPED
	end subroutine timer_stop
    !-----------------------------------------------------------------------------
    !  subroutine : timer_report
    !  Description : Print a formatted timing report
    !-----------------------------------------------------------------------------
	subroutine timer_report()
		if (timer_status == TIMER_NOT_STARTED) then
			write(output_unit,'(A)') &
				'  WARNING: Timer has not been started.'
			return
		end if
		write(output_unit,'(A)') ''
		write(output_unit,'(A)') '  +----------------------------------------------------------------------+'
		write(output_unit,'(A)') '                            TIMING REPORT                                 '
		write(output_unit,'(A)') '  +----------------------------------------------------------------------+'
		write(output_unit,'(A)') ''
		write(output_unit,'(A,F12.3,A)') &
			'    Elapsed time : ', elapsed_time, ' seconds'
	end subroutine timer_report

    !-----------------------------------------------------------------------------
    !  function : get_wall_time
    !  Description : Return the current elapsed wall-clock time.
    !-----------------------------------------------------------------------------
	function get_wall_time() result(time)
		real(dp) :: time
		select case (timer_status)

		case (TIMER_STOPPED)
			time = elapsed_time
		case (TIMER_RUNNING)
		call system_clock(count=sys_clock_finish)
			time = real(sys_clock_finish - sys_clock_start, dp) / &
				real(sys_clock_rate, dp)
		case default
			time = 0.0_dp
		end select
	end function get_wall_time

end module timer_module