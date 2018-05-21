#include "decoder.h"

#include <assert.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>

#define is_space(c) (c == ' ' || c == '\n' || c == '\r' || c == '\t')
#define is_digit(c) (c >= '0' && c <= '9')
#define max(a,b) (((a)>(b))?(a):(b))
#define min(a,b) (((a)<(b))?(a):(b))

uint8_t* skip_whitespace(uint8_t* buf, uint8_t* limit) {
    while (buf < limit && is_space(*buf)) {
        buf++;
    }
    return buf;
}

void make_decoder(decoder_t* d) {
    d->buffer = NULL;
    d->cursor = NULL;
    d->last_token = NULL;
}

void update_decoder_buffer(decoder_t* d, uint8_t* buf, size_t length) {
    d->buffer = buf;
    d->cursor = buf;
    d->buffer_length = length;
}

void parse_number(decoder_t* d, json_event_t* e) {
    uint8_t *limit = d->buffer + d->buffer_length;
    uint8_t *buf = d->cursor, *decimal_point = NULL;
    int exp_sign = 0, frac_sign = 0;
    long double frac = 0;
    long int exp = 0, frac_exp = 0;

    if(*buf == '-') {
        frac_sign = 1;
        buf += 1;
    } else if (*buf == '+') {
        buf += 1;
    }

    while(buf < limit) {
        if(is_digit(*buf)) {
            frac = (frac * 10) + (*buf - '0');
        } else if(*buf == '.') {
            decimal_point = buf;
        } else {
            break;
        }
        buf++;
    }

    if(decimal_point) {
        frac_exp = -(buf - decimal_point - 1);
    }

    if(buf == limit) {
        goto done;
    }

    if((*buf == 'e' || *buf == 'E') && (buf + 1 < limit)) {
        buf++;

        if(*buf == '-') {
            exp_sign = 1;
            buf += 1;
        } else if(*buf == '+'){
            buf += 1;
        }

        while(buf < limit) {
            if(is_digit(*buf)) {
                exp = (exp * 10) + (*buf - '0');
            } else {
                break;
            }
            buf++;
        }
    }

    if(exp_sign) {
        exp = -exp;
    }

    if(buf == limit) {
        goto done;
    }

done:

    if(buf < limit && (*buf == '.' || *buf == 'E' || *buf == 'e' ||
        *buf == '-' || *buf == '+')) {
        e->type = INCOMPLETE;
        e->value.string.buffer = d->last_token;
        e->value.string.size = buf - d->last_token;
    } else {
        long int abs_exp = labs(exp + frac_exp);
        double final_exp = pow(10.0, abs_exp);

        if(frac_exp == 0 && exp >= 0) {
            e->type = INTEGER;
            e->value.integer = (long int)(frac * final_exp);
            if(frac_sign) {
                e->value.integer = -e->value.integer;
            }
        } else {
            if(frac_exp + exp < 0) {
                e->value.decimal = frac / final_exp;
            } else {
                e->value.decimal = frac * final_exp;
            }
            e->type = DECIMAL;
            if(frac_sign) {
                e->value.decimal = -e->value.decimal;
            }
        }

        d->cursor = buf;
    }

    if(buf == limit) {
        e->type = (e->type == INTEGER) ? INCOMPLETE_INTEGER : INCOMPLETE_DECIMAL;

        e->secondary_value.string.buffer = d->last_token;
        e->secondary_value.string.size = buf - d->last_token;
    }
}

uint8_t* parse_string(uint8_t** buffer, uint8_t* limit) {
    uint8_t* buf = &(*buffer)[0];
    while (*buf != '"' && buf < limit) {
        if(*buf == '\\' && (buf + 1) < limit) {
            switch(*(++buf)) {
                case '\"':
                case '\\':
                case '/':
                    **buffer = *buf;
                    ++(*buffer);
                    ++buf;
                    continue;

                case 'n':
                    **buffer = '\n';
                    ++(*buffer);
                    ++buf;
                    continue;

                case 'r':
                    **buffer = '\r';
                    ++(*buffer);
                    ++buf;
                    continue;

                case 't':
                    **buffer = '\n';
                    ++(*buffer);
                    ++buf;
                    continue;

                case 'f':
                    **buffer = '\f';
                    ++(*buffer);
                    ++buf;
                    continue;

                case 'b':
                    **buffer = '\b';
                    ++(*buffer);
                    ++buf;
                    continue;


                case 'u':
                    if(buf + 4 < limit) {
                        buf++;
                        size_t size = 0;
                        uint32_t c =
                            (hex_byte_to_u32(buf[0]) << 12) +
                            (hex_byte_to_u32(buf[1]) << 8) +
                            (hex_byte_to_u32(buf[2]) << 4) +
                            (hex_byte_to_u32(buf[3]) << 0);

                        buf += 4;

                        if(c >= 0xD800 && c < 0xDC00 && buf + 6 < limit) {
                            buf += 2;
                            size += 2;

                            c = ((c & 0x3ff) << 10) + (
                                    (hex_byte_to_u32(buf[0]) << 12) +
                                    (hex_byte_to_u32(buf[1]) << 8) +
                                    (hex_byte_to_u32(buf[2]) << 4) +
                                    (hex_byte_to_u32(buf[3]) << 0) & 0x3ff
                                    ) + 0x10000;
                            buf += 4;
                        }

                        size = u32_to_utf8(c, *buffer);

                        (*buffer) += size;
                    }
                    continue;

                default:
                    break;

            }
        }
        *(*buffer) = *buf;
        (*buffer)++;
        buf++;
    }
    return buf;
}

