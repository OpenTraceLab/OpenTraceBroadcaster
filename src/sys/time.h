#pragma once
// Windows compatibility header for sys/time.h

#ifdef _WIN32
#include <time.h>
#include <winsock2.h>

// Use the timeval from winsock2.h
// No need to redefine it

#else
#include_next <sys/time.h>
#endif
