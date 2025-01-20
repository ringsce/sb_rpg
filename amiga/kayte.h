#ifndef KAYTE_H
#define KAYTE_H

#include <aros/types.h>

int KayteInit(const char *config);
int KayteCompile(const char *sourceFile, const char *outputFile);
void KayteCleanup();

#endif /* KAYTE_H */

