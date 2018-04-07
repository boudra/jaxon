ERL_INCLUDE_PATH=$(shell erl -eval 'io:format("~s~n", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)

all: priv/example priv/decoder.so

priv/decoder.so: c_src/decoder_nif.c c_src/decoder.c
	cc -O3 -undefined dynamic_lookup -dynamiclib -I$(ERL_INCLUDE_PATH) c_src/decoder*.c -o priv/decoder.so

priv/example: c_src/main.c priv/decoder.so
	cc c_src/decoder.c c_src/main.c -o priv/example

clean:
	@rm -rf priv/example priv/decoder.so
