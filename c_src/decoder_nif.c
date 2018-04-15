#include "erl_nif.h"

#include "decoder.h"

#include <assert.h>
#include <string.h>
#include <string.h>

typedef struct {
    ErlNifBinary binary;
    decoder_t decoder;
} decoder_resource_t;


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
    ERL_NIF_TERM nif_syntax_error;
    ERL_NIF_TERM nif_incomplete;
    ERL_NIF_TERM nif_end;

    ERL_NIF_TERM nif_ok;
    ERL_NIF_TERM nif_error;
} private_data_t;

ErlNifResourceType* decoder_resource_type;

static void decoder_nif_destructor(ErlNifEnv* env, void* ptr) {
    decoder_resource_t *dr = (decoder_resource_t*)ptr;
    enif_release_binary(&dr->binary);
    dr->binary.data = NULL;
    dr->binary.size = 0;
}

static int load(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info) {
    private_data_t *data = enif_alloc(sizeof(private_data_t));

    decoder_resource_type = enif_open_resource_type(
            env,
            NULL,
            "decoder_resource_type",
            decoder_nif_destructor,
            ERL_NIF_RT_CREATE,
            NULL
            );

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

    if(!enif_make_existing_atom(env, "syntax_error", &(data->nif_syntax_error), ERL_NIF_LATIN1))
        return 1;

    if(!enif_make_existing_atom(env, "incomplete", &(data->nif_incomplete), ERL_NIF_LATIN1))
        return 1;

    if(!enif_make_existing_atom(env, "end", &(data->nif_end), ERL_NIF_LATIN1))
        return 1;

    if(!enif_make_existing_atom(env, "ok", &(data->nif_ok), ERL_NIF_LATIN1))
        return 1;

    if(!enif_make_existing_atom(env, "error", &(data->nif_error), ERL_NIF_LATIN1))
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

ERL_NIF_TERM decode_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    json_event_t event;
    decoder_resource_t* dr;
    ErlNifBinary input;
    private_data_t *data = (private_data_t*)enif_priv_data(env);
    ERL_NIF_TERM binary, ret;
    unsigned char* value;

    assert(enif_get_resource(env, argv[0], decoder_resource_type, (void**)&dr));

    decode(&dr->decoder, &event);

    /* printf("event: %s\n", event_type_to_string(event.type)); */
    /* if(event.type == STRING || event.type == KEY) { */
    /* 	printf("string: `%.*s`\n", (int)event.value.string.size, event.value.string.buffer); */
    /* } */
    /* printf("\n"); */

    switch(event.type) {
        case STRING:
            value = enif_make_new_binary(env, event.value.string.size, &binary);
            memcpy(value, event.value.string.buffer, event.value.string.size);
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
            value = enif_make_new_binary(env, event.value.string.size, &binary);
            memcpy(value, event.value.string.buffer, event.value.string.size);
            ret = enif_make_tuple2(env, data->nif_key, binary);
            break;

        case INCOMPLETE:
            value = enif_make_new_binary(env, event.value.string.size, &binary);
            memcpy(value, event.value.string.buffer, event.value.string.size);
            ret = enif_make_tuple2(env, data->nif_incomplete, binary);
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
            value = enif_make_new_binary(env, event.value.string.size, &binary);
            memcpy(value, event.value.string.buffer, event.value.string.size);
            ret = enif_make_tuple2(env, data->nif_error, binary);
            break;

        default:
            ret = data->nif_ok;
            break;
    }

    return ret;
}

ERL_NIF_TERM update_decoder_resource(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    decoder_resource_t* dr;
    ErlNifBinary input;
    private_data_t *data = (private_data_t*)enif_priv_data(env);

    assert(enif_get_resource(env, argv[0], decoder_resource_type, (void**)&dr));

    if(!enif_inspect_binary(env, argv[1], &input)) {
        return enif_make_badarg(env);
    }

    if(input.size > dr->binary.size) {
        enif_realloc_binary(&dr->binary, input.size + 1);
    }

    memcpy(dr->binary.data, input.data, input.size);
    dr->binary.data[input.size] = '\0';
    /* printf("new %s\n", dr->binary.data); */

    update_decoder_buffer(&dr->decoder, (char *)dr->binary.data);

    return enif_make_resource(env, (void *)dr);
}

ERL_NIF_TERM make_decoder_resource(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    decoder_resource_t* dr =
        (decoder_resource_t*)enif_alloc_resource(decoder_resource_type, sizeof(decoder_resource_t));

    make_decoder(&dr->decoder);

    enif_alloc_binary(1024, &dr->binary);

    return enif_make_resource(env, (void *)dr);
}

static ErlNifFunc nif_exports[] = {
    {"make_decoder", 0, make_decoder_resource},
    {"update_decoder", 2, update_decoder_resource},
    {"decode", 1, decode_nif}
};

ERL_NIF_INIT(Elixir.Jaxon, nif_exports, load, reload, upgrade, unload);
