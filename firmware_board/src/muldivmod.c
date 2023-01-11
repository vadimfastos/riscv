/* Так как в процессоре нет аппаратной поддержки инструкций умножения, деления и взятия остатка,
 * необходимо реализовать программную поддержку этих действий.
 *
 * Для полноценной поддержки умножения / деления нужно реализовать все приведённые ниже функции
 * (описание с сайта https://gcc.gnu.org/onlinedocs/gccint/Integer-library-routines.html).
 * Все многообразие функций можно свести к 2 функциям для осуществления
 *	64-битного беззнакового умножения и 64-битного беззнакового деления с нахождением остатка.
 *
 * При необходимости (ошибка сборки) в файл будут добавляться новые функции.
 */


#include <stdbool.h>
#include <stdlib.h>


/* These functions return the signed product of a and b. */
int __mulsi3 (int a, int b);
long __muldi3 (long a, long b);
long long __multi3 (long long a, long long b);


/* These functions return the unsigned product of a and b. */
unsigned int __umulsi3 (unsigned int a, unsigned int b);
unsigned long __umuldi3 (unsigned long a, unsigned long b);
unsigned long long __umulti3 (unsigned long long a, unsigned long long b);


/* These functions return the quotient of the signed division of num and denum. */
int __divsi3 (int num, int denum);
long __divdi3 (long num, long denum);
long long __divti3 (long long num, long long denum);


/* These functions return the remainder of the signed division of num and denum. */
int __modsi3 (int num, int denum);
long __moddi3 (long num, long denum);
long long __modti3 (long long num, long long denum);


/* These functions return the quotient of the unsigned division of num and denum. */
unsigned int __udivsi3 (unsigned int num, unsigned int denum);
unsigned long __udivdi3 (unsigned long num, unsigned long denum);
unsigned long long __udivti3 (unsigned long long num, unsigned long long denum);


/* These functions return the remainder of the unsigned division of num and denum. */
unsigned int __umodsi3 (unsigned int num, unsigned int denum);
unsigned long __umoddi3 (unsigned long num, unsigned long denum);
unsigned long long __umodti3 (unsigned long long num, unsigned long long denum);


/* These functions calculate both the quotient and remainder of the unsigned division of num and denum.
	The return value is the quotient, and the remainder is placed in variable pointed to by rem. */
unsigned int __udivmodsi4 (unsigned int num, unsigned int denum, unsigned int *rem);
unsigned long __udivmoddi4 (unsigned long num, unsigned long denum, unsigned long *rem);
unsigned long long __udivmodti4 (unsigned long long num, unsigned long long denum, unsigned long long *rem);



/* ------------------------------ Умножение чисел со знаком ------------------------------ */


// Умножение двух чисел типа int, учитываем знак и используем беззнаковое умножение
int __mulsi3 (int a, int b) {
	bool sign = (a < 0) ^ (b < 0);
	if (a < 0) a = -a;
	if (b < 0) b = -b;
	
	int c = (int)__umulsi3(a, b);
	if (sign)
		c = -c;
	return c;
}


// Умножение двух чисел типа long, учитываем знак и используем беззнаковое умножение
long __muldi3 (long a, long b) {
	bool sign = (a < 0) ^ (b < 0);
	if (a < 0) a = -a;
	if (b < 0) b = -b;
	
	long c = (long)__umuldi3(a, b);
	if (sign)
		c = -c;
	return c;
}


// Умножение двух чисел типа long long, учитываем знак и используем беззнаковое умножение
long long __multi3 (long long a, long long b) {
	bool sign = (a < 0) ^ (b < 0);
	if (a < 0) a = -a;
	if (b < 0) b = -b;
	
	long long c = (long)__umulti3(a, b);
	if (sign)
		c = -c;
	return c;
}



/* ------------------------------ Умножение чисел без знака ------------------------------ */


// Умножение двух чисел типа unsigned int, используем умножение столбиком
unsigned int __umulsi3 (unsigned int a, unsigned int b) {
	unsigned int c = 0;
	
	while (b != 0) {

		// умножаем сдвинутый первый множитель на бит второго множителя и прибавляем к результату
		if (b & 1)
			c += a;

		// сдвигаем первый множитель влево на 1 бит
		a = a << 1;

		// сдвигаем второй множитель вправо на 1 бит
		b = b >> 1;
	}
	return c;
}


