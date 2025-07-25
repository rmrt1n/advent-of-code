import re
from collections import Counter

print('day 01:')
print('length:', len(open('src/days/data/day01.txt').readlines()))

print('\nday 02:')
print('length:', len(open('src/days/data/day02.txt').readlines()))
print('report_capacity:', max(len(i.split(' ')) for i in open('src/days/data/day02.txt').readlines()))

print('\nday 03:')

print('\nday 04:')
print('length:', len(open('src/days/data/day04.txt').readlines()))

print('\nday 05:')
print('length:', len(open('src/days/data/day05.txt').read().strip().split('\n\n')[1].split('\n')))
print('update_capacity:', max(len(i.split(',')) for i in open('src/days/data/day05.txt').read().strip().split('\n\n')[1].split('\n')))

print('\nday 06:')
print('length:', len(open('src/days/data/day06.txt').readlines()))

print('\nday 07:')
print('length:', len(open('src/days/data/day07.txt').readlines()))
print('operand_capacity:', max(len(i.strip().split(': ')[1].split(' ')) for i in open('src/days/data/day07.txt').readlines()))

print('\nday 08:')
print('length:', len(open('src/days/data/day08.txt').readlines()))

print('\nday 09:')
print('length:', len(open('src/days/data/day09.txt').read().strip()))

print('\nday 10:')
print('length:', len(open('src/days/data/day10.txt').readlines()))

print('\nday 11:')
print('length:', len(open('src/days/data/day11.txt').read().split(' ')))

print('\nday 12:')
print('length:', len(open('src/days/data/day12.txt').readlines()))

print('\nday 13:')
print('length:', len(open('src/days/data/day13.txt').read().split('\n\n')))

print('\nday 14:')
print('length: ',len(open('src/days/data/day14.txt').readlines()))

print('\nday 15:')
print('length: ',len(open('src/days/data/day15.txt').read().strip().split('\n\n')[0].split('\n')))

print('\nday 16:')
print('length: ',len(open('src/days/data/day16.txt').readlines()))

print('\nday 17:')
print('length: ',len(open('src/days/data/day17.txt').readlines()[-1][9:].split(',')))

print('\nday 18:')
print('length: ',len(open('src/days/data/day18.txt').readlines()))

print('\nday 19:')
print('n_patterns: ',len(open('src/days/data/day19.txt').readlines()[0].strip().split(', ')))
print('n_designs: ', len(open('src/days/data/day19.txt').readlines()[2:]))
print('longest_string', len(max(open('src/days/data/day19.txt').readlines()[2:], key=len)) - 1) # rm \n

print('\nday 20:')
print('length: ',len(open('src/days/data/day20.txt').readlines()))

print('\nday 21:')

print('\nday 22:')
print('length: ', len(open('src/days/data/day22.txt').readlines()))

print('\nday 23:')

print('\nday 24:')
print('length: ', len(open('src/days/data/day24.txt').read().strip().split('\n\n')[1].split('\n')))

print('\nday 25:')
