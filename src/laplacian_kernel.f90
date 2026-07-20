!-------------------------------------------------------------------------------
!
!  Submodule    : laplace_evaluation_sub
!  Purpose      : Compute Laplacian operators for the Cahn-Hilliard equation.
!                 Evaluates:
!                   1. Laplacian of concentration (∇²c)
!                   2. Chemical potential (μ = df/dc - κ∇²c)
!                   3. Laplacian of chemical potential (∇²μ)
!
!  Author      : Shahid Maqbool
!  Date        : 7 July 2026
!  Version     : 1.0.0
!  License     : MIT
!
!  Parent Module : phase_field_mod
!
!  Dependencies :
!    phase_field_mod  - Provides PhaseFieldGrid type and parent procedures
!    precision_module - Configurable working precision (rk)
!
!  Algorithm    :
!    Laplacian (5-point stencil):
!      ∇²f(i,j) = [f(i+1,j) + f(i-1,j) + f(i,j+1) + f(i,j-1) - 4f(i,j)] / (dx*dy)
!
!    Chemical Potential:
!      μ = df/dc - κ·∇²c
!
!    Cahn-Hilliard Equation:
!      ∂c/∂t = M·∇²μ
!
!  Memory Usage : 6 arrays x Nx x Ny x 4 bytes
!
!-------------------------------------------------------------------------------
submodule (phase_field_module) laplace_evaluation_sub
    !===========================================================================
    !  SUBMODULE DEPENDENCIES
    !===========================================================================
    !
    !  phase_field_mod  : Provides the PhaseFieldGrid type containing:
    !                     - con        : concentration field
    !                     - dfdcon     : free energy derivative
    !                     - lap_con    : Laplacian of concentration
    !                     - dummy_con  : chemical potential (μ)
    !                     - lap_dummy  : Laplacian of chemical potential
    !                     - dx, dy     : grid spacings
    !                     - grad_coef  : gradient energy coefficient
    !
    !  precision_module : Provides rk precision type
    !
    !===========================================================================
    use precision_module
    implicit none
contains
    !-----------------------------------------------------------------------------
    !  module procedure : laplace_evaluation
    !  Description      : Compute Laplacian of concentration, chemical potential,
    !                     and Laplacian of chemical potential using a 5-point
    !                     finite difference stencil with periodic boundary
    !                     conditions.
    !
    !  Arguments        :
    !    this - PhaseFieldGrid object (intent: inout)
    !
    !  Algorithm        :
    !    Step 1: Compute ∇²c using 5-point stencil
    !    Step 2: Compute μ = df/dc - κ·∇²c
    !    Step 3: Compute ∇²μ using 5-point stencil
    !
    !  Boundary        : Periodic (wrap-around)
    !  Parallelization : DO CONCURRENT 
    !-----------------------------------------------------------------------------
    module procedure laplace_evaluation
        integer(i_sp) :: ip, im, jp, jm
        real(rk) :: inv_dxdy
        !=========================================================================
        !  Phase 1 : Precompute Constants
        !=========================================================================
        ! Precompute inverse of dx*dy for efficiency
        inv_dxdy = 1.0_rk / (this%dx * this%dy)
        !=========================================================================
        !  Phase 2 : Compute Laplacian of Concentration and Chemical Potential
        !=========================================================================
        !
        !  Step 2a: Compute ∇²c using 5-point stencil
        !  Step 2b: Compute μ = df/dc - κ·∇²c
        !
        !  The 5-point stencil for Laplacian:
        !    ∇²f(i,j) = [f(i+1,j) + f(i-1,j) + f(i,j+1) + f(i,j-1) - 4f(i,j)] / (dx*dy)
        !
        !  Periodic boundary conditions:
        !    i=1    -> i-1 = Nx (wrap-around)
        !    i=Nx   -> i+1 = 1  (wrap-around)
        !    j=1    -> j-1 = Ny (wrap-around)
        !    j=Ny   -> j+1 = 1  (wrap-around)
        !
        !=========================================================================
		
		!=========================================================================
		! Kernel Computation
		!=========================================================================		
        do concurrent (integer(i_sp)::j=1:this%Ny) default (none) &
				local(ip,im,jp,jm) shared(this,inv_dxdy)					
			do concurrent (integer(i_sp)::i=1:this%Nx)		
			    !-----------------------------------------------------------------
                !  Step 1 : Compute Neighbor Indices with Periodic Boundary
                !-----------------------------------------------------------------                
                im = merge(this%nx, i - 1, i == 1)
                ip = merge(1, i + 1, i == this%nx)
                jm = merge(this%ny, j - 1, j == 1)
                jp = merge(1, j + 1, j == this%ny)
                !-----------------------------------------------------------------
                !  Step 2 : Compute Laplacian of Concentration (∇²c)
                !-----------------------------------------------------------------
                this%lap_con(i, j) = (this%con(ip, j) + this%con(im, j) + &
                                      this%con(i, jm) + this%con(i, jp) - &
                                      4.0_rk * this%con(i, j)) * inv_dxdy                
                !-----------------------------------------------------------------
                !  Step 3 : Compute Chemical Potential (μ = df/dc - κ·∇²c)
                !-----------------------------------------------------------------
                this%dummy_con(i, j) = this%dfdcon(i, j) - &
                                       this%grad_coef * this%lap_con(i, j)
                !-----------------------------------------------------------------
                !  Step 4 : Compute Laplacian of chemical potential (∇²μ)
                !-----------------------------------------------------------------									   
                this%lap_dummy(i, j) = (this%dummy_con(ip, j) + &
                                        this%dummy_con(im, j) + &
                                        this%dummy_con(i, jm) + &
                                        this%dummy_con(i, jp) - &
                                        4.0_rk * this%dummy_con(i, j)) * inv_dxdy
            end do
         end do	 
		
    end procedure    
end submodule