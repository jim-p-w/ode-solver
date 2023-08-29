module equations
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Module: equations
!
! This module implements a system of ODEs by providing routines
! to query the size of the system's state vector, get initial 
! conditions, and return the time-derivative of the state vector given
! the current state.
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    implicit none

    private

    public :: get_system_size, set_initial_state, f

    integer, parameter :: state_size = 3
    real, parameter :: sigma = 10
    real, parameter :: beta = 8./3.
    real, parameter :: rho = 28

    contains


    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !
    ! Name: get_system_size
    !
    ! Description: Returns the size of the state vector used by the 
    !   system implemented in this module.
    !
    ! Input: none
    !
    ! Return value: the size of the system's state vector
    !
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    function get_system_size()

        ! Return value
        integer :: get_system_size


        !
        ! Code...
        !
        get_system_size = state_size
        return

    end function get_system_size


    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !
    ! Name: set_initial_state
    !
    ! Description: Initializes a system state vector. Upon returning, 
    !   the elements of s have been set to contain the initial condition 
    !   of the system.
    !
    ! Input: none
    !
    ! Output: s -- the initial condition state vector
    !
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    subroutine set_initial_state(s)

        real, dimension(:), intent(out) :: s


        !
        ! Code...
        !
        s(:) = 10

    end subroutine set_initial_state


    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !
    ! Name: f
    !
    ! Description: This function returns a tendency vector, ds/dt, for 
    !   the system implemented in this module, given the current state of 
    !   the system.
    !
    ! Input: t -- the time at which the state, s, is valid
    !        s -- a state vector
    !
    ! Return value: the time-derivative, ds/dt, for the system at s
    !
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    function f(t,s)

        real, intent(in) :: t
        real, dimension(:), intent(in) :: s

        ! Return value
        real, dimension(size(s)) :: f
        real :: output(size(s))

        integer, parameter :: X = 1
        integer, parameter :: Y = 2
        integer, parameter :: Z = 3
        real :: dx, dy, dz

        !
        ! Code...
        !
        output(X) = sigma * (s(Y) - s(X))
        output(Y) = s(X) * (rho - s(Z)) - s(Y)
        output(Z) = s(X) * s(Y) -  (beta * s(Z))
        f = output

    end function f

end module equations
