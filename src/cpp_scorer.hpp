#include "cpp_common.hpp"


double cpp_ratio(const proc_string& s1, const proc_string& s2, double score_cutoff)
{                                                                                   
    return ratio_impl(s1, s2, score_cutoff);                           
}

double cpp_partial_ratio(const proc_string& s1, const proc_string& s2, double score_cutoff)
{                                                                                   
    return partial_ratio_impl(s1, s2, score_cutoff);                           
}

double cpp_token_sort_ratio(const proc_string& s1, const proc_string& s2, double score_cutoff)
{                                                                                   
    return token_sort_ratio_impl(s1, s2, score_cutoff);                           
}

double cpp_token_set_ratio(const proc_string& s1, const proc_string& s2, double score_cutoff)
{                                                                                   
    return token_set_ratio_impl(s1, s2, score_cutoff);                           
}

double cpp_token_ratio(const proc_string& s1, const proc_string& s2, double score_cutoff)
{                                                                                   
    return token_ratio_impl(s1, s2, score_cutoff);                           
}

double cpp_partial_token_sort_ratio(const proc_string& s1, const proc_string& s2, double score_cutoff)
{                                                                                   
    return partial_token_sort_ratio_impl(s1, s2, score_cutoff);                           
}

double cpp_partial_token_set_ratio(const proc_string& s1, const proc_string& s2, double score_cutoff)
{                                                                                   
    return partial_token_set_ratio_impl(s1, s2, score_cutoff);                           
}

double cpp_partial_token_ratio(const proc_string& s1, const proc_string& s2, double score_cutoff)
{                                                                                   
    return partial_token_ratio_impl(s1, s2, score_cutoff);                           
}

double cpp_WRatio(const proc_string& s1, const proc_string& s2, double score_cutoff)
{                                                                                   
    return WRatio_impl(s1, s2, score_cutoff);                           
}

double cpp_QRatio(const proc_string& s1, const proc_string& s2, double score_cutoff)
{                                                                                   
    return QRatio_impl(s1, s2, score_cutoff);                           
}

double cpp_normalized_hamming(const proc_string& s1, const proc_string& s2, double score_cutoff)
{                                                                                   
    return normalized_hamming_impl(s1, s2, score_cutoff);                           
}

double cpp_jaro_similarity(const proc_string& s1, const proc_string& s2, double score_cutoff)
{                                                                                   
    return jaro_similarity_impl(s1, s2, score_cutoff);                           
}

PyObject* cpp_hamming(const proc_string& s1, const proc_string& s2, size_t max)
{
    size_t result = hamming_impl(s1, s2, max);
    return dist_to_long(result);
}

PyObject* cpp_levenshtein(const proc_string& s1, const proc_string& s2,
    size_t insertion, size_t deletion, size_t substitution, size_t max)
{
    rapidfuzz::LevenshteinWeightTable weights = {insertion, deletion, substitution};

    size_t result = levenshtein_impl(s1, s2, weights, max);
    return dist_to_long(result);
}

double cpp_normalized_levenshtein(const proc_string& s1, const proc_string& s2,
    size_t insertion, size_t deletion, size_t substitution, double score_cutoff)
{
    rapidfuzz::LevenshteinWeightTable weights = {insertion, deletion, substitution};

    return normalized_levenshtein_impl(s1, s2, weights, score_cutoff);
}

double cpp_jaro_winkler_similarity(const proc_string& s1, const proc_string& s2,
    double prefix_weight, double score_cutoff)
{
    return jaro_winkler_similarity_impl(s1, s2, prefix_weight, score_cutoff);
}

# define X_ENUM(KIND, TYPE, RATIO_FUNC) \
    case KIND: return RATIO_FUNC(s2, no_process<TYPE>(s1));

template<typename Sentence>
std::vector<rapidfuzz::LevenshteinEditOp>
levenshtein_editops_inner(const proc_string& s1, const Sentence& s2)
{
    switch(s1.kind){
    LIST_OF_CASES(string_metric::levenshtein_editops)
    }          
}

std::vector<rapidfuzz::LevenshteinEditOp>
cpp_levenshtein_editops(const proc_string& s1, const proc_string& s2)
{
    switch(s1.kind){
    LIST_OF_CASES(levenshtein_editops_inner)
    }          
}

# undef X_ENUM
