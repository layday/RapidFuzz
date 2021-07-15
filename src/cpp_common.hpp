#pragma once
#include "Python.h"
#define RAPIDFUZZ_PYTHON
#include <rapidfuzz/fuzz.hpp>
#include <rapidfuzz/utils.hpp>
#include <rapidfuzz/string_metric.hpp>
#include <exception>
#include <iostream>

#define PYTHON_VERSION(major, minor, micro) ((major << 24) | (minor << 16) | (micro << 8))

namespace string_metric = rapidfuzz::string_metric;
namespace fuzz = rapidfuzz::fuzz;
namespace utils = rapidfuzz::utils;

class PythonTypeError: public std::bad_typeid {
public:

    PythonTypeError(char const* error)
      : m_error(error) {}

    virtual char const* what() const noexcept {
        return m_error;
    }
private:
    char const* m_error;
};


struct RapidFuzzString {
    uint8_t kind;
    /* flag to specify whether the string is dynamically allocated*/
    uint8_t allocated;
    void*   data;
    size_t  length;
    /* context which can be used by implementations to stor additional data
       like e.g. a pointer to a PyObject* */
    void*   context;
};

/* todo further thoughts required for parallelism and array allocators which should probably use a memory pool */
typedef RapidFuzzString (*RapidFuzzPyObjectProcess)(PyObject*);
// RapidFuzzString (*RapidFuzzStringProcess)(RapidFuzzString);
typedef void            (*RapidFuzzStringDealloc)(RapidFuzzString*);

class ProcStringWrapper
{
public:
    ProcStringWrapper()
      : str({0, 0, nullptr, 0, nullptr}), dealloc(nullptr) {}

    ProcStringWrapper(PyObject* py_str, RapidFuzzPyObjectProcess processor, RapidFuzzStringDealloc _dealloc)
    {
        dealloc = _dealloc;
        str = processor(py_str);
    }

    ProcStringWrapper(const ProcStringWrapper&) = delete;
    ProcStringWrapper& operator=(const ProcStringWrapper&) = delete;

    ProcStringWrapper(ProcStringWrapper&& other)
     : str(other.str), dealloc(other.dealloc)
    {
        other.dealloc = nullptr;
    }

    ProcStringWrapper& operator=(ProcStringWrapper&& other) {
        if (&other != this) {
            if (dealloc)
            {
                dealloc(&str);
            }
            str = other.str;
            other.dealloc = nullptr;
      }
      return *this;
    };

    ~ProcStringWrapper()
    {
       if (dealloc)
       {
           dealloc(&str);
       }
    }

    RapidFuzzString str;
    RapidFuzzStringDealloc dealloc;
};

template <typename T>
static inline rapidfuzz::basic_string_view<T> to_string_view(const RapidFuzzString& s)
{
    return rapidfuzz::basic_string_view<T>((T*)s.data, s.length);
}

static inline PyObject* dist_to_long(std::size_t dist)
{
    if (dist == (std::size_t)-1) {
        return PyLong_FromLong(-1);
    }
    return PyLong_FromSize_t(dist);
}

#define LIST_OF_CASES(...)   \
    X_ENUM(RAPIDFUZZ_UINT8,                       uint8_t  , (__VA_ARGS__)) \
    X_ENUM(RAPIDFUZZ_UINT16,                      uint16_t , (__VA_ARGS__)) \
    X_ENUM(RAPIDFUZZ_UINT32,                      uint32_t , (__VA_ARGS__)) \
    X_ENUM(RAPIDFUZZ_UINT64,                      uint64_t , (__VA_ARGS__)) \
    X_ENUM(RAPIDFUZZ_INT64,                        int64_t , (__VA_ARGS__))


enum RapidfuzzTypes {
#       define X_ENUM(kind, type, MSVC_TUPLE) kind,
        LIST_OF_CASES()
#       undef X_ENUM
};