// Беззнаковое умножение чисел типа unsigned long, используем умножение столбиком
unsigned long __umuldi3 (unsigned long a, unsigned long b) {
	unsigned long c = 0;
	
	while (b != 0) {

		// умножаем сдвинутый первый множитель на бит второго множителя и прибавляем к результату
		if (b & 1)
			c += a;

		// сдвигаем первый множитель влево на 1 бит
		a = a << 1;

		// сдвигаем второй множитель вправо на 1 бит
		b = b >> 1;
	}
	return c;
}


// Беззнаковое умножение чисел типа unsigned long long, используем умножение столбиком
unsigned long long __umulti3 (unsigned long long a, unsigned long long b) {
	unsigned long long c = 0;
	
	while (b != 0) {

		// умножаем сдвинутый первый множитель на бит второго множителя и прибавляем к результату
		if (b & 1)
			c += a;

		// сдвигаем первый множитель влево на 1 бит
		a = a << 1;

		// сдвигаем второй множитель вправо на 1 бит
		b = b >> 1;
	}
	return c;
}



/* ------------------------------ Знаковое деление/взятие остатка ------------------------------ */


// Целочисленное деление чисел со знаком типа int
int __divsi3 (int num, int denum) {
	bool sign = (num < 0) ^ (denum < 0);
	if (num < 0)
		num = -num;
	if (denum < 0)
		denum = -denum;
	
	int quot = (int)__udivmodsi4(num, denum, NULL);
	if (sign)
		quot = -quot;
	return quot;
}


// Целочисленное деление чисел со знаком типа long
long __divdi3 (long num, long denum) {
	bool sign = (num < 0) ^ (denum < 0);
	if (num < 0)
		num = -num;
	if (denum < 0)
		denum = -denum;
	
	long quot = (long)__udivmoddi4(num, denum, NULL);
	if (sign)
		quot = -quot;
	return quot;
}


// Целочисленное деление чисел со знаком типа long long
long long __divti3 (long long num, long long denum) {
	bool sign = (num < 0) ^ (denum < 0);
	if (num < 0)
		num = -num;
	if (denum < 0)
		denum = -denum;
	
	long long quot = (long long)__udivmodti4(num, denum, NULL);
	if (sign)
		quot = -quot;
	return quot;
}


// Взятие остатка от целочисленного деления чисел со знаком типа int
int __modsi3 (int num, int denum) {
	bool sign = (num < 0);
	if (num < 0)
		num = -num;
	if (denum < 0)
		denum = -denum;
	
	int rem = 0;
	__udivmodsi4(num, denum, (unsigned int*)&rem);
	if (sign)
		rem = -rem;
	return rem;
}


// Взятие остатка от целочисленного деления чисел со знаком типа long
long __moddi3 (long num, long denum) {
	bool sign = (num < 0);
	if (num < 0)
		num = -num;
	if (denum < 0)
		denum = -denum;
	
	long rem = 0;
	__udivmoddi4(num, denum, (unsigned long*)&rem);
	if (sign)
		rem = -rem;
	return rem;
}


// Взятие остатка от целочисленного деления чисел со знаком типа long long
long long __modti3 (long long num, long long denum) {
	bool sign = (num < 0);
	if (num < 0)
		num = -num;
	if (denum < 0)
		denum = -denum;
	
	long long rem = 0;
	__udivmodti4(num, denum, (unsigned long long*)&rem);
	if (sign)
		rem = -rem;
	return rem;	
}


/* ------------------------------ Беззнаковое деление/взятие остатка ------------------------------ */


// Целочисленное беззнаковое деление чисел типа unsigned int
unsigned int __udivsi3 (unsigned int num, unsigned int denum) {
	return __udivmodsi4(num, denum, NULL);
}


// Целочисленное беззнаковое деление чисел типа unsigned unsigned long
unsigned long __udivdi3 (unsigned long num, unsigned long denum) {
	return __udivmoddi4(num, denum, NULL);
}


