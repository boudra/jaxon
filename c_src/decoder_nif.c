#include "erl_nif.h"

#include "decoder.h"

#include <assert.h>
#include <string.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <time.h>
#include <sys/time.h>

#ifdef __MACH__
    #include <mach/clock.h>
    #include <mach/mach.h>
#endif


typedef struct {
    ERL_NIF_TERM nif_start_object;
    ERL_NIF_TERM nif_end_object;
    ERL_NIF_TERM nif_start_array;
    ERL_NIF_TERM nif_end_array;
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

    if(!enif_make_existing_atom(env, "comma", &(data->nif_comma), ERL_NIF_LATIN1))
        return 1;

    if(!enif_make_existing_atom(env, "colon", &(data->nif_colon), ERL_NIF_LATIN1))
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

inline double timespec_to_ms(struct timespec *t) {
    return ((double)t->tv_sec / 1000.0) + ((double)t->tv_nsec / 1000000.0);
}

void get_current_monotic_time(struct timespec* timestamp) {
/* clock_gettime is only supported from OS X 10.12 (Sierra) */
#if __MACH__ && __MAC_OS_X_VERSION_MIN_REQUIRED < 101200
  static clock_serv_t clock_server;
  static int clock_server_initialised = 0;

  mach_timespec_t mach_timestamp;

  if(!clock_server_initialised) {
      host_get_clock_service(mach_host_self(), SYSTEM_CLOCK, &clock_server);
      clock_server_initialised = 1;
  }

  clock_get_time(clock_server, &mach_timestamp);

  timestamp->tv_sec = mach_timestamp.tv_sec;
  timestamp->tv_nsec = mach_timestamp.tv_nsec;
#else
  clock_gettime(CLOCK_MONOTONIC_RAW, timestamp);
#endif
}

ERL_NIF_TERM decode_binary(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    struct timespec start, last, now, tmp;
    decoder_t decoder;
    ErlNifBinary input, input_copy_bin;
    size_t event_terms_allocated = 4096;
    size_t event_terms_index = event_terms_allocated;
    ERL_NIF_TERM stack_terms[event_terms_allocated];
    ERL_NIF_TERM *event_terms = &stack_terms[0];
    json_event_t event ;
    ERL_NIF_TERM binary, ret, input_copy;
    uint8_t* value;
    int total_slice = 0;

    get_current_monotic_time(&start);
    get_current_monotic_time(&last);

    private_data_t *data = (private_data_t*)enif_priv_data(env);

    if(!enif_inspect_binary(env, argv[0], &input)) {
        return enif_make_badarg(env);
    }

    uint8_t* buffer = input.data;
    input_copy = argv[0];

    /* clock_gettime(CLOCK_MONOTONIC_RAW, &tmp); */
    /* printf("init: %f %d\n", timespec_to_ms(&tmp) - timespec_to_ms(&start), input.size); */

    update_decoder_buffer(&decoder, buffer, input.size);

    event.type = UNDEFINED;

    while(event.type < SYNTAX_ERROR) {
        if(decoder.cursor < buffer + input.size && event.type > UNDEFINED) {
            get_current_monotic_time(&now);

            double since_start = timespec_to_ms(&now) - timespec_to_ms(&start);


            if(since_start > 1.0) {
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
                        enif_make_list_from_array(env, &stack_terms[event_terms_index], event_terms_allocated - event_terms_index),
                        binary
                        );
            }
        }

        if(event_terms_index == 0) {
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
                    enif_make_list_from_array(env, &stack_terms[event_terms_index], event_terms_allocated - event_terms_index),
                    binary
                    );
        }

        decode(&decoder, &event);

        switch(event.type) {
            case STRING:
                if(event.value.string.escapes > 0) {
                    ERL_NIF_TERM unescaped_binary;
                    uint8_t* unescaped =
                        enif_make_new_binary(env, event.value.string.size, &unescaped_binary);

                    const uint8_t* string_end =
                        unescape_unicode(event.value.string.buffer, unescaped, event.value.string.buffer + event.value.string.size);

                    binary = enif_make_sub_binary(env, unescaped_binary, 0, string_end - unescaped);
                } else {
                    binary = enif_make_sub_binary(env, input_copy, event.value.string.buffer - buffer, event.value.string.size);
                }
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

            case COMMA:
                ret = data->nif_comma;
                break;

            case COLON:
                ret = data->nif_colon;
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
                continue;

            case SYNTAX_ERROR:
                binary = enif_make_sub_binary(env, input_copy, event.value.string.buffer - buffer, event.value.string.size);
                ret = enif_make_tuple2(env, data->nif_error, binary);
                break;

            default:
                ret = data->nif_ok;
                break;
        }

        event_terms[--event_terms_index] = ret;
    }

    return enif_make_list_from_array(env, &stack_terms[event_terms_index], event_terms_allocated - event_terms_index);
}

static ErlNifFunc nif_exports[] = {
    {"parse_nif", 1, decode_binary}
};

ERL_NIF_INIT(Elixir.Jaxon.Parsers.NifParser, nif_exports, load, reload, upgrade, unload);
