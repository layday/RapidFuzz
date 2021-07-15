# distutils: language=c++
# cython: language_level=3
# cython: binding=True

from rapidfuzz.utils import default_process, no_process
from cpp_common cimport is_valid_string, convert_string, hash_array, hash_sequence, RapidFuzzString, ProcStringWrapper
from array import array
from libcpp.utility cimport move

from rapidfuzz_typeinfo cimport RapidFuzzProcess

cdef extern from "cpp_scorer.hpp":
    double ratio_func(                    const RapidFuzzString&, const RapidFuzzString&, double) nogil except +
    double partial_ratio_func(            const RapidFuzzString&, const RapidFuzzString&, double) nogil except +
    double token_sort_ratio_func(         const RapidFuzzString&, const RapidFuzzString&, double) nogil except +
    double token_set_ratio_func(          const RapidFuzzString&, const RapidFuzzString&, double) nogil except +
    double token_ratio_func(              const RapidFuzzString&, const RapidFuzzString&, double) nogil except +
    double partial_token_sort_ratio_func( const RapidFuzzString&, const RapidFuzzString&, double) nogil except +
    double partial_token_set_ratio_func(  const RapidFuzzString&, const RapidFuzzString&, double) nogil except +
    double partial_token_ratio_func(      const RapidFuzzString&, const RapidFuzzString&, double) nogil except +
    double partial_token_ratio_func(      const RapidFuzzString&, const RapidFuzzString&, double) nogil except +
    double WRatio_func(                   const RapidFuzzString&, const RapidFuzzString&, double) nogil except +
    double QRatio_func(                   const RapidFuzzString&, const RapidFuzzString&, double) nogil except +

cdef RapidFuzzProcess DefaultProcess = default_process.__RapidFuzzProcess
cdef RapidFuzzProcess NoProcess = no_process.__RapidFuzzProcess

cdef RapidFuzzProcess getProcessor(processor):
    if processor is True:
        return DefaultProcess
    else:
        return getattr(processor, "__RapidFuzzProcess", None)

def ratio(s1, s2, processor=None, score_cutoff=None):
    """
    calculates a simple ratio between two strings. This is a simple wrapper
    for string_metric.normalized_levenshtein using the weights:
    - weights = (1, 1, 2)

    Parameters
    ----------
    s1 : str
        First string to compare.
    s2 : str
        Second string to compare.
    processor: bool or callable, optional
        Optional callable that is used to preprocess the strings before
        comparing them. When processor is True ``utils.default_process``
        is used. Default is None, which deactivates this behaviour.
    score_cutoff : float, optional
        Optional argument for a score threshold as a float between 0 and 100.
        For ratio < score_cutoff 0 is returned instead. Default is 0,
        which deactivates this behaviour.

    Returns
    -------
    similarity : float
        similarity between s1 and s2 as a float between 0 and 100

    Notes
    -----
    .. image:: img/ratio.svg

    Examples
    --------
    >>> fuzz.ratio("this is a test", "this is a test!")
    96.55171966552734
    """
    cdef double c_score_cutoff = 0.0 if score_cutoff is None else score_cutoff
    c_processor = getProcessor(processor)

    if s1 is None or s2 is None:
        return 0
    
    if c_processor is None:
        c_processor = NoProcess
        if callable(processor):
            s1 = processor(s1)
            s2 = processor(s2)

    proc_s1 = ProcStringWrapper(s1, c_processor.process, c_processor.dealloc)
    proc_s2 = ProcStringWrapper(s2, c_processor.process, c_processor.dealloc)

    return ratio_func(proc_s1.str, proc_s2.str, c_score_cutoff)


