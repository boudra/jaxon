ERL_INCLUDE_PATH=$(shell erl -eval 'io:format("~s~n", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)

UNAME := $(shell uname)

ifeq ($(UNAME), Darwin)
	CC := clang
	CFLAGS := -undefined dynamic_lookup -dynamiclib
endif

ifeq ($(UNAME), Linux)
	CC := gcc
	CFLAGS := -shared -fpic
endif

all: priv/decoder.so

priv/decoder.so: c_src/decoder_nif.c c_src/decoder.c
	mkdir -p priv
	$(CC) $(CFLAGS) -O3 -I$(ERL_INCLUDE_PATH) c_src/decoder*.c -o priv/decoder.so

clean:
	@rm -rf priv/decoder.so
