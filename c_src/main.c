#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "decoder.h"

int main(int argc, char *argv[]) {

  char* json = "{ \"city\": \"barcelona\", \"age\": 36, \"pets\": \"hell";
  char* next_json = "o\"}";

  decoder_t decoder;
  json_event_t event;

  make_decoder(&decoder);
  update_decoder_buffer(&decoder, json);

  do {
    decode(&decoder, &event);
    printf("%s ", event_type_to_string(event.type));


    switch(event.type) {
      case KEY:
      case STRING:
        printf("string: \"%.*s\" ", (int)event.value.string.size, event.value.string.buffer);
        break;

      case SYNTAX_ERROR:
        printf("expected ");
        for(int i = 0; i < sizeof(event.value.syntax_error.expected)/sizeof(json_event_type_t); i++) {
          if(event.value.syntax_error.expected[i] == 0) {
            break;
          }
          printf("%s ", event_type_to_string(event.value.syntax_error.expected[i]));
        }
        printf(" in %s", event.value.syntax_error.context);
        break;

      case INCOMPLETE:
        {
          char* chunk = (char*)malloc(event.value.string.size + strlen(next_json));
          memcpy(chunk, event.value.string.buffer, event.value.string.size);
          memcpy(chunk + event.value.string.size, next_json, strlen(next_json));
          update_decoder_buffer(&decoder, chunk);
          break;
        }

      default:
        break;
    }

    printf("\n");

  } while(event.type != END && event.type != UNDEFINED && event.type != SYNTAX_ERROR);

  return 0;
}
