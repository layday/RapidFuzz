# distutils: language=c++
# cython: language_level=3
# cython: binding=True

from libc.stdint cimport uint8_t

cdef extern from "cpp_common.hpp":
    cdef struct RapidFuzzString:
        uint8_t kind
        uint8_t allocated
        void*   data
        size_t  length
        void*   context

    ctypedef RapidFuzzString (*RapidFuzzPyObjectProcess)(object) except*
    ctypedef void            (*RapidFuzzStringDealloc)(RapidFuzzString*) nogil

cdef class RapidFuzzProcess:
    cdef RapidFuzzPyObjectProcess process
    cdef RapidFuzzStringDealloc   dealloc