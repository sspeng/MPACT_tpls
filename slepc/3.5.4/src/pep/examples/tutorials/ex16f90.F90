!  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  SLEPc - Scalable Library for Eigenvalue Problem Computations
!  Copyright (c) 2002-2014, Universitat Politecnica de Valencia, Spain
!
!  This file is part of SLEPc.
!     
!  SLEPc is free software: you can redistribute it and/or modify it under  the
!  terms of version 3 of the GNU Lesser General Public License as published by
!  the Free Software Foundation.
!
!  SLEPc  is  distributed in the hope that it will be useful, but WITHOUT  ANY 
!  WARRANTY;  without even the implied warranty of MERCHANTABILITY or  FITNESS 
!  FOR  A  PARTICULAR PURPOSE. See the GNU Lesser General Public  License  for 
!  more details.
!
!  You  should have received a copy of the GNU Lesser General  Public  License
!  along with SLEPc. If not, see <http://www.gnu.org/licenses/>.
!  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!
!  Program usage: mpirun -np n ex16f90 [-help] [-n <n>] [-m <m>] [SLEPc opts] 
!
!  Description: Simple example that solves a quadratic eigensystem with the
!  PEP object. This is the Fortran90 equivalent to ex16.c
!
!  The command line options are:
!    -n <n>, where <n> = number of grid subdivisions in x dimension
!    -m <m>, where <m> = number of grid subdivisions in y dimension
!
! ---------------------------------------------------------------------- 
!
      program main

#include <finclude/slepcpepdef.h>
      use slepcpep

      implicit none

! For usage without modules, uncomment the following lines and remove 
! the previous lines between 'program main' and 'implicit none'
!
!#include <finclude/petsc.h>
!#include <finclude/slepc.h>

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
!     Declarations
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
!
!  Variables:
!     M,C,K  problem matrices
!     solver polynomial eigenproblem solver context

#if defined(PETSC_USE_FORTRAN_DATATYPES)
      type(Mat)      M, C, K, A(3)
      type(PEP)      solver
#else
      Mat            M, C, K, A(3)
      PEP            solver
#endif
      PEPType        tname
      PetscInt       N, nx, ny, i, j, Istart, Iend, II
      PetscInt       nev, ithree
      PetscMPIInt    rank
      PetscErrorCode ierr
      PetscBool      flg
      PetscScalar    one, mone, four

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!     Beginning of program
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

      call SlepcInitialize(PETSC_NULL_CHARACTER,ierr)
      call MPI_Comm_rank(PETSC_COMM_WORLD,rank,ierr)
      nx = 10
      call PetscOptionsGetInt(PETSC_NULL_CHARACTER,'-n',nx,flg,ierr)
      call PetscOptionsGetInt(PETSC_NULL_CHARACTER,'-m',ny,flg,ierr)
      if (.not. flg) then
        ny = nx
      endif
      N = nx*ny
      if (rank .eq. 0) then
        write(*,100) N, nx, ny
      endif
 100  format (/'Quadratic Eigenproblem, N=',I6,' (',I4,'x',I4,' grid)')

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
!     Compute the matrices that define the eigensystem, (k^2*M+k*C+K)x=0
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

!     ** K is the 2-D Laplacian
      call MatCreate(PETSC_COMM_WORLD,K,ierr)
      call MatSetSizes(K,PETSC_DECIDE,PETSC_DECIDE,N,N,ierr)
      call MatSetFromOptions(K,ierr)
      call MatSetUp(K,ierr)
      call MatGetOwnershipRange(K,Istart,Iend,ierr)
      mone = -1.0
      four = 4.0
      do II=Istart,Iend-1
        i = II/nx
        j = II-i*nx
        if (i .gt. 0) then 
          call MatSetValue(K,II,II-nx,mone,INSERT_VALUES,ierr)
        endif
        if (i .lt. ny-1) then 
          call MatSetValue(K,II,II+nx,mone,INSERT_VALUES,ierr)
        endif
        if (j .gt. 0) then 
          call MatSetValue(K,II,II-1,mone,INSERT_VALUES,ierr)
        endif
        if (j .lt. nx-1) then 
          call MatSetValue(K,II,II+1,mone,INSERT_VALUES,ierr)
        endif
        call MatSetValue(K,II,II,four,INSERT_VALUES,ierr)
      end do
      call MatAssemblyBegin(K,MAT_FINAL_ASSEMBLY,ierr)
      call MatAssemblyEnd(K,MAT_FINAL_ASSEMBLY,ierr)

!     ** C is the zero matrix
      call MatCreate(PETSC_COMM_WORLD,C,ierr)
      call MatSetSizes(C,PETSC_DECIDE,PETSC_DECIDE,N,N,ierr)
      call MatSetFromOptions(C,ierr)
      call MatSetUp(C,ierr)
      call MatAssemblyBegin(C,MAT_FINAL_ASSEMBLY,ierr)
      call MatAssemblyEnd(C,MAT_FINAL_ASSEMBLY,ierr)

!     ** M is the identity matrix
      call MatCreate(PETSC_COMM_WORLD,M,ierr)
      call MatSetSizes(M,PETSC_DECIDE,PETSC_DECIDE,N,N,ierr)
      call MatSetFromOptions(M,ierr)
      call MatSetUp(M,ierr)
      call MatGetOwnershipRange(M,Istart,Iend,ierr)
      one = 1.0
      do II=Istart,Iend-1
        call MatSetValue(M,II,II,one,INSERT_VALUES,ierr)
      end do
      call MatAssemblyBegin(M,MAT_FINAL_ASSEMBLY,ierr)
      call MatAssemblyEnd(M,MAT_FINAL_ASSEMBLY,ierr)

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
!     Create the eigensolver and set various options
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

!     ** Create eigensolver context
      call PEPCreate(PETSC_COMM_WORLD,solver,ierr)

!     ** Set matrices and problem type
      A(1) = K
      A(2) = C
      A(3) = M
      ithree = 3
      call PEPSetOperators(solver,ithree,A,ierr)
      call PEPSetProblemType(solver,PEP_GENERAL,ierr)

!     ** Set solver parameters at runtime
      call PEPSetFromOptions(solver,ierr)

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
!     Solve the eigensystem
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

      call PEPSolve(solver,ierr) 

!     ** Optional: Get some information from the solver and display it
      call PEPGetType(solver,tname,ierr)
      if (rank .eq. 0) then
        write(*,120) tname
      endif
 120  format (' Solution method: ',A)
      call PEPGetDimensions(solver,nev,PETSC_NULL_INTEGER,              &
     &                      PETSC_NULL_INTEGER,ierr)
      if (rank .eq. 0) then
        write(*,130) nev
      endif
 130  format (' Number of requested eigenvalues:',I4)

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
!     Display solution and clean up
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

      call PEPPrintSolution(solver,PETSC_NULL_OBJECT,ierr)
      call PEPDestroy(solver,ierr)
      call MatDestroy(K,ierr)
      call MatDestroy(C,ierr)
      call MatDestroy(M,ierr)
      call SlepcFinalize(ierr)
      end

