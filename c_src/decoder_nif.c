#include "erl_nif.h"

#include "decoder.h"

#include <assert.h>
#include <string.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <time.h>
#include <sys/time.h>

typedef struct {
    ERL_NIF_TERM nif_start_object;
    ERL_NIF_TERM nif_end_object;
    ERL_NIF_TERM nif_start_array;
    ERL_NIF_TERM nif_end_array;
    ERL_NIF_TERM nif_key;
    ERL_NIF_TERM nif_colon;
    ERL_NIF_TERM nif_comma;
    ERL_NIF_TERM nif_string;
    ERL_NIF_TERM nif_decimal;
    ERL_NIF_TERM nif_integer;
    ERL_NIF_TERM nif_boolean;
    ERL_NIF_TERM nif_true;
    ERL_NIF_TERM nif_false;
    ERL_NIF_TERM nif_nil;
    ERL_NIF_TERM nif_incomplete;
    ERL_NIF_TERM nif_end;
    ERL_NIF_TERM nif_yield;

    ERL_NIF_TERM nif_ok;
    ERL_NIF_TERM nif_error;
} private_data_t;

static int load(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info) {
    private_data_t *data = enif_alloc(sizeof(private_data_t));

    if(!enif_make_existing_atom(env, "start_object", &(data->nif_start_object), ERL_NIF_LATIN1))
        return 1;

    if(!enif_make_existing_atom(env, "end_object", &(data->nif_end_object), ERL_NIF_LATIN1))
        return 1;

    if(!enif_make_existing_atom(env, "start_array", &(data->nif_start_array), ERL_NIF_LATIN1))
        return 1;

    if(!enif_make_existing_atom(env, "end_array", &(data->nif_end_array), ERL_NIF_LATIN1))
        return 1;

    if(!enif_make_existing_atom(env, "key", &(data->nif_key), ERL_NIF_LATIN1))
        return 1;

    if(!enif_make_existing_atom(env, "string", &(data->nif_string), ERL_NIF_LATIN1))
        return 1;

    if(!enif_make_existing_atom(env, "decimal", &(data->nif_decimal), ERL_NIF_LATIN1))
        return 1;

    if(!enif_make_existing_atom(env, "integer", &(data->nif_integer), ERL_NIF_LATIN1))
        return 1;

    if(!enif_make_existing_atom(env, "boolean", &(data->nif_boolean), ERL_NIF_LATIN1))
        return 1;

    if(!enif_make_existing_atom(env, "nil", &(data->nif_nil), ERL_NIF_LATIN1))
        return 1;

    if(!enif_make_existing_atom(env, "true", &(data->nif_true), ERL_NIF_LATIN1))
        return 1;

    if(!enif_make_existing_atom(env, "false", &(data->nif_false), ERL_NIF_LATIN1))
        return 1;

    if(!enif_make_existing_atom(env, "incomplete", &(data->nif_incomplete), ERL_NIF_LATIN1))
        return 1;

    if(!enif_make_existing_atom(env, "end", &(data->nif_end), ERL_NIF_LATIN1))
        return 1;

    if(!enif_make_existing_atom(env, "ok", &(data->nif_ok), ERL_NIF_LATIN1))
        return 1;

    if(!enif_make_existing_atom(env, "error", &(data->nif_error), ERL_NIF_LATIN1))
        return 1;

    if(!enif_make_existing_atom(env, "yield", &(data->nif_yield), ERL_NIF_LATIN1))
        return 1;

    *priv_data = (void*)data;

    return 0;
}

static int reload(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info) {
    return 0;
}

static int upgrade(ErlNifEnv* env, void** priv_data, void** old_priv_data, ERL_NIF_TERM load_info) {
    return 0;
}

static void unload(ErlNifEnv* env, void* priv_data) {
    return;
}