def partial_ratio(s1, s2, processor=None, score_cutoff=None):
    """
    calculates the fuzz.ratio of the optimal string alignment

    Parameters
    ----------
    s1 : str
        First string to compare.
    s2 : str
        Second string to compare.
    processor: bool or callable, optional
        Optional callable that is used to preprocess the strings before
        comparing them. When processor is True ``utils.default_process``
        is used. Default is None, which deactivates this behaviour.
    score_cutoff : float, optional
        Optional argument for a score threshold as a float between 0 and 100.
        For ratio < score_cutoff 0 is returned instead. Default is 0,
        which deactivates this behaviour.

    Returns
    -------
    similarity : float
        similarity between s1 and s2 as a float between 0 and 100

    Notes
    -----
    .. image:: img/partial_ratio.svg

    Examples
    --------
    >>> fuzz.partial_ratio("this is a test", "this is a test!")
    100.0
    """
    cdef double c_score_cutoff = 0.0 if score_cutoff is None else score_cutoff
    c_processor = getProcessor(processor)

    if s1 is None or s2 is None:
        return 0

    if c_processor is None:
        c_processor = NoProcess
        if callable(processor):
            s1 = processor(s1)
            s2 = processor(s2)

    proc_s1 = ProcStringWrapper(s1, c_processor.process, c_processor.dealloc)
    proc_s2 = ProcStringWrapper(s2, c_processor.process, c_processor.dealloc)

    return partial_ratio_func(proc_s1.str, proc_s2.str, c_score_cutoff)

def token_sort_ratio(s1, s2, processor=True, score_cutoff=None):
    """
    sorts the words in the strings and calculates the fuzz.ratio between them

    Parameters
    ----------
    s1 : str
        First string to compare.
    s2 : str
        Second string to compare.
    processor: bool or callable, optional
        Optional callable that is used to preprocess the strings before
        comparing them. When processor is True ``utils.default_process``
        is used. Default is True.
    score_cutoff : float, optional
        Optional argument for a score threshold as a float between 0 and 100.
        For ratio < score_cutoff 0 is returned instead. Default is 0,
        which deactivates this behaviour.

    Returns
    -------
    similarity : float
        similarity between s1 and s2 as a float between 0 and 100

    Notes
    -----
    .. image:: img/token_sort_ratio.svg

    Examples
    --------
    >>> fuzz.token_sort_ratio("fuzzy wuzzy was a bear", "wuzzy fuzzy was a bear")
    100.0
    """
    cdef double c_score_cutoff = 0.0 if score_cutoff is None else score_cutoff
    c_processor = getProcessor(processor)

    if s1 is None or s2 is None:
        return 0

    if c_processor is None:
        c_processor = NoProcess
        if callable(processor):
            s1 = processor(s1)
            s2 = processor(s2)

    proc_s1 = ProcStringWrapper(s1, c_processor.process, c_processor.dealloc)
    proc_s2 = ProcStringWrapper(s2, c_processor.process, c_processor.dealloc)

    return token_sort_ratio_func(proc_s1.str, proc_s2.str, c_score_cutoff)


def token_set_ratio(s1, s2, processor=True, score_cutoff=None):
    """
    Compares the words in the strings based on unique and common words between them
    using fuzz.ratio

    Parameters
    ----------
    s1 : str
        First string to compare.
    s2 : str
        Second string to compare.
    processor: bool or callable, optional
        Optional callable that is used to preprocess the strings before
        comparing them. When processor is True ``utils.default_process``
        is used. Default is True.
    score_cutoff : float, optional
        Optional argument for a score threshold as a float between 0 and 100.
        For ratio < score_cutoff 0 is returned instead. Default is 0,
        which deactivates this behaviour.

    Returns
    -------
    similarity : float
        similarity between s1 and s2 as a float between 0 and 100

    Notes
    -----
    .. image:: img/token_set_ratio.svg

    Examples
    --------
    >>> fuzz.token_sort_ratio("fuzzy was a bear", "fuzzy fuzzy was a bear")
    83.8709716796875
    >>> fuzz.token_set_ratio("fuzzy was a bear", "fuzzy fuzzy was a bear")
    100.0
    """
    cdef double c_score_cutoff = 0.0 if score_cutoff is None else score_cutoff
    c_processor = getProcessor(processor)

    if s1 is None or s2 is None:
        return 0

    if c_processor is None:
        c_processor = NoProcess
        if callable(processor):
            s1 = processor(s1)
            s2 = processor(s2)

    proc_s1 = ProcStringWrapper(s1, c_processor.process, c_processor.dealloc)
    proc_s2 = ProcStringWrapper(s2, c_processor.process, c_processor.dealloc)

    return token_set_ratio_func(proc_s1.str, proc_s2.str, c_score_cutoff)


