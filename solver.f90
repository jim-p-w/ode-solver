program solver
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Program: solver
!
! 
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    use equations
    use observer
    implicit none
    real, allocatable, dimension(:) :: state
    real, allocatable, dimension(:) :: deltas

    ! get the delta-t and number of steps from the user
    real :: dt = 0.01
    integer :: nsteps = 2000
    integer :: index

    print *, "Enter delta t"
    read(*,*) dt
    print *, "Enter the number of steps to compute"
    read(*,*) nsteps

    print *, "dt:", dt, " steps:", nsteps

    ! open the data file for writing
    call observer_init()

    ! get the state vector
    allocate(state(get_system_size()))
    allocate(deltas(get_system_size()))
    call set_initial_state(state)

    ! save state to file
    print *, 'state:', state
    call observer_write(state)

    do index = 1, nsteps, 1
        deltas = f(dt, state)
        state(:) = state(:) + deltas(:) * dt
        call observer_write(state)
    end do

    ! close data file
    call observer_finalize()


end program solver
