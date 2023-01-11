#include <stdio.h>
#include <stdarg.h>
#include <string.h>


// My printf function
// Support only d,u,x,s specifiers
const char printf_conv_table[] =  "0123456789ABCDEF";
int printf(const char *format, ...) {
	va_list args;
	va_start(args, format);
	int is_spec = 0;
	while (*format != 0) {
		char c = *format;
		if (!is_spec) { // We have no specifier, usual write
			if (c == '%') {
				is_spec = 1;
			} else {
				putchar(c);
			}
		} else { // Write with specifier
			char buffer[256];
			unsigned int radix = 10;
			unsigned int number = 0;
			int pos = 0;
			switch (c) {
			case '%':
				putchar('%');
				break;
			case 's':
				puts(va_arg(args, char *));
				break;
			case 'x':
				radix = 16;
			case 'u':
			case 'd':
				number = va_arg(args, unsigned int);
				if ((c=='d') && ((int)number < 0)) {
					number = -number;
					putchar('-');
				}
				do {
					buffer[pos] = printf_conv_table[number % radix];
					number /= radix;
					pos++;
				} while (number > 0);
				for (int i=pos-1; i>=0; i--)
					putchar(buffer[i]);
				break;
			default:
				break;
			}
			is_spec = 0;
		}
		// Go to next symbol
		format++;
	}
	va_end(args);
	return 0;
}
