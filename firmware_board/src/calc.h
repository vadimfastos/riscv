#ifndef CALC_H
#define CALC_H


#include <stdint.h>
#include <stdbool.h>


/* Подсчёт строкового выражения в целых числах с учётом приоритетов.
 Допустимые входные символы: цифры, +, -, *
 Реализована обработка ошибок, сообщения об ошибке выводятся в консоль.
*/
bool calc(const char *s, int *result);

// Вспомогательная функция: подсчёт операции на стеке
bool calc_op(int *num_stack, int *num_stack_pos, char *op_stack, int *op_stack_pos);

// Вспомогательная функция, возвращает приоритет оператора. Чем ниже приоритет, тем раньше должен выполняться оператор.
int op_prior(char op);


#endif