// this has to be separate from the string conversion, since it can not be called without
// the GIL
static inline bool is_valid_string(PyObject* py_str)
{
    if (!PyUnicode_Check(py_str)) {
        return false;
    }

    // PEP 623 deprecates legacy strings and therefor
    // deprecates e.g. PyUnicode_READY in Python 3.10
#if PY_VERSION_HEX < PYTHON_VERSION(3, 10, 0)
    if (PyUnicode_READY(py_str)) {
      // cython will use the exception set by PyUnicode_READY
      throw std::runtime_error("");
    }
#endif
    return true;
}

// this has to be separate from the string conversion, since it can not be called without
// the GIL
static inline void validate_string(PyObject* py_str, const char* err)
{
    if (!PyUnicode_Check(py_str)) {
        throw PythonTypeError(err);
    }

    // PEP 623 deprecates legacy strings and therefor
    // deprecates e.g. PyUnicode_READY in Python 3.10
#if PY_VERSION_HEX < PYTHON_VERSION(3, 10, 0)
    if (PyUnicode_READY(py_str)) {
      // cython will use the exception set by PyUnicode_READY
      throw std::runtime_error("");
    }
#endif
}

// Right now this can be called without the GIL, since the used Python API
// is implemented using macros, which directly access the PyObject both in
// CPython and PyPy. If this changes the multiprocessing module needs to be updated
static inline RapidFuzzString convert_string(PyObject* py_str)
{
    RapidfuzzTypes kind;
    switch(PyUnicode_KIND(py_str)) {
    case PyUnicode_1BYTE_KIND:
      kind = RAPIDFUZZ_UINT8;
      break;
    case PyUnicode_2BYTE_KIND:
      kind = RAPIDFUZZ_UINT16;
      break;
    default:
      kind = RAPIDFUZZ_UINT32;
      break;
    }

    return {
        static_cast<uint8_t>(kind),
        0,
        PyUnicode_DATA(py_str),
        static_cast<std::size_t>(PyUnicode_GET_LENGTH(py_str)),
        nullptr
    };
}


/* note that the arguments s1 and s2 are switched on purpose, so when calling
 * the macro in impl and impl_inner both s1 and s2 are processed
 *
 * GET_RATIO_FUNC MSVC_TUPLE is used
 * to work around the utterly broken preprocessor in MSVC
 * in more recent versions a standard conformant preprocessor can be activated in MSVC using
 * a compiler flag: https://devblogs.microsoft.com/cppblog/msvc-preprocessor-progress-towards-conformance/
 * However until nobody uses the older versions of MSVC anymore this does not help ...
 */
#define GET_RATIO_FUNC(RATIO_FUNC) RATIO_FUNC

# define X_ENUM(KIND, TYPE, RATIO_FUNC) \
    case KIND: return RATIO_FUNC(s2, to_string_view<TYPE>(s1), args...);


/* generate <ratio_name>_impl_inner_<processor> functions which are used internally
 * for normalized distances
 */
