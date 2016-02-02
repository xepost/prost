#ifndef ELEM_OPERATION_HPP_
#define ELEM_OPERATION_HPP_

#include "prox/elemop/shared_mem.hpp"
#include "prox/elemop/vector.hpp"

namespace prox 
{

template<size_t DIM = 0, size_t COEFFS_COUNT = 0, typename SHARED_MEM_TYPE = char>
struct ElemOperation 
{
public: 
  static const size_t kCoeffsCount = COEFFS_COUNT;
  static const size_t kDim = DIM;
  static size_t GetSharedMemCount(size_t dim) { return 0; }
  typedef SHARED_MEM_TYPE SharedMemType;
};

}

#endif
