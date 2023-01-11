#include <string.h>


/* Copy memory block */
void* memcpy(void* destination, const void* source, size_t num) {
	unsigned char *dst = (unsigned char*)destination;
	const unsigned char *src = (const unsigned char*)source;
	while (num != 0) {
		*dst = *src;
		dst++;
		src++;
		num--;
	}
	return destination;
}


/* Copy string */
char* strcpy(char* destination, const char* source) {
	char *dst = destination;
	while (*source) {
		*(destination) = *(source);
		source++;
		destination++;
	}
	*destination = 0;
	return dst;
}


/* Copy maximum 'num' bytes of string */
char* strncpy(char* destination, const char* source, size_t num) {
	char *dst = destination;
	while (*source && num!=0) {
		*destination = *source;
		source++;
		destination++;
		num--;
	}
	while (num != 0) {
		*destination = 0;
		destination++;
		num--;
	}
	return dst;
}


/* Compare memory blocks */
int memcmp(const void* ptr1, const void* ptr2, size_t num) {
	const unsigned char *p1 = (const unsigned char*)ptr1;
	const unsigned char *p2 = (const unsigned char*)ptr2;
	while (num > 0) {
		if (*p1 != *p2)
			return (int)(*p1) - (int)(*p2);
		p1++;
		p2++;
		num--;
	}
	return 0;
}


/* Compare strings */
int strcmp(const char *str1, const char *str2) {
	while (*str1 && *str1==*str2) {
		str1++;
		str2++;
	}
	return (int)(*str1) - (int)(*str2);
}


/* Compare first 'num' symbols of strings */
int strncmp(const char *str1, const char *str2, size_t num) {
	while (num!=0 && *str1 && *str1==*str2) {
		str1++;
		str2++;
		num--;
	}
	return (int)(*str1) - (int)(*str2);
}


/* Fill each byte of memory block with 'value' */
void* memset(void* ptr, int value, size_t num) {
	unsigned char *p = (unsigned char*)ptr;
	while (num != 0) {
		*p = (unsigned char)value;
		p++;
		num--;
	}
	return ptr;
}


/* Get string length */
size_t strlen(const char* str) {
	size_t len = 0;
	while (*str) {
		len++;
		str++;
	}
	return len;
}


/* String contencate */
char* strcat(char* destination, const char* source) {
	strcpy(destination + strlen(destination), source);
	return destination;
}


/* Find simbol (single byte) in memory block */
void* memchr(const void* ptr, int value, size_t num) {
	const unsigned char* p = (const unsigned char*)ptr;
	while (*p && num) {
		if (*p == (unsigned char)value)
			return (void*)p;
		p++;
		num--;
	}
	return NULL;
}


/* Find simbol in string */
char* strchr(const char* str, int character){
	while (*str) {
		if (*str == (char)character)
			return (char*)str;
		str++;
	}
	return NULL;
}
