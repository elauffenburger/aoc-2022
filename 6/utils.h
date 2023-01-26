#pragma once

#define WINDOW_SIZE 14

#define true 1
#define false 0

typedef char bool;

typedef struct StrSlice {
  char *ptr;
  size_t len;
} StrSlice;

StrSlice read_all(int fileno);
bool buf_distinct(char *buf, bool debug);