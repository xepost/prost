#include "solver.hpp"

#include <algorithm>
#include <iostream>
#include <list>
#include <sstream>
#include "backend/backend.hpp"
#include "problem.hpp"

using std::cout;
using std::endl;

template<typename T>
std::list<double> 
linspace(T start_in, T end_in, int num_in) 
{
  double start = static_cast<double>(start_in);
  double end = static_cast<double>(end_in);
  double num = static_cast<double>(num_in);
  double delta = (end - start) / (num - 1);

  std::list<double> linspaced; 
  for(int i = 0; i < num; ++i) 
    linspaced.push_back(start + delta * i);

  linspaced.push_back(end);
  
  return linspaced;
}

template<typename T>
Solver<T>::Solver(std::shared_ptr<Problem<T> > problem, std::shared_ptr<Backend<T> > backend) 
  : problem_(problem), backend_(backend)
{
}

template<typename T>
Solver<T>::~Solver() 
{
}

template<typename T> 
void 
Solver<T>::SetOptions(const typename Solver<T>::Options& opts) 
{
  opts_ = opts;

  if(opts_.verbose)
  {
    // TODO: output individual solver options
  }
}

template<typename T>
void 
Solver<T>::SetStoppingCallback(const typename Solver<T>::StoppingCallback& cb)
{
  stopping_cb_ = cb;
}

template<typename T>
void 
Solver<T>::SetIntermCallback(const typename Solver<T>::IntermCallback& cb)
{
  interm_cb_ = cb;
}


template<typename T>
void
Solver<T>::Initialize() 
{
  problem_->Initialize();
  backend_->Initialize();

  cur_primal_sol_.resize( problem_->ncols() );
  cur_dual_sol_.resize( problem_->nrows() );

  if(opts_.verbose) 
  {
    std::cout << "Initialized solver successfully. Problem dimension:" << std::endl;
    std::cout << "# primal variables: " << problem_->ncols() << std::endl;
    std::cout << "# dual variables: " << problem_->nrows() << std::endl;

    // TODO: output precise memory requirements
  }
}

template<typename T>
typename Solver<T>::ConvergenceResult
Solver<T>::Solve() 
{
  // iterations to display
  std::list<double> cb_iters =
      linspace(0, opts_.max_iters - 1, opts_.num_cback_calls);
  
  for(int i = 0; i < opts_.max_iters; i++) 
  {    
    backend_->PerformIteration();

    // check if solver has converged
    T primal_res = backend_->primal_residual();
    T dual_res = backend_->dual_residual();
    T pv_norm = backend_->primal_var_norm();
    T dv_norm = backend_->dual_var_norm();

    bool is_converged = false;

    if((primal_res < (opts_.tol_abs_primal + opts_.tol_rel_primal * pv_norm)) &&
      (dual_res < (opts_.tol_abs_dual + opts_.tol_rel_dual * dv_norm)))
    {
      is_converged = true;
    }

    // check if we should run the intermediate solution callback this iteration
    if(i >= cb_iters.front() || is_converged) 
    {
      backend_->current_solution(cur_primal_sol_, cur_dual_sol_);
      interm_cb_(i + 1, cur_primal_sol_, cur_dual_sol_);

      if(opts_.verbose) 
      {
        std::cout << "TODO: output some residuals here" << std::endl;
      }
      
      cb_iters.pop_front();
    }

    if(is_converged)
    {
      if(opts_.verbose)
        std::cout << "Reached convergence tolerance." << std::endl;

      return Solver<T>::ConvergenceResult::kConverged;
    }

    if(stopping_cb_())
    {
      if(opts_.verbose)
        std::cout << "Terminated by user-input." << std::endl;

      return Solver<T>::ConvergenceResult::kStoppedUser;
    }
  }

  if(opts_.verbose)
    std::cout << "Reached maximum number of iterations." << std::endl;

  return Solver<T>::ConvergenceResult::kStoppedMaxIters;
}

template<typename T>
void 
Solver<T>::Release() 
{
  problem_->Release();
  backend_->Release();
}

// Explicit template instantiation
template class Solver<float>;
template class Solver<double>;