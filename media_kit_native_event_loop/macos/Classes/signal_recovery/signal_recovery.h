/*
 * Copyright (C) 2019 Wang Donghui
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef SIGNAL_RECOVERY_H
#define SIGNAL_RECOVERY_H

#include <setjmp.h>
#include <signal.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Sample code
 *
    // Global init
    signal_catch_init();

    // Three labels must be the same, can be empty.
    // Nested try-catch pairs must use different label names.
    signal_try(label) {
        // Add your code need try
    }
    signal_catch(label) {
        // Add your code to process exceptions, or do nothing.
        siginfo_t* info = signal_info();
    }
    signal_end(label)

    // Normal code
 */

void signal_catch_init(void);

/**
 * Get signal info in signal_catch() block.
 *
 * @return - read-only signal info struct
 */
siginfo_t* signal_info(void);

/**
 * Get signal name from signal number.
 *
 * @param signo - signal number
 * @return - read-only signal name
 */
const char* signal_name(int signo);

#define SAVE_SIGNAL_MASK 1

#define signal_try(name)    \
  goto signal_catch_##name; \
  signal_try_##name : {}

#define signal_catch(name)                                                \
  goto signal_end_##name;                                                 \
  signal_catch_##name : {                                                 \
    env_buf_t* env_buf_##name = env_buf_alloc();                          \
    if (sigsetjmp(*env_buf_get(env_buf_##name), SAVE_SIGNAL_MASK) == 0) { \
      env_buf_push(env_buf_##name);                                       \
      goto signal_try_##name;                                             \
    }                                                                     \
  }

#define signal_end(name) \
  signal_end_##name : {  \
    env_buf_pop();       \
  }

// Private API, do not call directly
typedef struct env_buf_t env_buf_t;

env_buf_t* env_buf_alloc(void);
env_buf_t* env_buf_cur(void);
sigjmp_buf* env_buf_get(env_buf_t* env_buf);
void env_buf_push(env_buf_t* env_buf);
void env_buf_pop(void);

#ifdef __cplusplus
}
#endif

#endif  // SIGNAL_RECOVERY_H
