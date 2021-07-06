
#pragma once

#include <stdio.h>
#include <stdarg.h>

typedef enum {
    ANDROID_LOG_FATAL = 'F',
    ANDROID_LOG_ERROR = 'E',
    ANDROID_LOG_WARN = 'W',
    ANDROID_LOG_INFO = 'I',
    ANDROID_LOG_DEBUG = 'D',
    ANDROID_LOG_VERBOSE = 'V',
    ANDROID_LOG_UNKNOWN = '0'
} android_LogPriority;

inline void __android_log_print(android_LogPriority p, const char* tag, const char* format, ...) {
    printf("[%c] %10s ", p, tag);
    va_list _args;
    va_start(_args, format);
    vprintf(format, _args);
    va_end(_args);
    printf("\n");
}
