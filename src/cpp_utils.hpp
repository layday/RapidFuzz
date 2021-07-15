#include "cpp_common.hpp"

PyObject* default_process_impl(PyObject* sentence) {
    RapidFuzzString c_sentence = convert_string(sentence);

    switch (c_sentence.kind) {
    case RAPIDFUZZ_UINT8:
    {
        auto proc_str = utils::default_process(
            rapidfuzz::basic_string_view<uint8_t>(static_cast<uint8_t*>(c_sentence.data), c_sentence.length));
        return PyUnicode_FromKindAndData(PyUnicode_1BYTE_KIND, proc_str.data(), (Py_ssize_t)proc_str.size());
    }
    case RAPIDFUZZ_UINT16:
    {
        auto proc_str = utils::default_process(
            rapidfuzz::basic_string_view<uint16_t>(static_cast<uint16_t*>(c_sentence.data), c_sentence.length));
        return PyUnicode_FromKindAndData(PyUnicode_2BYTE_KIND, proc_str.data(), (Py_ssize_t)proc_str.size());
    }
    case RAPIDFUZZ_UINT32:
    {
        auto proc_str = utils::default_process(
            rapidfuzz::basic_string_view<uint32_t>(static_cast<uint32_t*>(c_sentence.data), c_sentence.length));
        return PyUnicode_FromKindAndData(PyUnicode_4BYTE_KIND, proc_str.data(), (Py_ssize_t)proc_str.size());
    }
    // ToDo: for now do not process these elements should be done in some way in the future
    // negative and > uint32 are not relevant, so it should be possible to convert the input string to the unsigned version / uint32_t
    // and process this version
    default:
        return sentence;
    }
}

template <typename CharT>
RapidFuzzString default_process_impl(RapidFuzzString sentence) {
    RapidFuzzString proc_sentence;
    CharT* str = static_cast<CharT*>(sentence.data);
    if (!sentence.allocated)
    {
      CharT* temp_str = (CharT*)malloc(sentence.length * sizeof(CharT));
      if (temp_str == NULL)
      {
          throw std::bad_alloc();
      }
      std::copy(str, str + sentence.length, temp_str);
      str = temp_str;
    }

    proc_sentence.context = nullptr;
    proc_sentence.allocated = true;
    proc_sentence.data = str;
    proc_sentence.kind = sentence.kind;
    proc_sentence.length = utils::default_process(str, sentence.length);

    return proc_sentence;
}

RapidFuzzString default_process_func(RapidFuzzString sentence) {
    switch (sentence.kind) {
    # define X_ENUM(KIND, TYPE, MSVC_TUPLE) case KIND: return default_process_impl<TYPE>(std::move(sentence));
    LIST_OF_CASES()
    default:
       throw std::logic_error("Reached end of control flow in default_process_impl");
    # undef X_ENUM
    }
}

void process_dealloc_no_context(RapidFuzzString* sentence)
{
    if (sentence->allocated)
    {
        free(sentence->data);
        sentence->data = nullptr;
        sentence->allocated = false;
        sentence->length = 0;
        sentence->context = nullptr;
    }
}