int parse_constant(uint8_t** constant, const char* find, uint8_t* limit) {
    while(*constant < limit &&
          **constant == *find) {
        ++*constant;
        ++find;
    }

    return (*find == '\0');
}

void syntax_error(decoder_t* d, json_event_t* e) {
    const size_t context_length = 30;
    uint8_t* context = max(d->cursor - context_length, d->buffer);

    e->type = SYNTAX_ERROR;
    e->value.string.buffer = context;
    e->value.string.size = min(d->buffer + d->buffer_length, context + context_length) - context;
}

void decode(decoder_t* d, json_event_t* e) {
    uint8_t* limit = d->buffer + d->buffer_length;
    d->cursor = skip_whitespace(d->cursor, limit);
    d->last_token = d->cursor;

    /* printf("buffer: `%.*s`\n", min((int)(limit - d->cursor), 30), d->cursor); */

    if(d->cursor == limit) {
        e->type = END;
        return;
    }

    switch(*d->cursor) {
        case '{':
            d->cursor++;

            e->type = START_OBJECT;
            break;

        case '}':
            e->type = END_OBJECT;
            d->cursor++;
            break;

        case ':':
            d->cursor++;
            decode(d, e);
            break;

        case '[':
            e->type = START_ARRAY;
            d->cursor++;
            break;

        case ']':
            e->type = END_ARRAY;
            d->cursor++;
            break;

        case ',':
            d->cursor++;
            decode(d, e);
            break;

        case '-':
        case '+':
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
            parse_number(d, e);
            break;

        case 'n':
            {
                uint8_t* constant_end = d->cursor;

                if(parse_constant(&constant_end, "null", limit)) {
                    e->type = NIL;
                    d->cursor = constant_end;
                } else if(constant_end == limit) {
                    e->type = INCOMPLETE;
                    e->value.string.buffer = d->last_token;
                    e->value.string.size = constant_end - d->last_token;
                } else {
                    syntax_error(d, e);
                }
            }

            break;

        case 't':
            {
                uint8_t* constant_end = d->cursor;

                if(parse_constant(&constant_end, "true", limit)) {
                    e->type = BOOLEAN;
                    e->value.boolean = 1;
                    d->cursor = constant_end;
                } else if(constant_end == limit) {
                    e->type = INCOMPLETE;
                    e->value.string.buffer = d->last_token;
                    e->value.string.size = constant_end - d->last_token;
                } else {
                    syntax_error(d, e);
                }
            }
            break;

        case 'f':
            {
                uint8_t* constant_end = d->cursor;

                if(parse_constant(&constant_end, "false", limit)) {
                    e->type = BOOLEAN;
                    e->value.boolean = 0;
                    d->cursor = constant_end;
                } else if(constant_end == limit) {
                    e->type = INCOMPLETE;
                    e->value.string.buffer = d->last_token;
                    e->value.string.size = constant_end - d->last_token;
                } else {
                    syntax_error(d, e);
                }
            }
            break;

        case '"':
            {
                uint8_t* string_end = ++d->cursor;
                uint8_t* cursor = parse_string(&string_end, limit);

                if(cursor == limit) {
                    e->type = INCOMPLETE;
                    e->value.string.buffer = d->last_token;
                    e->value.string.size = cursor - d->last_token;
                } else {
                    e->type = STRING;
                    e->value.string.buffer = d->cursor;
                    e->value.string.size = string_end - d->cursor;
                    d->cursor = ++cursor;
                }

                break;
            }

        default:
            syntax_error(d, e);
            break;
    }
}