def token_ratio(s1, s2, processor=True, score_cutoff=None):
    """
    Helper method that returns the maximum of fuzz.token_set_ratio and fuzz.token_sort_ratio
    (faster than manually executing the two functions)

    Parameters
    ----------
    s1 : str
        First string to compare.
    s2 : str
        Second string to compare.
    processor: bool or callable, optional
        Optional callable that is used to preprocess the strings before
        comparing them. When processor is True ``utils.default_process``
        is used. Default is True.
    score_cutoff : float, optional
        Optional argument for a score threshold as a float between 0 and 100.
        For ratio < score_cutoff 0 is returned instead. Default is 0,
        which deactivates this behaviour.

    Returns
    -------
    similarity : float
        similarity between s1 and s2 as a float between 0 and 100

    Notes
    -----
    .. image:: img/token_ratio.svg
    """
    cdef double c_score_cutoff = 0.0 if score_cutoff is None else score_cutoff
    c_processor = getProcessor(processor)

    if s1 is None or s2 is None:
        return 0

    if c_processor is None:
        c_processor = NoProcess
        if callable(processor):
            s1 = processor(s1)
            s2 = processor(s2)

    proc_s1 = ProcStringWrapper(s1, c_processor.process, c_processor.dealloc)
    proc_s2 = ProcStringWrapper(s2, c_processor.process, c_processor.dealloc)

    return token_ratio_func(proc_s1.str, proc_s2.str, c_score_cutoff)


def partial_token_sort_ratio(s1, s2, processor=True, score_cutoff=None):
    """
    sorts the words in the strings and calculates the fuzz.partial_ratio between them

    Parameters
    ----------
    s1 : str
        First string to compare.
    s2 : str
        Second string to compare.
    processor: bool or callable, optional
        Optional callable that is used to preprocess the strings before
        comparing them. When processor is True ``utils.default_process``
        is used. Default is True.
    score_cutoff : float, optional
        Optional argument for a score threshold as a float between 0 and 100.
        For ratio < score_cutoff 0 is returned instead. Default is 0,
        which deactivates this behaviour.

    Returns
    -------
    similarity : float
        similarity between s1 and s2 as a float between 0 and 100

    Notes
    -----
    .. image:: img/partial_token_sort_ratio.svg
    """
    cdef double c_score_cutoff = 0.0 if score_cutoff is None else score_cutoff
    c_processor = getProcessor(processor)

    if s1 is None or s2 is None:
        return 0

    if c_processor is None:
        c_processor = NoProcess
        if callable(processor):
            s1 = processor(s1)
            s2 = processor(s2)

    proc_s1 = ProcStringWrapper(s1, c_processor.process, c_processor.dealloc)
    proc_s2 = ProcStringWrapper(s2, c_processor.process, c_processor.dealloc)

    return partial_token_sort_ratio_func(proc_s1.str, proc_s2.str, c_score_cutoff)


def partial_token_set_ratio(s1, s2, processor=True, score_cutoff=None):
    """
    Compares the words in the strings based on unique and common words between them
    using fuzz.partial_ratio

    Parameters
    ----------
    s1 : str
        First string to compare.
    s2 : str
        Second string to compare.
    processor: bool or callable, optional
        Optional callable that is used to preprocess the strings before
        comparing them. When processor is True ``utils.default_process``
        is used. Default is True.
    score_cutoff : float, optional
        Optional argument for a score threshold as a float between 0 and 100.
        For ratio < score_cutoff 0 is returned instead. Default is 0,
        which deactivates this behaviour.

    Returns
    -------
    similarity : float
        similarity between s1 and s2 as a float between 0 and 100

    Notes
    -----
    .. image:: img/partial_token_set_ratio.svg
    """
    cdef double c_score_cutoff = 0.0 if score_cutoff is None else score_cutoff
    c_processor = getProcessor(processor)

    if s1 is None or s2 is None:
        return 0

    if c_processor is None:
        c_processor = NoProcess
        if callable(processor):
            s1 = processor(s1)
            s2 = processor(s2)

    proc_s1 = ProcStringWrapper(s1, c_processor.process, c_processor.dealloc)
    proc_s2 = ProcStringWrapper(s2, c_processor.process, c_processor.dealloc)

    return partial_token_set_ratio_func(proc_s1.str, proc_s2.str, c_score_cutoff)


