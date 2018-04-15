ERL_INCLUDE_PATH=$(shell erl -eval 'io:format("~s~n", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)

all: decoder.so

decoder.so: c_src/decoder_nif.c c_src/decoder.c
	cc -O3 -undefined dynamic_lookup -dynamiclib -I$(ERL_INCLUDE_PATH) c_src/decoder*.c -o decoder.so

clean:
	@rm -rf decoder.so
