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

void syntax_error(decoder_t* d, json_event_t* e) {
    const size_t context_length = 30;
    uint8_t* context = max(d->cursor - context_length, d->buffer);

    e->type = SYNTAX_ERROR;
    e->value.string.buffer = context;
    e->value.string.size = min(d->buffer + d->buffer_length, context + context_length) - context;
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
        syntax_error(d, e);
        return;
    }

    if(*buf == '0' && buf + 1 < limit && is_digit(*(buf+1))) {
        syntax_error(d, e);
        return;
    }

    if(!is_digit(*buf)) {
        syntax_error(d, e);
        return;
    }

    while(buf < limit) {
        if(is_digit(*buf)) {
            frac = (frac * 10) + (*buf - '0');
        } else if(*buf == '.' && decimal_point == NULL) {
            decimal_point = buf;
        } else {
            break;
        }
        buf++;
    }

    if(buf < limit && *(buf - 1) == '.' && !is_digit(*buf)) {
        syntax_error(d, e);
        return;
    }

    if(*(buf - 1) == '.' && (buf - 1) == decimal_point) {
        buf--;
        goto done;
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

        if(!is_digit(*buf)) {
            syntax_error(d, e);
            return;
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
        e->value.string.size = (buf+1) - d->last_token;
    } else {
        long int abs_exp = labs(exp + frac_exp);

        if(abs_exp > 307) {
            abs_exp = 307;
        }

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

uint8_t* unescape_unicode(uint8_t* buf, uint8_t* buffer, uint8_t* limit) {
    while (buf < limit) {
        switch(*buf) {
            case '\\':
                if((buf + 1) < limit) {
                    switch(*(++buf)) {
                        case '\"':
                        case '\\':
                        case '/':
                            *buffer = *buf;
                            ++buffer;
                            ++buf;
                            continue;

                        case 'n':
                            *buffer = '\n';
                            ++buffer;
                            ++buf;
                            continue;

                        case 'r':
                            *buffer = '\r';
                            ++buffer;
                            ++buf;
                            continue;

                        case 't':
                            *buffer = '\t';
                            ++buffer;
                            ++buf;
                            continue;

                        case 'f':
                            *buffer = '\f';
                            ++buffer;
                            ++buf;
                            continue;

                        case 'b':
                            *buffer = '\b';
                            ++buffer;
                            ++buf;
                            continue;


                        case 'u':
                            if(buf + 5 <= limit) {
                                buf++;
                                int32_t r = -1;
                                uint32_t c = 0;

                                if((r = hex_byte_to_i32(buf[0])) >= 0) {
                                    c += r << 12;
                                }

                                if((r = hex_byte_to_i32(buf[1])) >= 0) {
                                    c += r << 8;
                                }

                                if((r = hex_byte_to_i32(buf[2])) >= 0) {
                                    c += r << 4;
                                }

                                if((r = hex_byte_to_i32(buf[3])) >= 0) {
                                    c += r << 0;
                                }

                                buf += 4;

                                if(c >= 0xD800 && c < 0xDC00 && buf + 6 <= limit) {
                                    buf += 2;

                                    c = ((c & 0x3ff) << 10) + (
                                            (hex_byte_to_i32(buf[0]) << 12) +
                                            (hex_byte_to_i32(buf[1]) << 8) +
                                            (hex_byte_to_i32(buf[2]) << 4) +
                                            (hex_byte_to_i32(buf[3]) << 0) & 0x3ff
                                            ) + 0x10000;

                                    buf += 4;
                                }

                                buffer += u32_to_utf8(c, buffer);
                            } else {
                                return buffer;
                            }
                            continue;

                        default:
                            return buffer;

                    }
                }
                break;
        }
        *buffer = *buf;
        buffer++;
        buf++;
    }
    return buffer;
}

uint8_t* parse_string(uint8_t* buffer, uint8_t* limit, size_t* escapes) {
    uint8_t* buf = buffer;

    while (*buf != '"' && buf < limit) {
        switch(*buf) {
            case '\t':
            case '\n':
            case '\0':
                return buf;

            case '\\':
                (*escapes)++;

                if((buf + 1) < limit) {
                    switch(*(++buf)) {
                        case '\"':
                        case '\\':
                        case '/':
                        case 'n':
                        case 'r':
                        case 't':
                        case 'f':
                        case 'b':
                            ++buf;
                            continue;

                        case 'u':
                            if(buf + 5 < limit) {
                                buf++;
                                int32_t r = -1;
                                uint32_t c = 0;

                                if((r = hex_byte_to_i32(buf[0])) >= 0) {
                                    c += r << 12;
                                } else {
                                    return buf;
                                }

                                if((r = hex_byte_to_i32(buf[1])) >= 0) {
                                    c += r << 8;
                                } else {
                                    return buf;
                                }

                                if((r = hex_byte_to_i32(buf[2])) >= 0) {
                                    c += r << 4;
                                } else {
                                    return buf;
                                }

                                if((r = hex_byte_to_i32(buf[3])) >= 0) {
                                    c += r << 0;
                                } else {
                                    return buf;
                                }

                                buf += 4;

                                if(c >= 0xD800 && c < 0xDC00 && buf + 6 < limit) {
                                    buf += 6;
                                }

                                continue;
                            } else {
                                return limit;
                            }

                            break;

                        default:
                            return buf;
                    }
                }
                break;
        }
        ++buf;
    }

    return buf;

}

void decode(decoder_t* d, json_event_t* e) {
    uint8_t* limit = d->buffer + d->buffer_length;
    d->cursor = skip_whitespace(d->cursor, limit);
    d->last_token = d->cursor;

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
            e->type = COLON;
            d->cursor++;
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
            e->type = COMMA;
            d->cursor++;
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
            if(d->cursor + 4 <= limit) {
                if(memcmp(d->cursor, "null", 4) == 0) {
                    e->type = NIL;
                    d->cursor = d->cursor + 4;
                } else {
                    syntax_error(d, e);
                }
            } else {
                e->type = INCOMPLETE;
                e->value.string.buffer = d->last_token;
                e->value.string.size = limit - d->last_token;
            }
            break;

        case 't':
            if(d->cursor + 4 <= limit) {
                if(memcmp(d->cursor, "true", 4) == 0) {
                    e->type = BOOLEAN;
                    e->value.boolean = 1;
                    d->cursor = d->cursor + 4;
                } else {
                    syntax_error(d, e);
                }
            } else {
                e->type = INCOMPLETE;
                e->value.string.buffer = d->last_token;
                e->value.string.size = limit - d->last_token;
            }
            break;

        case 'f':
            if(d->cursor + 5 <= limit) {
                if(memcmp(d->cursor, "false", 5) == 0) {
                    e->type = BOOLEAN;
                    e->value.boolean = 1;
                    d->cursor = d->cursor + 5;
                } else {
                    syntax_error(d, e);
                }
            } else {
                e->type = INCOMPLETE;
                e->value.string.buffer = d->last_token;
                e->value.string.size = limit - d->last_token;
            }
            break;

        case '"':
            {
                size_t escapes = 0;
                uint8_t* string_end = ++d->cursor;
                uint8_t* cursor = parse_string(string_end, limit, &escapes);

                if(cursor == limit) {
                    e->type = INCOMPLETE;
                    e->value.string.buffer = d->last_token;
                    e->value.string.size = cursor - d->last_token;
                } else if(*cursor == '\"') {
                    e->type = STRING;
                    e->value.string.buffer = d->cursor;
                    e->value.string.size = cursor - d->cursor;
                    e->value.string.escapes = escapes;
                    d->cursor = ++cursor;
                } else {
                    syntax_error(d, e);
                }

                break;
            }

        default:
            syntax_error(d, e);
            break;
    }
}
