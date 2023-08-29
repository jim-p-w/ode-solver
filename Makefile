.SUFFIXES: .f90 .o

FC=gfortran
CC=gfortran

OBJS := equations.o \
       observer.o solver.o

all:
	($(MAKE) solver)

solver:$(OBJS)

solver.o : equations.o observer.o

clean:
	$(RM) *.o *.mod 
	@# Certain systems with intel compilers generate *.i files
	@# This removes them during the clean process
	$(RM) *.i
	$(RM) solver

%.o : %.f90
	$(FC) $(FFLAGS) -g -c $*.f90 $(CPPINCLUDES) $(FCINCLUDES) 
