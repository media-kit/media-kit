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

#include "signal_recovery.h"

#include <memory.h>
#include <pthread.h>
#include <stdlib.h>

static pthread_key_t env_key;

struct env_buf_t {
  sigjmp_buf jmp_buf;
  struct env_buf_t* next;
  siginfo_t info;
};

env_buf_t* env_buf_alloc() {
  return (env_buf_t*)calloc(1, sizeof(env_buf_t));
}

void env_buf_free(env_buf_t* env_buf) {
  free(env_buf);
}

/**
 * @return - current env_buf in current thread
 */
env_buf_t* env_buf_cur() {
  return (env_buf_t*)pthread_getspecific(env_key);
}

sigjmp_buf* env_buf_get(env_buf_t* env_buf) {
  return &env_buf->jmp_buf;
}

void env_buf_push(env_buf_t* env_buf) {
  env_buf_t* top_item = env_buf_cur();
  env_buf->next = top_item;
  pthread_setspecific(env_key, env_buf);
}

void env_buf_pop() {
  env_buf_t* top_item = env_buf_cur();

  if (top_item != NULL) {
    env_buf_t* next_item = top_item->next;
    pthread_setspecific(env_key, next_item);
    env_buf_free(top_item);
  }
}

static pthread_once_t once = PTHREAD_ONCE_INIT;

#ifndef NSIG
#define NSIG 65
#endif

// Old signal action records
static struct sigaction old_sa[NSIG];

typedef struct signal_item {
  int signo;
  const char* name;
  struct signal_item* next;
} signal_item;

static signal_item* entry;

static void add_signal_name(int signo, const char* signame) {
  signal_item* item = (signal_item*)calloc(1, sizeof(signal_item));
  item->signo = signo;
  item->name = signame;
  item->next = entry;
  entry = item;
}

#define handle_signal(sig)    \
  add_signal_name(sig, #sig); \
  sigaction(sig, &action_info, &old_sa[sig])

static void env_key_create() {
  pthread_key_create(&env_key, NULL);
}

static void signal_handler(int signal, siginfo_t* info, void* reserved) {
  env_buf_t* cur_env = env_buf_cur();

  if (cur_env != NULL) {
    cur_env->info = *info;
    siglongjmp(cur_env->jmp_buf, SAVE_SIGNAL_MASK);
  } else {
    struct sigaction* old_action = &old_sa[signal];

    if (old_action->sa_flags & SA_SIGINFO) {
      if (old_action->sa_sigaction != NULL) {
        old_action->sa_sigaction(signal, info, reserved);
      }
    } else {
      if (old_action->sa_handler != NULL) {
        old_action->sa_handler(signal);
      }
    }
  }
}

static void signal_handler_init() {
  struct sigaction action_info;
  memset(&action_info, 0, sizeof(sigaction));
  action_info.sa_sigaction = signal_handler;
  action_info.sa_flags = SA_SIGINFO;

  handle_signal(SIGSEGV);  // Segmentation violation
  handle_signal(SIGFPE);   // Floating point exception
  handle_signal(SIGILL);   // Illegal instruction
  handle_signal(SIGBUS);   // Bus error
}

static void try_catch_init() {
  env_key_create();
  signal_handler_init();
}

void signal_catch_init() {
  pthread_once(&once, try_catch_init);
}

siginfo_t* signal_info() {
  env_buf_t* cur_env = env_buf_cur();

  if (cur_env != NULL && 0 < cur_env->info.si_signo) {
    return &cur_env->info;
  }
  return NULL;
}

const char* signal_name(int signo) {
  signal_item* item = entry;

  while (item != NULL) {
    if (item->signo == signo) {
      return item->name;
    }
    item = item->next;
  }

  return "";
}
