#include "decoder.h"

#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

#include <stdio.h>

#define is_space(c) (c == ' ' || c == '\n' || c == '\r' || c == '\t')
#define max(a,b) (((a)>(b))?(a):(b))
#define min(a,b) (((a)<(b))?(a):(b))

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
    d->pair_count = 0;
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
            ++buf;
            if(*buf == '\0') {
                break;
            }
        }
        buf++;
    }
    return buf;
}

int parse_constant(char** constant, const char *find) {
    const char *find_cursor = find;

    while(**constant != '\0' && **constant == *find_cursor) {
        ++*constant;
        ++find_cursor;
    }

    return (*find_cursor == '\0');
}

void syntax_error(decoder_t* d, json_event_t* e) {
    const size_t context_length = 30;
    char* context = max(d->cursor - context_length, d->buffer);

    e->type = SYNTAX_ERROR;
    e->value.string.buffer = context;
    e->value.string.size = min(strlen(context), context_length);
}

void decode(decoder_t* d, json_event_t* e) {
    d->cursor = skip_whitespace(d->cursor);
    d->last_token = d->cursor;

    /* printf("buffer: `%s`\n", d->cursor); */

    switch(*d->cursor) {
        case '{':
            d->cursor++;

            e->type = START_OBJECT;
            d->last_event_type = START_OBJECT;
            d->pair_count++;
            break;

        case '}':
            if(d->last_event_type != END_OBJECT &&
                    d->last_event_type != END_ARRAY &&
                    d->last_event_type != STRING &&
                    d->last_event_type != INTEGER &&
                    d->last_event_type != BOOLEAN &&
                    d->last_event_type != DECIMAL &&
                    d->last_event_type != NIL &&
                    d->last_event_type != BOOLEAN &&
                    d->last_event_type != START_OBJECT) {
                syntax_error(d, e);
            } else {
                e->type = END_OBJECT;
                d->cursor++;
                d->pair_count--;
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
            d->pair_count++;
            d->last_event_type = e->type;
            break;

        case ']':
            e->type = END_ARRAY;
            d->cursor++;
            d->pair_count--;
            d->last_event_type = e->type;
            break;

        case '\0':
            if(d->pair_count > 0) {
                e->type = INCOMPLETE;
                e->value.string.buffer = d->last_token;
                e->value.string.size = 0;
            } else if(d->last_event_type == KEY) {
                syntax_error(d, e);
            } else {
                e->type = END;
                d->last_event_type = e->type;
            }
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
                char *number_end = NULL;
                double fn = strtod(d->cursor, &number_end);
                unsigned long fl = ceil(fn);


                /* while (*number_end != '\0' && ((*number_end >= '0' && *number_end <= '9') || *number_end == '.')) { */
                /* 	if(*number_end == '.') { */
                /* 		decimal = 1; */
                /* 	} */
                /*   number_end++; */
                /* } */

                if(*number_end == '\0') {
                    e->type = INCOMPLETE;
                    e->value.string.buffer = d->last_token;
                    e->value.string.size = number_end - d->last_token;
                } else if (number_end == d->cursor) {
                    e->type = UNDEFINED;
                } else if(fn == fl) {
                    e->type = INTEGER;
                    e->value.integer = fl;
                    d->last_event_type = e->type;
                    d->cursor = number_end;
                } else {
                    e->type = DECIMAL;
                    e->value.decimal = fn;
                    d->last_event_type = e->type;
                    d->cursor = number_end;
                    /* e->type = STRING; */
                    /* e->value.string.buffer = d->last_token; */
                    /* e->value.string.size = number_end - d->last_token; */
                }

                break;
            }

        case 'n':
            {
                char* constant_end = d->cursor;

                if(parse_constant(&constant_end, "null")) {
                    e->type = NIL;
                    d->last_event_type = e->type;
                    d->cursor = constant_end;
                } else if(*constant_end == '\0') {
                    e->type = INCOMPLETE;
                    e->value.string.buffer = d->last_token;
                    e->value.string.size = constant_end - d->last_token;
                }
            }

            break;

        case 't':
            {
                char* constant_end = d->cursor;

                if(parse_constant(&constant_end, "true")) {
                    e->type = BOOLEAN;
                    e->value.boolean = 1;
                    d->last_event_type = e->type;
                    d->cursor = constant_end;
                } else if(*constant_end == '\0') {
                    e->type = INCOMPLETE;
                    e->value.string.buffer = d->last_token;
                    e->value.string.size = constant_end - d->last_token;
                }
            }
            break;

        case 'f':
            {
                char* constant_end = d->cursor;

                if(parse_constant(&constant_end, "false")) {
                    e->type = BOOLEAN;
                    e->value.boolean = 0;
                    d->last_event_type = e->type;
                    d->cursor = constant_end;
                } else if(*constant_end == '\0') {
                    e->type = INCOMPLETE;
                    e->value.string.buffer = d->last_token;
                    e->value.string.size = constant_end - d->last_token;
                }
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
                    e->value.string.buffer = d->cursor;
                    e->value.string.size = string_end - d->cursor;

                    d->cursor = skip_whitespace(++string_end);

                    if(*d->cursor == '\0') {
                        e->type = INCOMPLETE;
                        e->value.string.buffer = d->last_token;
                        e->value.string.size = string_end - d->last_token;
                    } else if (*d->cursor == ':') {
                        e->type = KEY;
                        d->cursor = string_end;
                    } else {
                        e->type = STRING;
                        d->cursor = string_end;
                    }

                    d->last_event_type = e->type;
                }

                break;
            }

        default:
            syntax_error(d, e);
            break;
    }
}
