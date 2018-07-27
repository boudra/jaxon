#include <stddef.h>
#include <stdint.h>

typedef enum {
    UNDEFINED,

    START_OBJECT,
    END_OBJECT,
    START_ARRAY,
    END_ARRAY,
    KEY,
    COLON,
    COMMA,
    STRING,
    INTEGER,
    DECIMAL,
    BOOLEAN,
    NIL,

    SYNTAX_ERROR,
    INCOMPLETE,
    INCOMPLETE_INTEGER,
    INCOMPLETE_DECIMAL,
    END
} json_event_type_t;

typedef struct {
    uint8_t* buffer;
    size_t size;
    size_t escapes;
} string_t;

typedef struct {
    json_event_type_t expected[5];
    unsigned char* context;
} syntax_error_t;

typedef union {
    string_t string;
    long int integer;
    double decimal;
    short boolean;
    syntax_error_t syntax_error;
} json_event_value_t;

typedef struct {
    json_event_type_t type;
    json_event_value_t value;
    json_event_value_t secondary_value;
} json_event_t;

typedef struct {
    unsigned char* buffer;
    unsigned char* cursor;
    unsigned char* last_token;
    size_t buffer_length;
} decoder_t;

void make_decoder(decoder_t* d);
void update_decoder_buffer(decoder_t* d, unsigned char* buf, size_t length);
void decode(decoder_t* d, json_event_t* e);
uint8_t* unescape_unicode(uint8_t*, uint8_t*, uint8_t*);

static inline const char* event_type_to_string(json_event_type_t type) {
    switch (type) {
        case STRING:
            return "string";

        case INTEGER:
            return "integer";

        case DECIMAL:
            return "decimal";

        case BOOLEAN:
            return "boolean";

        case NIL:
            return "null";

        case START_OBJECT:
            return "start_object";

        case START_ARRAY:
            return "start_array";

        case END_OBJECT:
            return "end_object";

        case END_ARRAY:
            return "end_array";

        case KEY:
            return "key";

        case UNDEFINED:
            return "undefined";

        case INCOMPLETE:
            return "incomplete";

        case INCOMPLETE_DECIMAL:
            return "incomplete decimal";

        case INCOMPLETE_INTEGER:
            return "incomplete integer";

        case END:
            return "end";

        case SYNTAX_ERROR:
            return "syntax_error";

        case COMMA:
            return "comma";

        case COLON:
            return ":";
    }
}

static inline const int32_t hex_byte_to_i32(const char in) {
    int8_t c = -1;
    if(in <= '9') {
        c = (in - '0');
    } else if (in >= 'A' && in <= 'F') {
        c = (in - 'A') + 10;
    } else if (in >= 'a' && in <= 'f') {
        c = (in - 'a') + 10;
    }
    return (int32_t)c;
}

static inline const size_t u32_size(const uint32_t in) {
    size_t num = 1;
    if(in >= 0x10000) {
        num = 4;
    } else if(in >= 0x800) {
        num = 3;
    } else if(in >= 0x80) {
        num = 2;
    }
    return num;
}

#define is_utf8(c) (((c) > 0x7f))

static inline const size_t u32_to_utf8(uint32_t in, uint8_t *out) {
    const size_t num = u32_size(in);
    out[0] = (in >> ((num - 1)*6));
    out[0] |= (0xff << (8 - num) & 0xff) * is_utf8(in);
    for(size_t i = 1; i < num; ++i) {
        out[i] = 0x80 + ((in >> ((num-i-1)*6)) & 0x3f);
    }
    return num;
}
