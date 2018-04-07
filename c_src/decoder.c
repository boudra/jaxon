#include "decoder.h"

#include <assert.h>
#include <string.h>
#include <stdlib.h>

#include <stdio.h>

#define is_space(c) (c == ' ' || c == '\n' || c == '\r' || c == '\t')
#define max(a,b) (((a)>(b))?(a):(b))

char* peek_until(char* buf, char c) {
  while (*buf != c) {
    buf++;
  }
  return buf;
}

char* skip_whitespace(char* buf) {
  while (is_space(*buf)) {
    buf++;
  }
  return buf;
}

void make_decoder(decoder_t* d) {
  d->buffer = NULL;
  d->cursor = NULL;
  d->last_token = NULL;
  d->last_event_type = UNDEFINED;
}

void update_decoder_buffer(decoder_t* d, char* buf) {
	if(d->last_event_type == END) {
		make_decoder(d);
	}

  d->buffer = buf;
  d->cursor = buf;
}

char* parse_string(char* buf) {
  while ((*buf != '"' && *buf != '\0')) {
		if(*buf == '\\') {
			buf++;
		}
    buf++;
  }
  return buf;
}

void syntax_error(decoder_t* d, json_event_t* e) {
  switch(d->last_event_type) {
    case KEY:
      e->type = SYNTAX_ERROR;
      e->value.syntax_error.expected[0] = COLON;
      e->value.syntax_error.expected[1] = UNDEFINED;
      e->value.syntax_error.context = max(d->cursor - 15, d->buffer);
      break;

    case START_OBJECT:
      e->type = SYNTAX_ERROR;
      e->value.syntax_error.expected[0] = KEY;
      e->value.syntax_error.expected[1] = END_OBJECT;
      e->value.syntax_error.expected[2] = UNDEFINED;
      e->value.syntax_error.context = max(d->cursor - 15, d->buffer);
      break;

    case START_ARRAY:
      e->type = SYNTAX_ERROR;
      e->value.syntax_error.expected[0] = VALUE;
      e->value.syntax_error.expected[1] = START_OBJECT;
      e->value.syntax_error.expected[2] = START_ARRAY;
      e->value.syntax_error.expected[3] = END_ARRAY;
      e->value.syntax_error.expected[4] = UNDEFINED;
      e->value.syntax_error.context = max(d->cursor - 15, d->buffer);
      break;

    case COLON:
      e->type = SYNTAX_ERROR;
      e->value.syntax_error.expected[0] = VALUE;
      e->value.syntax_error.expected[1] = START_OBJECT;
      e->value.syntax_error.expected[2] = START_ARRAY;
      e->value.syntax_error.expected[3] = UNDEFINED;
      e->value.syntax_error.context = max(d->cursor - 15, d->buffer);
      break;

    case END_ARRAY:
    case END_OBJECT:
    case VALUE:
      e->type = SYNTAX_ERROR;
      e->value.syntax_error.expected[0] = COMMA;
      e->value.syntax_error.expected[1] = END_OBJECT;
      e->value.syntax_error.expected[2] = END_ARRAY;
      e->value.syntax_error.expected[3] = UNDEFINED;
      e->value.syntax_error.context = max(d->cursor - 10, d->buffer);
      break;

    default:
      e->type = SYNTAX_ERROR;
      break;
  }
}

void decode(decoder_t* d, json_event_t* e) {
  d->cursor = skip_whitespace(d->cursor);
  d->last_token = d->cursor;

  /* printf("buffer: %5s\n\n", d->cursor); */

  switch(*d->cursor) {
    case '{':
      d->cursor++;

      e->type = START_OBJECT;
      d->last_event_type = START_OBJECT;
      break;

    case '}':
      if(d->last_event_type != END_OBJECT && d->last_event_type != END_ARRAY && d->last_event_type != VALUE && d->last_event_type != START_OBJECT) {
        syntax_error(d, e);
      } else {
        e->type = END_OBJECT;
        d->cursor++;
      }
      d->last_event_type = e->type;
      break;

    case ':':
      d->cursor++;

      if(d->last_event_type != KEY) {
        syntax_error(d, e);
      } else {
        d->last_event_type = COLON;
        decode(d, e);
      }
      break;

    case '[':
      e->type = START_ARRAY;
      d->cursor++;
      d->last_event_type = e->type;
      break;

    case ']':
      e->type = END_ARRAY;
      d->cursor++;
      d->last_event_type = e->type;
      break;

    case '\0':
      e->type = END;
      d->last_event_type = e->type;
      break;

    case ',':
      d->cursor++;
      d->last_event_type = COMMA;
      decode(d, e);
      break;

    case '-':
    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
      {
        char *number_end = *d->cursor == '-' ? ++d->cursor : d->cursor;

        while ((*number_end >= '0' && *number_end <= '9') || *number_end == '.') {
          number_end++;
        }

        const json_event_value_t number_value = {
          .string = {
            .buffer = d->cursor,
            .size = (number_end - d->cursor)
          }
        };

        e->type = VALUE;
        d->cursor = number_end;
        e->value = number_value;
        d->last_event_type = e->type;
        break;
      }

    case 'n':
			if(strncmp(d->cursor, "null", 4) == 0) {
				e->type = VALUE;
				e->value.string.buffer = d->cursor;
				e->value.string.size = 4;
				d->last_event_type = e->type;
				d->cursor += 4;
			}
			break;

    case 't':
			if(strncmp(d->cursor, "true", 4) == 0) {
				e->type = VALUE;
				e->value.string.buffer = d->cursor;
				e->value.string.size = 4;
				d->last_event_type = e->type;
				d->cursor += 4;
			}
			break;

    case 'f':
			if(strncmp(d->cursor, "false", 5) == 0) {
				e->type = VALUE;
				e->value.string.buffer = d->cursor;
				e->value.string.size = 5;
				d->last_event_type = e->type;
				d->cursor += 5;
			}
			break;

    case '"':
      {
        char* string_end = parse_string(++d->cursor);

        if(*string_end == '\0') {
          e->type = INCOMPLETE;
          e->value.string.buffer = d->last_token;
          e->value.string.size = string_end - d->last_token;
        } else {
          const json_event_value_t value = {
            .string = {
              .buffer = d->cursor,
              .size = (string_end - d->cursor)
            }
          };

					d->cursor = skip_whitespace(++string_end);

					if(*d->cursor == ':') {
            e->type = KEY;
            d->cursor = string_end;
					} else {
            e->type = VALUE;
            d->cursor = string_end;
					}

          e->value = value;
          d->last_event_type = e->type;
        }

        break;
      }

    default:
			syntax_error(d, e);
      break;
  }
}
