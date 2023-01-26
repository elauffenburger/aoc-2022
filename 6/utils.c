#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "utils.h"

StrSlice read_all(int fileno) {
  char *res = NULL;
  size_t res_len = 0;
  for (;;) {
    char buf[BUFSIZ];
    ssize_t n = read(fileno, buf, BUFSIZ);
    if (n == 0) {
      break;
    }

    res = realloc(res, sizeof(char) * (res_len + n));
    for (int i = 0; i < n; i++) {
      res[res_len + i] = buf[i];
    }

    res_len += n;
  }
  res = realloc(res, res_len + 1);
  res[res_len] = 0;

  return (StrSlice){.ptr = res, .len = res_len};
}

bool buf_distinct(char *buf, bool debug) {
  if (debug){
    char str[WINDOW_SIZE+1];
    memcpy(str, buf, WINDOW_SIZE);
    str[WINDOW_SIZE] = 0;
    fprintf(stderr, "comparing: %s\n", str);
  }

  for (int j = 0; j < WINDOW_SIZE; j++) {
    char left = buf[j];
    for (int k = j + 1; k < WINDOW_SIZE; k++) {
      char right = buf[k];

      if (left == right) {
        return false;
      }
    }
  }

  return true;
}