#define RATIO_IMPL_INNER(RATIO, RATIO_FUNC)                                             \
template<typename Sentence, typename... Args>                                                      \
double RATIO##_impl_inner(const RapidFuzzString& s1, const Sentence& s2, Args... args)     \
{                                                                                                  \
    switch(s1.kind){                                                                               \
    LIST_OF_CASES(RATIO_FUNC)                                                           \
    default:                                                                                       \
       throw std::logic_error("Reached end of control flow in " #RATIO "_impl_inner"); \
    }                                                                                              \
}

/* generate <ratio_name>_impl functions which are used internally
 * for normalized distances
 */
#define RATIO_IMPL(RATIO, RATIO_FUNC)                                             \
template<typename... Args>                                                                   \
double RATIO##_impl(const RapidFuzzString& s1, const RapidFuzzString& s2, Args... args)  \
{                                                                                            \
    switch(s1.kind){                                                                         \
    LIST_OF_CASES(RATIO##_impl_inner)                                 \
    default:                                                                                 \
       throw std::logic_error("Reached end of control flow in " #RATIO "_impl"); \
    }                                                                                        \
}

#define RATIO_IMPL_DEF(RATIO, RATIO_FUNC)            \
RATIO_IMPL_INNER(RATIO, RATIO_FUNC) \
RATIO_IMPL(      RATIO, RATIO_FUNC)


/* generate <ratio_name>_impl_inner functions which are used internally
 * for distances
 */
#define DISTANCE_IMPL_INNER(RATIO, RATIO_FUNC)                                          \
template<typename Sentence, typename... Args>                                                      \
size_t RATIO##_impl_inner(const RapidFuzzString& s1, const Sentence& s2, Args... args)     \
{                                                                                                  \
    switch(s1.kind){                                                                               \
    LIST_OF_CASES(RATIO_FUNC)                                                           \
    default:                                                                                       \
       throw std::logic_error("Reached end of control flow in " #RATIO "_impl_inner"); \
    }                                                                                              \
}

/* generate <ratio_name>_impl functions which are used internally
 * for distances
 */
#define DISTANCE_IMPL(RATIO, RATIO_FUNC)                                          \
template<typename... Args>                                                                   \
size_t RATIO##_impl(const RapidFuzzString& s1, const RapidFuzzString& s2, Args... args)  \
{                                                                                            \
    switch(s1.kind){                                                                         \
    LIST_OF_CASES(RATIO##_impl_inner)                                 \
    default:                                                                                 \
       throw std::logic_error("Reached end of control flow in " #RATIO "_impl"); \
    }                                                                                        \
}

#define DISTANCE_IMPL_DEF(RATIO, RATIO_FUNC)            \
DISTANCE_IMPL_INNER(RATIO, RATIO_FUNC) \
DISTANCE_IMPL(      RATIO, RATIO_FUNC)



/* fuzz */
RATIO_IMPL_DEF(ratio,                    fuzz::ratio)
RATIO_IMPL_DEF(partial_ratio,            fuzz::partial_ratio)
RATIO_IMPL_DEF(token_sort_ratio,         fuzz::token_sort_ratio)
RATIO_IMPL_DEF(token_set_ratio,          fuzz::token_set_ratio)
RATIO_IMPL_DEF(token_ratio,              fuzz::token_ratio)
RATIO_IMPL_DEF(partial_token_sort_ratio, fuzz::partial_token_sort_ratio)
RATIO_IMPL_DEF(partial_token_set_ratio,  fuzz::partial_token_set_ratio)
RATIO_IMPL_DEF(partial_token_ratio,      fuzz::partial_token_ratio)
RATIO_IMPL_DEF(WRatio,                   fuzz::WRatio)
RATIO_IMPL_DEF(QRatio,                   fuzz::QRatio)

/* string_metric */
DISTANCE_IMPL_DEF(levenshtein,           string_metric::levenshtein)
RATIO_IMPL_DEF(normalized_levenshtein,   string_metric::normalized_levenshtein)
DISTANCE_IMPL_DEF(hamming,               string_metric::hamming)
RATIO_IMPL_DEF(normalized_hamming,       string_metric::normalized_hamming)

# undef X_ENUM

/* this macro generates the function definition for a simple normalized scorer
 * which only takes a score_cutoff
 */
#define SIMPLE_RATIO_DEF(RATIO)                                                     \
double RATIO##_func(const RapidFuzzString& s1, const RapidFuzzString& s2, double score_cutoff)      \
{                                                                                   \
    return RATIO##_impl(s1, s2, score_cutoff);                           \
}


/* this macro generates the function definition for a simple scorer
 * which only takes a max
 */
#define SIMPLE_DISTANCE_DEF(RATIO)                                            \
PyObject* RATIO##_func(const RapidFuzzString& s1, const RapidFuzzString& s2, size_t max)      \
{                                                                             \
    size_t result = RATIO##_impl(s1, s2, max); \
    return dist_to_long(result);                                                \
}
