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
    d->last_event_type = UNDEFINED;
    d->pair_count = 0;
}

void update_decoder_buffer(decoder_t* d, uint8_t* buf, size_t length) {
    if(d->last_event_type == END) {
        make_decoder(d);
    }

    d->buffer = buf;
    d->cursor = buf;
    d->buffer_length = length;
}


static double powers_of_10[] = {
    10.,
    100.,
    1.0e4,
    1.0e8,
    1.0e16,
    1.0e32,
    1.0e64,
    1.0e128,
    1.0e256
};

void parse_number(decoder_t* d, json_event_t* e) {
    uint8_t* limit = d->buffer + d->buffer_length;
    uint8_t *mantissa = NULL, *buf = d->cursor, *decimal_point = NULL;
    int exp_sign = 0, frac_sign = 0;
    long unsigned int frac1 = 0, frac2 = 0;
    long int exp = 0, frac_exp = 0;

    if(*buf == '-') {
        frac_sign = 1;
        buf += 1;
    } else if (*buf == '+') {
        buf += 1;
    }

    mantissa = buf;

    while(buf < limit) {
        if(is_digit(*buf)) {
            if(buf - mantissa < 9) {
                frac1 = (frac1 * 10) + (*buf - '0');
            } else {
                frac2 = (frac2 * 10) + (*buf - '0');
            }
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

    if(d->last_event_type != UNDEFINED &&
            (buf == limit || *buf == '.' || *buf == 'E' || *buf == 'e' ||
             *buf == '-' || *buf == '+')) {
        e->type = INCOMPLETE;
        e->value.string.buffer = d->last_token;
        e->value.string.size = buf - d->last_token;
    } else {
        long int abs_exp = labs(exp + frac_exp);
        double final_exp = pow(10.0, abs_exp);

        if(frac_exp == 0 && exp >= 0) {
            e->type = INTEGER;
            e->value.integer = (((long int)1.e9 * frac2) + frac1) * (long int)final_exp;
            e->value.integer *= (frac_sign ? -1 : 1);
        } else {
            if(frac_exp + exp < 0) {
                e->value.decimal = ((1.e9 * (double)frac2) + (double)frac1) / final_exp;
            } else {
                e->value.decimal = ((1.e9 * (double)frac2) + (double)frac1) * final_exp;
            }
            e->type = DECIMAL;
            if(frac_sign) {
                e->value.decimal = -e->value.decimal;
            }
        }

        d->last_event_type = e->type;
        d->cursor = buf;
    }
}

uint8_t* parse_string(uint8_t** buffer, uint8_t* limit) {
    uint8_t* buf = &(*buffer)[0];
    while ((*buf != '"' && (buf + 1) < limit)) {
        if(*buf == '\\') {
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
        return;
    }

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

        case ',':
            d->cursor++;
            d->last_event_type = COMMA;
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
            if(d->last_event_type != UNDEFINED &&
                d->last_event_type != START_ARRAY &&
                d->last_event_type != COMMA &&
                d->last_event_type != COLON) {
                syntax_error(d, e);
            } else {
                parse_number(d, e);
            }
            break;

        case 'n':
            {
                uint8_t* constant_end = d->cursor;

                if(parse_constant(&constant_end, "null", limit)) {
                    e->type = NIL;
                    d->last_event_type = e->type;
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
                    d->last_event_type = e->type;
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
                    d->last_event_type = e->type;
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
                    e->value.string.buffer = d->cursor;
                    e->value.string.size = string_end - d->cursor;

                    d->cursor = skip_whitespace(++cursor, limit);

                    if((d->cursor == limit) && d->last_event_type != UNDEFINED) {
                        e->type = INCOMPLETE;
                        e->value.string.buffer = d->last_token;
                        e->value.string.size = cursor - d->last_token;
                    } else if (*d->cursor == ':') {
                        e->type = KEY;
                        d->cursor = cursor;
                    } else {
                        e->type = STRING;
                        d->cursor = cursor;
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
