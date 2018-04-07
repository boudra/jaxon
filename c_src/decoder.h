#include <stddef.h>

typedef enum {
  UNDEFINED,

  START_OBJECT,
  END_OBJECT,
  START_ARRAY,
  END_ARRAY,
  KEY,
  COLON,
  COMMA,
  VALUE,

  SYNTAX_ERROR,
  INCOMPLETE,
  END
} json_event_type_t;

typedef struct {
  char* buffer;
  size_t size;
} string_t;

typedef struct {
  json_event_type_t expected[5];
  char* context;
} syntax_error_t;

typedef union {
  string_t string;
  syntax_error_t syntax_error;
} json_event_value_t;

typedef struct {
  json_event_type_t type;
  json_event_value_t value;
} json_event_t;

typedef struct {
  char* buffer;
  char* cursor;
  char* last_token;
  json_event_type_t last_event_type;
} decoder_t;

void make_decoder(decoder_t* d);
void update_decoder_buffer(decoder_t* d, char* buf);
void decode(decoder_t* d, json_event_t* e);

static inline const char* event_type_to_string(json_event_type_t type) {
  switch (type) {
    case VALUE:
      return "value";

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
