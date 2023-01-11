#include <stdio.h>	
#include "calc.h"


/* Подсчёт строкового выражения в целых числах с учётом приоритетов.
 Допустимые входные символы: цифры, +, -, *
 Реализована обработка ошибок, сообщения об ошибке выводятся в консоль.
*/
bool calc(const char *s, int *result) {

    /* Используем метод двух стеков, в одном стеке будут храниться операнды (числа), в другом - операторы (знаки операций).
     При поступлении числа сразу добавляются в стек операндов.
     Если же встречается оператор, то пока приоритет нового оператора больше или равен приоритету оператора на верхушке стека,
     производятся вычисления. Затем новый оператор добавляется в стек.
     Когда вся строка разобрана, обрабатываются оставшиеся в стеке операторы.
    */

    // У нас нет скобок, большого количества операторов с различными приоритетами. Поэтому в стеках не будут накапливаться данные.
    const int max_stack_size = 30;
    int num_stack[max_stack_size];
    char op_stack[max_stack_size];

    // В начале оба стека пусты
    int num_stack_pos = 0, op_stack_pos = 0;
    num_stack[0] = 0;

    // Разбираем строку
	while (*s) {

        // Если попалась цифра, то считываем всё число и добавляем его в стек
		if (*s>='0' && *s<='9') {
            int cur_num = 0;
            while (*s>='0' && *s<='9') {
                cur_num = cur_num * 10 + *s - '0';
                s++;
            }
            num_stack[num_stack_pos] = cur_num;
            num_stack_pos++;
            continue;
		}

        // Если попался допустимый оператор, то обрабатываем его. Пробелы игнорируем, остальные символы вызывают ошибку (выходим).
        char ch = *s;
        if (ch=='+' || ch=='-' || ch=='*') {

            // Производим вычисления, пока приоритет нового оператора больше или равен приоритету оператора на верхушке стека
            while (op_stack_pos>0 && op_prior(ch)>=op_prior(op_stack[op_stack_pos-1]))
                if (!calc_op(num_stack, &num_stack_pos, op_stack, &op_stack_pos))
                    return false;

            // Добавляем новый операнд в стек
            op_stack[op_stack_pos] = ch;
            op_stack_pos++;

        } else if (ch != ' ') {
            printf("Calculating error: wrong character '%c'\n", ch);
            return false;
        }

        s++;
	}

    // Если стек операторов не пуст, то доделываем вычисления
    while (op_stack_pos > 0)
        if (!calc_op(num_stack, &num_stack_pos, op_stack, &op_stack_pos))
            return false;

    // В стеке должно быть одно число - результат
    if (num_stack_pos != 1) {
        printf("Calculating error: invalid expression\n");
        return false;
    }
    *result = num_stack[0];
	return true;
}


// Вспомогательная функция: подсчёт операции на стеке
bool calc_op(int *num_stack, int *num_stack_pos, char *op_stack, int *op_stack_pos) {

    // Ошибка: в стеке меньше двух операндов
    if (*num_stack_pos < 2) {
        printf("Calculating error: too little operands\n");
        return false;
    }

    // Вытаскиваем операнды и оператор со стека
    (*num_stack_pos)--;
    int b = num_stack[*num_stack_pos];
    (*num_stack_pos)--;
    int a = num_stack[*num_stack_pos];
    (*op_stack_pos)--;
    char op = op_stack[*op_stack_pos];

    // Вычисляем и запихиваем результат в стек
    int c;
    switch (op) {
    case '+': c = a + b; break;
    case '-': c = a - b; break;
    case '*': c = a * b; break;
    default: return false;
    }
    num_stack[*num_stack_pos] = c;
    (*num_stack_pos)++;
    return true;
}


// Вспомогательная функция, возвращает приоритет оператора. Чем ниже приоритет, тем раньше должен выполняться оператор.
int op_prior(char op) {
    switch (op) {
    case '+': return 2;
    case '-': return 2;
    case '*': return 1;
    }
    return 0;
}