// Целочисленное беззнаковое деление чисел типа unsigned unsigned long long
unsigned long long __udivti3 (unsigned long long num, unsigned long long denum) {
	return __udivmodti4(num, denum, NULL);
}


// Взятие остатка от целочисленного беззнакового деления чисел типа unsigned int
unsigned int __umodsi3 (unsigned int num, unsigned int denum) {
	unsigned int rem = 0;
	__udivmodsi4(num, denum, &rem);
	return rem;
}


// Взятие остатка от целочисленного беззнакового деления чисел типа unsigned long
unsigned long __umoddi3 (unsigned long num, unsigned long denum) {
	unsigned long rem = 0;
	__udivmoddi4(num, denum, &rem);
	return rem;
}


// Взятие остатка от целочисленного беззнакового деления чисел типа unsigned long long
unsigned long long __umodti3 (unsigned long long num, unsigned long long denum) {
	unsigned long long rem = 0;
	__udivmodti4(num, denum, &rem);
	return rem;
}



/* ------------------------------ Алгоритм деления/взятия остатка ------------------------------ */


// Нахождение частного и остатка при делении беззнаковых чисел типа unsigned int с помощью алгоритма деления "в столбик"
unsigned int __udivmodsi4 (unsigned int num, unsigned int denum, unsigned int *rem) {
    unsigned int quot, qbit;

    // Проверим, нет ли у нас деления на 0
    if (denum == 0)
        return (unsigned int)-1;

    // Умножаем на 2 (сдвигаем влево) делитель до тех пор, пока он не станет больше делимого и пока есть место
    qbit = 1;
    while (denum<num && ((int)denum)>0) {
        denum = denum << 1;
        qbit = qbit << 1;
    }

    // Реализуем жадный алгоритм, вычитаем из делимого умноженный на степень 2 (сдвинутый влево) делитель тогда, когда это возможно
    quot = 0;
    while (qbit != 0) {
        if (num >= denum) {
            num -= denum;
            quot |= qbit;
        }
        denum = denum >> 1;
        qbit = qbit >> 1;
    }

    if (rem != NULL)
        *rem = num;
    return quot;
}


// Нахождение частного и остатка при делении беззнаковых чисел типа unsigned long с помощью алгоритма деления "в столбик"
unsigned long __udivmoddi4 (unsigned long num, unsigned long denum, unsigned long *rem) {
    unsigned long quot, qbit;

    // Проверим, нет ли у нас деления на 0
    if (denum == 0)
        return (unsigned long)-1;

    // Умножаем на 2 (сдвигаем влево) делитель до тех пор, пока он не станет больше делимого и пока есть место
    qbit = 1;
    while (denum<num && ((long)denum)>0) {
        denum = denum << 1;
        qbit = qbit << 1;
    }

    // Реализуем жадный алгоритм, вычитаем из делимого умноженный на степень 2 (сдвинутый влево) делитель тогда, когда это возможно
    quot = 0;
    while (qbit != 0) {
        if (num >= denum) {
            num -= denum;
            quot |= qbit;
        }
        denum = denum >> 1;
        qbit = qbit >> 1;
    }

    if (rem != NULL)
        *rem = num;
    return quot;
}


// Нахождение частного и остатка при делении беззнаковых чисел типа unsigned long long с помощью алгоритма деления "в столбик"
unsigned long long __udivmodti4 (unsigned long long num, unsigned long long denum, unsigned long long *rem) {
    unsigned long long quot, qbit;

    // Проверим, нет ли у нас деления на 0
    if (denum == 0)
        return (unsigned long long)-1;

    // Умножаем на 2 (сдвигаем влево) делитель до тех пор, пока он не станет больше делимого и пока есть место
    qbit = 1;
    while (denum<num && ((long long)denum)>0) {
        denum = denum << 1;
        qbit = qbit << 1;
    }

    // Реализуем жадный алгоритм, вычитаем из делимого умноженный на степень 2 (сдвинутый влево) делитель тогда, когда это возможно
    quot = 0;
    while (qbit != 0) {
        if (num >= denum) {
            num -= denum;
            quot |= qbit;
        }
        denum = denum >> 1;
        qbit = qbit >> 1;
    }

    if (rem != NULL)
        *rem = num;
    return quot;
}
