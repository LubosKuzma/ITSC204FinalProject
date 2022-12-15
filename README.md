# ITSC204FinalProject

This is a repository for **ITSC 204 - Final Project** in Fall 2022.

*** client_v5.nasm is our final code ***

Things we worked on:

Gurkirat: TCP connection to server, file operations

Bryce: File operations

Sukhmandeep: analysing and review code features, such as C Call Convention

Geoffrey: Quick Sort, debugging client_v4.nasm

***********************************************

Progress record in fork repo by Geoffrey

2022-12-08:
Created first version of _quickSort

2022-12-10:
Debugged and modified client_v4.nasm to client_v5.nasm
  solved loop1 not writing properly to heap
  -> turned to using heap to store recieved message
  solved stack variable management issues which caused deleting return address

  updated _quickSort
  but still not functioning
