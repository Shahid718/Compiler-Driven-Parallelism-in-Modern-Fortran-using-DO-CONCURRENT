!---------------------------------------------------------------------------------------
!
!  Submodule    : free_energy_derivative_sub
!  Purpose      : Compute the derivative of the double-well free energy
!                 functional with respect to concentration (∂f/∂c).
!                 This forms the thermodynamic driving force for phase
!                 separation in the Cahn-Hilliard equation.
!
!  Author      : Shahid Maqbool
!  Date        : 7 July 2026
!  Version     : 1.0.0
!  License     : MIT
!
!  Parent Module : phase_field_module
!
!  Dependencies :
!    phase_field_module - Provides PhaseFieldGrid type and parent procedures
!    precision_module   - Configurable working precision (rk)
!
!  Mathematical Formulation :
!    Free Energy Functional (Double-Well Potential):
!      f(c) = A · c² · (1-c)²
!
!    Free Energy Derivative (Chemical Potential):
!      df/dc = A · [2c·(1-c)² - 2c²·(1-c)]
!           = 2A · c · (1-c) · (1-2c)
!
!    Physical Interpretation:
!      - df/dc = 0  at c = 0  (stable phase 1)
!      - df/dc = 0  at c = 1  (stable phase 2)
!      - df/dc = A/4 at c = 0.5 (unstable, spinodal decomposition)
!
!    The double-well potential drives the system toward phase separation
!    into two equilibrium phases with minimal free energy.
!
!-------------------------------------------------------------------------------

submodule (phase_field_module) free_energy_derivative_sub
    use precision_module
    implicit none
  contains
    module procedure free_energy_derivative
    ! Store A parameter
    this%A = A

	!=========================================================================
	! Kernel Computation
	!=========================================================================
    ! Outer loop handles 'j'
    do concurrent (integer(i_sp)::j=1:this%Ny) default(none) shared(this, A)
        ! Inner loop handles 'i' (no local clause needed, type is declared here)
        do concurrent (integer(i_sp)::i= 1:this%Nx)          
            this%dfdcon(i, j) = A * (2.0_rk*this%con(i,j)*(1.0_rk-this%con(i,j))* &
				(1.0_rk-this%con(i,j)) - 2.0_rk*this%con(i,j)*this%con(i,j)* &
				(1.0_rk-this%con(i,j)))            
        end do
    end do
    end procedure
end submodule


