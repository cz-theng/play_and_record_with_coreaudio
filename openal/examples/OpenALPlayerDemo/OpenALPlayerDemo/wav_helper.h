/*******************************************************************************\
** OpenALPlayerDemo:wav_helper.h
** Created by CZ(cz.devnet@gmail.com) on 12/5/16
**
**  Copyright © 2016 projm. All rights reserved.
\*******************************************************************************/


#ifndef OpenALPlayerDemo_wav_helper_h_
#define OpenALPlayerDemo_wav_helper_h_

#include <stdint.h>

int load_wav_file(const char *file, void **data, size_t *size, size_t *freq);

#endif /* OpenALPlayerDemo_wav_helper_h_ */
