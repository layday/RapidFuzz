# distutils: language=c++
# cython: language_level=3
# cython: binding=True

from cpp_common cimport RapidFuzzPyObjectProcess, RapidFuzzStringDealloc, RapidFuzzString, is_valid_string, convert_string, hash_array, hash_sequence
from array import array
from libcpp.utility cimport move
from rapidfuzz_typeinfo cimport RapidFuzzProcess
from rapidfuzz_typeinfo import RapidFuzzProcess

cdef extern from "cpp_common.hpp":
    void validate_string(object py_str, const char* err) except +

cdef extern from "cpp_utils.hpp":
    object default_process_impl(object) nogil except +

    void process_dealloc_no_context(RapidFuzzString*) nogil
    RapidFuzzString default_process_func(RapidFuzzString) except+

cdef inline RapidFuzzString conv_sequence(seq) except *:
    if is_valid_string(seq):
        return move(convert_string(seq))
    elif isinstance(seq, array):
        return move(hash_array(seq))
    else:
        return move(hash_sequence(seq))

def default_process(sentence):
    """
    This function preprocesses a string by:
    - removing all non alphanumeric characters
    - trimming whitespaces
    - converting all characters to lower case
    
    Parameters
    ----------
    sentence : str
        String to preprocess
    
    Returns
    -------
    processed_string : str
        processed string
    """
    validate_string(sentence, "sentence must be a String")
    return default_process_impl(sentence)

cdef RapidFuzzString c_default_process(_str):
    return default_process_func(conv_sequence(_str))

cdef RapidFuzzProcess DefaultProcess = RapidFuzzProcess()
DefaultProcess.dealloc = process_dealloc_no_context
DefaultProcess.process = c_default_process
default_process.__RapidFuzzProcess = DefaultProcess


def no_process(sentence):
    return sentence

cdef RapidFuzzString c_no_process(_str):
    return conv_sequence(_str)

cdef RapidFuzzProcess NoProcess = RapidFuzzProcess()
NoProcess.dealloc = process_dealloc_no_context
NoProcess.process = c_no_process
no_process.__RapidFuzzProcess = NoProcess
