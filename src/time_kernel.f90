!-------------------------------------------------------------------------------
!
!  Submodule    : time_integration_sub
!  Purpose      : Perform explicit time integration for the Cahn-Hilliard equation.
!                 Updates concentration field using forward Euler method.
!
!  Author       : Shahid Maqbool
!  Date         : 7 July 2026
!  Version      : 1.0.0
!  License      : MIT
!
!  Parent Module : phase_field_mod
!
!  Dependencies :
!    phase_field_mod  - Provides PhaseFieldGrid type and parent procedures
!    precision_module - Provides rk precision types
!
!  Algorithm    :
!    Cahn-Hilliard Equation:
!      ∂c/∂t = M · ∇²(μ)
!      where μ = df/dc - κ·∇²c  (chemical potential)
!
!    Forward Euler Time Integration:
!      c^{n+1} = c^n + Δt · M · ∇²(μ^n)
!
!    Bounds Enforcement:
!      [0.0001, 0.9999] prevents numerical instability)
!
!-------------------------------------------------------------------------------
submodule (phase_field_module) time_integration_sub
    !===========================================================================
    !  SUBMODULE DEPENDENCIES
    !===========================================================================
    !
    !  phase_field_mod  : Provides the PhaseFieldGrid type containing:
    !                     - con        : concentration field (updated)
    !                     - lap_dummy  : Laplacian of chemical potential (∇²μ)
    !                     - Nx, Ny     : grid dimensions
    !
    !  precision_module : Provides precision types
    !
    !===========================================================================
    use precision_module
    implicit none
contains
    !-----------------------------------------------------------------------------
    !  module procedure : time_integration
    !  Description      : Update concentration using explicit forward Euler
    !                     time integration for the Cahn-Hilliard equation.
    !
    !  Arguments        :
    !    this       - PhaseFieldGrid object (intent: inout)
    !    dt         - Time step (intent: in)
    !    mobility   - Mobility coefficient (intent: in)
    !    grad_coef  - Gradient energy coefficient (intent: in)
    !
    !  Algorithm        :
    !    Step 1: Store parameters in grid object
    !    Step 2: Compute c^{n+1} = c^n + dt·M·∇²(μ^n)
    !    Step 3: Enforce physical bounds [0, 1]
	
    module procedure time_integration
        real(rk) :: c_max, c_min
        !=========================================================================
        !  Phase 1 : Store Parameters
        !=========================================================================
        ! Store simulation parameters in grid object for future reference
        this%dt = dt
        this%mobility = mobility
        this%grad_coef = grad_coef
        c_max = 0.9999_rk
        c_min = 0.0001_rk
        !=========================================================================
        !  Phase 2 : Forward Euler Time Integration
        !=========================================================================
        !
        !  Cahn-Hilliard Equation:
        !    ∂c/∂t = M · ∇²(μ)
        !
        !  Forward Euler Update:
        !    c^{n+1}(i,j) = c^n(i,j) + Δt · M · ∇²(μ^n)(i,j)
        !
        !  Where:
        !    μ = df/dc - κ·∇²c  (chemical potential)
        !    ∇²(μ) is stored in lap_dummy
        !
        !=========================================================================	
		do concurrent (integer(i_sp)::j=1:this%Ny ) &
				default (none) shared(this,dt,mobility,c_max,c_min)	
				 do concurrent (integer(i_sp):: i=1:this%Nx)			 
                !-----------------------------------------------------------------
                !  Step 1 : Forward Euler Update
                !-----------------------------------------------------------------
                ! c_new = c_old + dt * mobility * ∇²(μ)
                this%con_next(i, j) = this%con(i, j) + dt * mobility * this%lap_dummy(i, j)
                
                !-----------------------------------------------------------------
                !  Step 2 : Enforce Physical Bounds
                !-----------------------------------------------------------------
                ! Concentration must stay within [0, 1] for numerical stability
                ! This prevents values from going negative or above 1
                this%con_next(i, j) = min(c_max, max(c_min, this%con_next(i, j)))
            end do
        end do	
		!=========================================================================
		!  Phase 3 : Update fields
		!=========================================================================
        call swap_fields(this%con, this%con_next)
        
    end procedure
    
    ! swap fields for update
    module subroutine swap_fields(this, that)
        real(rk), allocatable, intent(inout) :: this(:, :), that(:, :)
        real(rk), allocatable :: buffer(:, :)
        
        call move_alloc(this, buffer)
        call move_alloc(that, this)
        call move_alloc(buffer, that)
    end subroutine swap_fields
    
end submodule
