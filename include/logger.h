#pragma once

#include <sstream>

#ifdef __ANDROID__
#include <android/log.h>
#else
#include "printf_logger.h"
#endif

namespace plog {

    enum Severity {
        none = 0,
        fatal = 1,
        error = 2,
        warning = 3,
        info = 4,
        debug = 5,
        verbose = 6
    };

    /**********************************************************************/

    class Record {
    public:
        Record(Severity severity) : m_severity(severity), m_tag() {}

        Record(Record &&other) :
                m_severity(other.m_severity),
                m_tag(other.m_tag) {
            m_message = std::move(other.m_message);
        }

        Record &operator<<(std::ostream &(*data)(std::ostream &)) {
            m_message << data;
            return *this;
        }

        template<typename T>
        Record &operator<<(const T &data) {
            using namespace plog;
            m_message << data;
            return *this;
        }

        Severity severity() const {
            return m_severity;
        }

        std::string str() const {
            return m_message.str();
        }

        virtual ~Record() {
        }

    private:
        const Severity m_severity;
        const std::string m_tag;
        std::ostringstream m_message;
    };

    /**********************************************************************/

    class TaggedRecord;

    class IAppender {
    public:
        virtual ~IAppender() {
        }

        virtual void write(const TaggedRecord &record) const = 0;
    };

    /**********************************************************************/

    class TaggedRecord : public Record {
    public:
        TaggedRecord(const Severity severity, const std::string tag, const IAppender &appender)
                : Record(severity), m_tag(tag), m_appender(appender) {}

        TaggedRecord(TaggedRecord &&other)
                : Record(other.severity()), m_tag(other.m_tag), m_appender(other.m_appender) {
        }

        std::string tag() const {
            return m_tag;
        }

        virtual ~TaggedRecord() {
            m_appender.write(*this);
        }

    private:
        const std::string m_tag;
        const IAppender &m_appender;
    };

    /**********************************************************************/

    class LoggerOutput {
    public:
        LoggerOutput(const Severity severity, const IAppender &appender)
                : m_severity(severity), m_appender(appender) {}

        TaggedRecord operator<<(const char *tag) const {
            return TaggedRecord(m_severity, tag, m_appender);
        }

    private:
        const Severity m_severity;
        const IAppender &m_appender;
    };

    /**********************************************************************/

    class AndroidAppender : public IAppender {
    public:
        virtual void write(const TaggedRecord &record) const {
            std::string str = record.str();
            __android_log_print(
                    toPriority(record.severity()),
                    record.tag().c_str(),
                    "%s", str.c_str());
        }

    private:
        static android_LogPriority toPriority(Severity severity) {
            switch (severity) {
                case fatal:
                    return ANDROID_LOG_FATAL;
                case error:
                    return ANDROID_LOG_ERROR;
                case warning:
                    return ANDROID_LOG_WARN;
                case info:
                    return ANDROID_LOG_INFO;
                case debug:
                    return ANDROID_LOG_DEBUG;
                case verbose:
                    return ANDROID_LOG_VERBOSE;
                default:
                    return ANDROID_LOG_UNKNOWN;
            }
        }
    };

    /**********************************************************************/

    static AndroidAppender appender{};
    static LoggerOutput log_fatal{fatal, appender};
    static LoggerOutput log_error{error, appender};
    static LoggerOutput log_warn{warning, appender};
    static LoggerOutput log_info{info, appender};
    static LoggerOutput log_debug{debug, appender};
    static LoggerOutput log_verb{verbose, appender};

}

#define LOGD(F, ...) __android_log_print(ANDROID_LOG_DEBUG, "native-lib", F,  __VA_ARGS__)
#define LOGE(F, ...) __android_log_print(ANDROID_LOG_WARN, "native-lib", F,  __VA_ARGS__)