def partial_token_ratio(s1, s2, processor=True, score_cutoff=None):
    """
    Helper method that returns the maximum of fuzz.partial_token_set_ratio and
    fuzz.partial_token_sort_ratio (faster than manually executing the two functions)

    Parameters
    ----------
    s1 : str
        First string to compare.
    s2 : str
        Second string to compare.
    processor: bool or callable, optional
        Optional callable that is used to preprocess the strings before
        comparing them. When processor is True ``utils.default_process``
        is used. Default is True.
    score_cutoff : float, optional
        Optional argument for a score threshold as a float between 0 and 100.
        For ratio < score_cutoff 0 is returned instead. Default is 0,
        which deactivates this behaviour.

    Returns
    -------
    similarity : float
        similarity between s1 and s2 as a float between 0 and 100

    Notes
    -----
    .. image:: img/partial_token_ratio.svg
    """
    cdef double c_score_cutoff = 0.0 if score_cutoff is None else score_cutoff
    c_processor = getProcessor(processor)

    if s1 is None or s2 is None:
        return 0

    if c_processor is None:
        c_processor = NoProcess
        if callable(processor):
            s1 = processor(s1)
            s2 = processor(s2)

    proc_s1 = ProcStringWrapper(s1, c_processor.process, c_processor.dealloc)
    proc_s2 = ProcStringWrapper(s2, c_processor.process, c_processor.dealloc)

    return partial_token_ratio_func(proc_s1.str, proc_s2.str, c_score_cutoff)


def WRatio(s1, s2, processor=True, score_cutoff=None):
    """
    Calculates a weighted ratio based on the other ratio algorithms

    Parameters
    ----------
    s1 : str
        First string to compare.
    s2 : str
        Second string to compare.
    processor: bool or callable, optional
        Optional callable that is used to preprocess the strings before
        comparing them. When processor is True ``utils.default_process``
        is used. Default is True.
    score_cutoff : float, optional
        Optional argument for a score threshold as a float between 0 and 100.
        For ratio < score_cutoff 0 is returned instead. Default is 0,
        which deactivates this behaviour.

    Returns
    -------
    similarity : float
        similarity between s1 and s2 as a float between 0 and 100

    Notes
    -----
    .. image:: img/WRatio.svg
    """
    cdef double c_score_cutoff = 0.0 if score_cutoff is None else score_cutoff
    c_processor = getProcessor(processor)

    if s1 is None or s2 is None:
        return 0

    if c_processor is None:
        c_processor = NoProcess
        if callable(processor):
            s1 = processor(s1)
            s2 = processor(s2)

    proc_s1 = ProcStringWrapper(s1, c_processor.process, c_processor.dealloc)
    proc_s2 = ProcStringWrapper(s2, c_processor.process, c_processor.dealloc)

    return WRatio_func(proc_s1.str, proc_s2.str, c_score_cutoff)


def QRatio(s1, s2, processor=True, score_cutoff=None):
    """
    Calculates a quick ratio between two strings using fuzz.ratio.
    The only difference to fuzz.ratio is, that this preprocesses
    the strings by default.

    Parameters
    ----------
    s1 : str
        First string to compare.
    s2 : str
        Second string to compare.
    processor: bool or callable, optional
        Optional callable that is used to preprocess the strings before
        comparing them. When processor is True ``utils.default_process``
        is used. Default is True.
    score_cutoff : float, optional
        Optional argument for a score threshold as a float between 0 and 100.
        For ratio < score_cutoff 0 is returned instead. Default is 0,
        which deactivates this behaviour.

    Returns
    -------
    similarity : float
        similarity between s1 and s2 as a float between 0 and 100

    Examples
    --------
    >>> fuzz.QRatio("this is a test", "THIS is a test!")
    100.0
    """
    cdef double c_score_cutoff = 0.0 if score_cutoff is None else score_cutoff
    c_processor = getProcessor(processor)

    if s1 is None or s2 is None:
        return 0

    if c_processor is None:
        c_processor = NoProcess
        if callable(processor):
            s1 = processor(s1)
            s2 = processor(s2)

    proc_s1 = ProcStringWrapper(s1, c_processor.process, c_processor.dealloc)
    proc_s2 = ProcStringWrapper(s2, c_processor.process, c_processor.dealloc)

    return QRatio_func(proc_s1.str, proc_s2.str, c_score_cutoff)