ERL_NIF_TERM decode_binary(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    decoder_t decoder;
    ErlNifBinary input;
    size_t event_terms_count = 0, event_terms_allocated = 8192;
    ERL_NIF_TERM *event_terms = malloc(sizeof(ERL_NIF_TERM) * event_terms_allocated);
    json_event_t event ;
    ERL_NIF_TERM binary, ret, input_copy;
    uint8_t* value;
    struct timeval start, last, now;

    gettimeofday(&last, NULL);
    gettimeofday(&start, NULL);

    private_data_t *data = (private_data_t*)enif_priv_data(env);

    if(!enif_inspect_binary(env, argv[0], &input)) {
        return enif_make_badarg(env);
    }

    uint8_t* buffer = enif_make_new_binary(env, input.size, &input_copy);

    memcpy(buffer, input.data, input.size);

    update_decoder_buffer(&decoder, buffer, input.size);

    event.type = UNDEFINED;

    while(event.type < SYNTAX_ERROR) {
        if(decoder.cursor < buffer + input.size && event.type > UNDEFINED) {
            gettimeofday(&now, NULL);

            int slice = floor(
                    (1000000 * (now.tv_sec - last.tv_sec) +
                     (now.tv_usec - last.tv_usec)) / 10
                    );

            if (slice > 0) {
                if(slice < 0) slice = 0;
                else if(slice > 100) slice = 100;

                if(enif_consume_timeslice(env, slice)) {
                    binary =
                        enif_make_sub_binary(
                            env,
                            input_copy,
                            (decoder.cursor - buffer),
                            (buffer + input.size) - decoder.cursor
                        );

                    return enif_make_tuple3(
                            env,
                            data->nif_yield,
                            enif_make_list_from_array(env, event_terms, event_terms_count),
                            binary
                        );
                }
                last = now;
            }
        }

        if(event_terms_count == event_terms_allocated) {
            event_terms_allocated *= 2;
            event_terms =
                realloc(event_terms, sizeof(ERL_NIF_TERM) * event_terms_allocated);
        }

        decode(&decoder, &event);

        switch(event.type) {
            case STRING:
                binary = enif_make_sub_binary(env, input_copy, event.value.string.buffer - buffer, event.value.string.size);
                ret = enif_make_tuple2(env, data->nif_string, binary);
                break;

            case DECIMAL:
                ret = enif_make_tuple2(env, data->nif_decimal, enif_make_double(env, event.value.decimal));
                break;

            case NIL:
                ret = data->nif_nil;
                break;

            case INTEGER:
                ret = enif_make_tuple2(env, data->nif_integer, enif_make_int64(env, event.value.integer));
                break;

            case BOOLEAN:
                ret = enif_make_tuple2(env, data->nif_boolean, event.value.boolean ? data->nif_true : data->nif_false);
                break;

            case KEY:
                binary = enif_make_sub_binary(env, input_copy, event.value.string.buffer - buffer, event.value.string.size);
                ret = enif_make_tuple2(env, data->nif_key, binary);
                break;

            case INCOMPLETE:
                binary = enif_make_sub_binary(env, input_copy, event.value.string.buffer - buffer, event.value.string.size);
                ret = enif_make_tuple2(env, data->nif_incomplete, binary);
                break;

            case INCOMPLETE_DECIMAL:
                binary = enif_make_sub_binary(env, input_copy, event.secondary_value.string.buffer - buffer, event.secondary_value.string.size);
                ret = enif_make_tuple3(env, data->nif_incomplete, enif_make_tuple2(env, data->nif_decimal, enif_make_double(env, event.value.decimal)), binary);
                break;

            case INCOMPLETE_INTEGER:
                binary = enif_make_sub_binary(env, input_copy, event.secondary_value.string.buffer - buffer, event.secondary_value.string.size);
                ret = enif_make_tuple3(env, data->nif_incomplete, enif_make_tuple2(env, data->nif_integer, enif_make_int64(env, event.value.integer)), binary);
                break;

            case START_OBJECT:
                ret = data->nif_start_object;
                break;

            case START_ARRAY:
                ret = data->nif_start_array;
                break;

            case END_OBJECT:
                ret = data->nif_end_object;
                break;

            case END_ARRAY:
                ret = data->nif_end_array;
                break;

            case END:
                ret = data->nif_end;
                break;

            case SYNTAX_ERROR:
                binary = enif_make_sub_binary(env, input_copy, event.value.string.buffer - buffer, event.value.string.size);
                ret = enif_make_tuple2(env, data->nif_error, binary);
                break;

            default:
                ret = data->nif_ok;
                break;
        }

        event_terms[event_terms_count++] = ret;
    }

    return enif_make_list_from_array(env, event_terms, event_terms_count);
}

static ErlNifFunc nif_exports[] = {
    {"parse_nif", 1, decode_binary}
};

ERL_NIF_INIT(Elixir.Jaxon.Parsers.NifParser, nif_exports, load, reload, upgrade, unload);
