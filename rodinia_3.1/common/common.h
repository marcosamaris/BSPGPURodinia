
#include <time.h>
#include <stdint.h>

inline uint64_t getTime(void)
{
    struct timespec time;
    clock_gettime(CLOCK_REALTIME, &time);
    return ((uint64_t)(time.tv_sec)*1000000000 + (uint64_t)(time.tv_nsec));
}
