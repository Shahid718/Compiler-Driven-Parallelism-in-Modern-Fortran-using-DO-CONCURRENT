!-------------------------------------------------------------------------------
!
!  Submodule    : init_microstructure_sub
!  Purpose      : Initialize the phase-field microstructure with 
!                 random noise perturbations around a base concentration
!
!  Author       : Shahid Maqbool
!  Date         : 7 July 2026
!  Version      : 1.0.0
!  License      : MIT
!
!  Algorithm    : 
!    1. Generate uniform random field [0,1] using random_number()
!    2. Map to concentration: c = c0 + noise * (0.5 - r)
!
!  Precision    : Default Single-precision sp for all floating-point operations
!
!-------------------------------------------------------------------------------
submodule (phase_field_module) init_microstructure_sub
    use precision_module
    implicit none
contains
    module procedure init_microstructure
        integer(i_sp) :: i, j
        integer(i_sp) :: n_seed
        integer(i_sp), allocatable :: seed_array(:)

        ! Store initial concentration
        this%c0 = c0

        ! Initialize the RNG state. A positive seed gives bit-for-bit
        ! reproducible microstructures across runs (and, for a given
        ! compiler's RNG algorithm, across machines) - useful for
        ! regression testing and debugging. seed absent or <= 0 keeps
        ! the previous OS-entropy behavior.
        if (present(seed)) then
            if (seed > 0_i_sp) then
                call random_seed(size=n_seed)
                allocate(seed_array(n_seed))
                seed_array = seed
                call random_seed(put=seed_array)
            else
                call random_seed()
            end if
        else
            call random_seed()
        end if

        ! Generate random field serially, then parallelize the deterministic map.
        call random_number(this%r)

        do j = 1, this%Ny
            do i = 1, this%Nx
                this%con(i, j) = c0 + noise * (0.5 - this%r(i, j))
            end do
        end do
        
      write(*, '(A, F8.4)') '      c0     : ', c0
      write(*, '(A, F8.4)') '      noise  : ', noise
        
    end procedure
end submodule
