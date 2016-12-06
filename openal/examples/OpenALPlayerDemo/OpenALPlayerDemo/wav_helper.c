/*****************************************************************************\
** OpenALPlayerDemo:wav_helper.c
** Created by CZ(cz.devnet@gmail.com) on 12/5/16
**
**  Copyright © 2016 projm. All rights reserved.
\*****************************************************************************/

#include <stdio.h>
#include <stdlib.h>

#include "wav_helper.h"

int load_wav_file(const char *file, void **data, size_t *size, size_t *freq)
{
    if (NULL == file || NULL == data || NULL==size || NULL==freq) {
        return -1;
    }
    FILE *fp = fopen(file, "rb");
    if (NULL == fp) {
        return -1;
    }
    fseek(fp, 0, SEEK_END);
    long fs = ftell(fp);
    *data = malloc(fs-44);
    if (NULL == *data) {
        fclose(fp);
        return -1;
    }
    fseek(fp, 44, SEEK_SET);
    fread(*data, fs-44, 1, fp);
    fclose(fp);
    *size = fs-44;
    *freq = 11025;
    return 0;
}
