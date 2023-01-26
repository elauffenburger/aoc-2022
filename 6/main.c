#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "utils.h"

int main(int argc, char **argv) {
  bool debug = false;
  for (int i = 1; i < argc; i++) {
    if (strncmp(argv[i], "-d", 2) == 0) {
      debug = true;
    }
  }

  StrSlice input = read_all(STDIN_FILENO);
  if (input.len < WINDOW_SIZE) {
    printf("-1\n");
    return -1;
  }

  char buf[WINDOW_SIZE];
  memset(buf, 0, WINDOW_SIZE);

  for (int i = 0; input.ptr[i] != 0; i++) {
    // Shift buf elements left.
    for (int j = 0; j < WINDOW_SIZE - 1; j++) {
      buf[j] = buf[j + 1];
    }

    // Add the new element to the buf.
    buf[WINDOW_SIZE-1] = input.ptr[i];

    // Wait until we have a full buffer.
    if (i < WINDOW_SIZE - 1) {
      continue;
    }

    // Check if the buf is unique.
    if (buf_distinct(buf, debug)) {
      printf("%d\n", i+1);
      return 0;
    }
  }

  printf("-1\n");
  return -1;
}