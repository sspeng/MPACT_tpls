/*BHEADER**********************************************************************
 * Copyright (c) 2008,  Lawrence Livermore National Security, LLC.
 * Produced at the Lawrence Livermore National Laboratory.
 * This file is part of HYPRE.  See file COPYRIGHT for details.
 *
 * HYPRE is free software; you can redistribute it and/or modify it under the
 * terms of the GNU Lesser General Public License (as published by the Free
 * Software Foundation) version 2.1 dated February 1999.
 *
 * $Revision: 1.5 $
 ***********************************************************************EHEADER*/




/* ************************************************************************* */
/* See the file COPYRIGHT for a complete copyright notice, contact person    */
/* and disclaimer.                                                           */
/* ************************************************************************* */

/* ************************************************************************* */
/* data structures to hold aggregation information                           */
/* ************************************************************************* */
/* Author        : Ray Tuminaro (SNL), Charles Tong (LLNL)                   */
/* Date          : August, 1999                                              */
/* ************************************************************************* */

#ifndef __MLGENP__
#define __MLGENP__

#include "ml_common.h"
#include "ml_operator.h"
#include "ml_aggregate.h"

/* ************************************************************************* */
/* data structure to hold getrow function                                    */
/* ------------------------------------------------------------------------- */

struct ML_AGG_Matrix_Context 
{
   ML_Operator *Amat;
   double      omega;
   double      drop_tol;
   char        *near_bdry;
   int         *aggr_info;
};

#define ML_POLY_ORDER_MAX 10

struct ML_Field_Of_Values
{
  double real_max;                          
  double imag_max;
  double eta;
  int poly_order;
  double R_coeff[ML_POLY_ORDER_MAX];
  double P_coeff[ML_POLY_ORDER_MAX];
  void * EigenList;
  int choice;
  int compute_field_of_values;
  int compute_field_of_values_non_scaled;
};


  
/* ************************************************************************* */
/* functions defined here                                                    */
/* ************************************************************************* */

#ifndef ML_CPP
#ifdef __cplusplus
extern "C" {
#endif
#endif

/* ************************************************************************* */
/* functions called by users                                                 */
/* ------------------------------------------------------------------------- */

extern int ML_Gen_MGHierarchy_UsingAggregation(ML *, int start, 
                       int increment_or_decrement, ML_Aggregate *);

extern int  ML_Gen_MultiLevelHierarchy_UsingSmoothedAggr_ReuseExistingAgg(ML *ml,
								   ML_Aggregate *ag);

/* ************************************************************************* */
/* internal functions called by developers                                   */
/* ------------------------------------------------------------------------- */

extern int ML_Gen_MGHierarchy(ML *, int fine_level,
               int (*next_level)(ML *, int, void *),
               int (*user_gen_prolongator)(ML *,int,int,void *),
               void *data, ML_Aggregate *);
extern int  ML_AGG_Gen_Prolongator(ML*,int ,int,void *data);
extern int  ML_AGG_Gen_Prolongator_MinEnergy(ML*,int ,int,void *data);
extern int  ML_AGG_Gen_Restriction_MinEnergy(ML*,int ,int,void *data);
extern int  ML_AGG_Increment_Level(ML *, int current_level, void *);
extern int  ML_AGG_Decrement_Level(ML *, int current_level, void *);
extern int  ML_AGG_Increment_Two_Level(ML *, int current_level, void *);
extern int  ML_AGG_Decrement_Two_Level(ML *, int current_level, void *);
extern int  ML_AGG_JacobiSmoother_Getrows(ML_Operator *data, int N_requested_rows,
               int requested_rows[], int allocated_space, int columns[],
               double values[], int row_lengths[]);
extern int  ML_AGG_Compute_Near_Bdry(ML_Operator *Amatrix, char *near_bdry);
extern int  ML_AGG_Gen_DDProlongator(ML*,int ,int,void *data);
extern int  ML_AGG_Gen_DDProlongator2(ML *ml,int level, int clevel, void *data);
extern int  ML_AGG_DD_Matvec(ML_Operator *, int , double *, int, double *);
extern int  ML_AGG_DD_Getrow(ML_Operator *,int, int *, int, int *, double *, int *);
extern int  ML_AGG_Extract_Diag( ML_Operator *, double *diag);
extern void ML_AGG_Matrix_Context_Clean(void *data);
extern int  ML_AGG_DD_Solve(void *data, int, double *, int, double *);
extern int  ML_AGG_Extract_Matrix(ML_Operator *mat, int *, int **, double ***);
extern int  ML_AGG_Smoother_Wrapper(void *obj, int leng1, double *outvec, 
				   int leng2, double *invec);
extern int  ML_Gen_MGHierarchy_ReuseExistingOperators(ML *ml );
extern int  ML_Gen_MGHierarchy_UsingSmoothedAggr_ReuseExistingAgg(ML *ml,
								  ML_Aggregate *ag);

extern int ML_AGG_Amat_Getrows(ML_Operator *data, int N_requested_rows, 
               int requested_rows[], int allocated_space, int columns[], 
               double values[], int row_lengths[]);
extern int ML_AGG_DinvP(ML_Operator *Ptemp, struct MLSthing *mls_widget,
			int blk_size);


extern int ML_Gen_MultiLevelHierarchy(ML *ml, int fine_level,
        int (*user_next_level)(ML *, int, void *),
        int (*user_gen_restriction)(ML *, int, int, void *),
        int (*user_gen_prolongator)(ML *, int, int, void *),
        void *user_data);
extern int ML_Gen_MultiLevelHierarchy_UsingAggregation(ML *ml, int start, 
						       int increment_or_decrement,
						       ML_Aggregate *ag);
extern int ML_MultiLevel_Gen_Prolongator(ML *ml,int level, int clevel, void *data);
extern int ML_MultiLevel_Gen_Restriction(ML *ml,int level, int clevel, void *data);
extern void ML_Project_Coordinates(ML_Operator* Amat, ML_Operator* Pmat,
                            ML_Operator* Cmat);


#ifndef ML_CPP
#ifdef __cplusplus
}
#endif
#endif

#endif

